module pochoco_price_accel (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        sel_i,
    input  wire        req_i,
    input  wire        we_i,
    input  wire [7:0]  addr_i,
    input  wire [31:0] wdata_i,
    output reg  [31:0] rdata_o
);

    reg [7:0] history [0:7];
    reg [2:0] index;
    reg [3:0] count;

    reg [2:0] signals;

    wire wr = sel_i && req_i && we_i && addr_i[7:2] == 0;
    wire rd = sel_i && req_i && !we_i;

    wire signed [8:0] new_delta =
        $signed({1'b0, wdata_i[7:0]}) -
        $signed({1'b0, history[index]});

    integer i;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            index <= 0;
            count <= 0;
            signals <= 0;
            rdata_o <= 0;

            for (i = 0; i < 8; i = i + 1)
                history[i] <= 0;

        end else begin
            if (wr) begin
                history[index] <= wdata_i[7:0];
                index <= index + 3'd1;

                if (count < 8)
                    count <= count + 4'd1;

                signals <= 3'b000;

                if (count >= 8) begin
                    signals[0] <= 1'b1;
                    signals[1] <= (new_delta <= -4);
                    signals[2] <= (new_delta >= 4);
                end
            end

            if (rd)
                rdata_o <= (addr_i[7:2] == 6'd3)
                         ? {29'b0, signals}
                         : 32'b0;
        end
    end

endmodule
