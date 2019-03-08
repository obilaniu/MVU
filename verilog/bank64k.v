/**
 * Data Bank
 * 
 * 128-bit-wide access, 64kbit (8KB) total.
 */


/**** Module bank64k ****/
module bank64k(clk,
               rd_en,    rd_addr, rd_muxcode,
               wr_en,    wr_addr, wr_muxcode,
               rdi_word, wri_word,
               rdd_word, wrd_word,
               rdc_word, wrc_word);


/* Parameters */
parameter  w = 128;
parameter  a =   9;


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
wire[w-1 : 0] wr_word;
genvar i;



/* Wiring */
/*   Muxed Write */
generate for(i=0;i<w;i=i+1) begin:mux
    wire[2:0] wr_bits = {wri_word[i], wrd_word[i], wrc_word[i]};
    assign wr_word[i] = wr_bits[wr_muxcode];
end endgenerate
/*   Bcast Read */
assign rdi_word = rd_word;
assign rdd_word = rd_word;
assign rdc_word = rd_word;


/* 64k internal BRAM */
bram64k b (clk, wr_word, rd_addr, wr_addr, wr_en, rd_word);


/* Module end */
endmodule
