`timescale 1ns/1ps

module tb_cycle_counter;

    reg clk = 0;
    reg rst_ni = 0;

    wire [31:0] original;
    wire [31:0] optimized;

    always #5 clk = ~clk;

    cycle_counter dut_original (
        .clk(clk),
        .rst_ni(rst_ni),
        .cycles(original)
    );

    cycle_counter_optimized dut_optimized (
        .clk(clk),
        .rst_ni(rst_ni),
        .cycles(optimized)
    );

    initial begin
        #12;
        rst_ni = 1;

        repeat (100000) begin
            @(negedge clk);

            if (original !== optimized) begin
                $display("FAIL: original=%h optimized=%h",
                         original, optimized);
                $finish;
            end
        end

        $display("PASS: 100000 ciclos equivalentes");
        $finish;
    end

endmodule
