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

    /* Create input logicisters and output wires */
    parameter  NMVU    =  8;   /* Number of MVUs. Ideally a Power-of-2. */
    parameter  N       = 64;   /* N x N matrix-vector product size. Power-of-2. */
    parameter  NDBANK  = 32;   /* Number of 2N-bit, 512-element Data BANK. */
    localparam BMVUA   = $clog2(NMVU);  /* Bitwidth of MVU          Address */
    localparam BWBANKA = 9;             /* Bitwidth of Weights BANK Address */
    localparam BWBANKW = 4096;          // Bitwidth of Weights BANK Word
    localparam BDBANKABS = $clog2(NDBANK);  /* Bitwidth of Data    BANK Address Bank Select */
    localparam BDBANKAWS = 10;              /* Bitwidth of Data    BANK Address Word Select */
    localparam BDBANKA   = BDBANKABS+ BDBANKAWS;    /* Bitwidth of Data    BANK Address */
    localparam BDBANKW = N;             /* Bitwidth of Data    BANK Word */
	
	// Other Parameters
    localparam BCNTDWN	= 29;			// Bitwidth of the countdown ports
    localparam BPREC 	= 6;			// Bitwidth of the precision ports
    localparam BBWADDR	= 9;			// Bitwidth of the weight base address ports
    localparam BBDADDR	= 15;			// Bitwidth of the data base address ports
    localparam BJUMP	= 15;			// Bitwidth of the jump ports
    localparam BLENGTH	= 15;			// Bitwidth of the length ports
    localparam BSCALERB = 16;           // Bitwidth of multiplicative scaler (operand 'b')
    localparam BSCALERP = 48;           // Bitwidth of the scaler output
    localparam NJUMPS   = 5;            // Number of address jumps supported

    localparam BACC    = 27;            /* Bitwidth of Accumulators */

    // Quantizer parameters
    localparam BQMSBIDX = $clog2(BSCALERP); // Bitwidth of the quantizer MSB location specifier
    localparam BQBOUT   = $clog2(BSCALERP); // Bitwitdh of the quantizer 

    // I/O port wires
    reg                      clk         ;//input  clk;
    reg                      rst_n       ;//input  reset;
    reg [        NMVU-1 : 0] start       ;//input  start;
    reg [        NMVU-1 : 0] done        ;//output done;
    reg [        NMVU-1 : 0] irq         ;//output irq
    reg                      ic_clr      ;//input  ic_clr;
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
    reg[     NMVU*NMVU-1 : 0] omvusel;          // Config: MVU selector bits for output

    reg[  NMVU*BWBANKA-1 : 0] wrw_addr;         // Weight memory: write address
    reg[  NMVU*BWBANKW-1 : 0] wrw_word;         // Weight memory: write word
    reg[          NMVU-1 : 0] wrw_en;           // Weight memory: write enable
    reg[         BJUMP-1 : 0] wjump[NMVU-1 : 0][NJUMPS-1 : 0];            // Config: weight jumps
    reg[         BJUMP-1 : 0] ijump[NMVU-1 : 0][NJUMPS-1 : 0];            // Config: input jumps
    reg[         BJUMP-1 : 0] ojump[NMVU-1 : 0][NJUMPS-1 : 0];            // Config: output jumps
    reg[       BLENGTH-1 : 0] wlength[NMVU-1 : 0][NJUMPS-1 : 1];        // Config: weight lengths
    reg[       BLENGTH-1 : 0] ilength[NMVU-1 : 0][NJUMPS-1 : 1];        // Config: input length 1
    reg[       BLENGTH-1 : 0] olength[NMVU-1 : 0][NJUMPS-1 : 1];        // Config: output length 1
    reg[ NMVU*BSCALERB-1 : 0] scaler_b;         // Config: multiplicative scaler (operand 'b')
    reg[        NJUMPS-1 : 0] shacc_load_sel[NMVU-1 : 0];   // Config: select jump trigger for shift/accumultor load
    reg[        NJUMPS-1 : 0] zigzag_step_sel[NMVU-1 : 0];  // Config: select jump trigger for stepping the zig-zag address generator  

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
            .mul_mode         (mul_mode     ),
            .d_signed         (d_signed     ),
            .w_signed         (w_signed     ),
            .shacc_clr        (shacc_clr    ),
            .max_en           (max_en       ),
            .max_clr          (max_clr      ),
            .max_pool         (max_pool     ),
            .quant_clr        (quant_clr    ),
            .quant_msbidx     (quant_msbidx ),
            .countdown        (countdown),
            .wprecision       (wprecision),
            .iprecision       (iprecision),
            .oprecision       (oprecision),
            .wbaseaddr        (wbaseaddr),
            .ibaseaddr        (ibaseaddr),
            .obaseaddr        (obaseaddr),
            .omvusel          (omvusel),
            .wjump            (wjump),
            .ijump            (ijump),
            .ojump            (ojump),
            .wlength          (wlength),
            .ilength          (ilength),
            .olength          (olength),
            .scaler_b         (scaler_b),
            .shacc_load_sel   (shacc_load_sel),
            .zigzag_step_sel  (zigzag_step_sel),
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

task checkmvu(int mvu);
    if (mvu > N) begin
        print($sformatf("MVU specificed %d is greater than number of MVUs %d", mvu, N), "Error");
        $finish();
    end
endtask

task writeData(int mvu, unsigned[BDBANKW-1 : 0] word, unsigned[BDBANKA-1 : 0] addr);
    checkmvu(mvu);
    wrc_addr = addr;
    wrc_word = word;
    wrc_en[mvu] = 1'b1;
    #(`CLKPERIOD);
    wrc_en[mvu] = 1'b0;
endtask

task writeDataRepeat(int mvu, logic unsigned[BDBANKW-1 : 0] word, logic unsigned[BDBANKA-1 : 0] startaddr, int size, int stride=1);
    checkmvu(mvu);
    for (int i = 0; i < size; i++) begin
        writeData(.mvu(mvu), .word(word), .addr(startaddr));
        startaddr = startaddr + stride;
    end
endtask

task writeWeights(int mvu, unsigned[BWBANKW-1 : 0] word, unsigned[BWBANKA-1 : 0] addr);
    checkmvu(mvu);
    wrw_addr[mvu*BWBANKA +: BWBANKA] = addr;
    wrw_word[mvu*BWBANKW +: BWBANKW] = word;
    wrw_en[mvu] = 1'b1;
    #(`CLKPERIOD);
    wrw_en[mvu] = 1'b0;
endtask

task writeWeightsRepeat(int mvu, logic unsigned[BWBANKW-1 : 0] word, logic unsigned[BWBANKA-1 : 0] startaddr, int size, int stride=1);
    checkmvu(mvu);
    for (int i = 0; i < size; i++) begin
        writeWeights(.mvu(mvu), .word(word), .addr(startaddr));
        #(`CLKPERIOD);
        startaddr = startaddr + stride;
    end
endtask

task automatic readData(int mvu, logic unsigned [BDBANKA-1 : 0] addr, ref logic unsigned [BDBANKW-1 : 0] word, ref logic unsigned [NMVU-1 : 0] grnt);
    checkmvu(mvu);
    rdc_addr[mvu*BDBANKA +: BDBANKA] = addr;
    rdc_en[mvu] = 1;
    #(`CLKPERIOD);
    grnt[mvu] = rdc_grnt[mvu];
    rdc_en[mvu] = 0;
    #(`CLKPERIOD*2);
    word = rdc_word[mvu*BDBANKW +: BDBANKW];

endtask


// Executes a GMEV
task automatic runGEMV(
    int mvu,            // MVU number to execute on
    int iprec,
    int wprec,
    int oprec,
    int omsb,
    int iaddr,
    int waddr,
    byte omvu,          // output mvus
    int obank,
    int oaddr,
    int m_w,            // Matrix width / vector length
    int m_h,            // Matrix height
    logic isign = 0,    // True if input data are signed
    logic wsign = 0,    // True if weights are signed
    int scaler = 1
);

    logic [BDBANKABS-1 : 0]     obank_sel = obank;
    logic [BDBANKAWS-1 : 0]     oword_sel = oaddr;

    int countdown_val = m_w * m_h * iprec * wprec;
    int pipeline_latency = 9;
    int buffer_cycles = 10;
    int cyclecount = countdown_val + pipeline_latency + oprec + buffer_cycles;

    // Check that the MVU number is okay
    checkmvu(mvu);

    // Configure paramters on the port of the DUT
    wprecision[mvu*BPREC +: BPREC] = wprec;
    iprecision[mvu*BPREC +: BPREC] = iprec;
    oprecision[mvu*BPREC +: BPREC] = oprec;
    quant_msbidx[mvu*BQMSBIDX +: BQMSBIDX] = omsb;
    wbaseaddr[mvu*BWBANKA +: BWBANKA] = waddr;
    ibaseaddr[mvu*BDBANKA +: BDBANKA] = iaddr;
    obaseaddr[mvu*BDBANKA +: BDBANKA] = {obank_sel, oword_sel};
    omvusel[mvu*NMVU +: NMVU] = omvu;                           // Set the output MVUs
    wjump[mvu][0] = wprec;                        // move 1 tile ahead to next tile row
    wjump[mvu][1] = -wprec*(m_w-1);               // Move back to tile 0 of current tile row
    wjump[mvu][2] = wprec;                        // Move ahead one tile
    wjump[mvu][3] = 0;                            // Don't need this for GEMV
    wjump[mvu][4] = 0;                            // Don't need this for GEMV
    ijump[mvu][0] = -iprec*(m_w-1);               // Move back to beginning vector 
    ijump[mvu][1] = iprec;                        // Move ahead one tile
    ijump[mvu][2] = 0;                            // Don't need this for GEMV
    ijump[mvu][3] = 0;                            // Don't need this for GEMV
    ijump[mvu][4] = 0;                            // Don't need this for GEMV
    ojump[mvu][0] = 0;                            // Don't need this for GEMV
    ojump[mvu][1] = 0;                            // Don't need this for GEMV
    ojump[mvu][2] = 0;                            // Don't need this for GEMV
    ojump[mvu][3] = 0;                            // Don't need this for GEMV
    ojump[mvu][4] = 0;                            // Don't need this for GEMV
    wlength[mvu][1] = wprec*iprec-1;              // number bit combinations minus 1
    wlength[mvu][2] = m_w-1;                      // Number tiles in width minus 1
    wlength[mvu][3] = 0;                          // Don't need this for GEMV
    wlength[mvu][4] = 0;                          // Don't need this for GEMV
    ilength[mvu][1] = m_h-1;                      // Number tiles in height minus 1
    ilength[mvu][2] = 0;                          // Don't need this for GEMV
    ilength[mvu][3] = 0;                          // Don't need this for GEMV
    ilength[mvu][4] = 0;                          // Don't need this for GEMV
    olength[mvu][1] = 1;                          // Write out sequentially
    olength[mvu][2] = 0;                          // Don't need this for GEMV
    olength[mvu][3] = 0;                          // Don't need this for GEMV
    olength[mvu][4] = 0;                          // Don't need this for GEMV
    d_signed[mvu] = isign;
    w_signed[mvu] = wsign;
    scaler_b[mvu*BSCALERB +: BSCALERB] = scaler;
    shacc_load_sel[mvu] = 5'b00001;            // Load the shift/accumulator on when weight address jump 0 happens
    zigzag_step_sel[mvu] = 5'b00011;           // Bump the zig-zag on weight jumps 1 and 0
    countdown[mvu*BCNTDWN +: BCNTDWN] = countdown_val;

    // Run the GEMV
    start[mvu] = 1'b1;
    #(`CLKPERIOD);
    start[mvu] = 1'b0;
    #(`CLKPERIOD*cyclecount);

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
// Controller memory access test
//
task controllerMemTest();

    logic unsigned [BDBANKW-1 : 0] word;
    logic unsigned [NMVU-1 : 0] grnt;

    print_banner("Controller memory access test");

    // Read/Write tests
    writeData(0, 'hdeadbeefdeadbeef, 0);
    readData(0, 0, word, grnt);
    print($sformatf("word=%x, grnt=%b", word, grnt));
    writeData(0, 'hbeefdeadbeefdead, 1);
    readData(0, 1, word, grnt);
    print($sformatf("word=%x, grnt=%b", word, grnt));


endtask

//
// Matrix-vector multiplication (GEMV) test
//
task gemvTests(int mvu, int omvu, int scaler);

    print_banner("Matrix-vector multiplication (GEMV) test");

    print("TEST gemv 1: matrix-vector mult: 1x1 x 1 tiles, 1x1 => 1 bit precision, , input=all 0's");
    runGEMV(.mvu(mvu), .iprec(1), .wprec(1), .oprec(1), 
            .omsb(0), .iaddr(0), .waddr(0), .omvu(omvu), .obank(0), .oaddr(0), 
            .m_w(1), .m_h(1), .scaler(scaler));


    print("TEST gemv 2: matrix-vector mult: 2x2 x 2 tiles, 1x1 => 1 bit precision, input=all 0's");
    runGEMV(.mvu(mvu), .iprec(1), .wprec(1), .oprec(1), 
            .omsb(0), .iaddr(0), .waddr(0), .omvu(omvu), .obank(0), .oaddr(0), 
            .m_w(2), .m_h(2), .scaler(scaler));


    // TEST 3
    // Expected result: accumulators get to value h480, output to data memory is b10 for each element
    // (i.e. [hffffffffffffffff, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
    // (i.e. d3*d3*d64*d2 = d1152 = h480)
    // Result output to bank 1 starting at address 0
    print("TEST gemv 3: matrix-vector mult: 2x2 x 2 tiles, 2x2 => 2 bit precision, , input=all 1's");
    writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr('h0000), .size(4), .stride(1));
    writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b1}}), .startaddr('h0), .size(8), .stride(1));
    runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .oprec(2), .omsb(10), 
            .iaddr(0), .waddr(0), .omvu(omvu), .obank(1), .oaddr(0), 
            .m_w(2), .m_h(2), .scaler(scaler));


    // TEST 4
    // Expected result: accumulators get to value h6c0, output to data memory is b110 for each element
    // (i.e. [hffffffffffffffff, hffffffffffffffff, 0000000000000000, hffffffffffffffff, hffffffffffffffff, 0000000000000000, ...)
    // (i.e. d3*d3*d64*d3 = d1728 = h6c0)
    // Result output to bank 2 starting at address 0
    print("TEST gmev 4: matrix-vector mult: 3x3 x 3 tiles, 2x2 => 3 bit precision, input=all 1's");
    writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr('h0000), .size(6), .stride(1));
    writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b1}}), .startaddr('h0), .size(18), .stride(1));
    runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .oprec(3), .omsb(10), 
            .iaddr(0), .waddr(0), .omvu(omvu), .obank(2), .oaddr(0), 
            .m_w(3), .m_h(3), .scaler(scaler));


    // TEST 5
    // Expected result: accumulators get to value h180, output to data memory is b001 for each element
    // (i.e. [0000000000000000, 0000000000000000, hffffffffffffffff, 0000000000000000, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
    // (i.e. d2*d1*d64*d3 = d384 = h180)
    // Result output to bank 3 starting at address 0
    print("TEST gemv 5: matrix-vector mult: 3x3 x 3 tiles, 2x2 => 3 bit precision, input=b10, weights=b01");
    writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr('h0000), .size(3), .stride(2));      // MSB=1  \
    writeDataRepeat(.mvu(mvu), .word('h0000000000000000), .startaddr('h0001), .size(3), .stride(2));      // LSB=0  - = b10
    writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b0}}), .startaddr('h0), .size(9), .stride(2));         // MSB=0 \
    writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b1}}), .startaddr('h1), .size(9), .stride(2));         // LSB=1 - = b01
    runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .oprec(3), .omsb(10), 
            .iaddr(0), .waddr(0), .omvu(omvu), .obank(3), .oaddr(0), 
            .m_w(3), .m_h(3), .scaler(scaler));



endtask


//
// Test signed Matrix-Vector multiplication (gemv signed)
//
task gemvSignedTests(int mvu, int omvu, int scaler);

    print_banner("Matrix-vector signed multiplication (GEMV) test");

    // Expected result: accumulators get to value hffffffffffffff80, output to data memory is b10 for each element
    // (i.e. [hffffffffffffffff, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
    // (i.e. d1*-d1*d64*d2 = -d128 = 32'hffffffffffffff80)
    // Result output to bank 10 starting at address 0
    print("TEST gemv signed 1: matrix-vector mult: 2x2 x 2 tiles, 2u X 2s => 2 bit precision, input: d=1, w=-1");
    writeDataRepeat(.mvu(mvu), .word('h0000000000000000), .startaddr('h0000), .size(2), .stride(2));      // MSB=0 \
    writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr('h0001), .size(2), .stride(2));      // LSB=1 - = b01 = d1
    writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b1}}), .startaddr('h0), .size(8));            // MSB=1, LSB=1 => b11 = -d1
    runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .oprec(2), .omsb(7), 
            .iaddr(0), .waddr(0), .omvu(omvu), .obank(10), .oaddr(0), 
            .m_w(2), .m_h(2), .isign(0), .wsign(1), .scaler(scaler));
 


    // Expected result: accumulators get to value hfffffffffffffd00, output to data memory is b10 for each element
    // (i.e. [hffffffffffffffff, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
    // (i.e. -d2*d3*d64*d2 = -d768 = 32'hfffffffffffffd00)
    // Result output to bank 11 starting at address 0
    print("TEST gemv signed 2: matrix-vector mult: 2x2 x 2 tiles, 2s X 2u => 2 bit precision, input: d=-2, w=3");
    writeDataRepeat(mvu, 'hffffffffffffffff, 'h0000, 2, 2);      // MSB=1 \
    writeDataRepeat(mvu, 'h0000000000000000, 'h0001, 2, 2);      // LSB=0 - = b10 = -d2
    writeWeightsRepeat(mvu, {BWBANKW{1'b1}}, 'h0, 8);            // MSB=1, LSB=1 => b11 = d3
    runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .oprec(2), .omsb(10), 
            .iaddr(0), .waddr(0), .omvu(omvu), .obank(11), .oaddr(0), 
            .m_w(2), .m_h(2), .isign(1), .wsign(0), .scaler(scaler)); 


    // Expected result: accumulators get to value h0000000000000100, output to data memory is b01 for each element
    // (i.e. [0000000000000000, hffffffffffffffff, 0000000000000000, hffffffffffffffff, ...)
    // (i.e. -d2*-d1*d64*d2 = d256 = 32'h0000000000000100)
    // Result output to bank 12 starting at address 0
    print("TEST gemv signed 3: matrix-vector mult: 2x2 x 2 tiles, 2s X 2s => 2 bit precision, input: d=-2, w=-1");
    writeDataRepeat(mvu, 'hffffffffffffffff, 'h0000, 2, 2);      // MSB=1 \
    writeDataRepeat(mvu, 'h0000000000000000, 'h0001, 2, 2);      // LSB=0 - = b10 = -d2
    writeWeightsRepeat(mvu, {BWBANKW{1'b1}}, 'h0, 8);            // MSB=1, LSB=1 => b11 = d3
    runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .oprec(2), .omsb(9), 
        .iaddr(0), .waddr(0), .omvu(omvu), .obank(12), .oaddr(0), 
        .m_w(2), .m_h(2), .isign(1), .wsign(1), .scaler(scaler)); 

    // Expected result: accumulators get to value hfffffffffffffd00, output to data memory is b110 for each element
    // (i.e. [hffffffffffffffff, hffffffffffffffff, 0000000000000000, hffffffffffffffff, ...)
    // (i.e. d3*-d2*d64*d2 = -d768 = 32'hfffffffffffffd00)
    // Result output to bank 13 starting at address 0
    print("TEST gemv signed 4: matrix-vector mult: 2x2 x 2 tiles, 3s X 2s => 3 bit precision, input: d=3, w=-2");
    writeDataRepeat(mvu, 'h0000000000000000, 'h0000, 2, 3);      // MSB  =0 \
    writeDataRepeat(mvu, 'hffffffffffffffff, 'h0001, 2, 3);      // MSB-1=1 - = b011 = d3
    writeDataRepeat(mvu, 'hffffffffffffffff, 'h0002, 2, 3);      // LSB  =1 /
    writeWeightsRepeat(mvu, {BWBANKW{1'b1}}, 'h0, 4, 2);         // MSB  =1 \
    writeWeightsRepeat(mvu, {BWBANKW{1'b0}}, 'h1, 4, 2);         // LSB  =0 - = b10 = -d2
    runGEMV(.mvu(mvu), .iprec(3), .wprec(2), .oprec(3), .omsb(11), 
       .iaddr(0), .waddr(0), .omvu(omvu), .obank(13), .oaddr(0), 
       .m_w(2), .m_h(2), .isign(1), .wsign(1), .scaler(scaler)); 

    // Expected result: accumulators get to value hffffffffffffff00, output to data memory is b110 for each element
    // (i.e. [hffffffffffffffff, hffffffffffffffff, 0000000000000000, ...)
    // (i.e. (d3*-d2*d32 + d2*d1*d32)*d2 = -d256 = 32'hffffffffffffff00)
    // Result output to bank 14 starting at address 0
    print("TEST gemv signed 5: matrix-vector mult: 2x2 x 2 tiles, 3s X 2s => 3 bit precision, input: alternating d={3,2}, w={-2,1}");
    writeDataRepeat(mvu, 'h0000000000000000, 'h0000, 2, 3);      // MSB  ={0,0}... \
    writeDataRepeat(mvu, 'hffffffffffffffff, 'h0001, 2, 3);      // MSB-1={1,1}... - = {b011,b110} = {d3,d2}
    writeDataRepeat(mvu, 'haaaaaaaaaaaaaaaa, 'h0002, 2, 3);      // LSB  ={1,0}... /
    writeWeightsRepeat(mvu, {BWBANKW/2{2'b10}}, 'h0, 4, 2);      // MSB  ={1,0}... \
    writeWeightsRepeat(mvu, {BWBANKW/2{2'b01}}, 'h1, 4, 2);      // LSB  ={0,1}... - = {b10,b01} = {-d2, d1}
    runGEMV(.mvu(mvu), .iprec(3), .wprec(2), .oprec(3), .omsb(9), 
       .iaddr(0), .waddr(0), .omvu(omvu), .obank(14), .oaddr(0), 
       .m_w(2), .m_h(2), .isign(1), .wsign(1), .scaler(scaler)); 


    // Expected result: accumulators get to value hfffffffffffffe7d, output to data memory is b100 for each element
    // (i.e. [hffffffffffffffff, 0000000000000000, 0000000000000000, ...)
    // (i.e. (d3*-d2*d32 + d2*d1*d31 + d1*d1*d1)*d3 = -d387 = 32'hfffffffffffffe7d)
    // Result output to bank 15 starting at address 0
    print("TEST gemv signed 6: matrix-vector mult: 3x3 x 3 tiles, 3s X 2s => 3 bit precision, input: alternating d={3,2}, w={-2,1}, except one product term per tile with 1x1=1");
    writeDataRepeat(mvu, 'h0000000000000000, 'h0000, 3, 3);      // MSB  ={0,0}... \
    writeDataRepeat(mvu, 'hfffffffffffffffe, 'h0001, 3, 3);      // MSB-1={1,1}... - = {b011,b110} = {d3,d2}
    writeDataRepeat(mvu, 'haaaaaaaaaaaaaaab, 'h0002, 3, 3);      // LSB  ={1,0}... /
    writeWeightsRepeat(mvu, {BWBANKW/2{2'b10}}, 'h0, 9, 2);      // MSB  ={1,0}... \
    writeWeightsRepeat(mvu, {BWBANKW/2{2'b01}}, 'h1, 9, 2);      // LSB  ={0,1}... - = {b10,b01} = {-d2, d1}
    runGEMV(.mvu(mvu), .iprec(3), .wprec(2), .oprec(3), .omsb(9), 
       .iaddr(0), .waddr(0), .omvu(omvu), .obank(15), .oaddr(0), 
       .m_w(3), .m_h(3), .isign(1), .wsign(1), .scaler(scaler)); 


    // Expected result: accumulators get to value h0000000000000063, output to data memory is b001 for each element
    // (i.e. [0000000000000000, 0000000000000000, hffffffffffffffff, ...)
    // (i.e. (d3*d1*d32 + d2*-d1*d31 + d1*-d1*d1)*d3 = d99 = 32'h0000000000000063)
    // Result output to bank 16 starting at address 0
    print("TEST gemv signed 7: matrix-vector mult: 3x3 x 3 tiles, 3s X 2s => 3 bit precision, input: alternating d={3,2}, w={-2,1}, except one product term per tile with 1x1=1");
    writeDataRepeat(mvu, 'h0000000000000000, 'h0000, 3, 3);      // MSB  ={0,0}... \
    writeDataRepeat(mvu, 'hfffffffffffffffe, 'h0001, 3, 3);      // MSB-1={1,1}... - = {b011,b110} = {d3,d2}
    writeDataRepeat(mvu, 'haaaaaaaaaaaaaaab, 'h0002, 3, 3);      // LSB  ={1,0}... /
    writeWeightsRepeat(mvu, {BWBANKW/2{2'b01}}, 'h0, 9, 2);      // MSB  ={1,0}... \
    writeWeightsRepeat(mvu, {BWBANKW/2{2'b11}}, 'h1, 9, 2);      // LSB  ={0,1}... - = {b10,b01} = {-d2, d1}
    runGEMV(.mvu(mvu), .iprec(3), .wprec(2), .oprec(3), .omsb(8), 
       .iaddr(0), .waddr(0), .omvu(omvu), .obank(16), .oaddr(0), 
       .m_w(3), .m_h(3), .isign(1), .wsign(1), .scaler(scaler)); 


endtask


// =================================================================================================
// Main test thread

initial begin

    // Initialize signals
    rst_n = 0;
    start = 0;
    ic_clr = 0;      
    mul_mode = {NMVU{2'b01}};
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
    omvusel = 0;  
    scaler_b = 1;
    wrw_addr = 0;
    wrw_word = 0;
    wrw_en = 0;

    // Initialize arrays
    for (int m = 0; m < NMVU; m++) begin
        // Initialize jumps
        for (int i = 0; i < NJUMPS; i++) begin
            wjump[m][i] = 0;
            ijump[m][i] = 0;
            ojump[m][i] = 0;
        end

        // Initizalize lengths
        for (int i = 1; i < NJUMPS; i++) begin
            wlength[m][i] = 0;
            ilength[m][i] = 0;
            olength[m][i] = 0;
        end

        shacc_load_sel[m] = 0;
        zigzag_step_sel[m] = 0;
    end

    #(`CLKPERIOD*10);

    // Come out of reset
    rst_n = 1;
    #(`CLKPERIOD*10);

    // Turn some stuff on
    max_en = 1;

    // Test memory access
    controllerMemTest();
 
    // Run gemv tests, mvu0 -> mvu0
    print_banner("GEMV tests: mvu0 -> mvu0");
    gemvTests(.mvu(0), .omvu('b00000001), .scaler(1));

    // Run signed gemv tests, mvu0 -> mvu0
    print_banner("Signed GEMV tests: mvu0 -> mvu0");
    gemvSignedTests(.mvu(0), .omvu('b00000001), .scaler(1));

    // Repeat signed gemv tests, but with scaler set to 2
    // Test 1 -> -d256, b00 in bank 10
    // Test 2 -> -d1536, b01 in bank 11
    // Test 3 -> d512, b10 in bank 12
    // Test 4 -> -d1536, b101 in bank 13
    // Test 5 -> -d512, b100 in bank 14
    // Test 6 -> -d774, b001 in bank 15
    // Test 7 -> d198, b011 in bank 16
    //gemvSignedTests(.mvu(0), .omvu(0), .scaler(2));

    // Repeat signed gemv tests, but with scaler set to 5, mvu0 -> mvu0
    // Expected outcomes:
    // Test 1 -> -d640, b10 in bank 10
    // Test 2 -> -d3840, b00 in bank 11
    // Test 3 -> d1280, b01 in bank 12
    // Test 4 -> -d3840, b000 in bank 13
    // Test 5 -> -d1280, b110 in bank 14
    // Test 6 -> -d1935, b000 in bank 15
    // Test 7 -> d495, b111 in bank 16
    //gemvSignedTests(.mvu(0), .omvu(0), .scaler(5));

    //
    // Interconnect tests
    // 
/*
    // Repeat the unsigned gemv tests, mvu0 -> mvu1
    print_banner("GEMV tests: mvu0 -> mvu1");
    gemvTests(.mvu(0), .omvu('b00000010), .scaler(1));

    // Repeat the unsigned gemv tests, mvu2 -> mvu3
    print_banner("GEMV tests: mvu2 -> mvu3");
    gemvTests(.mvu(2), .omvu('b00001000), .scaler(1));

    // Repeat the unsigned gemv tests, mvu3-> mvu2
    print_banner("GEMV tests: mvu3 -> mvu2");
    gemvTests(.mvu(3), .omvu('b00000100), .scaler(1));

    // Repeat the unsigned gemv tests, mvu7-> mvu0
    // Blank out mvu0's memory banks first
    print_banner("GEMV tests: mvu7 -> mvu0");
    writeDataRepeat(0, 'h0000000000000000, 'h0000, 9, 1);
    writeDataRepeat(0, 'h0000000000000000, {5'b00001, 10'b0000000000}, 9, 1);
    writeDataRepeat(0, 'h0000000000000000, {5'b00010, 10'b0000000000}, 9, 1);
    writeDataRepeat(0, 'h0000000000000000, {5'b00011, 10'b0000000000}, 9, 1);
    gemvTests(.mvu(7), .omvu('b00000001), .scaler(1));

    //
    // Broadcast tests
    //

    // Repeat the unsigned gemv tests, mvu4-> mvu5, mvu6
    print_banner("GEMV tests: mvu4 -> mvu5,6");
    gemvTests(.mvu(4), .omvu('b01100000), .scaler(1));
*/
    

    print_banner($sformatf("Simulation done."));
    $finish();
end

endmodule

