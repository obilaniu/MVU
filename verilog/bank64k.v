/**
 * Data Bank
 * 
 * 128-bit-wide access, 64kbit (8KB) total.
 */


/**** Module portmux ****/
module bank64k(clk,
               rdi_csel, rdi_en, rdi_addr, rdi_word, rdi_grnt,
               wri_csel, wri_en, wri_addr, wri_word, wri_grnt,
               rdd_csel, rdd_en, rdd_addr, rdd_word, rdd_grnt,
               wrd_csel, wrd_en, wrd_addr, wrd_word, wrd_grnt,
               rdc_csel, rdc_en, rdc_addr, rdc_word, rdc_grnt,
               wrc_csel, wrc_en, wrc_addr, wrc_word, wrc_grnt);


/* Parameters */
parameter  w = 128;
parameter  a =   9;


/* Interface */
input  wire          clk;

input  wire          rdi_csel;
input  wire          rdi_en;
input  wire[a-1 : 0] rdi_addr;
output wire[w-1 : 0] rdi_word;
output wire          rdi_grnt;
input  wire          wri_csel;
input  wire          wri_en;
input  wire[a-1 : 0] wri_addr;
input  wire[w-1 : 0] wri_word;
output wire          wri_grnt;

input  wire          rdd_csel;
input  wire          rdd_en;
input  wire[a-1 : 0] rdd_addr;
output wire[w-1 : 0] rdd_word;
output wire          rdd_grnt;
input  wire          wrd_csel;
input  wire          wrd_en;
input  wire[a-1 : 0] wrd_addr;
input  wire[w-1 : 0] wrd_word;
output wire          wrd_grnt;

input  wire          rdc_csel;
input  wire          rdc_en;
input  wire[a-1 : 0] rdc_addr;
output wire[w-1 : 0] rdc_word;
output wire          rdc_grnt;
input  wire          wrc_csel;
input  wire          wrc_en;
input  wire[a-1 : 0] wrc_addr;
input  wire[w-1 : 0] wrc_word;
output wire          wrc_grnt;

/* Local */
wire          wr_en;
wire[a-1 : 0] rd_addr;
wire[a-1 : 0] wr_addr;
wire[w-1 : 0] rd_word;
wire[w-1 : 0] wr_word;


/* Wiring */
assign rdi_grnt =  rdi_csel &  rdi_en;
assign rdd_grnt = ~rdi_grnt &  rdd_csel &  rdd_en;
assign rdc_grnt = ~rdi_grnt & ~rdd_grnt &  rdc_csel &  rdc_en;
assign wri_grnt =  wri_csel &  wri_en;
assign wrd_grnt = ~wri_grnt &  wrd_csel &  wrd_en;
assign wrc_grnt = ~wri_grnt & ~wrd_grnt &  wrc_csel &  wrc_en;

assign wr_en    = wri_grnt|wrd_grnt|wrc_grnt;

assign rd_addr  = (rdi_grnt ? rdi_addr : (rdd_grnt ? rdd_addr : rdc_addr));
assign wr_addr  = (wri_grnt ? wri_addr : (wrd_grnt ? wrd_addr : wrc_addr));
assign wr_word  = (wri_grnt ? wri_word : (wrd_grnt ? wrd_word : wrc_word));

assign rdi_word = rd_word;
assign rdd_word = rd_word;
assign rdc_word = rd_word;


/* 64k internal BRAM */
bram64k b (clk, wr_word, rd_addr, wr_addr, wr_en, rd_word);


/* Module end */
endmodule
