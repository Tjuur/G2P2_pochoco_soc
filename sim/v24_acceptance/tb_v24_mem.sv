`timescale 1ns/1ps
module tb_v24_mem;
  reg clk=0; always #20 clk=~clk;
  reg a_req=0,b_req=0,b_we=0; reg [31:0] aa=0,ba=0,wd=0; reg [3:0] be=15;
  wire [31:0] ar,br;
  pochoco_v24_mem #(.NumWords(1024),.MemFile("sw/trade.hex")) dut(clk,a_req,aa,ar,b_req,b_we,be,ba,wd,br);
  reg [31:0] expected [0:1023];
  integer i;
  initial begin
    $readmemh("sw/trade.hex",expected);
    // Sweep the full instruction address space; independent data writes in parallel.
    for(i=0;i<1024;i=i+1) begin
      @(negedge clk); a_req=1; aa=4*i; b_req=1;b_we=1;ba=32'h10000000+4*(i%256);wd=32'h5a000000+i;
      @(posedge clk); #1;
      if(ar!==expected[i]) $fatal(1,"ROM word %0d expected %08x got %08x",i,expected[i],ar);
    end
    for(i=0;i<256;i=i+1) begin
      @(negedge clk); b_req=1;b_we=0;ba=32'h10000000+4*i;aa=4*i;
      @(posedge clk); #1;
      if(br!==(32'h5a000300+i)) $fatal(1,"RAM word %0d",i);
      if(ar!==expected[i]) $fatal(1,"RAM write corrupted ROM word %0d",i);
    end
    $display("PASS split ROM/RAM, full address sweep and independent ports");$finish;
  end
endmodule
