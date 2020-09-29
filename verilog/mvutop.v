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
                mul_mode,
                d_signed,
                w_signed,
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
                omvusel,
                wstride_0,
                wstride_1,
                wstride_2,
                wstride_3,
                istride_0,
                istride_1,
                istride_2,
                istride_3,
                ostride_0,
                ostride_1,
                ostride_2,
                ostride_3,
                wlength_0,
                wlength_1,
                wlength_2,
                wlength_3,
                ilength_0,
                ilength_1,
                ilength_2,
                ilength_3,
                olength_0,
                olength_1,
                olength_2,
                olength_3,
                scaler_b,
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
localparam BWBANKW = 4096;          // Bitwidth of Weights BANK Word
localparam BDBANKA = 15;            /* Bitwidth of Data    BANK Address */
localparam BDBANKW = N;             /* Bitwidth of Data    BANK Word */

localparam BACC    = 27;            /* Bitwidth of Accumulators */
localparam BSCALERP = 48;               // Bitwidth of the scaler output

// Quantizer parameters
localparam BQMSBIDX = $clog2(BSCALERP); // Bitwidth of the quantizer MSB location specifier
localparam BQBOUT   = $clog2(BSCALERP); // Bitwidth of the quantizer 
localparam QBWOUTBD = $clog2(BSCALERP); // Bitwidth of the quantizer bit-depth out specifier

// Other Parameters
localparam BCNTDWN	    = 29;			// Bitwidth of the countdown ports
localparam BPREC 	    = 6;			// Bitwidth of the precision ports
localparam BBWADDR	    = 9;			// Bitwidth of the weight base address ports
localparam BBDADDR	    = 15;			// Bitwidth of the data base address ports
localparam BSTRIDE	    = 15;			// Bitwidth of the stride ports
localparam BLENGTH	    = 15;			// Bitwidth of the length ports
localparam BSCALERB     = 16;           // Bitwidth of the scaler parameter
localparam VVPSTAGES    = 3;            // Number of stages in the VVP pipeline
localparam SCALERLATENCY = 3;           // Number of stages in the scaler pipeline
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

input  wire[        2*NMVU-1 : 0] mul_mode;             // Config: multiply mode
input  wire[          NMVU-1 : 0] d_signed;             // Config: input data signed
input  wire[          NMVU-1 : 0] w_signed;             // Config: weights signed
input  wire[          NMVU-1 : 0] shacc_clr;            // Control: accumulator clear
input  wire[          NMVU-1 : 0] max_en;               // Config: max pool enable
input  wire[          NMVU-1 : 0] max_clr;              // Config: max pool clear
input  wire[          NMVU-1 : 0] max_pool;	            // Config: max pool mode

input  wire[          NMVU-1 : 0] quant_clr;            // Quantizer: clear
input  wire[ NMVU*BQMSBIDX-1 : 0] quant_msbidx;         // Quantizer: bit position index of the MSB

input  wire[  NMVU*BCNTDWN-1 : 0] countdown;            // Config: number of clocks to countdown for given task
input  wire[    NMVU*BPREC-1 : 0] wprecision;           // Config: weight precision
input  wire[    NMVU*BPREC-1 : 0] iprecision;           // Config: input precision
input  wire[    NMVU*BPREC-1 : 0] oprecision;           // Config: output precision
input  wire[  NMVU*BBWADDR-1 : 0] wbaseaddr;            // Config: weight memory base address
input  wire[  NMVU*BBDADDR-1 : 0] ibaseaddr;            // Config: data memory base address for input
input  wire[  NMVU*BBDADDR-1 : 0] obaseaddr;            // Config: data memory base address for output
input  wire[     NMVU*NMVU-1 : 0] omvusel;	    		// Config: MVU selector bits for output
input  wire[  NMVU*BSTRIDE-1 : 0] wstride_0;            // Config: weight stride in dimension 0 (x)
input  wire[  NMVU*BSTRIDE-1 : 0] wstride_1;            // Config: weight stride in dimension 1 (y)
input  wire[  NMVU*BSTRIDE-1 : 0] wstride_2;            // Config: weight stride in dimension 2 (z)
input  wire[  NMVU*BSTRIDE-1 : 0] wstride_3;            // Config: weight stride in dimension 3 (w)
input  wire[  NMVU*BSTRIDE-1 : 0] istride_0;            // Config: input stride in dimension 0 (x)
input  wire[  NMVU*BSTRIDE-1 : 0] istride_1;            // Config: input stride in dimension 1 (y)
input  wire[  NMVU*BSTRIDE-1 : 0] istride_2;            // Config: input stride in dimension 2 (z)
input  wire[  NMVU*BSTRIDE-1 : 0] istride_3;            // Config: input stride in dimension 3 (w)
input  wire[  NMVU*BSTRIDE-1 : 0] ostride_0;            // Config: output stride in dimension 0 (x)
input  wire[  NMVU*BSTRIDE-1 : 0] ostride_1;            // Config: output stride in dimension 1 (y)
input  wire[  NMVU*BSTRIDE-1 : 0] ostride_2;            // Config: output stride in dimension 2 (z)
input  wire[  NMVU*BSTRIDE-1 : 0] ostride_3;            // Config: output stride in dimension 3 (w)
input  wire[  NMVU*BLENGTH-1 : 0] wlength_0;            // Config: weight length in dimension 0 (x)
input  wire[  NMVU*BLENGTH-1 : 0] wlength_1;            // Config: weight length in dimension 1 (y)
input  wire[  NMVU*BLENGTH-1 : 0] wlength_2;            // Config: weight length in dimension 2 (z)
input  wire[  NMVU*BLENGTH-1 : 0] wlength_3;            // Config: weight length in dimension 3 (w)
input  wire[  NMVU*BLENGTH-1 : 0] ilength_0;            // Config: input length in dimension 0 (x)
input  wire[  NMVU*BLENGTH-1 : 0] ilength_1;            // Config: input length in dimension 1 (y)
input  wire[  NMVU*BLENGTH-1 : 0] ilength_2;            // Config: input length in dimension 2 (z)
input  wire[  NMVU*BLENGTH-1 : 0] ilength_3;            // Config: input length in dimension 3 (w)
input  wire[  NMVU*BLENGTH-1 : 0] olength_0;            // Config: output length in dimension 0 (x)
input  wire[  NMVU*BLENGTH-1 : 0] olength_1;            // Config: output length in dimension 1 (y)
input  wire[  NMVU*BLENGTH-1 : 0] olength_2;            // Config: output length in dimension 2 (z)
input  wire[  NMVU*BLENGTH-1 : 0] olength_3;            // Config: output length in dimension 3 (w)
input  wire[ NMVU*BSCALERB-1 : 0] scaler_b;             // Config: multiplicative scaler (operand 'b')

input  wire[  NMVU*BWBANKA-1 : 0] wrw_addr;             // Weight memory: write address
input  wire[  NMVU*BWBANKW-1 : 0] wrw_word;             // Weight memory: write word
input  wire[          NMVU-1 : 0] wrw_en;               // Weight memory: write enable

input  wire[          NMVU-1 : 0] rdc_en;               // Data memory: controller read enable
output wire[          NMVU-1 : 0] rdc_grnt;             // Data memory: controller read grant
input  wire[  NMVU*BDBANKA-1 : 0] rdc_addr;             // Data memory: controller read address
output wire[  NMVU*BDBANKW-1 : 0] rdc_word;             // Data memory: controller read word
input  wire[          NMVU-1 : 0] wrc_en;               // Data memory: controller write enable
output wire[          NMVU-1 : 0] wrc_grnt;             // Data memory: controller write grant
input  wire[       BDBANKA-1 : 0] wrc_addr;             // Data memory: controller write address
input  wire[       BDBANKW-1 : 0] wrc_word;             // Data memory: controller write word

genvar i;


// Local registers
reg[      NMVU-1 : 0] start_q;                                  // Delayed start signal
reg[           1 : 0] mul_mode_q        [NMVU-1 : 0];           // Config: multiply mode
reg[  BQMSBIDX-1 : 0] quant_msbidx_q    [NMVU-1 : 0];           // Quantizer: bit position index of the MSB
reg[   BCNTDWN-1 : 0] countdown_q       [NMVU-1 : 0];           // Config: number of clocks to countdown for given task
reg[     BPREC-1 : 0] wprecision_q      [NMVU-1 : 0];           // Config: weight precision
reg[     BPREC-1 : 0] iprecision_q      [NMVU-1 : 0];           // Config: input precision
reg[     BPREC-1 : 0] oprecision_q      [NMVU-1 : 0];           // Config: output precision
reg[   BBWADDR-1 : 0] wbaseaddr_q       [NMVU-1 : 0];           // Config: weight memory base address
reg[   BBDADDR-1 : 0] ibaseaddr_q       [NMVU-1 : 0];           // Config: data memory base address for input
reg[   BBDADDR-1 : 0] obaseaddr_q       [NMVU-1 : 0];           // Config: data memory base address for output
reg[      NMVU-1 : 0] omvusel_q         [NMVU-1 : 0];    		// Config: MVU selection bits for output
reg[   BWBANKA-1 : 0] wstride_0_q       [NMVU-1 : 0];           // Config: weight stride in dimension 0 (x)
reg[   BWBANKA-1 : 0] wstride_1_q       [NMVU-1 : 0];           // Config: weight stride in dimension 1 (y)
reg[   BWBANKA-1 : 0] wstride_2_q       [NMVU-1 : 0];           // Config: weight stride in dimension 2 (z)
reg[   BWBANKA-1 : 0] wstride_3_q       [NMVU-1 : 0];           // Config: weight stride in dimension 3 (w)
reg[   BDBANKA-1 : 0] istride_0_q       [NMVU-1 : 0];           // Config: input stride in dimension 0 (x)
reg[   BDBANKA-1 : 0] istride_1_q       [NMVU-1 : 0];           // Config: input stride in dimension 1 (y)
reg[   BDBANKA-1 : 0] istride_2_q       [NMVU-1 : 0];           // Config: input stride in dimension 2 (z)
reg[   BDBANKA-1 : 0] istride_3_q       [NMVU-1 : 0];           // Config: input stride in dimension 3 (w)
reg[   BDBANKA-1 : 0] ostride_0_q       [NMVU-1 : 0];           // Config: output stride in dimension 0 (x)
reg[   BDBANKA-1 : 0] ostride_1_q       [NMVU-1 : 0];           // Config: output stride in dimension 1 (y)
reg[   BDBANKA-1 : 0] ostride_2_q       [NMVU-1 : 0];           // Config: output stride in dimension 2 (z)
reg[   BDBANKA-1 : 0] ostride_3_q       [NMVU-1 : 0];           // Config: output stride in dimension 3 (w)
reg[   BLENGTH-1 : 0] wlength_0_q       [NMVU-1 : 0];           // Config: weight length in dimension 0 (x)
reg[   BLENGTH-1 : 0] wlength_1_q       [NMVU-1 : 0];           // Config: weight length in dimension 1 (y)
reg[   BLENGTH-1 : 0] wlength_2_q       [NMVU-1 : 0];           // Config: weight length in dimension 2 (z)
reg[   BLENGTH-1 : 0] wlength_3_q       [NMVU-1 : 0];           // Config: weight length in dimension 3 (w)
reg[   BLENGTH-1 : 0] ilength_0_q       [NMVU-1 : 0];           // Config: input length in dimension 0 (x)
reg[   BLENGTH-1 : 0] ilength_1_q       [NMVU-1 : 0];           // Config: input length in dimension 1 (y)
reg[   BLENGTH-1 : 0] ilength_2_q       [NMVU-1 : 0];           // Config: input length in dimension 2 (z)
reg[   BLENGTH-1 : 0] ilength_3_q       [NMVU-1 : 0];           // Config: input length in dimension 3 (w)
reg[   BLENGTH-1 : 0] olength_0_q       [NMVU-1 : 0];           // Config: output length in dimension 0 (x)
reg[   BLENGTH-1 : 0] olength_1_q       [NMVU-1 : 0];           // Config: output length in dimension 1 (y)
reg[   BLENGTH-1 : 0] olength_2_q       [NMVU-1 : 0];           // Config: output length in dimension 2 (z)
reg[   BLENGTH-1 : 0] olength_3_q       [NMVU-1 : 0];           // Config: output length in dimension 3 (w)
reg[  BSCALERB-1 : 0] scaler_b_q        [NMVU-1 : 0];           // Config: multiplicative scaler (operand 'b')

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
wire                     ic_clr_int;
wire[   NMVU*NMVU-1 : 0] ic_send_to;
wire[        NMVU-1 : 0] ic_send_en;
wire[NMVU*BDBANKA-1 : 0] ic_send_addr;
wire[NMVU*BDBANKW-1 : 0] ic_send_word;
wire[        NMVU-1 : 0] ic_recv_en;
wire[   NMVU*NMVU-1 : 0] ic_recv_from;
wire[NMVU*BDBANKA-1 : 0] ic_recv_addr;
wire[NMVU*BDBANKW-1 : 0] ic_recv_word;
wire[NMVU*BDBANKW-1 : 0] rdi_word;
wire[        NMVU-1 : 0] wri_en;
wire[NMVU*BDBANKW-1 : 0] wri_word;

wire[        NMVU-1 : 0] rdi_en;
wire[        NMVU-1 : 0] rdi_grnt;
wire[NMVU*BDBANKA-1 : 0] rdi_addr;
wire[        NMVU-1 : 0] wri_grnt;
wire[NMVU*BDBANKA-1 : 0] wri_addr;

wire[NMVU*BDBANKW-1 : 0] mvu_word_out;

// Scaler
wire[        NMVU-1 : 0] scaler_clr;            // Scaler: clear/reset

// Quantizer
wire[        NMVU-1 : 0] quant_start;           // Quantizer: signal to start quantizing
wire[        NMVU-1 : 0] quant_stall;           // Quantizer: stall
wire[      NMVU*N-1 : 0] quantarray_out;        // Quantizer: output
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
wire[        NMVU-1 : 0] d_msb;             // Input data address on MSB
wire[        NMVU-1 : 0] w_msb;             // Weight data address on MSB
wire[        NMVU-1 : 0] neg_acc;           // Negate the input to the accumulators
wire[        NMVU-1 : 0] neg_acc_dly;       // Negation control delayed
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


/*
* Wiring 
*/

/*
* Interconnect
*/

interconn #(
    .N(NMVU),
    .W(BDBANKW),
    .BADDR(BDBANKA)
) ic (
    .clk(clk),
    .clr(ic_clr_int),
    .send_to(ic_send_to),
    .send_en(ic_send_en),
    .send_addr(ic_send_addr),
    .send_word(ic_send_word),
    .recv_from(ic_recv_from),
    .recv_en(ic_recv_en),
    .recv_addr(ic_recv_addr),
    .recv_word(ic_recv_word)
);

// Interconnect wires
generate for(i=0; i < NMVU; i = i+1) begin
    assign ic_send_to[i*NMVU +: NMVU] = omvusel_q[i];
    assign ic_send_en[i] = (| omvusel_q[i]) & !omvusel_q[i][i] & outstep[i];
end endgenerate

assign ic_send_word = mvu_word_out;
assign ic_send_addr = wrd_addr;
assign wri_word     = ic_recv_word;
assign wri_en       = ic_recv_en;
assign wri_addr     = ic_recv_addr;

// TODO: FIGURE OUT WHERE TO WIRE OTHER INTERCONNECT DATA ACCESS SIGNAL
assign rdi_en           = 0;
//assign rdi_grnt         = 0;
assign rdi_addr         = 0;
//assign wri_grnt         = 0;


// TODO: WIRE THESE UP TO THE AGU. PULLED UP/DOWN FOR NOW
assign rdd_en           = {NMVU{1'b1}};                     // Always reading for now

// TODO: WIRE THESE UP TO SOMETHING USEFUL
assign outload          = 0;
assign quant_stall      = 0;
assign step             = {NMVU{1'b1}};                      // No stalls for now

// Accumulator signals
assign run_acc          = run;                              // No stalls for now
assign shacc_load       = shacc_done | shacc_load_start;    // Load accumulator with current output of MVP's

// Clear signals (just connect to global reset for now)
assign ic_clr_int       = !rst_n | ic_clr;
assign controller_clr   = {NMVU{!rst_n}};
assign inagu_clr        = {NMVU{!rst_n}} | start_q;
assign outagu_clr       = {NMVU{!rst_n}};
assign shacc_clr_int    = {NMVU{!rst_n}} | shacc_clr;       // Clear the accumulator
assign scaler_clr       = {NMVU{!rst_n}};
assign quant_clr_int    = {NMVU{!rst_n}} | quant_clr;

// Quantizer and output control signals
assign quant_start      = maxpool_done;
assign outstep          = quant_step;
assign quant_ctrl_clr   = {NMVU{!rst_n}} | quant_clr;

// MVU Data Memory control
generate for(i = 0; i < NMVU; i = i + 1) begin: wrd_en_array
    assign wrd_en[i] = outstep[i] & omvusel_q[i][i];
end endgenerate


// Delayed start signal to sync with the parameter buffer registers
always @(posedge clk) begin
    if (~rst_n) begin
        start_q <= 0;
    end else begin
        start_q <= start;
    end
end

// Clock in the input parameters when the start signal is asserted
generate for(i = 0; i < NMVU; i = i + 1) begin: parambuf_array
    always @(posedge clk) begin
        if (~rst_n) begin
            mul_mode_q[i]       <= 0;
            quant_msbidx_q[i]   <= 0;
            countdown_q[i]      <= 0;
            wprecision_q[i]     <= 0;
            iprecision_q[i]     <= 0;
            oprecision_q[i]     <= 0;
            wbaseaddr_q[i]      <= 0;
            ibaseaddr_q[i]      <= 0;
            obaseaddr_q[i]      <= 0;
            omvusel_q[i]        <= 0;
            wstride_0_q[i]      <= 0;
            wstride_1_q[i]      <= 0;
            wstride_2_q[i]      <= 0;
            wstride_3_q[i]      <= 0;
            istride_0_q[i]      <= 0;
            istride_1_q[i]      <= 0;
            istride_2_q[i]      <= 0;
            istride_3_q[i]      <= 0;
            ostride_0_q[i]      <= 0;
            ostride_1_q[i]      <= 0;
            ostride_2_q[i]      <= 0;
            ostride_3_q[i]      <= 0;
            wlength_0_q[i]      <= 0;
            wlength_1_q[i]      <= 0;
            wlength_2_q[i]      <= 0;
            wlength_3_q[i]      <= 0;
            ilength_0_q[i]      <= 0;
            ilength_1_q[i]      <= 0;
            ilength_2_q[i]      <= 0;
            ilength_3_q[i]      <= 0;
            olength_0_q[i]      <= 0;
            olength_1_q[i]      <= 0;
            olength_2_q[i]      <= 0;
            scaler_b_q[i]       <= 0;
            olength_3_q[i]      <= 0;
        end else begin
            if (start[i]) begin
                mul_mode_q[i]       <= mul_mode     [i*2 +: 2];
                quant_msbidx_q[i]   <= quant_msbidx [i*BQMSBIDX +: BQMSBIDX];
                countdown_q[i]      <= countdown    [i*BCNTDWN +: BCNTDWN];
                wprecision_q[i]     <= wprecision   [i*BPREC +: BPREC];
                iprecision_q[i]     <= iprecision   [i*BPREC +: BPREC];
                oprecision_q[i]     <= oprecision   [i*BPREC +: BPREC];
                wbaseaddr_q[i]      <= wbaseaddr    [i*BBWADDR +: BBWADDR];
                ibaseaddr_q[i]      <= ibaseaddr    [i*BBDADDR +: BBDADDR];
                obaseaddr_q[i]      <= obaseaddr    [i*BBDADDR +: BBDADDR];
                omvusel_q[i]        <= omvusel      [i*NMVU +: NMVU];
                wstride_0_q[i]      <= wstride_0    [i*BSTRIDE +: BWBANKA];
                wstride_1_q[i]      <= wstride_1    [i*BSTRIDE +: BWBANKA];
                wstride_2_q[i]      <= wstride_2    [i*BSTRIDE +: BWBANKA];
                wstride_3_q[i]      <= wstride_3    [i*BSTRIDE +: BWBANKA];
                istride_0_q[i]      <= istride_0    [i*BSTRIDE +: BDBANKA];
                istride_1_q[i]      <= istride_1    [i*BSTRIDE +: BDBANKA];
                istride_2_q[i]      <= istride_2    [i*BSTRIDE +: BDBANKA];
                istride_3_q[i]      <= istride_3    [i*BSTRIDE +: BDBANKA];
                ostride_0_q[i]      <= ostride_0    [i*BSTRIDE +: BDBANKA];
                ostride_1_q[i]      <= ostride_1    [i*BSTRIDE +: BDBANKA];
                ostride_2_q[i]      <= ostride_2    [i*BSTRIDE +: BDBANKA];
                ostride_3_q[i]      <= ostride_3    [i*BSTRIDE +: BDBANKA];
                wlength_0_q[i]      <= wlength_0    [i*BLENGTH +: BLENGTH];
                wlength_1_q[i]      <= wlength_1    [i*BLENGTH +: BLENGTH];
                wlength_2_q[i]      <= wlength_2    [i*BLENGTH +: BLENGTH];
                wlength_3_q[i]      <= wlength_3    [i*BLENGTH +: BLENGTH];
                ilength_0_q[i]      <= ilength_0    [i*BLENGTH +: BLENGTH];
                ilength_1_q[i]      <= ilength_1    [i*BLENGTH +: BLENGTH];
                ilength_2_q[i]      <= ilength_2    [i*BLENGTH +: BLENGTH];
                ilength_3_q[i]      <= ilength_3    [i*BLENGTH +: BLENGTH];
                olength_0_q[i]      <= olength_0    [i*BLENGTH +: BLENGTH];
                olength_1_q[i]      <= olength_1    [i*BLENGTH +: BLENGTH];
                olength_2_q[i]      <= olength_2    [i*BLENGTH +: BLENGTH];
                scaler_b_q[i]       <= scaler_b     [i*BSCALERB +: BSCALERB];
                olength_3_q[i]      <= olength_3    [i*BLENGTH +: BLENGTH];
            end
        end
    end
end endgenerate


// Controllers
generate for(i = 0; i < NMVU; i = i + 1) begin: controllerarray
    controller #(
        .BCNTDWN    (BCNTDWN)
    ) controller_unit (
        .clk        (clk),
        .clr        (controller_clr[i]),
        .start      (start_q[i]),
        .countdown  (countdown_q[i]),
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
        .clr        (inagu_clr[i]),
        .en         (run[i]),
        .iprecision (iprecision_q[i]),
        .istride0   (istride_0_q[i]),
        .istride1   (istride_1_q[i]),
        .istride2   (istride_2_q[i]),
        .istride3   (istride_3_q[i]),
        .ilength0   (ilength_0_q[i]),
        .ilength1   (ilength_1_q[i]),
        .ilength2   (ilength_2_q[i]),
        .ilength3   (ilength_3_q[i]),
        .ibaseaddr  (ibaseaddr_q[i]),
        .wprecision (wprecision_q[i]),
        .wstride0   (wstride_0_q[i]),
        .wstride1   (wstride_1_q[i]),
        .wstride2   (wstride_2_q[i]),
        .wstride3   (wstride_3_q[i]),
        .wlength0   (wlength_0_q[i]),
        .wlength1   (wlength_1_q[i]),
        .wlength2   (wlength_2_q[i]),
        .wlength3   (wlength_3_q[i]),
        .wbaseaddr  (wbaseaddr_q[i]),
        .iaddr_out  (rdd_addr[i*BDBANKA +: BDBANKA]),
        .waddr_out  (rdw_addr[i*BWBANKA +: BWBANKA]),
        .imsb       (d_msb[i]),
        .wmsb       (w_msb[i]),
        .sh_out     (agu_sh_out[i]),
        .shacc_done (agu_shacc_done[i])
    );
end endgenerate

// Output address generators
generate for(i = 0; i < NMVU; i = i+1) begin:outaguarray
    outagu #(
            .BDBANKA    (BDBANKA)
        ) outaguunit
        (
            .clk        (clk                                ),
            .clr        (outagu_clr[i]                      ),
            .step       (outstep[i]),
            .load       (outagu_load[i]),
            .baseaddr   (obaseaddr[i*BBDADDR +:	BBDADDR]    ),
            .addrout    (wrd_addr[i*BDBANKA  +: BDBANKA]    )
        );
end endgenerate

// Quantizer Controllers
generate for(i = 0; i < NMVU; i = i+1) begin: quantser_ctrlarray
    assign quant_bwout[i*BPREC +: BQBOUT] = oprecision[i*BPREC +: BQBOUT];
    quantser_ctrl #(
        .BWOUT      (BSCALERP)
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

// Negate the input to the accumulators when one or both data/weights are signed and is on an MSB
assign neg_acc = (d_signed & d_msb) ^ (w_signed & w_msb);


// Insert delay for accumulator shifter signals to account for number of VVP pipeline stages
generate for(i=0; i < NMVU; i = i+1) begin: ctrl_delayarray

    // TODO: connect the step signals on these shift regs
    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY + 1)
    ) shacc_load_delayarrayunit (
        .clk    (clk), 
        .clr    (~rst_n),
        .step   (1'b1),
        .in     (start_q[i]),
        .out    (shacc_load_start[i])
    );

    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY + 0)
    ) neg_acc_delayarrayunit (
        .clk    (clk), 
        .clr    (~rst_n),
        .step   (1'b1),
        .in     (neg_acc[i]),
        .out    (neg_acc_dly[i])
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
        .N      (SCALERLATENCY+MAXPOOLSTAGES)
    ) maxpool_done_delayarrayunit (
        .clk    (clk),
        .clr    (~rst_n),
        .step   (1'b1),
        .in     (shacc_done[i]),
        .out    (maxpool_done[i])
    );

    shiftreg #(
        .N      (VVPSTAGES+MEMRDLATENCY+SCALERLATENCY+MAXPOOLSTAGES + 1)
    ) outagu_load_delayarrayunit (
        .clk    (clk),
        .clr    (~rst_n),
        .step   (1'b1),
        .in     (start_q[i]),
        .out    (outagu_load[i])
    );

end endgenerate


/*   Cores... */
generate for(i=0;i<NMVU;i=i+1) begin:mvuarray
    mvu #(
            .N              (N),
            .NDBANK         (NDBANK)
        ) mvunit
        (
            .clk            (clk                                    ),
            .mul_mode       (mul_mode_q[i]                          ),
            .neg_acc        (neg_acc_dly[i]                         ),
            .shacc_clr      (shacc_clr_int[i]                       ),
            .shacc_load     (shacc_load[i]                          ),
            .shacc_acc      (shacc_acc[i]                           ),
            .shacc_sh		(shacc_sh[i]							),
            .scaler_clr     (scaler_clr[i]                          ),
            .scaler_b       (scaler_b_q[i]                          ),
            .max_en			(max_en[i]								),
            .max_clr		(max_clr[i]								),
            .max_pool		(max_pool[i]							),
            .quant_clr		(quant_clr_int[i]	    				),
            .quant_msbidx   (quant_msbidx_q[i]	                    ),
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
        	.wrc_word		(wrc_word[BDBANKW-1 : 0]				),
            .mvu_word_out   (mvu_word_out[i*BDBANKW +: BDBANKW]     )
		);
end endgenerate


/* Module end */
endmodule
