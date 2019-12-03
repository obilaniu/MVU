import utils::*;

`define SIM_TIMEOUT 1 //ms

module mvu_tester;

    /* Parameters */
    parameter  NMVU    =  1;   /* Number of MVUs. Ideally a Power-of-2. */
    parameter  N       = 64;   /* N x N matrix-vector product size. Power-of-2. */
    parameter  NDBANK  = 32;   /* Number of 2N-bit, 512-element Data BANK. */

    localparam BWBANKA = 9;             /* Bitwidth of Weights BANK Address */
    localparam BDBANKA = 14;            /* Bitwidth of Data    BANK Address */
    localparam BDBANKW = 2*N;           /* Bitwidth of Data    BANK Word */

    reg                      clk;

    reg[      2*NMVU-1 : 0] mul_mode;
    reg[        NMVU-1 : 0] acc_clr;
    reg[        NMVU-1 : 0] acc_sh;
    reg[        NMVU-1 : 0] max_en;
    reg[        NMVU-1 : 0] max_clr;
    reg[        NMVU-1 : 0] max_pool;

    reg[NMVU*BWBANKA-1 : 0] rdw_addr;

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


    mvu #(N, NDBANK) mvunit (clk,
                             mul_mode[0*2 +: 2],
                             acc_clr[0],
                             acc_sh[0],
                             max_en[0],
                             max_clr[0],
                             max_pool[0],
                             rdw_addr[0*BWBANKA +: BWBANKA],
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
    initial begin
        print_banner("Starting Simulation");
        // #100us;
    end

//==================================================================================================
// Simulation specific Threads
    initial begin 
        clk = 0;
        #50ns;
        forever begin
          #50ns clk = !clk;
        end
    end

    initial begin
 
        // Initilize input signals
        // Hold in reset for first few clock cycles
        assign mul_mode = 2'b1;                     // basic binary mode {0, +1]
        assign acc_clr = 1'b1;
        assign acc_sh = 1'b0;
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
        #1000ns;


        #(`SIM_TIMEOUT*1ms);
        // print_banner($sformatf("Simulation took more than expected ( more than %0dms)", `SIM_TIMEOUT), ID="ERROR");

        $finish();
    end

endmodule
