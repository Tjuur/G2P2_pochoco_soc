`timescale 1ns/1ps

module tb_price_accel;

    parameter integer VERSION = 2;

    reg clk_i = 0;
    reg rst_ni = 0;
    reg sel_i = 0;
    reg req_i = 0;
    reg we_i = 0;
    reg [7:0] addr_i = 0;
    reg [31:0] wdata_i = 0;

    wire [31:0] rdata_o;

    integer tests = 0;

    always #20 clk_i = ~clk_i;

    pochoco_price_accel dut (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .sel_i(sel_i),
        .req_i(req_i),
        .we_i(we_i),
        .addr_i(addr_i),
        .wdata_i(wdata_i),
        .rdata_o(rdata_o)
    );

    task automatic check(
        input [31:0] actual,
        input [31:0] expected,
        input [255:0] description
    );
        begin
            tests = tests + 1;

            if (actual !== expected) begin
                $display(
                    "FAIL: %0s | esperado=%h obtenido=%h",
                    description, expected, actual
                );
                $fatal(1);
            end

            $display("PASS: %0s", description);
        end
    endtask

    task automatic write_price(input [7:0] price);
        begin
            @(negedge clk_i);
            sel_i = 1;
            req_i = 1;
            we_i = 1;
            addr_i = 0;
            wdata_i = {24'b0, price};

            @(negedge clk_i);
            sel_i = 0;
            req_i = 0;
            we_i = 0;
        end
    endtask

    task automatic read_reg(
        input [7:0] address,
        output [31:0] value
    );
        begin
            @(negedge clk_i);
            sel_i = 1;
            req_i = 1;
            we_i = 0;
            addr_i = address;

            @(negedge clk_i);
            value = rdata_o;

            sel_i = 0;
            req_i = 0;
        end
    endtask

    reg [31:0] value;
    integer i;

    initial begin
        repeat (3) @(negedge clk_i);
        rst_ni = 1;

        // Ocho precios iniciales: 100.
        for (i = 0; i < 7; i = i + 1)
            write_price(100);

        if (VERSION == 1) begin
            read_reg(8, value);
            check(value, 0, "Historial incompleto");
        end else begin
            read_reg(12, value);
            check(value, 0, "Flags invalidos durante warmup");
        end

        write_price(100);

        if (VERSION == 1) begin
            read_reg(8, value);
            check(value, 1, "Historial completo");
        end else begin
            read_reg(12, value);
            check(value, 0, "Octavo precio aun en warmup");
        end

        // Precio 96 contra precio historico 100.
        write_price(96);

        if (VERSION == 1) begin
            read_reg(4, value);
            check(value, 32'hFFFFFFFC, "Delta negativo -4");
        end else begin
            read_reg(12, value);
            check(value, 3, "Flag de compra con delta -4");
        end

        // Precio 105 contra precio historico 100.
        write_price(105);

        if (VERSION == 1) begin
            read_reg(4, value);
            check(value, 5, "Delta positivo +5");
        end else begin
            read_reg(12, value);
            check(value, 5, "Flag de venta con delta +5");
        end

        // Precio 102 contra precio historico 100.
        write_price(102);

        if (VERSION == 1) begin
            read_reg(4, value);
            check(value, 2, "Delta dentro del umbral");
        end else begin
            read_reg(12, value);
            check(value, 1, "Sin senal de compra o venta");
        end

        $display(
            "PASS: Acelerador %0d, %0d verificaciones",
            VERSION, tests
        );

        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "Timeout del testbench");
    end

endmodule
