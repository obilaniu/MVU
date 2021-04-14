//
// MVU top level
//
// Notes:
// * For wlength_X and ilength_X parameters, the value to assign is actual_length - 1.
//
//
 


`timescale 1ns/1ps
/**** Module ****/
module mvutop import mvu_pkg::*; ( mvu_interface.system_interface intf);


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
reg[      NMVU-1 : 0] omvusel_q         [NMVU-1 : 0];                   // Config: MVU selection bits for output
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
reg[    NJUMPS-1 : 0] shacc_load_sel_q  [NMVU-1 : 0];           // Config: select jump trigger for shift/accumultor load

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
reg [        NMVU-1 : 0] agu_shacc_done;    // AGU accumulator done indicator
wire[        NMVU-1 : 0] run_acc;           // Run signal for the accumulator/shifters
wire[        NMVU-1 : 0] shacc_done;        // Accumulator done control
wire[        NMVU-1 : 0] maxpool_done;      // Max pool done control
wire[        NMVU-1 : 0] outagu_clr;        // Clear the output AGU
wire[        NMVU-1 : 0] outagu_load;       // Load the output AGU base address
wire[        NMVU-1 : 0] wagu_on_j0;        // Indicates when a weight address jump 0 happens
wire[        NMVU-1 : 0] wagu_on_j1;        // Indicates when a weight address jump 1 happens
wire[        NMVU-1 : 0] wagu_on_j2;        // Indicates when a weight address jump 2 happens
wire[        NMVU-1 : 0] wagu_on_j3;        // Indicates when a weight address jump 3 happens
wire[        NMVU-1 : 0] wagu_on_j4;        // Indicates when a weight address jump 4 happens


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
    .clk(intf.clk),
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

assign rdd_en           = run;                              // MVU reads when running

// TODO: WIRE THESE UP TO SOMETHING USEFUL
assign outload          = 0;
assign quant_stall      = 0;
assign step             = {NMVU{1'b1}};                      // No stalls for now

// Accumulator signals
assign run_acc          = run;                              // No stalls for now
assign shacc_load       = shacc_done | shacc_load_start;    // Load accumulator with current output of MVP's

// Clear signals (just connect to global reset for now)
assign ic_clr_int       = !intf.rst_n | intf.ic_clr;
assign controller_clr   = {NMVU{!intf.rst_n}};
assign inagu_clr        = {NMVU{!intf.rst_n}} | start_q;
assign outagu_clr       = {NMVU{!intf.rst_n}};
assign shacc_clr_int    = {NMVU{!intf.rst_n}} | intf.shacc_clr;       // Clear the accumulator
assign scaler_clr       = {NMVU{!intf.rst_n}};
assign quant_clr_int    = {NMVU{!intf.rst_n}} | intf.quant_clr;

// Quantizer and output control signals
assign quant_start      = maxpool_done;
assign outstep          = quant_step;
assign quant_ctrl_clr   = {NMVU{!intf.rst_n}} | intf.quant_clr;

// MVU Data Memory control
generate for(i = 0; i < NMVU; i = i + 1) begin: wrd_en_array
    assign wrd_en[i] = outstep[i] & omvusel_q[i][i];
end endgenerate


// Delayed start signal to sync with the parameter buffer registers
always @(posedge intf.clk) begin
    if (~intf.rst_n) begin
        start_q <= 0;
    end else begin
        start_q <= intf.start;
    end
end

// Clock in the input parameters when the start signal is asserted
generate for(i = 0; i < NMVU; i = i + 1) begin: parambuf_array
    always @(posedge intf.clk) begin
        if (~intf.rst_n) begin
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
            shacc_load_sel_q[i] <= 5'b00100;                // For 5 jumps, select the j2 by default
        end else begin
            if (intf.start[i]) begin
                mul_mode_q[i]       <= intf.mul_mode     [i*2 +: 2];
                quant_msbidx_q[i]   <= intf.quant_msbidx [i*BQMSBIDX +: BQMSBIDX];
                countdown_q[i]      <= intf.countdown    [i*BCNTDWN +: BCNTDWN];
                wprecision_q[i]     <= intf.wprecision   [i*BPREC +: BPREC];
                iprecision_q[i]     <= intf.iprecision   [i*BPREC +: BPREC];
                oprecision_q[i]     <= intf.oprecision   [i*BPREC +: BPREC];
                wbaseaddr_q[i]      <= intf.wbaseaddr    [i*BBWADDR +: BBWADDR];
                ibaseaddr_q[i]      <= intf.ibaseaddr    [i*BBDADDR +: BBDADDR];
                obaseaddr_q[i]      <= intf.obaseaddr    [i*BBDADDR +: BBDADDR];
                omvusel_q[i]        <= intf.omvusel      [i*NMVU +: NMVU];
                wstride_0_q[i]      <= intf.wstride_0    [i*BSTRIDE +: BWBANKA];
                wstride_1_q[i]      <= intf.wstride_1    [i*BSTRIDE +: BWBANKA];
                wstride_2_q[i]      <= intf.wstride_2    [i*BSTRIDE +: BWBANKA];
                wstride_3_q[i]      <= intf.wstride_3    [i*BSTRIDE +: BWBANKA];
                istride_0_q[i]      <= intf.istride_0    [i*BSTRIDE +: BDBANKA];
                istride_1_q[i]      <= intf.istride_1    [i*BSTRIDE +: BDBANKA];
                istride_2_q[i]      <= intf.istride_2    [i*BSTRIDE +: BDBANKA];
                istride_3_q[i]      <= intf.istride_3    [i*BSTRIDE +: BDBANKA];
                ostride_0_q[i]      <= intf.ostride_0    [i*BSTRIDE +: BDBANKA];
                ostride_1_q[i]      <= intf.ostride_1    [i*BSTRIDE +: BDBANKA];
                ostride_2_q[i]      <= intf.ostride_2    [i*BSTRIDE +: BDBANKA];
                ostride_3_q[i]      <= intf.ostride_3    [i*BSTRIDE +: BDBANKA];
                wlength_0_q[i]      <= intf.wlength_0    [i*BLENGTH +: BLENGTH];
                wlength_1_q[i]      <= intf.wlength_1    [i*BLENGTH +: BLENGTH];
                wlength_2_q[i]      <= intf.wlength_2    [i*BLENGTH +: BLENGTH];
                wlength_3_q[i]      <= intf.wlength_3    [i*BLENGTH +: BLENGTH];
                ilength_0_q[i]      <= intf.ilength_0    [i*BLENGTH +: BLENGTH];
                ilength_1_q[i]      <= intf.ilength_1    [i*BLENGTH +: BLENGTH];
                ilength_2_q[i]      <= intf.ilength_2    [i*BLENGTH +: BLENGTH];
                ilength_3_q[i]      <= intf.ilength_3    [i*BLENGTH +: BLENGTH];
                olength_0_q[i]      <= intf.olength_0    [i*BLENGTH +: BLENGTH];
                olength_1_q[i]      <= intf.olength_1    [i*BLENGTH +: BLENGTH];
                olength_2_q[i]      <= intf.olength_2    [i*BLENGTH +: BLENGTH];
                scaler_b_q[i]       <= intf.scaler_b     [i*BSCALERB +: BSCALERB];
                olength_3_q[i]      <= intf.olength_3    [i*BLENGTH +: BLENGTH];
                shacc_load_sel_q[i] <= intf.shacc_load_sel[i*NJUMPS +: NJUMPS];
            end
        end
    end
end endgenerate


// Controllers
generate for(i = 0; i < NMVU; i = i + 1) begin: controllerarray
    controller #(
        .BCNTDWN    (BCNTDWN)
    ) controller_unit (
        .clk        (intf.clk),
        .clr        (controller_clr[i]),
        .start      (start_q[i]),
        .countdown  (countdown_q[i]),
        .step       (step[i]),
        .run        (run[i]),
        .done       (intf.done[i]),
        .irq        (intf.irq[i])
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
        .clk        (intf.clk),
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
        .wagu_on_j0 (wagu_on_j0[i]),
        .wagu_on_j1 (wagu_on_j1[i]),
        .wagu_on_j2 (wagu_on_j2[i]),
        .wagu_on_j3 (wagu_on_j3[i]),
        .wagu_on_j4 (wagu_on_j4[i])
        //.shacc_done (agu_shacc_done[i])
    );
end endgenerate

// Output address generators
generate for(i = 0; i < NMVU; i = i+1) begin:outaguarray
    outagu #(
            .BDBANKA    (BDBANKA)
        ) outaguunit
        (
            .clk        (intf.clk                            ),
            .clr        (outagu_clr[i]                      ),
            .step       (outstep[i]                         ),
            .load       (outagu_load[i]                     ),
            .baseaddr   (intf.obaseaddr[i*BBDADDR +: BBDADDR]),
            .addrout    (wrd_addr[i*BDBANKA  +: BDBANKA]    )
        );
end endgenerate

// Quantizer Controllers
generate for(i = 0; i < NMVU; i = i+1) begin: quantser_ctrlarray
    assign quant_bwout[i*BPREC +: BQBOUT] = intf.oprecision[i*BPREC +: BQBOUT];
    quantser_ctrl #(
        .BWOUT      (BSCALERP)
    ) quantser_ctrl_unit (
        .clk        (intf.clk),
        .clr        (quant_ctrl_clr[i]),
        .bwout      (quant_bwout[i*BPREC +: BQBOUT]),
        .start      (quant_start[i]),
        .stall      (quant_stall[i]),
        .load       (quant_load[i]),
        .step       (quant_step[i])
    );
end endgenerate

// Negate the input to the accumulators when one or both data/weights are signed and is on an MSB
assign neg_acc = (intf.d_signed & d_msb) ^ (intf.w_signed & w_msb);

// Trigger when the shacc should load
generate for(i = 0; i < NMVU; i = i+1) begin: triggers
    always @(shacc_load_sel_q, wagu_on_j0, wagu_on_j1, wagu_on_j2, wagu_on_j3, wagu_on_j4) begin
        if (run[i]) begin
            case (shacc_load_sel_q[i])
                5'b00001:
                    agu_shacc_done[i] = wagu_on_j0[i];
                5'b00010:
                    agu_shacc_done[i] = wagu_on_j1[i];
                5'b00100:
                    agu_shacc_done[i] = wagu_on_j2[i];
                5'b01000:
                    agu_shacc_done[i] = wagu_on_j3[i];
                5'b10000:
                    agu_shacc_done[i] = wagu_on_j4[i];
                default:
                    agu_shacc_done[i] = 1'b0;
            endcase
        end else begin
            agu_shacc_done[i] = 1'b0;
        end
    end
end endgenerate


// Insert delay for accumulator shifter signals to account for number of VVP pipeline stages
generate for(i=0; i < NMVU; i = i+1) begin: ctrl_delayarray

    // TODO: connect the step signals on these shift regs
    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY + 1)
    ) shacc_load_delayarrayunit (
        .clk    (intf.clk), 
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (start_q[i]),
        .out    (shacc_load_start[i])
    );

    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY + 0)
    ) neg_acc_delayarrayunit (
        .clk    (intf.clk), 
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (neg_acc[i]),
        .out    (neg_acc_dly[i])
    );

    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY + 0)
    ) shacc_sh_delayarrayunit (
        .clk    (intf.clk), 
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (agu_sh_out[i]),
        .out    (shacc_sh[i])
    );

    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY + 1)
    ) shacc_acc_delayarrayunit (
        .clk    (intf.clk), 
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (run_acc[i]),
        .out    (shacc_acc[i])
    );

    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY + 1)      // TODO: find a better way to re-time this
    ) acc_done_delayarrayunit (
        .clk    (intf.clk), 
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (agu_shacc_done[i]),
        .out    (shacc_done[i])
    );

    shiftreg #(
        .N      (SCALERLATENCY+MAXPOOLSTAGES)
    ) maxpool_done_delayarrayunit (
        .clk    (intf.clk),
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (shacc_done[i]),
        .out    (maxpool_done[i])
    );

    shiftreg #(
        .N      (VVPSTAGES+MEMRDLATENCY+SCALERLATENCY+MAXPOOLSTAGES + 1)
    ) outagu_load_delayarrayunit (
        .clk    (intf.clk),
        .clr    (~intf.rst_n),
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
            .clk            (intf.clk                                ),
            .mul_mode       (mul_mode_q[i]                          ),
            .neg_acc        (neg_acc_dly[i]                         ),
            .shacc_clr      (shacc_clr_int[i]                       ),
            .shacc_load     (shacc_load[i]                          ),
            .shacc_acc      (shacc_acc[i]                           ),
            .shacc_sh       (shacc_sh[i]                            ),
            .scaler_clr     (scaler_clr[i]                          ),
            .scaler_b       (scaler_b_q[i]                          ),
            .max_en         (intf.max_en[i]                          ),
            .max_clr        (intf.max_clr[i]                         ),
            .max_pool       (intf.max_pool[i]                        ),
            .quant_clr      (quant_clr_int[i]                       ),
            .quant_msbidx   (quant_msbidx_q[i]                      ),
            .quant_load     (quant_load[i]                          ),
            .quant_step     (quant_step[i]                          ),
            .rdw_addr       (rdw_addr[i*BWBANKA +: BWBANKA]         ),
            .wrw_addr       (intf.wrw_addr[i*BWBANKA +: BWBANKA]     ),
            .wrw_word       (intf.wrw_word[i*BWBANKW +: BWBANKW]     ),
            .wrw_en         (intf.wrw_en[i]                          ),
            .rdd_en         (rdd_en[i]                              ),
            .rdd_grnt       (rdd_grnt[i]                            ),
            .rdd_addr       (rdd_addr[i*BDBANKA +: BDBANKA]         ),
            .wrd_en         (wrd_en[i]                              ),
            .wrd_grnt       (wrd_grnt[i]                            ),
            .wrd_addr       (wrd_addr[i*BDBANKA +: BDBANKA]         ),
            .rdi_en         (rdi_en[i]                              ),
            .rdi_grnt       (rdi_grnt[i]                            ),
            .rdi_addr       (rdi_addr[i*BDBANKA +: BDBANKA]         ),
            .rdi_word       (rdi_word[i*BDBANKW +: BDBANKW]         ),
            .wri_en         (wri_en[i]                              ),
            .wri_grnt       (wri_grnt[i]                            ),
            .wri_addr       (wri_addr[i*BDBANKA +: BDBANKA]         ),
            .wri_word       (wri_word[i*BDBANKW +: BDBANKW]         ),
            .rdc_en         (intf.rdc_en[i]                          ),
            .rdc_grnt       (intf.rdc_grnt[i]                        ),
            .rdc_addr       (intf.rdc_addr[i*BDBANKA +: BDBANKA]     ),
            .rdc_word       (intf.rdc_word[i*BDBANKW +: BDBANKW]     ),
            .wrc_en         (intf.wrc_en[i]                          ),
            .wrc_grnt       (intf.wrc_grnt[i]                        ),
            .wrc_addr       (intf.wrc_addr[BDBANKA-1: 0]             ),
            .wrc_word       (intf.wrc_word[BDBANKW-1 : 0]            ),
            .mvu_word_out   (mvu_word_out[i*BDBANKW +: BDBANKW]     )
                );
end endgenerate


/* Module end */
endmodule
