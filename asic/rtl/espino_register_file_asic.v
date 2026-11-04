module espino_register_file (
    input wire clk_i,
    input wire rst_ni,

    input wire [3:0] raddr_a_i,
    output reg [31:0] rdata_a_o,

    input wire [3:0] raddr_b_i,
    output reg [31:0] rdata_b_o,

    input wire [3:0] waddr_i,
    input wire [31:0] wdata_i,
    input wire we_i
);

    reg [31:0] registers [0:15];

    integer i;

    // Initialize registers through hardware reset.
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (i = 0; i < 16; i = i + 1)
                registers[i] <= 32'b0;
        end else if (we_i && waddr_i != 4'd0) begin
            registers[waddr_i] <= wdata_i;
        end
    end

    // Preserve synchronous read latency.
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rdata_a_o <= 32'b0;
            rdata_b_o <= 32'b0;
        end else begin
            rdata_a_o <= (raddr_a_i == 4'd0)
                       ? 32'b0 : registers[raddr_a_i];

            rdata_b_o <= (raddr_b_i == 4'd0)
                       ? 32'b0 : registers[raddr_b_i];
        end
    end

endmodule
