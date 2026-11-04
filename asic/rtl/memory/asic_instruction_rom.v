module asic_instruction_rom (
    input wire clk_i,
    input wire req_i,
    input wire [31:0] addr_i,
    output reg [31:0] rdata_o
);

    wire [31:0] rom_data;

    game_rom u_game_rom (
        .addr_i(addr_i),
        .data_o(rom_data)
    );

    always @(posedge clk_i) begin
        if (req_i)
            rdata_o <= rom_data;
    end

endmodule
