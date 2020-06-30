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
				wrw_addr,
				wrw_word,
				wrw_en,
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
localparam BWBANKW = 4096;			// Bitwidth of Weights BANK Word
localparam BDBANKA = 15;            /* Bitwidth of Data    BANK Address */
localparam BDBANKW = N;             /* Bitwidth of Data    BANK Word */

localparam BACC    = 32;            /* Bitwidth of Accumulators */

// Quantizer parameters
localparam BQMSBIDX = $clog2(BACC);     // Bitwidth of the quantizer MSB location specifier
localparam BQBOUT   = $clog2(BACC);     // Bitwitdh of the quantizer 

// Other Parameters
localparam BCNTDWN	= 29;			// Bitwidth of the countdown ports
localparam BPREC 	= 6;			// Bitwidth of the precision ports
localparam BBWADDR	= 9;			// Bitwidth of the weight base address ports
localparam BBDADDR	= 15;			// Bitwidth of the data base address ports
localparam BSTRIDE	= 15;			// Bitwidth of the stride ports
localparam BLENGTH	= 15;			// Bitwidth of the length ports


//
// Port definitions
//

input wire                        clk;

input  wire                       ic_clr;				// Interconnect: clear
input  wire[    NMVU*BMVUA-1 : 0] ic_recv_from;			// Interconnect: receive from MVU number

input  wire[        2*NMVU-1 : 0] mul_mode;				// Config: multiply mode
input  wire[          NMVU-1 : 0] acc_clr;				// Control: accumulator clear
input  wire[          NMVU-1 : 0] acc_sh;				// Control: accumulator shift
input  wire[          NMVU-1 : 0] max_en;				// Config: max pool enable
input  wire[          NMVU-1 : 0] max_clr;				// Config: max pool clear
input  wire[          NMVU-1 : 0] max_pool;				// Config: max pool mode

input  wire[          NMVU-1 : 0] quant_clr;			// Quantizer: clear
input  wire[ NMVU*BQMSBIDX-1 : 0] quant_msbidx;			// Quantizer: bit position index of the MSB
input  wire[          NMVU-1 : 0] quant_start;			// Quantizer: signal to start quantizing
output wire[        NMVU*N-1 : 0] quantarray_out;		// Quantizer: output

input  wire[  NMVU*BCNTDWN-1 : 0] countdown;			// Config: number of clocks to countdown for given task
input  wire[    NMVU*BPREC-1 : 0] wprecision;			// Config: weight precision
input  wire[    NMVU*BPREC-1 : 0] iprecision;			// Config: input precision
input  wire[    NMVU*BPREC-1 : 0] oprecision;			// Config: output precision
input  wire[  NMVU*BBWADDR-1 : 0] wbaseaddr;			// Config: weight memory base address
input  wire[  NMVU*BBDADDR-1 : 0] ibaseaddr;			// Config: data memory base address for input
input  wire[  NMVU*BBDADDR-1 : 0] obaseaddr;			// Config: data memory base address for output
input  wire[  NMVU*BSTRIDE-1 : 0] wstride_0;			// Config: weight stride in dimension 0 (x)
input  wire[  NMVU*BSTRIDE-1 : 0] wstride_1;			// Config: weight stride in dimension 1 (y)
input  wire[  NMVU*BSTRIDE-1 : 0] wstride_2;			// Config: weight stride in dimension 2 (z)
input  wire[  NMVU*BSTRIDE-1 : 0] istride_0;			// Config: input stride in dimension 0 (x)
input  wire[  NMVU*BSTRIDE-1 : 0] istride_1;			// Config: input stride in dimension 1 (y)
input  wire[  NMVU*BSTRIDE-1 : 0] istride_2;			// Config: input stride in dimension 2 (z)
input  wire[  NMVU*BSTRIDE-1 : 0] ostride_0;			// Config: output stride in dimension 0 (x)
input  wire[  NMVU*BSTRIDE-1 : 0] ostride_1;			// Config: output stride in dimension 1 (y)
input  wire[  NMVU*BSTRIDE-1 : 0] ostride_2;			// Config: output stride in dimension 2 (z)
input  wire[  NMVU*BLENGTH-1 : 0] wlength_0;			// Config: weight length in dimension 0 (x)
input  wire[  NMVU*BLENGTH-1 : 0] wlength_1;			// Config: weight length in dimension 1 (y)
input  wire[  NMVU*BLENGTH-1 : 0] wlength_2;			// Config: weight length in dimension 2 (z)
input  wire[  NMVU*BLENGTH-1 : 0] ilength_0;			// Config: input length in dimension 0 (x)
input  wire[  NMVU*BLENGTH-1 : 0] ilength_1;			// Config: input length in dimension 1 (y)
input  wire[  NMVU*BLENGTH-1 : 0] ilength_2;			// Config: input length in dimension 2 (z)
input  wire[  NMVU*BLENGTH-1 : 0] olength_0;			// Config: output length in dimension 0 (x)
input  wire[  NMVU*BLENGTH-1 : 0] olength_1;			// Config: output length in dimension 1 (y)
input  wire[  NMVU*BLENGTH-1 : 0] olength_2;			// Config: output length in dimension 2 (z)

input  wire[  NMVU*BWBANKA-1 : 0] wrw_addr;				// Weight memory: write address
input  wire[  NMVU*BWBANKW-1 : 0] wrw_word;				// Weight memory: write word
input  wire[          NMVU-1 : 0] wrw_en;				// Weight memory: write enable

input  wire[          NMVU-1 : 0] rdc_en;				// Data memory: controller read enable
output wire[          NMVU-1 : 0] rdc_grnt;				// Data memory: controller read grant
input  wire[  NMVU*BDBANKA-1 : 0] rdc_addr;				// Data memory: controller read address
output wire[  NMVU*BDBANKW-1 : 0] rdc_word;				// Data memory: controller read word
input  wire[          NMVU-1 : 0] wrc_en;				// Data memory: controller write enable
output wire[          NMVU-1 : 0] wrc_grnt;				// Data memory: controller write grant
input  wire[       BDBANKA-1 : 0] wrc_addr;				// Data memory: controller write address
input  wire[       BDBANKW-1 : 0] wrc_word;				// Data memory: controller write word

genvar i;


/* Local Wires */

// MVU Weight memory controll
wire[NMVU*BWBANKA-1 : 0] rdw_addr;

// MVU Data memory control
wire[        NMVU-1 : 0] rdd_en;
wire[        NMVU-1 : 0] rdd_grnt;
wire[NMVU*BDBANKA-1 : 0] rdd_addr;
wire[        NMVU-1 : 0] wrd_en;
wire[        NMVU-1 : 0] wrd_grnt;
wire[NMVU*BDBANKA-1 : 0] wrd_addr;

// Interconnect
wire[        NMVU-1 : 0] ic_send_en;
wire[NMVU*BDBANKW-1 : 0] ic_send_word;
wire[        NMVU-1 : 0] ic_recv_en;
wire[NMVU*BDBANKW-1 : 0] ic_recv_word;
wire[NMVU*BDBANKW-1 : 0] rdi_word;
wire[        NMVU-1 : 0] wri_en;
wire[NMVU*BDBANKW-1 : 0] wri_word;

wire[        NMVU-1 : 0] rdi_en;
wire[        NMVU-1 : 0] rdi_grnt;
wire[NMVU*BDBANKA-1 : 0] rdi_addr;
wire[        NMVU-1 : 0] wri_grnt;
wire[NMVU*BDBANKA-1 : 0] wri_addr;



/* Wiring */
/*   Interconnect... */
interconn #(NMVU, BDBANKW) ic (clk,  ic_clr, ic_send_en, ic_send_word,
                               ic_recv_from, ic_recv_en, ic_recv_word);
assign ic_send_en   = rdi_grnt;
assign ic_send_word = rdi_word;
assign wri_word     = ic_recv_word;
assign wri_en       = ic_recv_en;

// TODO: FIGURE OUT WHERE TO WIRE OTHER INTERCONNECT DATA ACCESS SIGNAL
assign rdi_en   = 0;
assign rdi_grnt = 0;
assign rdi_addr = 0;
assign wri_grnt = 0;
assign wri_addr = 0;


// TODO: WIRE THESE UP TO THE AGU. PULLED DOWN FOR NOW
assign rdw_addr = 0;
assign rdd_en   = 0;
assign rdd_grnt = 0;
assign rdd_addr = 0;
assign wrd_en   = 0;
assign wrd_grnt = 0;
assign wrd_addr = 0;

// TODO: INSERT AGU/ZIGZAG ARRAY HERE




/*   Cores... */
generate for(i=0;i<NMVU;i=i+1) begin:mvuarray
    mvu #(
            .N				(N				),
            .NDBANK			(NDBANK			)
        ) mvunit 
        (
            .clk			(clk									),
            .mul_mode		(mul_mode[i*2 +: 2]						),
            .acc_clr		(acc_clr[i]								),
            .acc_sh			(acc_sh[i]								),
            .max_en			(max_en[i]								),
            .max_clr		(max_clr[i]								),
            .max_pool		(max_pool[i]							),
            .quant_clr		(quant_clr[i]							),
            .quant_msbidx   (quant_msbidx[i*BQMSBIDX +: BQMSBIDX]	),
            .quant_bdout	(oprecision[i*BPREC +: BQBOUT]			),
            .quant_start	(quant_start[i]							),
            .quantarray_out	(quantarray_out[0*N +: N]				),
            .rdw_addr		(rdw_addr[i*BWBANKA +: BWBANKA]			),
			.wrw_addr		(wrw_addr[i*BWBANKA +: BWBANKA			]),
			.wrw_word		(wrw_word[i*BWBANKW +: BWBANKW]			),
			.wrw_en			(wrw_en[i]								),
            .rdd_en			(rdd_en[i]								),
            .rdd_grnt		(rdd_grnt[i]							),
            .rdd_addr		(rdd_addr[i*BDBANKA +: BDBANKA]			),
            .wrd_en			(wrd_en[i]								),
            .wrd_grnt		(wrd_grnt[i]							),
            .wrd_addr		(wrd_addr[i*BDBANKA +: BDBANKA]			),
            .rdi_en			(rdi_en[i]								),
            .rdi_grnt		(rdi_grnt[i]							),
            .rdi_addr		(rdi_addr[i*BDBANKA +: BDBANKA]			),
            .rdi_word		(rdi_word[i*BDBANKW +: BDBANKW]			),
            .wri_en			(wri_en[i]								),
            .wri_grnt		(wri_grnt[i]							),
            .wri_addr		(wri_addr[i*BDBANKA +: BDBANKA]			),
            .wri_word		(wri_word[i*BDBANKW +: BDBANKW]			),
            .rdc_en			(rdc_en[i]								),
            .rdc_grnt		(rdc_grnt[i]							),
            .rdc_addr		(rdc_addr[i*BDBANKA +: BDBANKA]			),
            .rdc_word		(rdc_word[i*BDBANKW +: BDBANKW]			),
            .wrc_en			(wrc_en[i]								),
            .wrc_grnt		(wrc_grnt[i]							),
            .wrc_addr		(wrc_addr[BDBANKA-1: 0]					),
        	.wrc_word		(wrc_word[BDBANKW-1 : 0]				)
		);
end endgenerate


/* Module end */
endmodule
