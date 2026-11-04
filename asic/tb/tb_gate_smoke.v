`timescale 1ns/1ps

module tb_gate_smoke;

    reg clk = 0;
    reg rst_n = 0;
    reg [3:0] buttons = 0;

    wire [3:0] leds;

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

    initial begin
        $display("Starting gate-level smoke test");

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        repeat (1000) @(negedge clk);

        if (^leds === 1'bx) begin
            $display("FAIL: LEDs contain unknown values");
            $fatal(1);
        end

        $display("PASS: Gate-level smoke test");
        $display("Final LEDs: %b", leds);

        $finish;
    end

endmodule
