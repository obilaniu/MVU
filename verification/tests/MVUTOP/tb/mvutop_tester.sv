/**** Test Module test_vvp ****/
`define SIM_TIMEOUT 1
import utils::*;

module mvutop_tester();
    /* Create input registers and output wires */
    parameter  NMVU    =  1;   /* Number of MVUs. Ideally a Power-of-2. */
    parameter  N       = 64;   /* N x N matrix-vector product size. Power-of-2. */
    parameter  NDBANK  = 32;   /* Number of 2N-bit, 512-element Data BANK. */
    localparam BMVUA   = $clog2(NMVU);  /* Bitwidth of MVU          Address */
    localparam BWBANKA = 9;             /* Bitwidth of Weights BANK Address */
    localparam BDBANKA = 14;            /* Bitwidth of Data    BANK Address */
    localparam BDBANKW = 2*N;           /* Bitwidth of Data    BANK Word */

    logic                      clk         ;//input  clk;
    logic                      ic_clr      ;//input  ic_clr;
    logic [  NMVU*BMVUA-1 : 0] ic_recv_from;//input  ic_recv_from;
    logic [      2*NMVU-1 : 0] mul_mode    ;//input  mul_mode;
    logic [        NMVU-1 : 0] acc_clr     ;//input  acc_clr;
    logic [        NMVU-1 : 0] acc_sh      ;//input  acc_sh;
    logic [        NMVU-1 : 0] max_en      ;//input  max_en;
    logic [        NMVU-1 : 0] max_clr     ;//input  max_clr;
    logic [        NMVU-1 : 0] max_pool    ;//input  max_pool;
    logic [NMVU*BWBANKA-1 : 0] rdw_addr    ;//input  rdw_addr;
    logic [        NMVU-1 : 0] rdd_en      ;//input  rdd_en;
    logic [        NMVU-1 : 0] rdd_grnt    ;//output rdd_grnt;
    logic [NMVU*BDBANKA-1 : 0] rdd_addr    ;//input  rdd_addr;
    logic [        NMVU-1 : 0] wrd_en      ;//input  wrd_en;
    logic [        NMVU-1 : 0] wrd_grnt    ;//output wrd_grnt;
    logic [NMVU*BDBANKA-1 : 0] wrd_addr    ;//input  wrd_addr;
    logic [        NMVU-1 : 0] rdi_en      ;//input  rdi_en;
    logic [        NMVU-1 : 0] rdi_grnt    ;//output rdi_grnt;
    logic [NMVU*BDBANKA-1 : 0] rdi_addr    ;//input  rdi_addr;
    logic [        NMVU-1 : 0] wri_grnt    ;//output wri_grnt;
    logic [NMVU*BDBANKA-1 : 0] wri_addr    ;//input  wri_addr;
    logic [        NMVU-1 : 0] rdc_en      ;//input  rdc_en;
    logic [        NMVU-1 : 0] rdc_grnt    ;//output rdc_grnt;
    logic [NMVU*BDBANKA-1 : 0] rdc_addr    ;//input  rdc_addr;
    logic [NMVU*BDBANKW-1 : 0] rdc_word    ;//output rdc_word;
    logic [        NMVU-1 : 0] wrc_en      ;//input  wrc_en;
    logic [        NMVU-1 : 0] wrc_grnt    ;//output wrc_grnt;
    logic [     BDBANKA-1 : 0] wrc_addr    ;//input  wrc_addr;
    logic [     BDBANKW-1 : 0] wrc_word    ;//input  wrc_word;


    mvutop #(
            .NMVU  (NMVU  ),
            .N     (N     ),
            .NDBANK(NDBANK)
        ) pe_core
        (
            .clk          (clk          ),
            .ic_clr       (ic_clr       ),
            .ic_recv_from (ic_recv_from ),
            .mul_mode     (mul_mode     ),
            .acc_clr      (acc_clr      ),
            .acc_sh       (acc_sh       ),
            .max_en       (max_en       ),
            .max_clr      (max_clr      ),
            .max_pool     (max_pool     ),
            .rdw_addr     (rdw_addr     ),
            .rdd_en       (rdd_en       ),
            .rdd_grnt     (rdd_grnt     ),
            .rdd_addr     (rdd_addr     ),
            .wrd_en       (wrd_en       ),
            .wrd_grnt     (wrd_grnt     ),
            .wrd_addr     (wrd_addr     ),
            .rdi_en       (rdi_en       ),
            .rdi_grnt     (rdi_grnt     ),
            .rdi_addr     (rdi_addr     ),
            .wri_grnt     (wri_grnt     ),
            .wri_addr     (wri_addr     ),
            .rdc_en       (rdc_en       ),
            .rdc_grnt     (rdc_grnt     ),
            .rdc_addr     (rdc_addr     ),
            .rdc_word     (rdc_word     ),
            .wrc_en       (wrc_en       ),
            .wrc_grnt     (wrc_grnt     ),
            .wrc_addr     (wrc_addr     ),
            .wrc_word     (wrc_word     )
        );
/* Run test */
    initial begin

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
        #(`SIM_TIMEOUT*1ms);
        print_banner($sformatf("Simulation took more than expected ( more than %0dms)", `SIM_TIMEOUT), "ERROR");
        $finish();
    end

endmodule

