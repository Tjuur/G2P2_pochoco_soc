`timescale 1ns/1ps

module tb_asic_top;

    parameter USE_UNIFIED_MEMORY = 0;

    reg clk = 0;
    reg rst_n = 0;
    reg [3:0] buttons = 0;

    wire [3:0] leds;

    always #50 clk = ~clk;

    asic_top #(
        .USE_UNIFIED_MEMORY(USE_UNIFIED_MEMORY)
    ) dut (
        .i_Clk(clk),
        .i_Reset_n(rst_n),
        .i_Switch(buttons),
        .o_LED(leds),

        .i_SPI_SCLK(1'b0),
        .i_SPI_MOSI(1'b0),
        .i_SPI_CS_n(1'b1)
    );





    // Debug: button MMIO reads
    always @(negedge clk) begin
        if (buttons != 4'b0000) begin
            $display(
                "[DEBUG %0t] buttons=%b data_req=%b data_we=%b data_addr=%h per_rdata=%h",
                $time,
                buttons,
                dut.u_pochoco.data_req,
                dut.u_pochoco.data_we,
                dut.u_pochoco.data_addr,
                dut.u_pochoco.per_rdata
            );
        end
    end

    // Monitor LED transitions
    always @(leds) begin
        $display(
            "[TIME %0t] LEDs changed to %b | buttons=%b",
            $time, leds, buttons
        );
    end

    integer cycles = 0;
    integer start_cycle = -1;
    integer selection_cycle = -1;

    reg started = 0;
    reg selected = 0;
    reg correct_detected = 0;
    reg wrong_detected = 0;

    reg [3:0] selected_led;
    reg [3:0] wrong_button;

    // Esperar una cantidad determinada de ciclos
    task wait_cycles(input integer n);
        integer j;
        begin
            for (j = 0; j < n; j = j + 1)
                @(negedge clk);
        end
    endtask

    // Esperar hasta que aparezca un LED individual
    task wait_for_selection;
        integer timeout;
        begin
            timeout = 0;

            while (!(leds == 4'b0001 ||
                     leds == 4'b0010 ||
                     leds == 4'b0100 ||
                     leds == 4'b1000) && timeout < 2000) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 2000) begin
                $display("FAIL: LED selection timeout");
                $fatal(1);
            end

            selected_led = leds;
        end
    endtask

    initial begin
        $display("Starting ASIC simulation");
        $display("Memory architecture: %0d", USE_UNIFIED_MEMORY);

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        // Esperar inicio
        wait_cycles(20);

        if (leds != 4'b1111) begin
            $display("FAIL: Game did not start");
            $fatal(1);
        end

        $display("PASS: Game started");

        // Primera selección
        wait_for_selection();

        $display("PASS: Selected LED = %b", selected_led);

        // Presionar botón correcto
        buttons = selected_led;
        wait_cycles(20);
        buttons = 0;

        $display("PASS: Correct button submitted");

        // Esperar nueva ronda sin perder la transición
        begin : wait_next_round
            integer timeout;
            timeout = 0;

            while (leds != 4'b1111 && timeout < 1000) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (leds != 4'b1111) begin
                $display("FAIL: Game did not advance");
                $fatal(1);
            end
        end

        $display("PASS: Game advanced after correct button");

        // Segunda selección
        wait_for_selection();

        $display("PASS: Second LED = %b", selected_led);

        // Elegir un botón incorrecto
        wrong_button = (selected_led == 4'b0001)
                     ? 4'b0010 : 4'b0001;

        buttons = wrong_button;
        wait_cycles(20);
        buttons = 0;

        // Verificar que se apaguen los LEDs
        wait_cycles(10);

        if (leds != 4'b0000) begin
            $display("FAIL: Wrong button not detected");
            $fatal(1);
        end

        $display("PASS: Wrong button detected");

        $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
