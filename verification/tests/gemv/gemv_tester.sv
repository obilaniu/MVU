`include "testbench_base.sv"

class gemv_tester extends mvu_testbench_base;

    function new(Logger logger, virtual mvu_interface intf);
        super.new(logger, intf);
    endfunction

    //
    // Matrix-vector multiplication (GEMV) test
    //
    task gemvTests(int mvu, int omvu, int scaler);

        logger.print_banner("Matrix-vector multiplication (GEMV) test");

        logger.print("TEST gemv 1: matrix-vector mult: 1x1 x 1 tiles, 1x1 => 1 bit precision, , input=all 0's");
        runGEMV(.mvu(mvu), .iprec(1), .wprec(1), .oprec(1), 
                .omsb(0), .iaddr(0), .waddr(0), .omvu(omvu), .obank(0), .oaddr(0), 
                .m_w(1), .m_h(1), .scaler(scaler));


        logger.print("TEST gemv 2: matrix-vector mult: 2x2 x 2 tiles, 1x1 => 1 bit precision, input=all 0's");
        runGEMV(.mvu(mvu), .iprec(1), .wprec(1), .oprec(1), 
                .omsb(0), .iaddr(0), .waddr(0), .omvu(omvu), .obank(0), .oaddr(0), 
                .m_w(2), .m_h(2), .scaler(scaler));


        // TEST 3
        // Expected result: accumulators get to value h480, output to data memory is b10 for each element
        // (i.e. [hffffffffffffffff, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. d3*d3*d64*d2 = d1152 = h480)
        // Result output to bank 1 starting at address 0
        logger.print("TEST gemv 3: matrix-vector mult: 2x2 x 2 tiles, 2x2 => 2 bit precision, , input=all 1's");
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
        logger.print("TEST gmev 4: matrix-vector mult: 3x3 x 3 tiles, 2x2 => 3 bit precision, input=all 1's");
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
        logger.print("TEST gemv 5: matrix-vector mult: 3x3 x 3 tiles, 2x2 => 3 bit precision, input=b10, weights=b01");
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

        logger.print_banner("Matrix-vector signed multiplication (GEMV) test");

        // Expected result: accumulators get to value hffffffffffffff80, output to data memory is b10 for each element
        // (i.e. [hffffffffffffffff, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. d1*-d1*d64*d2 = -d128 = 32'hffffffffffffff80)
        // Result output to bank 10 starting at address 0
        logger.print("TEST gemv signed 1: matrix-vector mult: 2x2 x 2 tiles, 2u X 2s => 2 bit precision, input: d=1, w=-1");
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
        logger.print("TEST gemv signed 2: matrix-vector mult: 2x2 x 2 tiles, 2s X 2u => 2 bit precision, input: d=-2, w=3");
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
        logger.print("TEST gemv signed 3: matrix-vector mult: 2x2 x 2 tiles, 2s X 2s => 2 bit precision, input: d=-2, w=-1");
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
        logger.print("TEST gemv signed 4: matrix-vector mult: 2x2 x 2 tiles, 3s X 2s => 3 bit precision, input: d=3, w=-2");
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
        logger.print("TEST gemv signed 5: matrix-vector mult: 2x2 x 2 tiles, 3s X 2s => 3 bit precision, input: alternating d={3,2}, w={-2,1}");
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
        logger.print("TEST gemv signed 6: matrix-vector mult: 3x3 x 3 tiles, 3s X 2s => 3 bit precision, input: alternating d={3,2}, w={-2,1}, except one product term per tile with 1x1=1");
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
        logger.print("TEST gemv signed 7: matrix-vector mult: 3x3 x 3 tiles, 3s X 2s => 3 bit precision, input: alternating d={3,2}, w={-2,1}, except one product term per tile with 1x1=1");
        writeDataRepeat(mvu, 'h0000000000000000, 'h0000, 3, 3);      // MSB  ={0,0}... \
        writeDataRepeat(mvu, 'hfffffffffffffffe, 'h0001, 3, 3);      // MSB-1={1,1}... - = {b011,b110} = {d3,d2}
        writeDataRepeat(mvu, 'haaaaaaaaaaaaaaab, 'h0002, 3, 3);      // LSB  ={1,0}... /
        writeWeightsRepeat(mvu, {BWBANKW/2{2'b01}}, 'h0, 9, 2);      // MSB  ={1,0}... \
        writeWeightsRepeat(mvu, {BWBANKW/2{2'b11}}, 'h1, 9, 2);      // LSB  ={0,1}... - = {b10,b01} = {-d2, d1}
        runGEMV(.mvu(mvu), .iprec(3), .wprec(2), .oprec(3), .omsb(8), 
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

        // Repeat the unsigned gemv tests, mvu0 -> mvu1
        logger.print_banner("GEMV tests: mvu0 -> mvu1");
        gemvTests(.mvu(0), .omvu('b00000010), .scaler(1));

        // Repeat the unsigned gemv tests, mvu2 -> mvu3
        logger.print_banner("GEMV tests: mvu2 -> mvu3");
        gemvTests(.mvu(2), .omvu('b00001000), .scaler(1));

        // Repeat the unsigned gemv tests, mvu3-> mvu2
        logger.print_banner("GEMV tests: mvu3 -> mvu2");
        gemvTests(.mvu(3), .omvu('b00000100), .scaler(1));

        // Repeat the unsigned gemv tests, mvu7-> mvu0
        // Blank out mvu0's memory banks first
        logger.print_banner("GEMV tests: mvu7 -> mvu0");
        writeDataRepeat(0, 'h0000000000000000, 'h0000, 9, 1);
        writeDataRepeat(0, 'h0000000000000000, {5'b00001, 10'b0000000000}, 9, 1);
        writeDataRepeat(0, 'h0000000000000000, {5'b00010, 10'b0000000000}, 9, 1);
        writeDataRepeat(0, 'h0000000000000000, {5'b00011, 10'b0000000000}, 9, 1);
        gemvTests(.mvu(7), .omvu('b00000001), .scaler(1));

        //
        // Broadcast tests
        //

        // Repeat the unsigned gemv tests, mvu4-> mvu5, mvu6
        logger.print_banner("GEMV tests: mvu4 -> mvu5,6");
        gemvTests(.mvu(4), .omvu('b01100000), .scaler(1));

        endtask

    task report();
        super.report();
    endtask

endclass
