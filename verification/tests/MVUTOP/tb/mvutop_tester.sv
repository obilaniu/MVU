//
// Test Module mvutop_tester
//
// Notes:
// * For wlength_X and ilength_X parameters, the value to is actual_length - 1.
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
    reg                      clk         ;//input  clk;
    reg                      rst_n       ;//input  reset;
    reg [        NMVU-1 : 0] start       ;//input  start;
    reg [        NMVU-1 : 0] done        ;//output done;
    reg [        NMVU-1 : 0] irq         ;//output irq
    reg                      ic_clr      ;//input  ic_clr;
    reg [  NMVU*BMVUA-1 : 0] ic_recv_from;//input  ic_recv_from;
    reg [      2*NMVU-1 : 0] mul_mode    ;//input  mul_mode;
    reg [        NMVU-1 : 0] d_signed    ;//input  d_signed
    reg [        NMVU-1 : 0] w_signed    ;//input  w_signed
    reg [        NMVU-1 : 0] shacc_clr   ;//input  shacc_clr;
    reg [        NMVU-1 : 0] max_en      ;//input  max_en;
    reg [        NMVU-1 : 0] max_clr     ;//input  max_clr;
    reg [        NMVU-1 : 0] max_pool    ;//input  max_pool;
    reg [        NMVU-1 : 0] rdc_en      ;//input  rdc_en;
    reg [        NMVU-1 : 0] rdc_grnt    ;//output rdc_grnt;
    reg [NMVU*BDBANKA-1 : 0] rdc_addr    ;//input  rdc_addr;
    reg [NMVU*BDBANKW-1 : 0] rdc_word    ;//output rdc_word;
    reg [        NMVU-1 : 0] wrc_en      ;//input  wrc_en;
    reg [        NMVU-1 : 0] wrc_grnt    ;//output wrc_grnt;
    reg [     BDBANKA-1 : 0] wrc_addr    ;//input  wrc_addr;
    reg [     BDBANKW-1 : 0] wrc_word    ;//input  wrc_word;

	reg [         NMVU-1 : 0] quant_clr;        // Quantizer: clear
    reg [NMVU*BQMSBIDX-1 : 0] quant_msbidx;     // Quantizer: bit position index of the MSB

    reg[  NMVU*BCNTDWN-1 : 0] countdown;        // Config: number of clocks to countdown for given task
    reg[    NMVU*BPREC-1 : 0] wprecision;       // Config: weight precision
    reg[    NMVU*BPREC-1 : 0] iprecision;       // Config: input precision
    reg[    NMVU*BPREC-1 : 0] oprecision;       // Config: output precision
    reg[  NMVU*BBWADDR-1 : 0] wbaseaddr;        // Config: weight memory base address
    reg[  NMVU*BBDADDR-1 : 0] ibaseaddr;        // Config: data memory base address for input
    reg[  NMVU*BBDADDR-1 : 0] obaseaddr;        // Config: data memory base address for output


    reg[  NMVU*BWBANKA-1 : 0] wrw_addr;         // Weight memory: write address
    reg[  NMVU*BWBANKW-1 : 0] wrw_word;	        // Weight memory: write word
    reg[          NMVU-1 : 0] wrw_en;           // Weight memory: write enable
    reg[  NMVU*BSTRIDE-1 : 0] wstride_0;        // Config: weight stride in dimension 0 (x)
    reg[  NMVU*BSTRIDE-1 : 0] wstride_1;        // Config: weight stride in dimension 1 (y)
    reg[  NMVU*BSTRIDE-1 : 0] wstride_2;        // Config: weight stride in dimension 2 (z)
    reg[  NMVU*BSTRIDE-1 : 0] istride_0;        // Config: input stride in dimension 0 (x)
    reg[  NMVU*BSTRIDE-1 : 0] istride_1;        // Config: input stride in dimension 1 (y)
    reg[  NMVU*BSTRIDE-1 : 0] istride_2;        // Config: input stride in dimension 2 (z)
    reg[  NMVU*BSTRIDE-1 : 0] ostride_0;        // Config: output stride in dimension 0 (x)
    reg[  NMVU*BSTRIDE-1 : 0] ostride_1;        // Config: output stride in dimension 1 (y)
    reg[  NMVU*BSTRIDE-1 : 0] ostride_2;        // Config: output stride in dimension 2 (z)
    reg[  NMVU*BLENGTH-1 : 0] wlength_0;        // Config: weight length in dimension 0 (x)
    reg[  NMVU*BLENGTH-1 : 0] wlength_1;        // Config: weight length in dimension 1 (y)
    reg[  NMVU*BLENGTH-1 : 0] wlength_2;        // Config: weight length in dimension 2 (z)
    reg[  NMVU*BLENGTH-1 : 0] ilength_0;        // Config: input length in dimension 0 (x)
    reg[  NMVU*BLENGTH-1 : 0] ilength_1;        // Config: input length in dimension 1 (y)
    reg[  NMVU*BLENGTH-1 : 0] ilength_2;        // Config: input length in dimension 2 (z)
    reg[  NMVU*BLENGTH-1 : 0] olength_0;        // Config: output length in dimension 0 (x)
    reg[  NMVU*BLENGTH-1 : 0] olength_1;        // Config: output length in dimension 1 (y)
    reg[  NMVU*BLENGTH-1 : 0] olength_2;        // Config: output length in dimension 2 (z)

    //
    // DUT
    //
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
            .d_signed         (d_signed     ),
            .w_signed         (w_signed     ),
            .shacc_clr        (shacc_clr    ),
            .max_en           (max_en       ),
            .max_clr          (max_clr      ),
            .max_pool         (max_pool     ),
            .quant_clr        (quant_clr	),
    		.quant_msbidx     (quant_msbidx ),
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


// =================================================================================================
// Utility Tasks

task writeData(unsigned[BDBANKW-1 : 0] word, unsigned[BDBANKA-1 : 0] addr);
    wrc_addr = addr;
    wrc_word = word;
    wrc_en = 1;
    #(`CLKPERIOD);
    wrc_en = 0;
endtask

task writeDataRepeat(logic unsigned[BDBANKW-1 : 0] word, logic unsigned[BDBANKA-1 : 0] startaddr, int size, int stride=1);

    for (int i = 0; i < size; i++) begin
        writeData(word, startaddr);
        startaddr = startaddr + stride;
    end
endtask

task writeWeights(unsigned[BWBANKW-1 : 0] word, unsigned[BWBANKA-1 : 0] addr);
    wrw_addr = addr;
    wrw_word = word;
    wrw_en = 1;
    #(`CLKPERIOD);
    wrw_en = 0;
endtask

task writeWeightsRepeat(logic unsigned[BWBANKW-1 : 0] word, logic unsigned[BWBANKA-1 : 0] startaddr, int size, int stride=1);
    for (int i = 0; i < size; i++) begin
        writeWeights(word, startaddr);
        #(`CLKPERIOD);
        startaddr = startaddr + stride;
    end
endtask


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
// Testbench tasks

//
// Memory test
//
task memTests();

endtask

//
//
//
task gemvTests();

    print("TEST 1: matrix-vector mult: 1x1 x 1 tiles, 1x1 => 1 bit precision, , input=all 0's");
    wprecision = 1;
    iprecision = 1;
    oprecision = 1;
    wbaseaddr = 0;
    ibaseaddr = 0;
    obaseaddr = 0;
    wstride_0 = 0;
    wstride_1 = 0;
    wstride_2 = 0;
    istride_0 = 0;
    istride_1 = 0;
    istride_2 = 0;
    ostride_0 = 0;
    ostride_1 = 0;
    ostride_2 = 0;
    wlength_0 = 0;
    wlength_1 = 0;
    wlength_2 = 0;
    ilength_0 = 0;
    ilength_1 = 0;
    ilength_2 = 0;
    olength_0 = 0;
    olength_1 = 0;
    olength_2 = 0;
    countdown = 1;
    start = 1;
    #(`CLKPERIOD);
    start = 0;
    #(`CLKPERIOD*10);

    print("TEST 2: matrix-vector mult: 2x2 x 2 tiles, 1x1 => 1 bit precision, input=all 0's");
    wprecision = 1;
    iprecision = 1;
    oprecision = 1;
    wbaseaddr = 0;
    ibaseaddr = 0;
    obaseaddr = 0;
    wstride_0 = 0;
    wstride_1 = 0;
    wstride_2 = 0;
    istride_0 = -1;
    istride_1 = 0;
    istride_2 = 0;
    ostride_0 = 0;
    ostride_1 = 0;
    ostride_2 = 0;
    wlength_0 = 3;
    wlength_1 = 0;
    wlength_2 = 0;
    ilength_0 = 1;
    ilength_1 = 1;
    ilength_2 = 0;
    olength_0 = 1;
    olength_1 = 0;
    olength_2 = 0;
    countdown = 4;
    start = 1;
    #(`CLKPERIOD);
    start = 0;
    #(`CLKPERIOD*15);

    // TEST 3
    // Expected result: accumulators get to value h480, output to data memory is b10 for each element
    // (i.e. [hffffffffffffffff, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
    // (i.e. d3*d3*d64*d2 = d1152 = h480)
    print("TEST 3: matrix-vector mult: 2x2 x 2 tiles, 2x2 => 2 bit precision, , input=all 1's");
    writeDataRepeat('hffffffffffffffff, 'h0000, 4);
    writeWeightsRepeat({BWBANKW{1'b1}}, 'h0, 8);
    wprecision = 2;
    iprecision = 2;
    oprecision = 2;
    quant_msbidx = 10;
    wbaseaddr = 0;
    ibaseaddr = 0;
    obaseaddr = 'h4000;
    wstride_0 = -2;      // 1 tile back move x 2 bits
    wstride_1 = 2;       // 1 tile ahead move x 2 bits
    wstride_2 = 0;
    istride_0 = -2;      // 1 tile back move x 2 bits 
    istride_1 = 0;
    istride_2 = -2;
    ostride_0 = 0;
    ostride_1 = 0;
    ostride_2 = 0;
    wlength_0 = 1;       // 2 tiles in width
    wlength_1 = 3;       // number bit combinations i.e. 2x2 bits
    wlength_2 = 1;       // 2 tiles in height
    ilength_0 = 1;       // 2 tiles in height
    ilength_1 = 0;       // number bit combinations
    ilength_2 = 0;       // 2 tiles in width of matrix operand
    olength_0 = 1;
    olength_1 = 0;
    olength_2 = 0;
    countdown = 16;       // 2 tiles x 2 tiles x 2bit x 2bits
    start = 1;
    #(`CLKPERIOD);
    start = 0;
    #(`CLKPERIOD*28);

    // TEST 4
    // Expected result: accumulators get to value h6c0, output to data memory is b110 for each element
    // (i.e. [hffffffffffffffff, hffffffffffffffff, 0000000000000000, hffffffffffffffff, hffffffffffffffff, 0000000000000000, ...)
    // (i.e. d3*d3*d64*d3 = d1728 = h6c0)
    print("TEST 4: matrix-vector mult: 3x3 x 3 tiles, 2x2 => 3 bit precision, input=all 1's");
    writeDataRepeat('hffffffffffffffff, 'h0000, 6);
    writeWeightsRepeat({BWBANKW{1'b1}}, 'h0, 18);
    wprecision = 2;
    iprecision = 2;
    oprecision = 3;
    quant_msbidx = 10;
    wbaseaddr = 0;
    ibaseaddr = 0;
    obaseaddr = 'h6000;
    wstride_0 = -4;      // 2 tile back move x 2 bits
    wstride_1 = 2;       // 1 tile ahead move x 2 bits
    wstride_2 = 0;
    istride_0 = -4;      // 2 tile back move x 2 bits 
    istride_1 = 0;
    istride_2 = -4;
    ostride_0 = 0;
    ostride_1 = 0;
    ostride_2 = 0;
    wlength_0 = 2;       // 3 tiles in width
    wlength_1 = 3;       // number bit combinations i.e. 2x2 bits
    wlength_2 = 2;       // 3 tiles in height
    ilength_0 = 2;       // 3 tiles in height
    ilength_1 = 0;       // number bit combinations
    ilength_2 = 0;       // 2 tiles in width of matrix operand
    olength_0 = 2;
    olength_1 = 0;
    olength_2 = 0;
    countdown = 36;       // 3 tiles x 3 tiles x 2bit x 2bits
    start = 1;
    #(`CLKPERIOD);
    start = 0;
    #(`CLKPERIOD*48);

    // TEST 5
    // Expected result: accumulators get to value h180, output to data memory is b001 for each element
    // (i.e. [hffffffffffffffff, hffffffffffffffff, 0000000000000000, hffffffffffffffff, hffffffffffffffff, 0000000000000000, ...)
    // (i.e. d2*d1*d64*d3 = d384 = h180)
    print("TEST 5: matrix-vector mult: 3x3 x 3 tiles, 2x2 => 3 bit precision, input=b10, weights=b01");
    writeDataRepeat('hffffffffffffffff, 'h0000, 3, 2);      // MSB=1  \
    writeDataRepeat('h0000000000000000, 'h0001, 3, 2);      // LSB=0  - = b10
    writeWeightsRepeat({BWBANKW{1'b0}}, 'h0, 9, 2);         // MSB=0 \
    writeWeightsRepeat({BWBANKW{1'b1}}, 'h1, 9, 2);         // LSB=1 - = b01
    wprecision = 2;
    iprecision = 2;
    oprecision = 3;
    quant_msbidx = 10;
    wbaseaddr = 0;
    ibaseaddr = 0;
    obaseaddr = 'h7000;
    wstride_0 = -4;      // 2 tile back move x 2 bits
    wstride_1 = 2;       // 1 tile ahead move x 2 bits
    wstride_2 = 0;
    istride_0 = -4;      // 2 tile back move x 2 bits 
    istride_1 = 0;
    istride_2 = -4;
    ostride_0 = 0;
    ostride_1 = 0;
    ostride_2 = 0;
    wlength_0 = 2;       // 3 tiles in width
    wlength_1 = 3;       // number bit combinations i.e. 2x2 bits
    wlength_2 = 2;       // 3 tiles in height
    ilength_0 = 2;       // 3 tiles in height
    ilength_1 = 0;       // number bit combinations
    ilength_2 = 0;       // 2 tiles in width of matrix operand
    olength_0 = 2;
    olength_1 = 0;
    olength_2 = 0;
    countdown = 36;       // 3 tiles x 3 tiles x 2bit x 2bits
    start = 1;
    #(`CLKPERIOD);
    start = 0;
    #(`CLKPERIOD*48);

endtask


// =================================================================================================
// Main test thread

initial begin

    // Initialize signals
    rst_n = 0;
    start = 0;
    ic_clr = 0;      
    ic_recv_from = 0;
    mul_mode = 'b01;
    d_signed = 0;
    w_signed = 0;
    shacc_clr = 0;
    max_en = 0;
    max_clr = 0;
    max_pool = 0;
    rdc_en = 0;
    rdc_addr = 0;
    wrc_en = 0;
    wrc_addr = 0;
    wrc_word = 0;
	quant_clr = 0;
    quant_msbidx = 0;
    countdown = 0;
    wprecision = 0;
    iprecision = 0;
    oprecision = 0;
    wbaseaddr = 0;
    ibaseaddr = 0;
    obaseaddr = 0;
    wstride_0 = 0;
    wstride_1 = 0;
    wstride_2 = 0;
    istride_0 = 0;
    istride_1 = 0;
    istride_2 = 0;
    ostride_0 = 0;
    ostride_1 = 0;
    ostride_2 = 0;
    wlength_0 = 0;
    wlength_1 = 0;
    wlength_2 = 0;
    ilength_0 = 0;
    ilength_1 = 0;
    ilength_2 = 0;
    olength_0 = 0;
    olength_1 = 0;
    olength_2 = 0;
    wrw_addr = 0;
    wrw_word = 0;
    wrw_en = 0;
    #(`CLKPERIOD*10);

    // Come out of reset
    rst_n = 1;
    #(`CLKPERIOD*10);

    // Turn some stuff on
    max_en = 1;

 
    // Run gemv tests
    gemvTests();


    print_banner($sformatf("Simulation done."));
    $finish();
end

endmodule

