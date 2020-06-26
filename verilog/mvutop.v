/**
 * Top-Level
 */
 
`timescale 1 ps / 1 ps
/**** Module ****/
module mvutop(  clk,
                ic_clr,
                ic_recv_from,
                mul_mode,
                acc_clr,
                acc_sh,
                max_en,
                max_clr,
                max_pool,
                quant_clr,
                quant_msbidx,
                quant_start,
                quantarray_out,
                countdown,
                wprecision,
                iprecision,
                oprecision,
                wbaseaddr,
                ibaseaddr,
                obaseaddr,
                wstride_0,
                wstride_1,
                wstride_2,
                istride_0,
                istride_1,
                istride_2,
                ostride_0,
                ostride_1,
                ostride_2,
                wlength_0,
                wlength_1,
                wlength_2,
                ilength_0,
                ilength_1,
                ilength_2,
                olength_0,
                olength_1,
                olength_2,
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
parameter  NDBANK  = 32;   /* Number of N-bit, 1024-element Data BANK. */

localparam BMVUA   = $clog2(NMVU);  /* Bitwidth of MVU          Address */
localparam BWBANKA = 9;             /* Bitwidth of Weights BANK Address */
localparam BDBANKA = 15;            /* Bitwidth of Data    BANK Address */
localparam BDBANKW = N;             /* Bitwidth of Data    BANK Word */

localparam BACC    = 32;            /* Bitwidth of Accumulators */

// Quantizer parameters
localparam BQMSBIDX  = $clog2(BACC);    // Bitwidth of the quantizer MSB location specifier
localparam BQBOUT = $clog2(BACC);       // Bitwitdh of the quantizer 

// Other Parameters
localparam BCNTDWN = 29;            // Bitwidth of the countdown ports
localparam BPREC = 6;               // Bitwidth of the precision ports
localparam BBWADDR = 32;            // Bitwidth of the weight base address ports
localparam BBDADDR = 32;            // Bitwidth of the data base address ports
localparam BSTRIDE = 32;            // Bitwidth of the stride ports
localparam BLENGTH = 32;            // Bitwidth of the length ports


//
// Port definitions
//

input wire                     clk;

input  wire                     ic_clr;
input  wire[  NMVU*BMVUA-1 : 0] ic_recv_from;

input  wire[      2*NMVU-1 : 0] mul_mode;
input  wire[        NMVU-1 : 0] acc_clr;
input  wire[        NMVU-1 : 0] acc_sh;
input  wire[        NMVU-1 : 0] max_en;
input  wire[        NMVU-1 : 0] max_clr;
input  wire[        NMVU-1 : 0] max_pool;

input  wire[          NMVU-1 : 0]   quant_clr;              // Quantizer: clear
input  wire[  MVU*BQMSBIDX-1 : 0]   quant_msbidx;           // Quantizer: bit position index of the MSB
input  wire[          NMVU-1 : 0]   quant_start;            // Quantizer: signal to start quantizing
output wire[        NMVU*N-1 : 0]   quantarray_out;         // Quantizer: output

input  wire[  NMVU*BCNTDWN-1 : 0]   countdown;              // Config: number of clocks to countdown for given task
input  wire[    NVMU*BPREC-1 : 0]   wprecision;             // Config: weight precision
input  wire[    NVMU*BPREC-1 : 0]   iprecision;             // Config: input precision
input  wire[    NVMU*BPREC-1 : 0]   oprecision;             // Config: output precision
input  wire[  NVMU*BWBADDR-1 : 0]   wbaseaddr;              // Config: weight memory base address
input  wire[  NVMU*BDBADDR-1 : 0]   ibaseaddr;              // Config: data memory base address for input
input  wire[  NVMU*BDBADDR-1 : 0]   obaseaddr;              // Config: data memory base address for output
input  wire[  NVMU*BSTRIDE-1 : 0]   wstride_0;              // Config: weight stride in dimension 0 (x)
input  wire[  NVMU*BSTRIDE-1 : 0]   wstride_1;              // Config: weight stride in dimension 1 (y)
input  wire[  NVMU*BSTRIDE-1 : 0]   wstride_2;              // Config: weight stride in dimension 2 (z)
input  wire[  NVMU*BSTRIDE-1 : 0]   istride_0;              // Config: input stride in dimension 0 (x)
input  wire[  NVMU*BSTRIDE-1 : 0]   istride_1;              // Config: input stride in dimension 1 (y)
input  wire[  NVMU*BSTRIDE-1 : 0]   istride_2;              // Config: input stride in dimension 2 (z)
input  wire[  NVMU*BSTRIDE-1 : 0]   ostride_0;              // Config: output stride in dimension 0 (x)
input  wire[  NVMU*BSTRIDE-1 : 0]   ostride_1;              // Config: output stride in dimension 1 (y)
input  wire[  NVMU*BSTRIDE-1 : 0]   ostride_2;              // Config: output stride in dimension 2 (z)
input  wire[  NVMU*BLENGTH-1 : 0]   wlength_0;              // Config: weight length in dimension 0 (x)
input  wire[  NVMU*BLENGTH-1 : 0]   wlength_1;              // Config: weight length in dimension 1 (y)
input  wire[  NVMU*BLENGTH-1 : 0]   wlength_2;              // Config: weight length in dimension 2 (z)
input  wire[  NVMU*BLENGTH-1 : 0]   ilength_0;              // Config: input length in dimension 0 (x)
input  wire[  NVMU*BLENGTH-1 : 0]   ilength_1;              // Config: input length in dimension 1 (y)
input  wire[  NVMU*BLENGTH-1 : 0]   ilength_2;              // Config: input length in dimension 2 (z)
input  wire[  NVMU*BLENGTH-1 : 0]   olength_0;              // Config: output length in dimension 0 (x)
input  wire[  NVMU*BLENGTH-1 : 0]   olength_1;              // Config: output length in dimension 1 (y)
input  wire[  NVMU*BLENGTH-1 : 0]   olength_2;              // Config: output length in dimension 2 (z)

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
                             quant_clr[i],
                             quant_msbidx[i*BQMSBIDX +: BQMSBIDX],
                             quant_bdout[i*BPREC +: BQBOUT],
                             quant_start[i],
                             quantarray_out[0*N +: N],
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
