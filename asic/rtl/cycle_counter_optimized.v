module cycle_counter_optimized (
    input wire clk,
    input wire rst_ni,
    output reg [31:0] cycles
);

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            cycles <= 32'd0;
        end else begin
            cycles[7:0]   <= cycles[7:0]   + 8'd1;
            cycles[15:8]  <= cycles[15:8]  + (&cycles[7:0]);
            cycles[23:16] <= cycles[23:16] + (&cycles[15:0]);
            cycles[31:24] <= cycles[31:24] + (&cycles[23:0]);
        end
    end

endmodule
