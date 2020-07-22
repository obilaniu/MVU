//
// MVU top level
//
// Notes:
// * For wlength_X and ilength_X parameters, the value to assign is actual_length - 1.
//
//
 
`timescale 1 ps / 1 ps
/**** Module ****/
module mvutop(  clk,
                rst_n,
                start,
                done,
                irq,
                ic_clr,
                ic_recv_from,
                mul_mode,
                shacc_clr,
                max_en,
                max_clr,
                max_pool,
                quant_clr,
                quant_msbidx,
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
localparam QBWOUTBD = $clog2(BACC);     // Bitwidth of the quantizer bit-depth out specifier

// Other Parameters
localparam BCNTDWN	    = 29;			// Bitwidth of the countdown ports
localparam BPREC 	    = 6;			// Bitwidth of the precision ports
localparam BBWADDR	    = 9;			// Bitwidth of the weight base address ports
localparam BBDADDR	    = 15;			// Bitwidth of the data base address ports
localparam BSTRIDE	    = 15;			// Bitwidth of the stride ports
localparam BLENGTH	    = 15;			// Bitwidth of the length ports
localparam VVPSTAGES    = 3;            // Number of stages in the VVP pipeline
localparam MAXPOOLSTAGES = 1;           // Number of max pool pipeline stages
localparam MEMRDLATENCY = 2;            // Memory read latency


//
// Port definitions
//

input wire                        clk;
input wire                        rst_n;                // Global reset

input  wire[          NMVU-1 : 0] start;                // Start the MVU job
output wire[          NMVU-1 : 0] done;                 // Indicates if a job is done
output wire[          NMVU-1 : 0] irq;                  // Interrupt request

input  wire                       ic_clr;				// Interconnect: clear
input  wire[    NMVU*BMVUA-1 : 0] ic_recv_from;			// Interconnect: receive from MVU number

input  wire[        2*NMVU-1 : 0] mul_mode;				// Config: multiply mode
input  wire[          NMVU-1 : 0] shacc_clr;			// Control: accumulator clear
input  wire[          NMVU-1 : 0] max_en;				// Config: max pool enable
input  wire[          NMVU-1 : 0] max_clr;				// Config: max pool clear
input  wire[          NMVU-1 : 0] max_pool;				// Config: max pool mode

input  wire[          NMVU-1 : 0] quant_clr;			// Quantizer: clear
input  wire[ NMVU*BQMSBIDX-1 : 0] quant_msbidx;			// Quantizer: bit position index of the MSB

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

// Quantizer
wire[        NMVU-1 : 0] quant_start;			// Quantizer: signal to start quantizing
wire[        NMVU-1 : 0] quant_stall;           // Quantizer: stall
wire[      NMVU*N-1 : 0] quantarray_out;		// Quantizer: output
wire[  BPREC*NMVU-1 : 0] quant_bwout;           // Quantizer: output bitwidth
wire[        NMVU-1 : 0] quant_load;            // Quantizer: load base address
wire[        NMVU-1 : 0] quant_step;            // Quantizer: step the quantizer
wire[        NMVU-1 : 0] quant_ctrl_clr;        // Quantizer: clear/reset controller
wire[        NMVU-1 : 0] quant_clr_int;         // Quantizer: internal clear control

// Output data write back to memory
// TODO: DO SOMETHING USEFUL WITH THESE SIGNALS
wire[        NMVU-1 : 0] outstep;
wire[        NMVU-1 : 0] outload;
// Other wires
wire[        NMVU-1 : 0] inagu_clr;
wire[        NMVU-1 : 0] controller_clr;    // Controller clear/reset
wire[        NMVU-1 : 0] step;              // Step if 1, stall if 0
wire[        NMVU-1 : 0] run;               // Running if 1
wire[        NMVU-1 : 0] shacc_load;        // Accumulator load control
wire[        NMVU-1 : 0] shacc_sh;          // Accumulator shift control
wire[        NMVU-1 : 0] shacc_acc;         // Accumulator accumulate control
wire[        NMVU-1 : 0] shacc_clr_int;     // Accumulator clear internal control
wire[        NMVU-1 : 0] shacc_load_start;  // Accumulator load from start of job
wire[        NMVU-1 : 0] agu_sh_out;        // Input AGU shift accumulator
wire[        NMVU-1 : 0] agu_shacc_done;    // AGU accumulator done indicator
wire[        NMVU-1 : 0] run_acc;           // Run signal for the accumulator/shifters
wire[        NMVU-1 : 0] shacc_done;        // Accumulator done control
wire[        NMVU-1 : 0] maxpool_done;      // Max pool done control
wire[        NMVU-1 : 0] outagu_clr;        // Clear the output AGU
wire[        NMVU-1 : 0] outagu_load;       // Load the output AGU base address


/* Wiring */
/*   Interconnect... */
interconn #(NMVU, BDBANKW) ic (clk,  ic_clr, ic_send_en, ic_send_word,
                               ic_recv_from, ic_recv_en, ic_recv_word);
assign ic_send_en   = rdi_grnt;
assign ic_send_word = rdi_word;
assign wri_word     = ic_recv_word;
assign wri_en       = ic_recv_en;

// TODO: FIGURE OUT WHERE TO WIRE OTHER INTERCONNECT DATA ACCESS SIGNAL
assign rdi_en           = 0;
//assign rdi_grnt         = 0;
assign rdi_addr         = 0;
//assign wri_grnt         = 0;
assign wri_addr         = 0;


// TODO: WIRE THESE UP TO THE AGU. PULLED UP/DOWN FOR NOW
assign rdd_en           = 1;

// TODO: WIRE THESE UP TO SOMETHING USEFUL
assign outload          = 0;
assign quant_stall      = 0;
assign step             = {NMVU{1'b1}};                      // No stalls for now

// Accumulator signals
assign run_acc          = run;                              // No stalls for now
assign shacc_load       = shacc_done | shacc_load_start;    // Load accumulator with current output of MVP's

// Clear signals (just connect to global reset for now)
assign controller_clr   = {NMVU{!rst_n}};
assign inagu_clr        = {NMVU{!rst_n}} | start;
assign outagu_clr       = {NMVU{!rst_n}};
assign shacc_clr_int    = {NMVU{!rst_n}} | shacc_clr;       // Clear the accumulator
assign quant_clr_int    = {NMVU{!rst_n}} | quant_clr;

// Quantizer and output control signals
assign quant_start      = maxpool_done;
assign outstep          = quant_step;
assign quant_ctrl_clr   = {NMVU{!rst_n}} | quant_clr;

// MVU Data Memory control
assign wrd_en           = outstep;


// Controllers
generate for(i = 0; i < NMVU; i = i + 1) begin: controllerarray
    controller #(
        .BCNTDWN    (BCNTDWN)
    ) controller_unit (
        .clk        (clk),
        .clr        (controller_clr[i]),
        .start      (start[i]),
        .countdown  (countdown[i*BCNTDWN +: BCNTDWN]),
        .step       (step[i]),
        .run        (run[i]),
        .done       (done[i]),
        .irq        (irq[i])
    );
end endgenerate


// Address generation modules for input and weight memory
generate for(i = 0; i < NMVU; i = i + 1) begin: inaguarray
	inagu #(
        .BPREC      (BPREC),
        .BDBANKA    (BDBANKA),
        .BWBANKA    (BWBANKA),
        .BWLENGTH   (BLENGTH)
	) inagu_unit (
        .clk        (clk),
        .clr        (inagu_clr      [i]),
        .en         (run            [i]),
        .iprecision (iprecision     [  i*BPREC +: BPREC]),
        .istride0   (istride_0      [i*BSTRIDE +: BDBANKA]),
        .istride1   (istride_1      [i*BSTRIDE +: BDBANKA]),
        .istride2   (istride_2      [i*BSTRIDE +: BDBANKA]),
	    .ilength0   (ilength_0      [i*BLENGTH +: BLENGTH]),
        .ilength1   (ilength_1      [i*BLENGTH +: BLENGTH]),
        .ilength2   (ilength_2      [i*BLENGTH +: BLENGTH]),
        .ibaseaddr  (ibaseaddr      [i*BBDADDR +: BBDADDR]),
        .wprecision (wprecision     [  i*BPREC +: BPREC]),
        .wstride0   (wstride_0      [i*BSTRIDE +: BWBANKA]),
        .wstride1   (wstride_1      [i*BSTRIDE +: BWBANKA]),
        .wstride2   (wstride_2      [i*BSTRIDE +: BWBANKA]),
        .wlength0   (wlength_0      [i*BLENGTH +: BLENGTH]),
        .wlength1   (wlength_1      [i*BLENGTH +: BLENGTH]),
        .wlength2   (wlength_2      [i*BLENGTH +: BLENGTH]),
        .wbaseaddr  (wbaseaddr      [i*BBWADDR +: BBWADDR]),
        .iaddr_out  (rdd_addr       [i*BDBANKA +: BDBANKA]),
        .waddr_out  (rdw_addr       [i*BWBANKA +: BWBANKA]),
        .sh_out     (agu_sh_out     [i]),
        .shacc_done (agu_shacc_done [i])
	);
end endgenerate

// Output address generators
generate for(i = 0; i < NMVU; i = i+1) begin:outaguarray
	outagu #(
			.BDBANKA	(BDBANKA			)
		) outaguunit
		(
			.clk		(clk								),
            .clr        (outagu_clr[i]                      ),
			.step 		(outstep[i]),
			.load		(outagu_load[i]),
			.baseaddr	(obaseaddr[i*BBDADDR +:	BBDADDR]	),
			.addrout	(wrd_addr[i*BDBANKA  +: BDBANKA]	)
		);
end endgenerate

// Quantizer Controllers
generate for(i = 0; i < NMVU; i = i+1) begin: quantser_ctrlarray
    assign quant_bwout[i*BPREC +: BQBOUT] = oprecision[i*BPREC +: BQBOUT];
    quantser_ctrl #(
        .BWOUT      (BACC)
    ) quantser_ctrl_unit (
        .clk        (clk),
        .clr        (quant_ctrl_clr[i]),
        .bwout      (quant_bwout[i*BPREC +: BQBOUT]),
        .start      (quant_start[i]),
        .stall      (quant_stall[i]),
        .load       (quant_load[i]),
        .step       (quant_step[i])
    );
end endgenerate

// Insert delays on some control signals to account for pipeline stages
generate for(i=0; i < NMVU; i = i+1) begin: acc_delayarray

    // TODO: connect the step signals on these shift regs
    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY + 1)
    ) shacc_load_delayarrayunit (
        .clk    (clk), 
        .clr    (~rst_n),
        .step   (1'b1),
        .in     (start[i]),
        .out    (shacc_load_start[i])
    );

    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY + 0)
    ) shacc_sh_delayarrayunit (
        .clk    (clk), 
        .clr    (~rst_n),
        .step   (1'b1),
        .in     (agu_sh_out[i]),
        .out    (shacc_sh[i])
    );

    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY + 1)
    ) shacc_acc_delayarrayunit (
        .clk    (clk), 
        .clr    (~rst_n),
        .step   (1'b1),
        .in     (run_acc[i]),
        .out    (shacc_acc[i])
    );

    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY + 1)      // TODO: find a better way to re-time this
    ) acc_done_delayarrayunit (
        .clk    (clk), 
        .clr    (~rst_n),
        .step   (1'b1),
        .in     (agu_shacc_done[i]),
        .out    (shacc_done[i])
    );

    shiftreg #(
        .N      (MAXPOOLSTAGES)
    ) maxpool_done_delayarrayunit (
        .clk    (clk),
        .clr    (~rst_n),
        .step   (1'b1),
        .in     (shacc_done[i]),
        .out    (maxpool_done[i])
    );

    shiftreg #(
        .N      (VVPSTAGES+MEMRDLATENCY+MAXPOOLSTAGES + 1)
    ) outagu_load_delayarrayunit (
        .clk    (clk),
        .clr    (~rst_n),
        .step   (1'b1),
        .in     (start[i]),
        .out    (outagu_load[i])
    );

end endgenerate


/*   Cores... */
generate for(i=0;i<NMVU;i=i+1) begin:mvuarray
    mvu #(
            .N				(N				),
            .NDBANK			(NDBANK			)
        ) mvunit 
        (
            .clk			(clk									),
            .mul_mode		(mul_mode[i*2 +: 2]						),
            .shacc_clr	    (shacc_clr_int[i]  						),
            .shacc_load     (shacc_load[i]                          ),
            .shacc_acc      (shacc_acc[i]                           ),
            .shacc_sh		(shacc_sh[i]							),
            .max_en			(max_en[i]								),
            .max_clr		(max_clr[i]								),
            .max_pool		(max_pool[i]							),
            .quant_clr		(quant_clr_int[i]	    				),
            .quant_msbidx   (quant_msbidx[i*BQMSBIDX +: BQMSBIDX]	),
            .quant_load     (quant_load[i]                          ),
            .quant_step 	(quant_step[i]							),
            .rdw_addr		(rdw_addr[i*BWBANKA +: BWBANKA]			),
			.wrw_addr		(wrw_addr[i*BWBANKA +: BWBANKA]			),
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
