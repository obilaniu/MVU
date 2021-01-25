/**
 * High-precision data RAM
 *
 *
 */


 module ram_highprec #(
    BDADDR = 12,
    BDWORD = 32*64
)(
    input   wire                clk,
    input   wire                rd_en,
    input   wire[BDADDR-1 : 0]  rd_addr, 
    output  reg [BDWORD-1 : 0]  rd_word,
    input   wire                wr_en,
    input   wire[BDADDR-1 : 0]  wr_addr,
    input   wire[BDWORD-1 : 0]  wr_word
 );


// Use vanilla Verilog code and have synthesizer infer.
// For Xilinx, structuring for UltraRAM blocks.
reg [BDWORD-1 : 0] mem[2**BDADDR-1 : 0];

always @(posedge clk) begin
    if (rd_en) begin
        rd_word <= mem[rd_addr];
    end
    if (wr_en) begin
        mem[wr_addr] <= wr_word;
    end
end


endmodule