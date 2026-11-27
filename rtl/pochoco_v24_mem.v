// Separate synchronous instruction ROM and word data RAM for V24-T.
// All software data accesses are aligned word accesses; no byte-write logic.
module pochoco_v24_mem #(
  parameter NumWords=1024, parameter MemFile="sw/trade.hex"
)(input wire clk_i,
   input wire a_req_i, input wire [31:0] a_addr_i, output reg [31:0] a_rdata_o,
   input wire b_req_i, input wire b_we_i, input wire [3:0] b_be_i,
   input wire [31:0] b_addr_i, input wire [31:0] b_wdata_i, output reg [31:0] b_rdata_o);
  localparam AW=$clog2(NumWords);
  reg [31:0] rom [0:NumWords-1];
  reg [31:0] ram [0:255];
  initial $readmemh(MemFile,rom);
  always @(posedge clk_i) begin
    if(a_req_i) a_rdata_o <= rom[a_addr_i[AW+1:2]];
    if(b_req_i) begin
      if(b_we_i && (&b_be_i)) ram[b_addr_i[9:2]] <= b_wdata_i;
      else b_rdata_o <= ram[b_addr_i[9:2]];
    end
  end
endmodule
