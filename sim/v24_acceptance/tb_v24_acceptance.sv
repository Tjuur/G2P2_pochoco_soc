// Acceptance testbench based on course SPI interface. Simulation only.
// Requires the actual V24-T firmware, never flash from this bench.
`timescale 1ns/1ps
module tb_v24_acceptance;
  parameter PROGRAMA = "sw/trade.hex";
  reg clk=0;
  always #20 clk=~clk;
  reg sclk=0,mosi=0,cs_n=1;
  wire miso;
  pochoco_soc #(.MemFile(PROGRAMA)) dut (
    .i_Clk(clk), .o_LED(), .i_Switch(4'b0000),
    .o_Segment1_A(), .o_Segment1_B(), .o_Segment1_C(), .o_Segment1_D(),
    .o_Segment1_E(), .o_Segment1_F(), .o_Segment1_G(),
    .o_Segment2_A(), .o_Segment2_B(), .o_Segment2_C(), .o_Segment2_D(),
    .o_Segment2_E(), .o_Segment2_F(), .o_Segment2_G(),
    .i_SPI_SCLK(sclk), .i_SPI_MOSI(mosi), .i_SPI_CS_n(cs_n), .o_SPI_MISO(miso));
  reg [7:0] prices [0:19999], expected [0:19999], expected_next [0:19999];
  string pricefile, decisionfile, nextfile, outfile;
  integer n=20000, period_ns=100000, half_ns=500, phase_ns=7, repetitions=1;
  integer narg, i, round_id, fd, q, cash, shares, wealth, orders, peak, dd;
  integer reads, writes, bytes_seen, cycles, max_cycles, cycles_at_done;
  integer cycle_counter=0;
  integer total_cycles=0;
  integer max_compute_cycles=0;
  integer ic=0, total_ic=0, max_ic=0;
  reg computing=0;
  reg armed=0;
  reg [7:0] next_written, decision;
  always @(posedge clk) begin
    cycle_counter=cycle_counter+1;
    if (armed) begin
      if (dut.u_spi.byte_done) begin
        if (dut.u_spi.new_price_q) $fatal(1,"Unconsumed previous price at tick %0d",i);
        bytes_seen=bytes_seen+1;
        cycles_at_done=cycle_counter;
        computing=1; ic=0;
      end
      if (computing && dut.u_core.u_id.commit) begin
        ic=ic+1;
        if(dut.u_core.illegal_insn) $fatal(1,"Illegal instruction at tick %0d pc=%08x",i,dut.u_core.pc_id);
      end
      if (dut.u_spi.rd && dut.u_spi.off==1) begin
        if (bytes_seen!=1) $fatal(1,"Price read before complete byte at tick %0d",i);
        reads=reads+1;
      end
      if (dut.u_spi.wr && dut.u_spi.off==2) begin
        if (bytes_seen!=1 || reads<1) $fatal(1,"Decision before price at tick %0d",i);
        writes=writes+1;
        next_written=dut.u_spi.wdata_i[7:0];
        cycles=cycle_counter-cycles_at_done;
        if (cycles>max_cycles) max_cycles=cycles;
        if (cycles>max_compute_cycles) max_compute_cycles=cycles;
        total_cycles=total_cycles+cycles;
        total_ic=total_ic+ic;
        if(ic>max_ic) max_ic=ic;
        computing=0;
      end
    end
  end
  task automatic spi(input [7:0] tx,output reg [7:0] rx);
    integer b;
    begin
      cs_n=0; #1000;
      for(b=7;b>=0;b=b-1) begin
        mosi=tx[b]; #(half_ns); sclk=1;
        if (miso!==1'b0 && miso!==1'b1) $fatal(1,"MISO X/Z at tick %0d bit %0d",i,b);
        rx[b]=miso;
        #(half_ns); sclk=0;
      end
      #500; cs_n=1;
    end
  endtask
  task automatic execute_order(input [7:0] b,input integer p);
    begin
      q=b[5:0];
      case(b[7:6])
        2'b01: begin
          if(cash<5) q=0;
          else if(q>(cash-5)/p) q=(cash-5)/p;
          if(q>0) begin cash=cash-q*p-5; shares=shares+q; orders=orders+1; end
        end
        2'b10: begin
          if(q>shares) q=shares;
          if(q>0 && cash+q*p>=5) begin cash=cash+q*p-5; shares=shares-q; orders=orders+1; end
        end
        default: ;
      endcase
      if(cash<0 || shares<0) $fatal(1,"Invalid real ledger at tick %0d",i);
      wealth=cash+shares*p;
      if(wealth>peak) peak=wealth;
      if(peak-wealth>dd) dd=peak-wealth;
    end
  endtask
  // Require the firmware to finish clearing state and publish its initial HOLD.
  task automatic wait_boot;
    integer elapsed;
    begin
      elapsed = 0;

      @(negedge clk);

      while (!(dut.u_spi.wr === 1'b1 &&
               dut.u_spi.off === 2) &&
               elapsed < 25000) begin
        @(negedge clk);
        elapsed = elapsed + 1;
      end

      if (!(dut.u_spi.wr === 1'b1 &&
            dut.u_spi.off === 2))
        $fatal(1,"Firmware boot timeout");

      if (dut.u_spi.wdata_i[7:0] !== 8'h00)
        $fatal(1,"Boot decision is not HOLD");

      @(posedge clk);
      #1000;

      $display("PASS firmware initialized at %0t",$time);
    end
  endtask

  task automatic wait_por;
    integer elapsed;
    begin
      elapsed = 0;

      while (dut.rst_ni !== 1'b1 &&
             elapsed < 2500000) begin
        @(negedge clk);
        elapsed = elapsed + 1;
      end

      if (dut.rst_ni !== 1'b1)
        $fatal(1,"Power-on reset timeout");

      $display("PASS reset released at %0t",$time);
    end
  endtask
  initial begin
    if (!$value$plusargs("PRICES=%s",pricefile)) $fatal(1,"Missing +PRICES");
    if (!$value$plusargs("DECISIONS=%s",decisionfile)) $fatal(1,"Missing +DECISIONS");
    if (!$value$plusargs("NEXT=%s",nextfile)) $fatal(1,"Missing +NEXT");
    if (!$value$plusargs("OUT=%s",outfile)) $fatal(1,"Missing +OUT");
    narg=$value$plusargs("N=%d",n);
    narg=$value$plusargs("PERIOD=%d",period_ns);
    narg=$value$plusargs("HALF=%d",half_ns);
    narg=$value$plusargs("PHASE=%d",phase_ns);
    narg=$value$plusargs("REPEAT=%d",repetitions);
    if(n<1 || n>20000 || half_ns<500 || period_ns<=1500+16*half_ns || repetitions<1) $fatal(1,"Invalid configuration");
    $readmemh(pricefile,prices); $readmemh(decisionfile,expected); $readmemh(nextfile,expected_next);
    wait_por;
    wait_boot;
    #(phase_ns);
    for(round_id=0;round_id<repetitions;round_id=round_id+1) begin
      if(round_id>0) begin
        // Internal reset forced for simulation ONLY. Must separately validate real reset mechanism.
        force dut.rst_ni=1'b0;
        #1000; release dut.rst_ni;
        wait(dut.rst_ni===1'b1);
        wait_boot;
      end
      cash=10000; shares=0; wealth=10000; peak=10000; dd=0; orders=0; max_cycles=0;
      total_cycles=0; max_compute_cycles=0; total_ic=0; max_ic=0; computing=0;
      fd=$fopen(outfile,"w"); if(fd==0) $fatal(1,"Cannot open output");
      $fdisplay(fd,"tick,precio,decision,caja,acciones,patrimonio,next_decision");
      for(i=0;i<n;i=i+1) begin
        if(^prices[i]===1'bx || prices[i]==0 || ^expected[i]===1'bx || ^expected_next[i]===1'bx) $fatal(1,"Invalid oracle at tick %0d",i);
        reads=0; writes=0; bytes_seen=0; next_written=8'hxx; armed=1;
        spi(prices[i],decision);
        if(decision!==expected[i]) $fatal(1,"SPI decision mismatch tick %0d expected %02h got %02h",i,expected[i],decision);
        execute_order(decision,prices[i]);
        #(period_ns-1500-16*half_ns);
        armed=0;
        if(bytes_seen!=1 || reads!=1 || writes!=1) $fatal(1,"Tick %0d byte/read/write=%0d/%0d/%0d",i,bytes_seen,reads,writes);
        if(dut.u_spi.new_price_q!==1'b0) $fatal(1,"Price flag not cleared at tick %0d",i);
        if(next_written!==expected_next[i]) $fatal(1,"New decision mismatch tick %0d expected %02h got %02h",i,expected_next[i],next_written);
        if(dut.u_ram.ram[106]!==cash || dut.u_ram.ram[107]!==shares)
          $fatal(1,"Internal ledger mismatch tick %0d cash=%0d/%0d shares=%0d/%0d",i,dut.u_ram.ram[106],cash,dut.u_ram.ram[107],shares);
        $fdisplay(fd,"%0d,%0d,%02h,%0d,%0d,%0d,%02h",i,prices[i],decision,cash,shares,wealth,next_written);
      end
      $fclose(fd);
      $display("PASS round=%0d ticks=%0d period_ns=%0d half_spi_ns=%0d wealth=%0d orders=%0d fees=%0d dd=%0d max_cycles=%0d mean_cycles=%f",round_id,n,period_ns,half_ns,wealth,orders,orders*5,dd,max_cycles,1.0*total_cycles/n);
      $display("METRICS mean_IC=%f max_IC=%0d CPI=%f mean_time_ns=%f max_time_ns=%0d",1.0*total_ic/n,max_ic,1.0*total_cycles/total_ic,40.0*total_cycles/n,40*max_cycles);
    end
    $display("PASS RTL SPI, all decisions, per-tick reads/writes and deadlines");
    $finish;
  end
endmodule
