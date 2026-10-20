module cycle_counter (
    input wire clk,
    input wire rst_ni,
    output reg [31:0] cycles
);

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni)
            cycles <= 32'd0;
        else
            cycles <= cycles + 32'd1;
    end

endmodule