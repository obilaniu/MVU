/**
 * Top-Level
 */

/**** Module ****/
module toplevel(clk,
                ic_clr,
                ic_recv_from,
                mul_mode,
                acc_clr,
                acc_sh,
                max_en,
                max_clr,
                max_pool,
                rdw_addr,
                rdd_en,
                rdd_grnt,
                rdd_addr,
                wrd_en,
                wrd_grnt,
                wrd_addr,
                rdi_en,
                rdi_grnt,
                rdi_addr,
                wri_grnt,
                wri_addr,
                rdc_en,
                rdc_grnt,
                rdc_addr,
                rdc_word,
                wrc_en,
                wrc_grnt,
                wrc_addr,
                wrc_word);


/* Parameters */
parameter  NMVU    =  8;   /* Number of MVUs. Ideally a Power-of-2. */
parameter  N       = 64;   /* N x N matrix-vector product size. Power-of-2. */
parameter  NDBANK  = 32;   /* Number of 2N-bit, 512-element Data BANK. */

localparam BMVUA   = $clog2(NMVU);  /* Bitwidth of MVU          Address */
localparam BWBANKA = 9;             /* Bitwidth of Weights BANK Address */
localparam BDBANKA = 14;            /* Bitwidth of Data    BANK Address */
localparam BDBANKW = 2*N;           /* Bitwidth of Data    BANK Word */

input  wire                     clk;

input  wire                     ic_clr;
input  wire[  NMVU*BMVUA-1 : 0] ic_recv_from;

input  wire[      2*NMVU-1 : 0] mul_mode;
input  wire[        NMVU-1 : 0] acc_clr;
input  wire[        NMVU-1 : 0] acc_sh;
input  wire[        NMVU-1 : 0] max_en;
input  wire[        NMVU-1 : 0] max_clr;
input  wire[        NMVU-1 : 0] max_pool;

input  wire[NMVU*BWBANKA-1 : 0] rdw_addr;

input  wire[        NMVU-1 : 0] rdd_en;
output wire[        NMVU-1 : 0] rdd_grnt;
input  wire[NMVU*BDBANKA-1 : 0] rdd_addr;
input  wire[        NMVU-1 : 0] wrd_en;
output wire[        NMVU-1 : 0] wrd_grnt;
input  wire[NMVU*BDBANKA-1 : 0] wrd_addr;

input  wire[        NMVU-1 : 0] rdi_en;
output wire[        NMVU-1 : 0] rdi_grnt;
input  wire[NMVU*BDBANKA-1 : 0] rdi_addr;
output wire[        NMVU-1 : 0] wri_grnt;
input  wire[NMVU*BDBANKA-1 : 0] wri_addr;

input  wire[        NMVU-1 : 0] rdc_en;
output wire[        NMVU-1 : 0] rdc_grnt;
input  wire[NMVU*BDBANKA-1 : 0] rdc_addr;
output wire[NMVU*BDBANKW-1 : 0] rdc_word;
input  wire[        NMVU-1 : 0] wrc_en;
output wire[        NMVU-1 : 0] wrc_grnt;
input  wire[     BDBANKA-1 : 0] wrc_addr;
input  wire[     BDBANKW-1 : 0] wrc_word;

genvar i;


/* Local Wires */
wire[        NMVU-1 : 0] ic_send_en;
wire[NMVU*BDBANKW-1 : 0] ic_send_word;
wire[        NMVU-1 : 0] ic_recv_en;
wire[NMVU*BDBANKW-1 : 0] ic_recv_word;

wire[NMVU*BDBANKW-1 : 0] rdi_word;
wire[        NMVU-1 : 0] wri_en;
wire[NMVU*BDBANKW-1 : 0] wri_word;


/* Wiring */
/*   Interconnect... */
interconn #(NMVU, BDBANKW) ic (clk,  ic_clr, ic_send_en, ic_send_word,
                               ic_recv_from, ic_recv_en, ic_recv_word);
assign ic_send_en   = rdi_grnt;
assign ic_send_word = rdi_word;
assign wri_word     = ic_recv_word;
assign wri_en       = ic_recv_en;


/*   Cores... */
generate for(i=0;i<NMVU;i=i+1) begin:mvuarray
    mvu #(N, NDBANK) mvunit (clk,
                             mul_mode[i*2 +: 2],
                             acc_clr[i],
                             acc_sh[i],
                             max_en[i],
                             max_clr[i],
                             max_pool[i],
                             rdw_addr[i*BWBANKA +: BWBANKA],
                             rdd_en[i],
                             rdd_grnt[i],
                             rdd_addr[i*BDBANKA +: BDBANKA],
                             wrd_en[i],
                             wrd_grnt[i],
                             wrd_addr[i*BDBANKA +: BDBANKA],
                             rdi_en[i],
                             rdi_grnt[i],
                             rdi_addr[i*BDBANKA +: BDBANKA],
                             rdi_word[i*BDBANKW +: BDBANKW],
                             wri_en[i],
                             wri_grnt[i],
                             wri_addr[i*BDBANKA +: BDBANKA],
                             wri_word[i*BDBANKW +: BDBANKW],
                             rdc_en[i],
                             rdc_grnt[i],
                             rdc_addr[i*BDBANKA +: BDBANKA],
                             rdc_word[i*BDBANKW +: BDBANKW],
                             wrc_en[i],
                             wrc_grnt[i],
                             wrc_addr,
                             wrc_word);
end endgenerate


/* Module end */
endmodule
