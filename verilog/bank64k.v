/**
 * Data Bank
 * 
 * 128-bit-wide access, 64kbit (8KB) total.
 */

`timescale 1ns/1ps

/**** Module bank64k ****/
module bank64k(clk,
               rd_en,    rd_addr, rd_muxcode,
               wr_en,    wr_addr, wr_muxcode,
               rdi_word, wri_word,
               rdd_word, wrd_word,
               rdc_word, wrc_word);


/* Parameters */
parameter  w = 64;
parameter  a = 10;
parameter C_DISABLE_WARN_BHV_COLL = 0;


/* Interface */
input  wire          clk;

input  wire          rd_en;
input  wire[a-1 : 0] rd_addr;
input  wire[  1 : 0] rd_muxcode;
input  wire          wr_en;
input  wire[a-1 : 0] wr_addr;
input  wire[  1 : 0] wr_muxcode;

output wire[w-1 : 0] rdi_word;
output wire[w-1 : 0] rdd_word;
output wire[w-1 : 0] rdc_word;

input  wire[w-1 : 0] wri_word;
input  wire[w-1 : 0] wrd_word;
input  wire[w-1 : 0] wrc_word;


/* Local */
wire[w-1 : 0] rd_word;
reg[w-1 : 0] wr_word;
genvar i;



/* Wiring */
always @(wri_word or wrd_word or wrc_word or wr_muxcode) begin
    case (wr_muxcode)
        2'b00: wr_word = wri_word;
        2'b01: wr_word = wrd_word;
        2'b10: wr_word = wrc_word;
        default: wr_word = {w{1'b0}};
    endcase
end
    
/*   Bcast Read */
assign rdi_word = rd_word;
assign rdd_word = rd_word;
assign rdc_word = rd_word;

/* Temporary signals */
wire[w-1 : 0] douta;
wire[w-1 : 0] dinb;

// Temporary assignments
assign dinb = 0;

/* 64k internal BRAM */
`ifdef INTEL
    bram64k b (clk, wr_word, rd_addr, wr_addr, wr_en, rd_word);
`elsif XILINX_BRAM_IP
    bram64k_64x1024_xilinx b (
        .clka(clk),    // input wire clka
        .ena(1'b1),         // always enabled
        .wea(wr_en),      // input wire [0 : 0] wea
        .addra(wr_addr),  // input wire [9 : 0] addra
        .dina(wr_word),    // input wire [63 : 0] dina
        .douta(douta),      // output data (going nowhere, for now)
        .clkb(clk),    // input wire clkb
        .enb(rd_en),      // input wire enb
        .web(1'b0),         // disable writes on second port (for now)
        .addrb(rd_addr),  // input wire [9 : 0] addrb
        .dinb(dinb),        // input data (going nowhere, for now)
        .doutb(rd_word)  // output wire [64 : 0] doutb
    );
`else
    ram_simple2port #(
        .BDADDR (a),
        .BDWORD (w)        
    ) data_ram (
        .clk(clk),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_word(rd_word),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_word(wr_word)
    );
`endif


/* Module end */
endmodule
