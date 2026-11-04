module asic_data_ram #(
    parameter NumWords = 64
) (
    input wire clk_i,

    input wire req_i,
    input wire we_i,
    input wire [3:0] be_i,

    input wire [31:0] addr_i,
    input wire [31:0] wdata_i,

    output reg [31:0] rdata_o
);

    localparam AddrW = $clog2(NumWords);

    reg [31:0] mem [0:NumWords-1];

    wire [AddrW-1:0] word_addr;
    assign word_addr = addr_i[AddrW+1:2];

    always @(posedge clk_i) begin
        if (req_i && we_i) begin
            if (be_i[0])
                mem[word_addr][7:0] <= wdata_i[7:0];

            if (be_i[1])
                mem[word_addr][15:8] <= wdata_i[15:8];

            if (be_i[2])
                mem[word_addr][23:16] <= wdata_i[23:16];

            if (be_i[3])
                mem[word_addr][31:24] <= wdata_i[31:24];
        end

        rdata_o <= mem[word_addr];
    end

endmodule
