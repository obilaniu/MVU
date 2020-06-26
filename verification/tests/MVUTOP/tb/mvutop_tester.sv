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
	localparam BWBANKW = 4096;			// Bitwidth of Weights BANK Word
    localparam BDBANKA = 14;            /* Bitwidth of Data    BANK Address */
    localparam BDBANKW = 2*N;           /* Bitwidth of Data    BANK Word */
	
	// Other Parameters
    localparam BCNTDWN	= 29;			// Bitwidth of the countdown ports
    localparam BPREC 	= 6;			// Bitwidth of the precision ports
    localparam BBWADDR	= 9;			// Bitwidth of the weight base address ports
    localparam BBDADDR	= 15;			// Bitwidth of the data base address ports
    localparam BSTRIDE	= 15;			// Bitwidth of the stride ports
    localparam BLENGTH	= 15;			// Bitwidth of the length ports

    localparam BACC    = 32;            /* Bitwidth of Accumulators */

	// Quantizer parameters
    localparam BQMSBIDX = $clog2(BACC);     // Bitwidth of the quantizer MSB location specifier
    localparam BQBOUT   = $clog2(BACC);     // Bitwitdh of the quantizer 

    // I/O port wires
    logic                      clk         ;//input  clk;
    logic                      ic_clr      ;//input  ic_clr;
    logic [  NMVU*BMVUA-1 : 0] ic_recv_from;//input  ic_recv_from;
    logic [      2*NMVU-1 : 0] mul_mode    ;//input  mul_mode;
    logic [        NMVU-1 : 0] acc_clr     ;//input  acc_clr;
    logic [        NMVU-1 : 0] acc_sh      ;//input  acc_sh;
    logic [        NMVU-1 : 0] max_en      ;//input  max_en;
    logic [        NMVU-1 : 0] max_clr     ;//input  max_clr;
    logic [        NMVU-1 : 0] max_pool    ;//input  max_pool;
    logic [        NMVU-1 : 0] rdc_en      ;//input  rdc_en;
    logic [        NMVU-1 : 0] rdc_grnt    ;//output rdc_grnt;
    logic [NMVU*BDBANKA-1 : 0] rdc_addr    ;//input  rdc_addr;
    logic [NMVU*BDBANKW-1 : 0] rdc_word    ;//output rdc_word;
    logic [        NMVU-1 : 0] wrc_en      ;//input  wrc_en;
    logic [        NMVU-1 : 0] wrc_grnt    ;//output wrc_grnt;
    logic [     BDBANKA-1 : 0] wrc_addr    ;//input  wrc_addr;
    logic [     BDBANKW-1 : 0] wrc_word    ;//input  wrc_word;

    logic[  NMVU*BCNTDWN-1 : 0] countdown;			// Config: number of clocks to countdown for given task
    logic[    NMVU*BPREC-1 : 0] wprecision;			// Config: weight precision
    logic[    NMVU*BPREC-1 : 0] iprecision;			// Config: input precision
    logic[    NMVU*BPREC-1 : 0] oprecision;			// Config: output precision
    logic[  NMVU*BBWADDR-1 : 0] wbaseaddr;			// Config: weight memory base address
    logic[  NMVU*BBDADDR-1 : 0] ibaseaddr;			// Config: data memory base address for input
    logic[  NMVU*BBDADDR-1 : 0] obaseaddr;			// Config: data memory base address for output
    logic[  NMVU*BSTRIDE-1 : 0] wstride_0;			// Config: weight stride in dimension 0 (x)
    logic[  NMVU*BSTRIDE-1 : 0] wstride_1;			// Config: weight stride in dimension 1 (y)
    logic[  NMVU*BSTRIDE-1 : 0] wstride_2;			// Config: weight stride in dimension 2 (z)
    logic[  NMVU*BSTRIDE-1 : 0] istride_0;			// Config: input stride in dimension 0 (x)
    logic[  NMVU*BSTRIDE-1 : 0] istride_1;			// Config: input stride in dimension 1 (y)
    logic[  NMVU*BSTRIDE-1 : 0] istride_2;			// Config: input stride in dimension 2 (z)
    logic[  NMVU*BSTRIDE-1 : 0] ostride_0;			// Config: output stride in dimension 0 (x)
    logic[  NMVU*BSTRIDE-1 : 0] ostride_1;			// Config: output stride in dimension 1 (y)
    logic[  NMVU*BSTRIDE-1 : 0] ostride_2;			// Config: output stride in dimension 2 (z)
    logic[  NMVU*BLENGTH-1 : 0] wlength_0;			// Config: weight length in dimension 0 (x)
    logic[  NMVU*BLENGTH-1 : 0] wlength_1;			// Config: weight length in dimension 1 (y)
    logic[  NMVU*BLENGTH-1 : 0] wlength_2;			// Config: weight length in dimension 2 (z)
    logic[  NMVU*BLENGTH-1 : 0] ilength_0;			// Config: input length in dimension 0 (x)
    logic[  NMVU*BLENGTH-1 : 0] ilength_1;			// Config: input length in dimension 1 (y)
    logic[  NMVU*BLENGTH-1 : 0] ilength_2;			// Config: input length in dimension 2 (z)
    logic[  NMVU*BLENGTH-1 : 0] olength_0;			// Config: output length in dimension 0 (x)
    logic[  NMVU*BLENGTH-1 : 0] olength_1;			// Config: output length in dimension 1 (y)
    logic[  NMVU*BLENGTH-1 : 0] olength_2;			// Config: output length in dimension 2 (z)

    logic[  NMVU*BWBANKA-1 : 0] wrw_addr;				// Weight memory: write address
    logic[  NMVU*BWBANKW-1 : 0] wrw_word;				// Weight memory: write word
    logic[          NMVU-1 : 0] wrw_en;				// Weight memory: write enable

	




    mvutop #(
            .NMVU  (NMVU  ),
            .N     (N     ),
            .NDBANK(NDBANK)
        ) pe_core
        (
            .clk              (clk          ),
            .ic_clr           (ic_clr       ),
            .ic_recv_from     (ic_recv_from ),
            .mul_mode         (mul_mode     ),
            .acc_clr          (acc_clr      ),
            .acc_sh           (acc_sh       ),
            .max_en           (max_en       ),
            .max_clr          (max_clr      ),
            .max_pool         (max_pool     ),
            .quant_clr        (quant_clr	),
    		.quant_msbidx     (quant_msbidx ),
            .quant_start      (quant_start	),
            .quantarray_out   (quantarray_out),
            .countdown        (countdown),
            .wprecision       (wprecision),
            .iprecision       (iprecision),
            .oprecision       (oprecision),
            .wbaseaddr        (wbaseaddr),
            .ibaseaddr        (ibaseaddr),
            .obaseaddr        (obaseaddr),
            .wstride_0        (wstride_0),
            .wstride_1        (wstride_1),
            .wstride_2        (wstride_2),
            .istride_0        (istride_0),
            .istride_1        (istride_1),
            .istride_2        (istride_2),
            .ostride_0        (ostride_0),
            .ostride_1        (ostride_1),
            .ostride_2        (ostride_2),
            .wlength_0        (wlength_0),
            .wlength_1        (wlength_1),
            .wlength_2        (wlength_2),
            .ilength_0        (ilength_0),
            .ilength_1        (ilength_1),
            .ilength_2        (ilength_2),
            .olength_0        (olength_0),
            .olength_1        (olength_1),
            .olength_2        (olength_2),
			.wrw_addr         (wrw_addr),
			.wrw_word         (wrw_word),
			.wrw_en           (wrw_en),
            .rdc_en           (rdc_en),
            .rdc_grnt         (rdc_grnt),
            .rdc_addr         (rdc_addr),
            .rdc_word         (rdc_word),
            .wrc_en           (wrc_en),
            .wrc_grnt         (wrc_grnt),
            .wrc_addr         (wrc_addr),
            .wrc_word         (wrc_word)
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

