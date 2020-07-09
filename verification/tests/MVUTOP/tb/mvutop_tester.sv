//
// Test Module mvutop_tester
//
// Notes:
// * For wlength_X and ilength_X parameters, the value to assign is actual_length - 1.
//


import utils::*;

// Clock parameters
`define SIM_TIMEOUT 1
`define CLKPERIOD 10ns

`timescale 1 ps / 1 ps


module mvutop_tester();
    /* Create input registers and output wires */
    parameter  NMVU    =  1;   /* Number of MVUs. Ideally a Power-of-2. */
    parameter  N       = 64;   /* N x N matrix-vector product size. Power-of-2. */
    parameter  NDBANK  = 32;   /* Number of 2N-bit, 512-element Data BANK. */
    localparam BMVUA   = $clog2(NMVU);  /* Bitwidth of MVU          Address */
    localparam BWBANKA = 9;             /* Bitwidth of Weights BANK Address */
	localparam BWBANKW = 4096;			// Bitwidth of Weights BANK Word
    localparam BDBANKA = 15;            /* Bitwidth of Data    BANK Address */
    localparam BDBANKW = N;             /* Bitwidth of Data    BANK Word */
	
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
    logic                      rst_n       ;//input  reset;
    logic [        NMVU-1 : 0] start       ;//input  start;
    logic [        NMVU-1 : 0] done        ;//output done;
    logic [        NMVU-1 : 0] irq         ;//output irq
    logic                      ic_clr      ;//input  ic_clr;
    logic [  NMVU*BMVUA-1 : 0] ic_recv_from;//input  ic_recv_from;
    logic [      2*NMVU-1 : 0] mul_mode    ;//input  mul_mode;
    logic [        NMVU-1 : 0] acc_clr     ;//input  acc_clr;
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

	logic [         NMVU-1 : 0] quant_clr;			// Quantizer: clear
    logic [NMVU*BQMSBIDX-1 : 0] quant_msbidx;		// Quantizer: bit position index of the MSB
    logic [         NMVU-1 : 0] quant_start;		// Quantizer: signal to start quantizing

    logic[  NMVU*BCNTDWN-1 : 0] countdown;			// Config: number of clocks to countdown for given task
    logic[    NMVU*BPREC-1 : 0] wprecision;			// Config: weight precision
    logic[    NMVU*BPREC-1 : 0] iprecision;			// Config: input precision
    logic[    NMVU*BPREC-1 : 0] oprecision;			// Config: output precision
    logic[  NMVU*BBWADDR-1 : 0] wbaseaddr;			// Config: weight memory base address
    logic[  NMVU*BBDADDR-1 : 0] ibaseaddr;			// Config: data memory base address for input
    logic[  NMVU*BBDADDR-1 : 0] obaseaddr;			// Config: data memory base address for output


    logic[  NMVU*BWBANKA-1 : 0] wrw_addr;			// Weight memory: write address
    logic[  NMVU*BWBANKW-1 : 0] wrw_word;			// Weight memory: write word
    logic[          NMVU-1 : 0] wrw_en;				// Weight memory: write enable
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

	




    mvutop #(
            .NMVU  (NMVU  ),
            .N     (N     ),
            .NDBANK(NDBANK)
        ) dut
        (
            .clk              (clk          ),
            .rst_n            (rst_n        ),
            .start            (start        ),
            .done             (done         ),
            .irq              (irq          ),
            .ic_clr           (ic_clr       ),
            .ic_recv_from     (ic_recv_from ),
            .mul_mode         (mul_mode     ),
            .acc_clr          (acc_clr      ),
            .max_en           (max_en       ),
            .max_clr          (max_clr      ),
            .max_pool         (max_pool     ),
            .quant_clr        (quant_clr	),
    		.quant_msbidx     (quant_msbidx ),
            .quant_start      (quant_start	),
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


//==================================================================================================
// Simulation specific Threads

// Clock generator
initial begin 
    clk = 0;
    #(`CLKPERIOD/2);
    forever begin
         #(`CLKPERIOD/2);
         clk = !clk;
    end
end

// Simulation timeout
initial begin
    #(`SIM_TIMEOUT*1ms);
    print_banner($sformatf("Simulation took more than expected ( more than %0dms)", `SIM_TIMEOUT), "ERROR");
    $finish();
end


// =================================================================================================
// Main test thread

initial begin

    // Initialize signals
    assign rst_n = 0;
    assign start = 0;
    assign ic_clr = 0;      
    assign ic_recv_from = 0;
    assign mul_mode = 0;
    assign acc_clr = 0;
    assign max_en = 0;
    assign max_clr = 0;
    assign max_pool = 0;
    assign rdc_en = 0;
    assign rdc_addr = 0;
    assign wrc_en = 0;
    assign wrc_addr = 0;
    assign wrc_word = 0;
	assign quant_clr = 0;
    assign quant_msbidx = 0;
    assign quant_start = 0;
    assign countdown = 0;
    assign wprecision = 0;
    assign iprecision = 0;
    assign oprecision = 0;
    assign wbaseaddr = 0;
    assign ibaseaddr = 0;
    assign obaseaddr = 0;
    assign wstride_0 = 0;
    assign wstride_1 = 0;
    assign wstride_2 = 0;
    assign istride_0 = 0;
    assign istride_1 = 0;
    assign istride_2 = 0;
    assign ostride_0 = 0;
    assign ostride_1 = 0;
    assign ostride_2 = 0;
    assign wlength_0 = 0;
    assign wlength_1 = 0;
    assign wlength_2 = 0;
    assign ilength_0 = 0;
    assign ilength_1 = 0;
    assign ilength_2 = 0;
    assign olength_0 = 0;
    assign olength_1 = 0;
    assign olength_2 = 0;
    assign wrw_addr = 0;
    assign wrw_word = 0;
    assign wrw_en = 0;
    #(`CLKPERIOD*10);

    // Come out of reset
    assign rst_n = 1;
    #(`CLKPERIOD*10);

    print("TEST 1: matrix-vector mult: 1x1 x 1 tiles, 1x1 => 1 bit precision");
    assign wprecision = 1;
    assign iprecision = 1;
    assign oprecision = 1;
    assign wstride_0 = 0;
    assign wstride_1 = 0;
    assign wstride_2 = 0;
    assign istride_0 = 0;
    assign istride_1 = 0;
    assign istride_2 = 0;
    assign ostride_0 = 0;
    assign ostride_1 = 0;
    assign ostride_2 = 0;
    assign wlength_0 = 0;
    assign wlength_1 = 0;
    assign wlength_2 = 0;
    assign ilength_0 = 0;
    assign ilength_1 = 0;
    assign ilength_2 = 0;
    assign olength_0 = 0;
    assign olength_1 = 0;
    assign olength_2 = 0;
    assign countdown = 1;
    assign start = 1;
    #(`CLKPERIOD);
    assign start = 0;
    #(`CLKPERIOD*10);

    print("TEST 2: matrix-vector mult: 2x2 x 2 tiles, 1x1 => 1 bit precision");
    assign wprecision = 1;
    assign iprecision = 1;
    assign oprecision = 1;
    assign wstride_0 = 0;
    assign wstride_1 = 0;
    assign wstride_2 = 0;
    assign istride_0 = -1;
    assign istride_1 = 0;
    assign istride_2 = 0;
    assign ostride_0 = 0;
    assign ostride_1 = 0;
    assign ostride_2 = 0;
    assign wlength_0 = 3;
    assign wlength_1 = 0;
    assign wlength_2 = 0;
    assign ilength_0 = 1;
    assign ilength_1 = 1;
    assign ilength_2 = 0;
    assign olength_0 = 1;
    assign olength_1 = 0;
    assign olength_2 = 0;
    assign countdown = 4;
    assign start = 1;
    #(`CLKPERIOD);
    assign start = 0;
    #(`CLKPERIOD*10);

    print("TEST 3: matrix-vector mult: 2x2 x 2 tiles, 2x2 => 2 bit precision");
    assign wprecision = 2;
    assign iprecision = 2;
    assign oprecision = 2;
    assign wstride_0 = -2;      // 1 tile back move x 2 bits
    assign wstride_1 = 2;       // 1 tile ahead move x 2 bits
    assign wstride_2 = 0;
    assign istride_0 = -2;      // 1 tile back move x 2 bits 
    assign istride_1 = 0;
    assign istride_2 = -2;
    assign ostride_0 = 0;
    assign ostride_1 = 0;
    assign ostride_2 = 0;
    assign wlength_0 = 1;       // 2 tiles in width
    assign wlength_1 = 3;       // number bit combinations i.e. 2x2 bits
    assign wlength_2 = 1;       // 2 tiles in height
    assign ilength_0 = 1;       // 2 tiles in height
    assign ilength_1 = 0;       // number bit combinations
    assign ilength_2 = 0;       // 2 tiles in width of matrix operand
    assign olength_0 = 1;
    assign olength_1 = 0;
    assign olength_2 = 0;
    assign countdown = 16;       // 2 tiles x 2 tiles x 2bit x 2bits
    assign start = 1;
    #(`CLKPERIOD);
    assign start = 0;
    #(`CLKPERIOD*20);

    print_banner($sformatf("Simulation done."));
    $finish();
end

endmodule

