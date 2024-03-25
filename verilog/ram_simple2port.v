/**
 * 2-port (1 read, 1 write) RAM
 *
 *
 */


 module ram_simple2port #(
    parameter BDADDR = 12,
    parameter BDWORD = 32*64
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
    end else begin
        rd_word <= {BDWORD{1'b0}};
    end
    if (wr_en) begin
        mem[wr_addr] <= wr_word;
    end
end


endmodule