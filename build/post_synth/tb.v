`timescale 1ns/1ps

module tb;

  reg clk = 0;
  always #20 clk = ~clk;

  reg [3:0] switches = 0;

  reg spi_sclk = 0;
  reg spi_mosi = 0;
  reg spi_cs_n = 1;

  wire spi_miso;
  wire [3:0] leds;

  game_top dut (
    .i_Clk(clk),
    .i_Switch(switches),
    .o_LED(leds),
    .i_SPI_SCLK(spi_sclk),
    .i_SPI_MOSI(spi_mosi),
    .i_SPI_CS_n(spi_cs_n),
    .o_SPI_MISO(spi_miso)
  );

  initial begin
    $display("=== SIMULACION POST-SYNTHESIS ===");

    #1000000;

    $display("LED finales: %b", leds);

    if (leds === 4'b1111)
      $display("PASS: instrucciones detectadas");
    else
      $display("FAIL: instrucciones no detectadas");

    $finish;
  end

endmodule
