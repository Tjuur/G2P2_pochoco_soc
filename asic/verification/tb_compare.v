`timescale 1ns/1ps

module tb_compare;

    reg clk = 0;
    reg rst_n = 0;
    reg [3:0] buttons = 0;
    wire [3:0] leds;

    integer cycles = 0;
    integer timeout;
    reg [3:0] selected_led;
    reg [3:0] wrong_button;

    always #50 clk = ~clk;

    asic_top dut (
        .i_Clk(clk),
        .i_Reset_n(rst_n),
        .i_Switch(buttons),
        .o_LED(leds),
        .i_SPI_SCLK(1'b0),
        .i_SPI_MOSI(1'b0),
        .i_SPI_CS_n(1'b1)
    );

    always @(posedge clk) begin
        if (rst_n)
            cycles <= cycles + 1;
    end

    task wait_cycles(input integer n);
        integer j;
        begin
            for (j = 0; j < n; j = j + 1)
                @(negedge clk);
        end
    endtask

    task wait_for_selection;
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
                $display("FAIL: Selection timeout");
                $fatal(1);
            end

            selected_led = leds;
            $display("EVENT selection cycle=%0d led=%b",
                     cycles, selected_led);
        end
    endtask

    initial begin
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        wait_cycles(20);

        if (leds !== 4'b1111) begin
            $display("FAIL: Game startup");
            $fatal(1);
        end

        $display("EVENT startup cycle=%0d", cycles);

        wait_for_selection();

        buttons = selected_led;
        $display("EVENT correct_press cycle=%0d", cycles);

        wait_cycles(20);
        buttons = 0;

        timeout = 0;
        while (leds != 4'b1111 && timeout < 1000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        if (leds !== 4'b1111) begin
            $display("FAIL: Correct answer");
            $fatal(1);
        end

        $display("EVENT correct_advance cycle=%0d", cycles);

        wait_for_selection();

        wrong_button = (selected_led == 4'b0001)
                     ? 4'b0010 : 4'b0001;

        buttons = wrong_button;
        $display("EVENT wrong_press cycle=%0d", cycles);

        wait_cycles(20);
        buttons = 0;

        wait_cycles(10);

        if (leds !== 4'b0000) begin
            $display("FAIL: Wrong answer");
            $fatal(1);
        end

        $display("EVENT wrong_reset cycle=%0d", cycles);
        $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
