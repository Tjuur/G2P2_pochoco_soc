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

    reg signed [8:0] delta;
    reg [7:0] decision;
    reg position;

    wire access = sel_i && req_i;
    wire wr = access && we_i;
    wire rd = access && !we_i;

    wire [5:0] off = addr_i[7:2];

    wire signed [8:0] new_delta =
        $signed({1'b0, wdata_i[7:0]}) -
        $signed({1'b0, history[index]});

    integer i;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            index <= 0;
            count <= 0;
            delta <= 0;
            decision <= 0;
            position <= 0;
            rdata_o <= 0;

            for (i = 0; i < 8; i = i + 1)
                history[i] <= 0;

        end else begin

            if (wr && off == 0) begin
                delta <= new_delta;

                history[index] <= wdata_i[7:0];
                index <= index + 3'd1;

                if (count < 8)
                    count <= count + 4'd1;

                decision <= 8'h00;

                if (count >= 8) begin

                    if (!position && new_delta <= -4) begin
                        decision <= 8'h7F;
                        position <= 1'b1;
                    end

                    else if (position && new_delta >= 4) begin
                        decision <= 8'hBF;
                        position <= 1'b0;
                    end

                end
            end

            if (rd) begin
                case (off)
                    6'd1: rdata_o <= {{23{delta[8]}}, delta};
                    6'd2: rdata_o <= {31'b0, count == 8};
                    6'd3: rdata_o <= {24'b0, decision};
                    default: rdata_o <= 0;
                endcase
            end

        end
    end

endmodule
