`include "testbench_base.sv"

class gemv_tester_w_relu extends mvu_testbench_base;

    function new(Logger logger, virtual mvu_interface intf);
        super.new(logger, intf);
    endfunction

    //
    // Matrix-vector multiplication (GEMV) test
    //
    task gemvTests(int mvu, int omvu, int scaler);

        logger.print_banner("Matrix-vector multiplication (GEMV) test with ReLU");

        // Intialization
        // First, set the max_clr to 1 always
        intf.max_clr[mvu] = 1;
        intf.max_pool[mvu] = 1;

        // TEST 3
        // Expected result: accumulators get to value h480, output to data memory is b10 for each element
        // (i.e. [hffffffffffffffff, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. d3*d3*d64*d2 = d1152 = h480)
        // Result output to bank 1 starting at address 0
        logger.print("TEST gemv 3: matrix-vector mult: 2x2 x 2 tiles, 2x2 => 2 bit precision, , input=all 1's");
        writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr('h0000), .size(4), .stride(1));
        writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b1}}), .startaddr('h0), .size(8), .stride(1));
        runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .saddr(0), .baddr(0), .oprec(2), .omsb(10), 
                .iaddr(0), .waddr(0), .omvu(omvu), .obank(1), .oaddr(0), 
                .m_w(2), .m_h(2), .scaler(scaler));


        // TEST 4
        // Expected result: accumulators get to value h6c0, output to data memory is b110 for each element
        // (i.e. [hffffffffffffffff, hffffffffffffffff, 0000000000000000, hffffffffffffffff, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. d3*d3*d64*d3 = d1728 = h6c0)
        // Result output to bank 2 starting at address 0
        logger.print("TEST gmev 4: matrix-vector mult: 3x3 x 3 tiles, 2x2 => 3 bit precision, input=all 1's");
        writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr('h0000), .size(6), .stride(1));
        writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b1}}), .startaddr('h0), .size(18), .stride(1));
        runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .saddr(0), .baddr(0), .oprec(3), .omsb(10), 
                .iaddr(0), .waddr(0), .omvu(omvu), .obank(2), .oaddr(0), 
                .m_w(3), .m_h(3), .scaler(scaler));


        // TEST 5
        // Expected result: accumulators get to value h180, output to data memory is b001 for each element
        // (i.e. [0000000000000000, 0000000000000000, hffffffffffffffff, 0000000000000000, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. d2*d1*d64*d3 = d384 = h180)
        // Result output to bank 3 starting at address 0
        logger.print("TEST gemv 5: matrix-vector mult: 3x3 x 3 tiles, 2x2 => 3 bit precision, input=b10, weights=b01");
        writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr('h0000), .size(3), .stride(2));      // MSB=1  \
        writeDataRepeat(.mvu(mvu), .word('h0000000000000000), .startaddr('h0001), .size(3), .stride(2));      // LSB=0  - = b10
        writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b0}}), .startaddr('h0), .size(9), .stride(2));         // MSB=0 \
        writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b1}}), .startaddr('h1), .size(9), .stride(2));         // LSB=1 - = b01
        runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .saddr(0), .baddr(0), .oprec(3), .omsb(10), 
                .iaddr(0), .waddr(0), .omvu(omvu), .obank(3), .oaddr(0), 
                .m_w(3), .m_h(3), .scaler(scaler));

    endtask

    //
    // Test signed Matrix-Vector multiplication (gemv signed)
    //
    task gemvSignedTests(int mvu, int omvu, int scaler);

        logger.print_banner("Matrix-vector signed multiplication (GEMV) test");

        // Intialization
        // First, set the max_clr to 1 always
        intf.max_clr[mvu] = 1;
        intf.max_pool[mvu] = 1;

        // Expected result: accumulators get to value hffffffffffffff80, output to data memory is b10 for each element
        // (i.e. [hffffffffffffffff, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. d1*-d1*d64*d2 = -d128 = 32'hffffffffffffff80)
        // Result output to bank 10 starting at address 0
        logger.print("TEST gemv signed 1: matrix-vector mult: 2x2 x 2 tiles, 2u X 2s => 2 bit precision, input: d=1, w=-1");
        writeDataRepeat(.mvu(mvu), .word('h0000000000000000), .startaddr('h0000), .size(2), .stride(2));      // MSB=0 \
        writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr('h0001), .size(2), .stride(2));      // LSB=1 - = b01 = d1
        writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b1}}), .startaddr('h0), .size(8));            // MSB=1, LSB=1 => b11 = -d1
        runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .saddr(0), .baddr(0), .oprec(2), .omsb(7), 
                .iaddr(0), .waddr(0), .omvu(omvu), .obank(10), .oaddr(0), 
                .m_w(2), .m_h(2), .isign(0), .wsign(1), .scaler(scaler));
     


        // Expected result: accumulators get to value hfffffffffffffd00, output to data memory is b10 for each element
        // (i.e. [hffffffffffffffff, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. -d2*d3*d64*d2 = -d768 = 32'hfffffffffffffd00)
        // Result output to bank 11 starting at address 0
        logger.print("TEST gemv signed 2: matrix-vector mult: 2x2 x 2 tiles, 2s X 2u => 2 bit precision, input: d=-2, w=3");
        writeDataRepeat(mvu, 'hffffffffffffffff, 'h0000, 2, 2);      // MSB=1 \
        writeDataRepeat(mvu, 'h0000000000000000, 'h0001, 2, 2);      // LSB=0 - = b10 = -d2
        writeWeightsRepeat(mvu, {BWBANKW{1'b1}}, 'h0, 8);            // MSB=1, LSB=1 => b11 = d3
        runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .saddr(0), .baddr(0), .oprec(2), .omsb(10), 
                .iaddr(0), .waddr(0), .omvu(omvu), .obank(11), .oaddr(0), 
                .m_w(2), .m_h(2), .isign(1), .wsign(0), .scaler(scaler)); 


        // Expected result: accumulators get to value h0000000000000100, output to data memory is b01 for each element
        // (i.e. [0000000000000000, hffffffffffffffff, 0000000000000000, hffffffffffffffff, ...)
        // (i.e. -d2*-d1*d64*d2 = d256 = 32'h0000000000000100)
        // Result output to bank 12 starting at address 0
        logger.print("TEST gemv signed 3: matrix-vector mult: 2x2 x 2 tiles, 2s X 2s => 2 bit precision, input: d=-2, w=-1");
        writeDataRepeat(mvu, 'hffffffffffffffff, 'h0000, 2, 2);      // MSB=1 \
        writeDataRepeat(mvu, 'h0000000000000000, 'h0001, 2, 2);      // LSB=0 - = b10 = -d2
        writeWeightsRepeat(mvu, {BWBANKW{1'b1}}, 'h0, 8);            // MSB=1, LSB=1 => b11 = d3
        runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .saddr(0), .baddr(0), .oprec(2), .omsb(9), 
            .iaddr(0), .waddr(0), .omvu(omvu), .obank(12), .oaddr(0), 
            .m_w(2), .m_h(2), .isign(1), .wsign(1), .scaler(scaler)); 

        // Expected result: accumulators get to value hfffffffffffffd00, output to data memory is b110 for each element
        // (i.e. [hffffffffffffffff, hffffffffffffffff, 0000000000000000, hffffffffffffffff, ...)
        // (i.e. d3*-d2*d64*d2 = -d768 = 32'hfffffffffffffd00)
        // Result output to bank 13 starting at address 0
        logger.print("TEST gemv signed 4: matrix-vector mult: 2x2 x 2 tiles, 3s X 2s => 3 bit precision, input: d=3, w=-2");
        writeDataRepeat(mvu, 'h0000000000000000, 'h0000, 2, 3);      // MSB  =0 \
        writeDataRepeat(mvu, 'hffffffffffffffff, 'h0001, 2, 3);      // MSB-1=1 - = b011 = d3
        writeDataRepeat(mvu, 'hffffffffffffffff, 'h0002, 2, 3);      // LSB  =1 /
        writeWeightsRepeat(mvu, {BWBANKW{1'b1}}, 'h0, 4, 2);         // MSB  =1 \
        writeWeightsRepeat(mvu, {BWBANKW{1'b0}}, 'h1, 4, 2);         // LSB  =0 - = b10 = -d2
        runGEMV(.mvu(mvu), .iprec(3), .wprec(2), .saddr(0), .baddr(0), .oprec(3), .omsb(11), 
           .iaddr(0), .waddr(0), .omvu(omvu), .obank(13), .oaddr(0), 
           .m_w(2), .m_h(2), .isign(1), .wsign(1), .scaler(scaler)); 

        // Expected result: accumulators get to value hffffffffffffff00, output to data memory is b110 for each element
        // (i.e. [hffffffffffffffff, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. (d3*-d2*d32 + d2*d1*d32)*d2 = -d256 = 32'hffffffffffffff00)
        // Result output to bank 14 starting at address 0
        logger.print("TEST gemv signed 5: matrix-vector mult: 2x2 x 2 tiles, 3s X 2s => 3 bit precision, input: alternating d={3,2}, w={-2,1}");
        writeDataRepeat(mvu, 'h0000000000000000, 'h0000, 2, 3);      // MSB  ={0,0}... \
        writeDataRepeat(mvu, 'hffffffffffffffff, 'h0001, 2, 3);      // MSB-1={1,1}... - = {b011,b110} = {d3,d2}
        writeDataRepeat(mvu, 'haaaaaaaaaaaaaaaa, 'h0002, 2, 3);      // LSB  ={1,0}... /
        writeWeightsRepeat(mvu, {BWBANKW/2{2'b10}}, 'h0, 4, 2);      // MSB  ={1,0}... \
        writeWeightsRepeat(mvu, {BWBANKW/2{2'b01}}, 'h1, 4, 2);      // LSB  ={0,1}... - = {b10,b01} = {-d2, d1}
        runGEMV(.mvu(mvu), .iprec(3), .wprec(2), .saddr(0), .baddr(0), .oprec(3), .omsb(9), 
           .iaddr(0), .waddr(0), .omvu(omvu), .obank(14), .oaddr(0), 
           .m_w(2), .m_h(2), .isign(1), .wsign(1), .scaler(scaler)); 


        // Expected result: accumulators get to value hfffffffffffffe7d, output to data memory is b100 for each element
        // (i.e. [hffffffffffffffff, 0000000000000000, 0000000000000000, ...)
        // (i.e. (d3*-d2*d32 + d2*d1*d31 + d1*d1*d1)*d3 = -d387 = 32'hfffffffffffffe7d)
        // Result output to bank 15 starting at address 0
        logger.print("TEST gemv signed 6: matrix-vector mult: 3x3 x 3 tiles, 3s X 2s => 3 bit precision, input: alternating d={3,2}, w={-2,1}, except one product term per tile with 1x1=1");
        writeDataRepeat(mvu, 'h0000000000000000, 'h0000, 3, 3);      // MSB  ={0,0}... \
        writeDataRepeat(mvu, 'hfffffffffffffffe, 'h0001, 3, 3);      // MSB-1={1,1}... - = {b011,b110} = {d3,d2}
        writeDataRepeat(mvu, 'haaaaaaaaaaaaaaab, 'h0002, 3, 3);      // LSB  ={1,0}... /
        writeWeightsRepeat(mvu, {BWBANKW/2{2'b10}}, 'h0, 9, 2);      // MSB  ={1,0}... \
        writeWeightsRepeat(mvu, {BWBANKW/2{2'b01}}, 'h1, 9, 2);      // LSB  ={0,1}... - = {b10,b01} = {-d2, d1}
        runGEMV(.mvu(mvu), .iprec(3), .wprec(2), .saddr(0), .baddr(0), .oprec(3), .omsb(9), 
           .iaddr(0), .waddr(0), .omvu(omvu), .obank(15), .oaddr(0), 
           .m_w(3), .m_h(3), .isign(1), .wsign(1), .scaler(scaler)); 


        // Expected result: accumulators get to value h0000000000000063, output to data memory is b001 for each element
        // (i.e. [0000000000000000, 0000000000000000, hffffffffffffffff, ...)
        // (i.e. (d3*d1*d32 + d2*-d1*d31 + d1*-d1*d1)*d3 = d99 = 32'h0000000000000063)
        // Result output to bank 16 starting at address 0
        logger.print("TEST gemv signed 7: matrix-vector mult: 3x3 x 3 tiles, 3s X 2s => 3 bit precision, input: alternating d={3,2}, w={-2,1}, except one product term per tile with 1x1=1");
        writeDataRepeat(mvu, 'h0000000000000000, 'h0000, 3, 3);      // MSB  ={0,0}... \
        writeDataRepeat(mvu, 'hfffffffffffffffe, 'h0001, 3, 3);      // MSB-1={1,1}... - = {b011,b110} = {d3,d2}
        writeDataRepeat(mvu, 'haaaaaaaaaaaaaaab, 'h0002, 3, 3);      // LSB  ={1,0}... /
        writeWeightsRepeat(mvu, {BWBANKW/2{2'b01}}, 'h0, 9, 2);      // MSB  ={1,0}... \
        writeWeightsRepeat(mvu, {BWBANKW/2{2'b11}}, 'h1, 9, 2);      // LSB  ={0,1}... - = {b10,b01} = {-d2, d1}
        runGEMV(.mvu(mvu), .iprec(3), .wprec(2), .saddr(0), .baddr(0), .oprec(3), .omsb(8), 
           .iaddr(0), .waddr(0), .omvu(omvu), .obank(16), .oaddr(0), 
           .m_w(3), .m_h(3), .isign(1), .wsign(1), .scaler(scaler)); 


    endtask

    task tb_setup();
        super.tb_setup();
    endtask

    task run();
        logger.print_banner("Testbench Run phase");
        // Run gemv tests, mvu0 -> mvu0
        logger.print_banner("GEMV tests: mvu0 -> mvu0");
        gemvTests(.mvu(0), .omvu('b00000001), .scaler(1));

        // Run signed gemv tests, mvu0 -> mvu0
        logger.print_banner("Signed GEMV tests: mvu0 -> mvu0");
        gemvSignedTests(.mvu(0), .omvu('b00000001), .scaler(1));

     
    endtask

    task report();
        super.report();
    endtask

endclass
