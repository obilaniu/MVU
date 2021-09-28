//
// MVU top level
//
// Notes:
// * For wlength_X and ilength_X parameters, the value to assign is actual_length - 1.
//
//
`timescale 1ns/1ps

`include "mvu_inf.svh"

/**** Module ****/
module mvutop import mvu_pkg::*; ( mvu_interface.system_interface intf);


genvar i;

// Local registers
logic[      NMVU-1 : 0] start_q;                                  // Delayed start signal
logic[           1 : 0] mul_mode_q        [NMVU-1 : 0];           // Config: multiply mode
logic[  BQMSBIDX-1 : 0] quant_msbidx_q    [NMVU-1 : 0];           // Quantizer: bit position index of the MSB
logic[   BCNTDWN-1 : 0] countdown_q       [NMVU-1 : 0];           // Config: number of clocks to countdown for given task
logic[     BPREC-1 : 0] wprecision_q      [NMVU-1 : 0];           // Config: weight precision
logic[     BPREC-1 : 0] iprecision_q      [NMVU-1 : 0];           // Config: input precision
logic[     BPREC-1 : 0] oprecision_q      [NMVU-1 : 0];           // Config: output precision
logic[   BBWADDR-1 : 0] wbaseaddr_q       [NMVU-1 : 0];           // Config: weight memory base address
logic[   BBDADDR-1 : 0] ibaseaddr_q       [NMVU-1 : 0];           // Config: data memory base address for input
logic[   BSBANKA-1 : 0] sbaseaddr_q       [NMVU-1 : 0];           // Config: scaler memory base address
logic[   BBBANKA-1 : 0] bbaseaddr_q       [NMVU-1 : 0];           // Config: bias memory base address
logic[   BBDADDR-1 : 0] obaseaddr_q       [NMVU-1 : 0];           // Config: data memory base address for output
logic[      NMVU-1 : 0] omvusel_q         [NMVU-1 : 0];           // Config: MVU selection bits for output
logic[ BDHPBANKA-1 : 0] ihpbaseaddr_q     [NMVU-1 : 0];           // Config: high-precision data memory base address for input
logic[ BDHPBANKA-1 : 0] ohpbaseaddr_q     [NMVU-1 : 0];           // Config: high-precision data memory base address for output
logic[      NMVU-1 : 0] ohpmvusel_q       [NMVU-1 : 0];           // Config: MVU selector bits for high-precision output
logic[   BWBANKA-1 : 0] wjump_q           [NMVU-1 : 0][NJUMPS-1 : 0];           // Config: weight jumps
logic[   BDBANKA-1 : 0] ijump_q           [NMVU-1 : 0][NJUMPS-1 : 0];           // Config: input jumps
logic[ BDHPBANKA-1 : 0] hpjump_q          [NMVU-1 : 0][NJUMPS-1 : 0];           // Config: high-precision jump
logic[   BSBANKA-1 : 0] sjump_q           [NMVU-1 : 0][NJUMPS-1 : 0];           // Config: scaler jump
logic[   BBBANKA-1 : 0] bjump_q           [NMVU-1 : 0][NJUMPS-1 : 0];           // Config: bias jump
logic[   BDBANKA-1 : 0] ojump_q           [NMVU-1 : 0][NJUMPS-1 : 0];           // Config: output jump
logic[   BLENGTH-1 : 0] wlength_q         [NMVU-1 : 0][NJUMPS-1 : 1];           // Config: weight length
logic[   BLENGTH-1 : 0] ilength_q         [NMVU-1 : 0][NJUMPS-1 : 1];           // Config: input length
logic[   BLENGTH-1 : 0] hplength_q        [NMVU-1 : 0][NJUMPS-1 : 1];           // Config: high-precision length
logic[   BLENGTH-1 : 0] slength_q         [NMVU-1 : 0][NJUMPS-1 : 1];           // Config: scaler length
logic[   BLENGTH-1 : 0] blength_q         [NMVU-1 : 0][NJUMPS-1 : 1];           // Config: bias length
logic[   BLENGTH-1 : 0] olength_q         [NMVU-1 : 0][NJUMPS-1 : 1];           // Config: output length
logic[  BSCALERB-1 : 0] scaler1_b_q       [NMVU-1 : 0];                         // Config: multiplicative scaler (operand 'b') for scaler 1
logic[  BSCALERB-1 : 0] scaler2_b_q       [NMVU-1 : 0];                         // Config: multiplicative scaler (operand 'b') for scaler 2
logic                   usescaler_mem_q   [NMVU-1 : 0];                         // Config: use scalar mem if 1; otherwise use the scaler_b input for scaling
logic                   usebias_mem_q     [NMVU-1 : 0];                         // Config: use the bias memory if 1; if not, not bias is added in the scaler
logic                   usepooler4hpout_q [NMVU-1 : 0];                         // Config: for the high-precision interconnect, use the output of pooler if 1, or use output of scaler1 if 0
logic                   usehpadder_q      [NMVU-1 : 0];                         // Config: use the hpadder if 1
logic[    NJUMPS-1 : 0] shacc_load_sel_q  [NMVU-1 : 0];                         // Config: select jump trigger for shift/accumultor load
logic[    NJUMPS-1 : 0] zigzag_step_sel_q [NMVU-1 : 0];                         // Config: select jump trigger for stepping the zig-zag address generator

/* Local Wires */

// MVU Weight memory controll
logic[NMVU*BWBANKA-1 : 0] rdw_addr;

// MVU Data memory control (low precision)
logic[        NMVU-1 : 0] rdd_en;
logic[        NMVU-1 : 0] rdd_grnt;
logic[NMVU*BDBANKA-1 : 0] rdd_addr;
logic[        NMVU-1 : 0] wrd_en;
logic[        NMVU-1 : 0] wrd_grnt;
logic[NMVU*BDBANKA-1 : 0] wrd_addr;

// MVU Data memory control (high precision)
logic                       rddhp_en [NMVU-1 : 0];
logic                       rddhp_grnt [NMVU-1 : 0];
logic[     BDHPBANKA-1 : 0] rddhp_addr [NMVU-1 : 0];
logic[     BDHPBANKA-1 : 0] rddhp_addr_offset [NMVU-1 : 0];
logic                       wrdhp_en [NMVU-1 : 0];
logic                       wrdhp_grnt [NMVU-1 : 0];
logic[     BDHPBANKA-1 : 0] wrdhp_addr [NMVU-1 : 0];

// MVU Scaler and Bias memory control
logic[        NMVU-1 : 0] rds_en;                        // Scaler memory: read enable
logic[NMVU*BSBANKA-1 : 0] rds_addr;                      // Scaler memory: read address
logic[     BSBANKA-1 : 0] rds_addr_offset [NMVU-1 : 0];  // Scaler memory: read address offset from scaler mem AGU
logic[        NMVU-1 : 0] rdb_en;                        // Bias memory: read enable
logic[NMVU*BBBANKA-1 : 0] rdb_addr;                      // Bias memory: read address
logic[     BBBANKA-1 : 0] rdb_addr_offset [NMVU-1 : 0];  // Bias memory: read address offset from bias mem AGU

// Interconnect
logic                     ic_clr_int;
logic[   NMVU*NMVU-1 : 0] ic_send_to;
logic[        NMVU-1 : 0] ic_send_en;
logic[NMVU*BDBANKA-1 : 0] ic_send_addr;
logic[NMVU*BDBANKW-1 : 0] ic_send_word;
logic[        NMVU-1 : 0] ic_recv_en;
logic[   NMVU*NMVU-1 : 0] ic_recv_from;
logic[NMVU*BDBANKA-1 : 0] ic_recv_addr;
logic[NMVU*BDBANKW-1 : 0] ic_recv_word;
logic[NMVU*BDBANKW-1 : 0] rdi_word;
logic[        NMVU-1 : 0] wri_en;
logic[NMVU*BDBANKW-1 : 0] wri_word;

logic[        NMVU-1 : 0] rdi_en;
logic[        NMVU-1 : 0] rdi_grnt;
logic[NMVU*BDBANKA-1 : 0] rdi_addr;
logic[        NMVU-1 : 0] wri_grnt;
logic[NMVU*BDBANKA-1 : 0] wri_addr;

logic[NMVU*BDBANKW-1 : 0] mvu_word_out;

// Interconnect (high-precision)
logic                     ichp_clr_int;
logic[        NMVU-1 : 0] ichp_send_to [NMVU-1 : 0];
logic                     ichp_send_en [NMVU-1 : 0];
logic                     ichp_send_en_trig [NMVU-1 : 0];
logic[   BDHPBANKA-1 : 0] ichp_send_addr [NMVU-1 : 0];
logic[    BDHPBUSW-1 : 0] ichp_send_word [NMVU-1 : 0];
logic                     ichp_recv_en [NMVU-1 : 0];
logic[        NMVU-1 : 0] ichp_recv_from [NMVU-1 : 0];
logic[   BDHPBANKA-1 : 0] ichp_recv_addr [NMVU-1 : 0];
logic[    BDHPBUSW-1 : 0] ichp_recv_word [NMVU-1 : 0];
logic[NMVU*BDHPBUSW-1 : 0] rdihp_word;
logic[        NMVU-1 : 0] wrihp_en;
logic[    BDHPBUSW-1 : 0] wrihp_word [NMVU-1 : 0];
logic[        NMVU-1 : 0] rdihp_en;
logic[        NMVU-1 : 0] rdihp_grnt;
logic[NMVU*BDHPBANKA-1 : 0] rdihp_addr;
logic[        NMVU-1 : 0] wrihp_grnt;
logic[   BDHPBANKA-1 : 0] wrihp_addr [NMVU-1 : 0];
logic[    BDHPBUSW-1 : 0] mvu_word_outhp [NMVU-1 : 0];

// Scaler1
logic[        NMVU-1 : 0] scaler1_clr;            // Scaler: clear/reset

// High-precision adder
logic[        NMVU-1 : 0] hpadder_clr;            // Adder: clear/reset

// Scaler2
logic[        NMVU-1 : 0] scaler2_clr;            // Scaler: clear/reset

// Quantizer
logic[        NMVU-1 : 0] quant_start;           // Quantizer: signal to start quantizing
logic[        NMVU-1 : 0] quant_stall;           // Quantizer: stall
logic[      NMVU*N-1 : 0] quantarray_out;        // Quantizer: output
logic[  BPREC*NMVU-1 : 0] quant_bwout;           // Quantizer: output bitwidth
logic[        NMVU-1 : 0] quant_load;            // Quantizer: load base address
logic[        NMVU-1 : 0] quant_step;            // Quantizer: step the quantizer
logic[        NMVU-1 : 0] quant_ctrl_clr;        // Quantizer: clear/reset controller
logic[        NMVU-1 : 0] quant_clr_int;         // Quantizer: internal clear control

// Output data write back to memory
// TODO: DO SOMETHING USEFUL WITH THESE SIGNALS
logic[        NMVU-1 : 0] outstep;
logic[        NMVU-1 : 0] outload;

// Other wires
logic[        NMVU-1 : 0] inagu_clr;
logic[        NMVU-1 : 0] controller_clr;    // Controller clear/reset
logic[        NMVU-1 : 0] step;              // Step if 1, stall if 0
logic[        NMVU-1 : 0] run;               // Running if 1
logic[        NMVU-1 : 0] d_msb;             // Input data address on MSB
logic[        NMVU-1 : 0] w_msb;             // Weight data address on MSB
logic[        NMVU-1 : 0] neg_acc;           // Negate the input to the accumulators
logic[        NMVU-1 : 0] neg_acc_dly;       // Negation control delayed
logic[        NMVU-1 : 0] shacc_load;        // Accumulator load control
logic[        NMVU-1 : 0] shacc_sh;          // Accumulator shift control
logic[        NMVU-1 : 0] shacc_acc;         // Accumulator accumulate control
logic[        NMVU-1 : 0] shacc_clr_int;     // Accumulator clear internal control
logic[        NMVU-1 : 0] shacc_load_start;  // Accumulator load from start of job
logic[        NMVU-1 : 0] agu_sh_out;        // Input AGU shift accumulator
logic[        NMVU-1 : 0] agu_shacc_done;    // AGU accumulator done indicator
logic[        NMVU-1 : 0] run_acc;           // Run signal for the accumulator/shifters
logic[        NMVU-1 : 0] shacc_done;        // Accumulator done control
logic[        NMVU-1 : 0] scaler1_done;      // Scaler 1 done control
logic[        NMVU-1 : 0] hpadder_done;      // High-precision adder done control
logic[        NMVU-1 : 0] maxpool_done;      // Max pool done control
logic[        NMVU-1 : 0] scaler2_done;      // Scaler 2 done control
logic[        NMVU-1 : 0] outagu_clr;        // Clear the output AGU
logic[        NMVU-1 : 0] outagu_load;       // Load the output AGU base address
logic[        NMVU-1 : 0] inhpagu_clr;       // Clear the input high-precision AGU
logic[        NMVU-1 : 0] inhpagu_step;      // Step the input high-precision AGU
logic[        NMVU-1 : 0] outhpagu_clr;      // Clear the output high-precision AGU
logic[        NMVU-1 : 0] outhpagu_step;     // Step the output high-precision AGU
logic[        NMVU-1 : 0] outhpagu_load;     // Load the output high-precision AGU base address
logic[        NMVU-1 : 0] outhpagu_load_onscaler1;
logic[        NMVU-1 : 0] outhpagu_load_onpooler;
logic[      NJUMPS-1 : 0] wagu_on_j[NMVU-1 : 0];      // Indicates when a weight address jump X
logic[        NMVU-1 : 0] scaleragu_step;    // Steps the scaler memory AGU
logic[        NMVU-1 : 0] biasagu_step;      // Steps the bias memory AGU
logic[        NMVU-1 : 0] scaleragu_clr;     // Clears the state of the Scaler memory AGU
logic[        NMVU-1 : 0] biasagu_clr;       // Clears the state of the bias memory AGU
logic[        NMVU-1 : 0] scaleragu_clr_dly; // Clears the state of the Scaler memory AGU
logic[        NMVU-1 : 0] biasagu_clr_dly;   // Clears the state of the bias memory AGU


/*
* Wiring 
*/

/*
* Interconnect (quantized)
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
assign ic_send_addr = wrd_addr;             // Set to address that MVU output is writing to
assign wri_word     = ic_recv_word;
assign wri_en       = ic_recv_en;
assign wri_addr     = ic_recv_addr;         // This is the incoming address from the interconnect

// TODO: FIGURE OUT WHERE TO WIRE OTHER INTERCONNECT DATA ACCESS SIGNAL
assign rdi_en           = 0;
//assign rdi_grnt         = 0;
assign rdi_addr         = 0;
//assign wri_grnt         = 0;


/*
* Interconnect (high-precision)
*/

interconn_new #(
    .N(NMVU),
    .W(BDHPBUSW),
    .BADDR(BDHPBANKA)
) ichp (
    .clk(intf.clk),
    .clr(ichp_clr_int),
    .send_to(ichp_send_to),
    .send_en(ichp_send_en),
    .send_addr(ichp_send_addr),
    .send_word(ichp_send_word),
    .recv_from(ichp_recv_from),
    .recv_en(ichp_recv_en),
    .recv_addr(ichp_recv_addr),
    .recv_word(ichp_recv_word)
);

// Interconnect wires
generate for(i=0; i < NMVU; i = i+1) begin
    assign ichp_send_to[i] = ohpmvusel_q[i];
    assign ichp_send_en_trig[i] = usepooler4hpout_q[i] ? maxpool_done[i] : scaler1_done[i];
    assign ichp_send_en[i] = (| ohpmvusel_q[i]) & ichp_send_en_trig[i];      // Trigger when source unit is done
    assign wrihp_en[i] = ichp_recv_en[i];
    assign ichp_send_word[i] = mvu_word_outhp[i];
    assign ichp_send_addr[i] = wrdhp_addr[i];
    assign wrihp_word[i] = ichp_recv_word[i];
    assign wrihp_addr[i] = ichp_recv_addr[i];
end endgenerate


/*
* More signals
*/

assign rdd_en           = run;                              // MVU reads when running

generate for(i=0; i < NMVU; i = i+1) begin
    assign rds_en[i] = run[i] & usescaler_mem_q[i];            // No need to read from scaler mem if not using
    assign rdb_en[i] = run[i] & usebias_mem_q[i];              // No need to read from bias mem if not using
end endgenerate

// TODO: WIRE THESE UP TO SOMETHING USEFUL
assign outload          = 0;
assign quant_stall      = 0;
assign step             = {NMVU{1'b1}};                      // No stalls for now

// Accumulator signals
assign run_acc          = run;                              // No stalls for now
assign shacc_load       = shacc_done | shacc_load_start;    // Load accumulator with current output of MVP's

// Clear signals (just connect to global reset for now)
assign ic_clr_int       = !intf.rst_n | intf.ic_clr;
assign ichp_clr_int     = !intf.rst_n | intf.ichp_clr;
assign controller_clr   = {NMVU{!intf.rst_n}};
assign inagu_clr        = {NMVU{!intf.rst_n}} | start_q;
assign outagu_clr       = {NMVU{!intf.rst_n}};
assign outhpagu_clr     = {NMVU{!intf.rst_n}};
assign shacc_clr_int    = {NMVU{!intf.rst_n}} | intf.shacc_clr;       // Clear the accumulator
assign inhpagu_clr      = {NMVU{!intf.rst_n}};
assign scaleragu_clr    = {NMVU{!intf.rst_n}} | scaleragu_clr_dly;
assign biasagu_clr      = {NMVU{!intf.rst_n}} | biasagu_clr_dly;
assign scaler1_clr      = {NMVU{!intf.rst_n}};
assign quant_clr_int    = {NMVU{!intf.rst_n}} | intf.quant_clr;
assign scaler2_clr      = {NMVU{!intf.rst_n}};
assign hpadder_clr      = {NMVU{!intf.rst_n}};

// Quantizer and output control signals
assign quant_start      = scaler2_done;
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
            sbaseaddr_q[i]      <= 0;
            bbaseaddr_q[i]      <= 0;
            obaseaddr_q[i]      <= 0;
            omvusel_q[i]        <= 0;
            ihpbaseaddr_q[i]    <= 0;
            ohpbaseaddr_q[i]    <= 0;
            ohpmvusel_q[i]      <= 0;
            scaler1_b_q[i]      <= 0;
            scaler2_b_q[i]      <= 0;
            usescaler_mem_q[i]  <= 0;
            usebias_mem_q[i]    <= 0;
            usepooler4hpout_q[i] <= 0;
            shacc_load_sel_q[i] <= 5'b00100;                // For 5 jumps, select the j2 by default
            zigzag_step_sel_q[i] <= 5'b00001;               // For 5 jumps, select the j0 by default

            // Initialize the jump parameters
            for (int j = 0; j < NJUMPS; j++) begin
                wjump_q[i][j] <= 0;
                ijump_q[i][j] <= 0;
                sjump_q[i][j] <= 0;
                bjump_q[i][j] <= 0;
                ojump_q[i][j] <= 0;
            end

            // Intialize the length parameters
            for (int j = 1; j < NJUMPS; j++) begin
                wlength_q[i][j] <= 0;
                ilength_q[i][j] <= 0;
                slength_q[i][j] <= 0;
                blength_q[i][j] <= 0;
                olength_q[i][j] <= 0;
            end

        end else begin
            if (intf.start[i]) begin
                mul_mode_q[i]           <= intf.mul_mode     [i*2 +: 2];
                quant_msbidx_q[i]       <= intf.quant_msbidx [i*BQMSBIDX +: BQMSBIDX];
                countdown_q[i]          <= intf.countdown    [i*BCNTDWN +: BCNTDWN];
                wprecision_q[i]         <= intf.wprecision   [i*BPREC +: BPREC];
                iprecision_q[i]         <= intf.iprecision   [i*BPREC +: BPREC];
                oprecision_q[i]         <= intf.oprecision   [i*BPREC +: BPREC];
                wbaseaddr_q[i]          <= intf.wbaseaddr    [i*BBWADDR +: BBWADDR];
                ibaseaddr_q[i]          <= intf.ibaseaddr    [i*BBDADDR +: BBDADDR];
                sbaseaddr_q[i]          <= intf.sbaseaddr    [i*BSBANKA +: BSBANKA];
                bbaseaddr_q[i]          <= intf.bbaseaddr    [i*BBBANKA +: BBBANKA];
                obaseaddr_q[i]          <= intf.obaseaddr    [i*BBDADDR +: BBDADDR];
                omvusel_q[i]            <= intf.omvusel      [i*NMVU +: NMVU];
                ihpbaseaddr_q[i]        <= intf.ihpbaseaddr  [i*BBDADDR +: BBDADDR];
                ohpbaseaddr_q[i]        <= intf.ohpbaseaddr  [i*BBDADDR +: BBDADDR];
                ohpmvusel_q[i]          <= intf.ohpmvusel    [i*NMVU +: NMVU];
                scaler1_b_q[i]          <= intf.scaler1_b    [i*BSCALERB +: BSCALERB];
                scaler2_b_q[i]          <= intf.scaler2_b    [i*BSCALERB +: BSCALERB];
                usescaler_mem_q[i]      <= intf.usescaler_mem[i];
                usebias_mem_q[i]        <= intf.usebias_mem[i];
                usehpadder_q[i]         <= intf.usehpadder[i];
                usepooler4hpout_q[i]    <= intf.usepooler4hpout[i];
                shacc_load_sel_q[i]     <= intf.shacc_load_sel[i];
                zigzag_step_sel_q[i]    <= intf.zigzag_step_sel[i];

                // Assign the jump parameters
                for (int j = 0; j < NJUMPS; j++) begin
                    wjump_q[i][j] <= intf.wjump[i][j];
                    ijump_q[i][j] <= intf.ijump[i][j];
                    hpjump_q[i][j] <= intf.hpjump[i][j];
                    sjump_q[i][j] <= intf.sjump[i][j];
                    bjump_q[i][j] <= intf.bjump[i][j];
                    ojump_q[i][j] <= intf.ojump[i][j];
                end

                // Assign the length parameters
                for (int j = 1; j < NJUMPS; j++) begin
                    wlength_q[i][j] <= intf.wlength[i][j];
                    ilength_q[i][j] <= intf.ilength[i][j];
                    hplength_q[i][j] <= intf.hplength[i][j];
                    slength_q[i][j] <= intf.slength[i][j];
                    blength_q[i][j] <= intf.blength[i][j];
                    olength_q[i][j] <= intf.olength[i][j];
                end
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
        .ijump      (ijump_q[i]),
        .ilength    (ilength_q[i]),
        .ibaseaddr  (ibaseaddr_q[i]),
        .wprecision (wprecision_q[i]),
        .wjump      (wjump_q[i]),
        .wlength    (wlength_q[i]),
        .wbaseaddr  (wbaseaddr_q[i]),
        .zigzag_step_sel(zigzag_step_sel_q[i]),
        .iaddr_out  (rdd_addr[i*BDBANKA +: BDBANKA]),
        .waddr_out  (rdw_addr[i*BWBANKA +: BWBANKA]),
        .imsb       (d_msb[i]),
        .wmsb       (w_msb[i]),
        .sh_out     (agu_sh_out[i]),
        .wagu_on_j  (wagu_on_j[i])
    );
end endgenerate

// Scaler and Bias memory address generation units
generate for(i = 0; i < NMVU; i = i+1) begin: scalerbiasaguarray

    agu #(
        .BWADDR     (BSBANKA),
        .BWLENGTH   (BLENGTH)
    ) scaleragu_unit (
        .clk        (intf.clk),
        .clr        (scaleragu_clr[i]),
        .step       (scaleragu_step[i]),
        .l          (slength_q[i]),
        .j          (sjump_q[i]),            // TODO: come up with better numbering scheme
        .addr_out   (rds_addr_offset[i]),
        .z_out      (),
        .on_j       ()
    );

    agu #(
        .BWADDR     (BBBANKA),
        .BWLENGTH   (BLENGTH)
    ) biasagu_unit (
        .clk        (intf.clk),
        .clr        (scaleragu_clr[i]),
        .step       (scaleragu_step[i]),
        .l          (blength_q[i]),
        .j          (bjump_q[i]),            // TODO: come up with better numbering scheme
        .addr_out   (rdb_addr_offset[i]),
        .z_out      (),
        .on_j       ()
    );

    assign rds_addr[i*BSBANKA +: BSBANKA] = sbaseaddr_q[i] + rds_addr_offset[i];
    assign rdb_addr[i*BBBANKA +: BBBANKA] = bbaseaddr_q[i] + rdb_addr_offset[i];

end endgenerate

// High-precision data read address generators
generate for(i = 0; i < NMVU; i = i+1) begin: hprdaguarray
    agu #(
        .BWADDR     (BDHPBANKA),
        .BWLENGTH   (BLENGTH)
    ) hprdagu_unit (
        .clk        (intf.clk),
        .clr        (inhpagu_clr[i]),
        .step       (inhpagu_step[i]),
        .l          (hplength_q[i]),
        .j          (hpjump_q[i]),
        .addr_out   (rddhp_addr_offset[i]),
        .z_out      (),
        .on_j       ()
    );
    assign rddhp_addr[i] = ihpbaseaddr_q[i] + rddhp_addr_offset[i];
    assign inhpagu_step[i] = scaler1_done[i];
end endgenerate


// Output address generators
generate for(i = 0; i < NMVU; i = i+1) begin:outaguarray
    outagu #(
            .BDBANKA    (BDBANKA)
        ) outaguunit
        (
            .clk        (intf.clk                           ),
            .clr        (outagu_clr[i]                      ),
            .step       (outstep[i]                         ),
            .load       (outagu_load[i]                     ),
            .baseaddr   (obaseaddr_q[i]                     ),
            .addrout    (wrd_addr[i*BDBANKA  +: BDBANKA]    )
        );
end endgenerate

// Output address generators for high precision data
generate for(i = 0; i < NMVU; i = i+1) begin:outhpaguarray
    outagu #(
            .BDBANKA    (BDHPBANKA)
        ) outaguunit
        (
            .clk        (intf.clk),
            .clr        (outhpagu_clr[i]),
            .step       (outhpagu_step[i]),
            .load       (outhpagu_load[i]),
            .baseaddr   (ohpbaseaddr_q[i]),
            .addrout    (wrdhp_addr[i])
        );
    assign outhpagu_load[i] = usepooler4hpout_q[i] ? outhpagu_load_onpooler[i] : outhpagu_load_onscaler1[i];
    assign outhpagu_step[i] = usepooler4hpout_q[i] ? maxpool_done[i] : scaler1_done[i];
end endgenerate


// Quantizer Controllers
generate for(i = 0; i < NMVU; i = i+1) begin: quantser_ctrlarray
    assign quant_bwout[i*BPREC +: BQBOUT] = oprecision_q[i];
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
    assign agu_shacc_done[i] = run[i] && (wagu_on_j[i] & shacc_load_sel_q[i]);
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
        .N      (VVPSTAGES + MEMRDLATENCY)      // TODO: find a better way to re-time this
    ) scaleragu_step_delayarrayunit (
        .clk    (intf.clk), 
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (agu_shacc_done[i]),
        .out    (scaleragu_step[i])
    );

    shiftreg #(
        .N      (VVPSTAGES + MEMRDLATENCY)      // TODO: find a better way to re-time this
    ) scaleragu_clr_delayarrayunit (
        .clk    (intf.clk), 
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (start_q[i]),
        .out    (scaleragu_clr_dly[i])
    );

    shiftreg #(
        .N      (SCALERLATENCY+HPADDERLATENCY+MAXPOOLSTAGES)
    ) maxpool_done_delayarrayunit (
        .clk    (intf.clk),
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (shacc_done[i]),
        .out    (maxpool_done[i])
    );

    shiftreg #(
        .N      (SCALERLATENCY)
    ) scaler2_done_delayarrayunit (
        .clk    (intf.clk),
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (maxpool_done[i]),
        .out    (scaler2_done[i])
    );

    shiftreg #(
        .N      (VVPSTAGES+MEMRDLATENCY+2*SCALERLATENCY+HPADDERLATENCY+MAXPOOLSTAGES + 1)
    ) outagu_load_delayarrayunit (
        .clk    (intf.clk),
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (start_q[i]),
        .out    (outagu_load[i])
    );

    shiftreg #(
        .N      (VVPSTAGES+MEMRDLATENCY+SCALERLATENCY)
    ) outhpagu_load_onscaler1_delayarrayunit (
        .clk    (intf.clk),
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (start_q[i]),
        .out    (outhpagu_load_onscaler1[i])
    );

    shiftreg #(
        .N      (VVPSTAGES+MEMRDLATENCY+SCALERLATENCY+HPADDERLATENCY+MAXPOOLSTAGES)
    ) outhpagu_load_onpooler_delayarrayunit (
        .clk    (intf.clk),
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (start_q[i]),
        .out    (outhpagu_load_onpooler[i])
    );

    shiftreg #(
        .N      (SCALERLATENCY)
    ) scaler1_done_delayarrayunit (
        .clk    (intf.clk),
        .clr    (~intf.rst_n),
        .step   (1'b1),
        .in     (shacc_done[i]),
        .out    (scaler1_done[i])
    );

end endgenerate


/*   Cores... */
generate for(i=0;i<NMVU;i=i+1) begin:mvuarray
    mvu #(
            .N              (N),
            .NDBANK         (NDBANK),
            .BDHPBANKW      (BDHPBANKW),
            .BDHPBANKA      (BDHPBANKA)
        ) mvunit
        (
            .clk            (intf.clk                               ),
            .mul_mode       (mul_mode_q[i]                          ),
            .neg_acc        (neg_acc_dly[i]                         ),
            .shacc_clr      (shacc_clr_int[i]                       ),
            .shacc_load     (shacc_load[i]                          ),
            .shacc_acc      (shacc_acc[i]                           ),
            .shacc_sh       (shacc_sh[i]                            ),
            .scaler1_clr    (scaler1_clr[i]                         ),
            .scaler1_b      (scaler1_b_q[i]                         ),
            .usescaler_mem  (usescaler_mem_q[i]                     ),
            .usebias_mem    (usebias_mem_q[i]                       ),
            .usehpadder     (usehpadder_q[i]                        ),
            .usepooler4hpout(usepooler4hpout_q[i]                   ),
            .hpadder_clr    (hpadder_clr[i]                         ),
            .max_en         (intf.max_en[i]                         ),
            .max_clr        (intf.max_clr[i]                        ),
            .max_pool       (intf.max_pool[i]                       ),
            .scaler2_clr    (scaler2_clr[i]                         ),
            .scaler2_b      (scaler2_b_q[i]                         ),
            .quant_clr      (quant_clr_int[i]                       ),
            .quant_msbidx   (quant_msbidx_q[i]                      ),
            .quant_load     (quant_load[i]                          ),
            .quant_step     (quant_step[i]                          ),
            .rdw_addr       (rdw_addr[i*BWBANKA +: BWBANKA]         ),
            .wrw_addr       (intf.wrw_addr[i*BWBANKA +: BWBANKA]    ),
            .wrw_word       (intf.wrw_word[i*BWBANKW +: BWBANKW]    ),
            .wrw_en         (intf.wrw_en[i]                         ),
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
            .rdc_en         (intf.rdc_en[i]                         ),
            .rdc_grnt       (intf.rdc_grnt[i]                       ),
            .rdc_addr       (intf.rdc_addr[i*BDBANKA +: BDBANKA]    ),
            .rdc_word       (intf.rdc_word[i*BDBANKW +: BDBANKW]    ),
            .wrc_en         (intf.wrc_en[i]                         ),
            .wrc_grnt       (intf.wrc_grnt[i]                       ),
            .wrc_addr       (intf.wrc_addr[BDBANKA-1: 0]            ),
            .wrc_word       (intf.wrc_word[BDBANKW-1 : 0]           ),
            .mvu_word_out   (mvu_word_out[i*BDBANKW +: BDBANKW]     ),
            .rddhp_addr     (rddhp_addr[i]                          ),
            .wrihp_en       (wrihp_en[i]                            ),
            .wrihp_addr     (wrihp_addr[i]                          ),
            .wrihp_word     (wrihp_word[i]                          ),
            .mvu_word_outhp (mvu_word_outhp[i]                      ),
            .rds_en         (rds_en[i]                              ),
            .rds_addr       (rds_addr[i*BSBANKA +: BSBANKA]         ),
            .wrs_en         (intf.wrs_en[i]                         ),
            .wrs_addr       (intf.wrs_addr                          ),
            .wrs_word       (intf.wrs_word                          ),
            .rdb_en         (rdb_en[i]                              ),
            .rdb_addr       (rdb_addr[i*BBBANKA +: BBBANKA]         ),
            .wrb_en         (intf.wrb_en[i]                         ),
            .wrb_addr       (intf.wrb_addr                          ),
            .wrb_word       (intf.wrb_word                          )
        );
end endgenerate


/* Module end */
endmodule