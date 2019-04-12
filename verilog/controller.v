/**
 * Controller
 */

/**** Module ****/
module controller(clk,
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

localparam BMVUA   = $clog2(NMVU);   /* Bitwidth of MVU          Address */
localparam BWBANKA = 9;              /* Bitwidth of Weights BANK Address */
localparam BDBANKA = 14;             /* Bitwidth of Data    BANK Address */
localparam BDBANKW = 2*N;            /* Bitwidth of Data    BANK Word */
localparam BTCR    = 24+(24*3)+(5*3);/** Bitwidth of Tensor config register:
                                       * BASE + size0..2 + stride0..2
                                       * Total: 111 bits
                                       **/

input  wire                     clk;

output wire                     ic_clr;
output wire[  NMVU*BMVUA-1 : 0] ic_recv_from;

output wire[      2*NMVU-1 : 0] mul_mode;
output wire[        NMVU-1 : 0] acc_clr;
output wire[        NMVU-1 : 0] acc_sh;
output wire[        NMVU-1 : 0] max_en;
output wire[        NMVU-1 : 0] max_clr;
output wire[        NMVU-1 : 0] max_pool;

output wire[NMVU*BWBANKA-1 : 0] rdw_addr;

output wire[        NMVU-1 : 0] rdd_en;
input  wire[        NMVU-1 : 0] rdd_grnt;
output wire[NMVU*BDBANKA-1 : 0] rdd_addr;
output wire[        NMVU-1 : 0] wrd_en;
input  wire[        NMVU-1 : 0] wrd_grnt;
output wire[NMVU*BDBANKA-1 : 0] wrd_addr;

output wire[        NMVU-1 : 0] rdi_en;
input  wire[        NMVU-1 : 0] rdi_grnt;
output wire[NMVU*BDBANKA-1 : 0] rdi_addr;
input  wire[        NMVU-1 : 0] wri_grnt;
output wire[NMVU*BDBANKA-1 : 0] wri_addr;

output wire[        NMVU-1 : 0] rdc_en;
input  wire[        NMVU-1 : 0] rdc_grnt;
output wire[NMVU*BDBANKA-1 : 0] rdc_addr;
input  wire[NMVU*BDBANKW-1 : 0] rdc_word;
output wire[        NMVU-1 : 0] wrc_en;
input  wire[        NMVU-1 : 0] wrc_grnt;
output wire[     BDBANKA-1 : 0] wrc_addr;
output wire[     BDBANKW-1 : 0] wrc_word;

genvar i;


/* Local Wires */



/*   Per-core resources */
generate for(i=0;i<NMVU;i=i+1) begin:mvuarray
    reg dtensor_cfg_reg[8*BTCR-1 : 0];
    reg wtensor_cfg_reg[8*BTCR-1 : 0];
    
    always @(posedge clk) begin
        rdw_addr <= wtensor_cfg_reg[0 +: 24] + (wtensor_cfg_reg[24 +: 24] << wtensor_cfg_reg[ 96 +: 5])
                                             + (wtensor_cfg_reg[48 +: 24] << wtensor_cfg_reg[101 +: 5])
                                             + (wtensor_cfg_reg[72 +: 24] << wtensor_cfg_reg[106 +: 5]);
        rdd_addr <= dtensor_cfg_reg[0 +: 24] + (dtensor_cfg_reg[24 +: 24] << dtensor_cfg_reg[ 96 +: 5])
                                             + (dtensor_cfg_reg[48 +: 24] << dtensor_cfg_reg[101 +: 5])
                                             + (dtensor_cfg_reg[72 +: 24] << dtensor_cfg_reg[106 +: 5]);
    end
end endgenerate


/* Module end */
endmodule
