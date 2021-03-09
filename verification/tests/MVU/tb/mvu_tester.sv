`timescale 1 ns / 1 ps

import utils::*;

`define CLKPERIOD 10ns
`define SIM_TIMEOUT 1 //ms

module mvu_tester;

    /* Parameters */
    parameter  NMVU    =  1;   /* Number of MVUs. Ideally a Power-of-2. */
    parameter  N       = 64;   /* N x N matrix-vector product size. Power-of-2. */
    parameter  NDBANK  = 32;   /* Number of 2N-bit, 512-element Data BANK. */

    localparam BWBANKA = 9;             /* Bitwidth of Weights BANK Address */
    localparam BWBANKW = N*N;           /* Bitwidth of Weights BANK Word */
    localparam BDBANKA = 14;            /* Bitwidth of Data    BANK Address */
    localparam BDBANKW = N;           /* Bitwidth of Data    BANK Word */

    localparam BACC    = 27;            /* Bitwidth of Accumulators */
    localparam BSCALERB = 16;           /* Bitwidth of multiplier operands to scalers */

    // Quantizer parameters
    localparam QMSBLOCBD  = $clog2(BACC);   // Bitwidth of the quantizer MSB location specifier
    localparam QBDOUTBD   = $clog2(BACC);   // Bitwidth of the quantizer bit-depth out specifier


    reg                      clk;

    reg[      2*NMVU-1 : 0] mul_mode;
    reg[        NMVU-1 : 0] neg_acc;
    reg[        NMVU-1 : 0] shacc_clr;
    reg[        NMVU-1 : 0] shacc_load;
    reg[        NMVU-1 : 0] shacc_acc;
    reg[        NMVU-1 : 0] shacc_sh;
    reg[NMVU*BSCALERB-1 : 0 ] scaler_b;
    reg[        NMVU-1 : 0] max_en;
    reg[        NMVU-1 : 0] max_clr;
    reg[        NMVU-1 : 0] max_pool;

    reg[          NMVU-1 : 0]    quant_clr;
    reg[NMVU*QMSBLOCBD-1 : 0]    quant_msbidx;
    reg[          NMVU-1  : 0]    quant_step;
    reg[          NMVU-1 : 0]    quant_load;

    reg[NMVU*BWBANKA-1 : 0] rdw_addr;
    reg[NMVU*BWBANKA-1 : 0] wrw_addr;
	reg[NMVU*BWBANKW-1 : 0] wrw_word;
	reg[        NMVU-1 : 0]	wrw_en;

    reg[        NMVU-1 : 0] rdd_en;
    wire[        NMVU-1 : 0] rdd_grnt;
    reg[NMVU*BDBANKA-1 : 0] rdd_addr;
    reg[        NMVU-1 : 0] wrd_en;
    wire[        NMVU-1 : 0] wrd_grnt;
    reg[NMVU*BDBANKA-1 : 0] wrd_addr;

    reg[        NMVU-1 : 0] rdi_en;
    wire[        NMVU-1 : 0] rdi_grnt;
    reg[NMVU*BDBANKA-1 : 0] rdi_addr;
    wire[NMVU*BDBANKW-1 : 0] rdi_word;
    reg[        NMVU-1 : 0] wri_en;
    wire[        NMVU-1 : 0] wri_grnt;
    reg[NMVU*BDBANKA-1 : 0] wri_addr;
    reg[NMVU*BDBANKW-1 : 0] wri_word;

    reg[        NMVU-1 : 0] rdc_en;
    wire[        NMVU-1 : 0] rdc_grnt;
    reg[NMVU*BDBANKA-1 : 0] rdc_addr;
    wire[NMVU*BDBANKW-1 : 0] rdc_word;
    reg[        NMVU-1 : 0] wrc_en;
    wire[        NMVU-1 : 0] wrc_grnt;
    reg[     BDBANKA-1 : 0] wrc_addr;
    reg[     BDBANKW-1 : 0] wrc_word;

    /* Local Wires */
    wire[        NMVU-1 : 0] ic_send_en;
    wire[NMVU*BDBANKW-1 : 0] ic_send_word;
    wire[        NMVU-1 : 0] ic_recv_en;
    wire[NMVU*BDBANKW-1 : 0] ic_recv_word;


    mvu #(N, NDBANK) dut (  clk,
                            mul_mode[0*2 +: 2],
                            neg_acc[0],
                            shacc_clr[0],
                            shacc_load[0],
                            shacc_acc[0],
                            shacc_sh[0],
                            scaler_b[0],
                            max_en[0],
                            max_clr[0],
                            max_pool[0],
                            quant_clr[0],
                            quant_msbidx[0*QMSBLOCBD +: QMSBLOCBD],
                            quant_step[0],
                            quant_load[0],
                            rdw_addr[0*BWBANKA +: BWBANKA],
                   			wrw_addr[0*BWBANKA +: BWBANKA],
			                wrw_word[0*BWBANKW +: BWBANKW],
			                wrw_en[0],
                            rdd_en[0],
                            rdd_grnt[0],
                            rdd_addr[0*BDBANKA +: BDBANKA],
                            wrd_en[0],
                            wrd_grnt[0],
                            wrd_addr[0*BDBANKA +: BDBANKA],
                            rdi_en[0],
                            rdi_grnt[0],
                            rdi_addr[0*BDBANKA +: BDBANKA],
                            rdi_word[0*BDBANKW +: BDBANKW],
                            wri_en[0],
                            wri_grnt[0],
                            wri_addr[0*BDBANKA +: BDBANKA],
                            wri_word[0*BDBANKW +: BDBANKW],
                            rdc_en[0],
                            rdc_grnt[0],
                            rdc_addr[0*BDBANKA +: BDBANKA],
                            rdc_word[0*BDBANKW +: BDBANKW],
                            wrc_en[0],
                            wrc_grnt[0],
                            wrc_addr,
                            wrc_word);
    


// ================================================================= 
// Helper functions/tasks

/*
task writeToWeightRAM(byte data);
    for (int i=0; i < data.size(); i++) begin
        dut.
    end
endtask
*/

//=============================================================================
// Simulation specific Threads
    
    // Clock
    initial begin 
        clk = 0;
        #(`CLKPERIOD/2);
        forever begin
          #(`CLKPERIOD/2) clk = !clk;
        end
    end

    // MAIN 
    initial begin
        print_banner("Starting Simulation");

        // Initilize input signals
        // Hold in reset for first few clock cycles
        assign mul_mode = 2'b01;                     // basic binary mode {0, +1]
        assign shacc_clr = 1'b1;
        assign shacc_load = 1'b0;
        assign shacc_acc = 1'b0;
        assign shacc_sh = 1'b0;
        assign scaler_b = 0;
        assign max_en = 1'b1;
        assign max_clr = 1'b1;
        assign max_pool = 1'b0;
        assign rdw_addr = {BWBANKA{1'b0}};
        assign rdd_en = 1'b1;
        assign rdd_addr = {BDBANKA{1'b0}};
        assign wrd_en = 1'b0;
        assign wrd_addr = {BDBANKA{1'b0}};
        assign rdi_en = 1'b0;
        assign rdi_addr = {BDBANKA{1'b0}};
        assign wri_en = 1'b0;
        assign wri_addr = {BDBANKA{1'b0}};
        assign wri_word = {BDBANKW{1'b0}};
        assign rdc_en = 1'b0;
        assign rdc_addr = {BDBANKA{1'b0}};
        assign wrc_en = 1'b0;
        assign wrc_addr = {BDBANKA{1'b0}};
        assign wrc_word = {BDBANKW{1'b0}};
        #(`CLKPERIOD*10);


        #(`SIM_TIMEOUT*1ms);
        // print_banner($sformatf("Simulation took more than expected ( more than %0dms)", `SIM_TIMEOUT), ID="ERROR");

        $finish();
    end

endmodule
