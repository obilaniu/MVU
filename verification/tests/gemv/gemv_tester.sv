`include "testbench_base.sv"
`include "testbench_macros.svh"

class gemv_tester extends mvu_testbench_base;

    function new(Logger logger, virtual MVU_EXT_INTERFACE mvu_ext_if,  virtual APB_DV apb);
        super.new(logger, mvu_ext_if, apb);
    endfunction

    //
    // Checks the results in data memory match a given array of expected words
    //
    function bit checkResult(int omvu[], int bank, int startaddr, logic [BDBANKW-1 : 0] expected[]);
        logic [BWBANKW-1 : 0] memdata;
        for (int m=0; m < omvu.size; m++) begin
            for (int i=0; i < expected.size; i++) begin
                memdata = peekData(.mvu(omvu[m]), .bank(bank), .addr(startaddr + i));
                if (memdata != expected[i]) begin
                    logger.print($sformatf("FAIL: Value h%16h at bank %2d addr h%h in MVU %1d does not match expected h%16h", memdata, bank, startaddr+i, omvu[m], expected[i]), "ERROR");
                    test_stat.fail_cnt += 1;
                    return 0;
                end
            end
            logger.print("PASS");
            test_stat.pass_cnt += 1;
        end
        return 1;
    endfunction

    //
    // Calculates expected result
    //
    function automatic void calcExpected(int d, int w, int s, int tile_w, int tile_h, int oprec, int omsb, ref logic[BDBANKW-1:0] expected[]);
        int value;
        int idx;
        int obit;
        
        expected = new[tile_h*oprec];
        value = s * 64 * tile_w * d * w;
        value = value >> (omsb-oprec+1);
        for (int j = 0; j < tile_h; j++) begin
            for (int i = 0; i < oprec; i++) begin
                idx = j*oprec + i;
                obit = oprec - i - 1;
                if (value[obit] == 'b1) begin
                    expected[idx] = 64'hffffffffffffffff;
                end else begin
                    expected[idx] = 64'h0000000000000000;
                end
            end
        end
        return;
    endfunction

    //
    // Calculated GEMV
    // 
    function automatic void calcGEMV(int m[][], int v[], ref int out[]);
        out = new[v.size];

        foreach(m[j]) begin
            out[j] = 0;
            foreach(v[i]) begin
                out[j] += m[j][i]*v[i];
            end
        end

    endfunction

    //
    // Calculated expected results from the full input matrix and vector
    //
    function automatic void calcExpectedFull(int d[], int w[][], int s, int tile_w, int tile_h, int oprec, int omsb, ref logic[BDBANKW-1:0] expected[]);
        // Compute GEMV
        int expected_vector[];
        logic[N-1:0] value;
        
        calcGEMV(w, d, expected_vector);
        
        // Construct the transposed formatted vector
        expected = new[tile_h*oprec];
        expected = '{default: '0};
        for (int j = 0; j < tile_h; j++) begin
            for (int i = 0; i < 64; i++) begin
                value = expected_vector[j*64 + i] * s;
                value = value >> (omsb-oprec+1);
                for (int k = 0; k < oprec; k++) begin
                    expected[j*oprec + k] |= (value[oprec-1-k] << i);
                end
            end
        end

    endfunction

    //
    // Generates repeated pattern for a matrix
    //
    function automatic void generateRepeatPatternMatrix(int d[], int width, int height=1, ref int out[][]);
        out = new[height];
        for (int j=0; j < height; j++) begin
            out[j] = new[width];
            for (int i=0; i < width; i++) begin
                out[j][i] = d[i % d.size];
            end
        end
    endfunction

    // 
    // Generates a repeated pattern for a vector
    //
    function automatic void generateRepeatPatternVector(int d[], int width, ref int out[]);
        int innerout[][];
        generateRepeatPatternMatrix(d, width, 1, innerout);
        out = innerout[0];
    endfunction

    //
    // Matrix-vector multiplication (GEMV) test
    //
    task gemvTests(int mvu, int omvu[], int scaler);
        int d[];
        int w[][];
        int tile_w;
        int tile_h;
        logic[BDBANKW-1:0] expected[];

        logger.print_banner("Matrix-vector multiplication (GEMV) test");

        // TEST 1
        // All zeros
        logger.print("TEST gemv 1: matrix-vector mult: 1x1 x 1 tiles, 1x1 => 1 bit precision, , input=all 0's");
        tile_w = 1;
        tile_h = 1;
        d = new[BDBANKW];
        foreach (d[i]) d[i] = 0;
        w = new[BWBANKW];
        foreach (w[i]) begin
            w[i] = new[BWBANKW];
            foreach (w[i][j]) w[i][j] = 0;
        end
        writeDataRepeat(.mvu(mvu), .word('h0000000000000000), .startaddr('h0000), .size(1), .stride(1));
        writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b0}}), .startaddr('h0), .size(1), .stride(1));
        runGEMV(.mvu(mvu), .iprec(1), .wprec(1), .oprec(1), 
                .omsb(0), .iaddr(0), .waddr(0), .saddr(0), .baddr(0), .omvu(omvu), .obank(1), .oaddr(0), 
                .m_w(1), .m_h(1), .scaler(scaler));
        calcExpected(.d(0), .w(0), .s(scaler), .tile_w(1), .tile_h(1), .oprec(1), .omsb(0), .expected(expected));
        checkResult(.omvu(omvu), .bank(1), .startaddr(0), .expected(expected));

        // TEST 2
        // All zeros
        logger.print("TEST gemv 2: matrix-vector mult: 2x2 x 2 tiles, 1x1 => 1 bit precision, input=all 0's");
        writeDataRepeat(.mvu(mvu), .word('h0000000000000000), .startaddr('h0000), .size(2), .stride(1));
        writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b0}}), .startaddr('h0), .size(4), .stride(1));
        runGEMV(.mvu(mvu), .iprec(1), .wprec(1), .oprec(1), 
                .omsb(0), .iaddr(0), .waddr(0), .saddr(0), .baddr(0), .omvu(omvu), .obank(2), .oaddr(0), 
                .m_w(2), .m_h(2), .scaler(scaler));
        calcExpected(.d(0), .w(0), .s(scaler), .tile_w(2), .tile_h(2), .oprec(1), .omsb(0), .expected(expected));
        checkResult(.omvu(omvu), .bank(2), .startaddr(0), .expected({64'h0}));

        // TEST 3
        // Expected result: accumulators get to value h480, output to data memory is b10 for each element
        // (i.e. [hffffffffffffffff, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. d3*d3*d64*d2 = d1152 = h480)
        // Result output to bank 1 starting at address 0
        logger.print("TEST gemv 3: matrix-vector mult: 2x2 x 2 tiles, 2x2 => 2 bit precision, , input=all 1's");
        writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr('h0000), .size(4), .stride(1));
        writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b1}}), .startaddr('h0), .size(8), .stride(1));
        runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .saddr(0), .baddr(0), .oprec(2), .omsb(10), 
                .iaddr(0), .waddr(0), .omvu(omvu), .obank(3), .oaddr(0), 
                .m_w(2), .m_h(2), .scaler(scaler));
        calcExpected(.d(3), .w(3), .s(scaler), .tile_w(2), .tile_h(2), .oprec(2), .omsb(10), .expected(expected));
        checkResult(.omvu(omvu), .bank(3), .startaddr(0), .expected(expected)); //.expected({64'hffffffffffffffff, 64'h0, 64'hffffffffffffffff, 64'h0}));

        // TEST 4
        // Expected result: accumulators get to value h6c0, output to data memory is b110 for each element
        // (i.e. [hffffffffffffffff, hffffffffffffffff, 0000000000000000, hffffffffffffffff, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. d3*d3*d64*d3 = d1728 = h6c0)
        // Result output to bank 2 starting at address 0
        logger.print("TEST gmev 4: matrix-vector mult: 3x3 x 3 tiles, 2x2 => 3 bit precision, input=all 1's");
        writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr('h0000), .size(6), .stride(1));
        writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b1}}), .startaddr('h0), .size(18), .stride(1));
        runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .saddr(0), .baddr(0), .oprec(3), .omsb(10), 
                .iaddr(0), .waddr(0), .omvu(omvu), .obank(4), .oaddr(0), 
                .m_w(3), .m_h(3), .scaler(scaler));
        calcExpected(.d(3), .w(3), .s(scaler), .tile_w(3), .tile_h(3), .oprec(3), .omsb(10), .expected(expected));
        checkResult(.omvu(omvu), .bank(4), .startaddr(0), .expected(expected));

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
                .iaddr(0), .waddr(0), .omvu(omvu), .obank(5), .oaddr(0), 
                .m_w(3), .m_h(3), .scaler(scaler));
        calcExpected(.d(2), .w(1), .s(scaler), .tile_w(3), .tile_h(3), .oprec(3), .omsb(10), .expected(expected));
        checkResult(.omvu(omvu), .bank(5), .startaddr(0), .expected(expected));

    endtask

    //
    // Test signed Matrix-Vector multiplication (gemv signed)
    //
    // Note: the expected values in the comments of each test assume scaler=1
    //
    task gemvSignedTests(int mvu, int omvu[], int scaler);
        logic[BDBANKW-1:0] expected[];
        int weights[][];
        int data[];
        int expectedv[];
        int m_w; 
        int m_h;
        int oprec;
        int omsb;
        int obank;
        int oaddr;

        logger.print_banner("Matrix-vector signed multiplication (GEMV) test");

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
        calcExpected(.d(1), .w(-1), .s(scaler), .tile_w(2), .tile_h(2), .oprec(2), .omsb(7), .expected(expected));
        checkResult(.omvu(omvu), .bank(10), .startaddr(0), .expected(expected));     


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
        calcExpected(.d(-2), .w(3), .s(scaler), .tile_w(2), .tile_h(2), .oprec(2), .omsb(10), .expected(expected));
        checkResult(.omvu(omvu), .bank(11), .startaddr(0), .expected(expected));


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
        calcExpected(.d(-2), .w(-1), .s(scaler), .tile_w(2), .tile_h(2), .oprec(2), .omsb(9), .expected(expected));
        checkResult(.omvu(omvu), .bank(12), .startaddr(0), .expected(expected));

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
        calcExpected(.d(3), .w(-2), .s(scaler), .tile_w(2), .tile_h(2), .oprec(3), .omsb(11), .expected(expected));
        checkResult(.omvu(omvu), .bank(13), .startaddr(0), .expected(expected));

        // Expected result: accumulators get to value hffffffffffffff00, output to data memory is b110 for each element
        // (i.e. [hffffffffffffffff, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. (d3*-d2*d32 + d2*d1*d32)*d2 = -d256 = 32'hffffffffffffff00)
        // Result output to bank 14 starting at address 0
        logger.print("TEST gemv signed 5: matrix-vector mult: 2x2 x 2 tiles, 3s X 2s => 3 bit precision, input: alternating d={3,2}, w={-2,1}");
        m_w = 2; 
        m_h = 2;
        oprec = 3;
        omsb = 9;
        obank = 14;
        oaddr = 0;
        generateRepeatPatternMatrix({-2, 1}, N*m_w, N*m_h, weights);
        generateRepeatPatternVector({3, 2}, N*m_w, data);
        writeDataRepeat(mvu, 'h0000000000000000, 'h0000, 2, 3);      // MSB  ={0,0}... \
        writeDataRepeat(mvu, 'hffffffffffffffff, 'h0001, 2, 3);      // MSB-1={1,1}... - = {b011,b110} = {d3,d2}
        writeDataRepeat(mvu, 'haaaaaaaaaaaaaaaa, 'h0002, 2, 3);      // LSB  ={1,0}... /
        writeWeightsRepeat(mvu, {BWBANKW/2{2'b10}}, 'h0, 4, 2);      // MSB  ={1,0}... \
        writeWeightsRepeat(mvu, {BWBANKW/2{2'b01}}, 'h1, 4, 2);      // LSB  ={0,1}... - = {b10,b01} = {-d2, d1}
        runGEMV(.mvu(mvu), .iprec(3), .wprec(2), .saddr(0), .baddr(0), .oprec(oprec), .omsb(omsb), 
           .iaddr(0), .waddr(0), .omvu(omvu), .obank(obank), .oaddr(oaddr), 
           .m_w(m_w), .m_h(m_h), .isign(1), .wsign(1), .scaler(scaler));
        calcExpectedFull(.d(data), .w(weights), .s(scaler), .tile_w(m_w), .tile_h(m_h), .oprec(oprec), .omsb(omsb), .expected(expected));
        checkResult(.omvu(omvu), .bank(obank), .startaddr(oaddr), .expected(expected));


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
        //logger.print_banner("GEMV tests: mvu0 -> mvu0");
        //gemvTests(.mvu(0), .omvu({0}), .scaler(1));

        // Run signed gemv tests, mvu0 -> mvu0
        logger.print_banner("Signed GEMV tests: mvu0 -> mvu0");
        gemvSignedTests(.mvu(0), .omvu({0}), .scaler(1));

        // Repeat signed gemv tests, but with scaler set to 2
        // Test 1 -> -d256, b00 in bank 10
        // Test 2 -> -d1536, b01 in bank 11
        // Test 3 -> d512, b10 in bank 12
        // Test 4 -> -d1536, b101 in bank 13
        // Test 5 -> -d512, b100 in bank 14
        // Test 6 -> -d774, b001 in bank 15
        // Test 7 -> d198, b011 in bank 16
        //logger.print_banner("Signed GEMV tests: mvu0 -> mvu0 with scaler=2");
        //gemvSignedTests(.mvu(0), .omvu({0}), .scaler(2));

        // Repeat signed gemv tests, but with scaler set to 5, mvu0 -> mvu0
        // Expected outcomes:
        // Test 1 -> -d640, b10 in bank 10
        // Test 2 -> -d3840, b00 in bank 11
        // Test 3 -> d1280, b01 in bank 12
        // Test 4 -> -d3840, b000 in bank 13
        // Test 5 -> -d1280, b110 in bank 14
        // Test 6 -> -d1935, b000 in bank 15
        // Test 7 -> d495, b111 in bank 16
        //logger.print_banner("Signed GEMV tests: mvu0 -> mvu0 with scaler=5");
        //gemvSignedTests(.mvu(0), .omvu({0}), .scaler(5));

        //
        // Interconnect tests
        // 

        // Repeat the unsigned gemv tests, mvu0 -> mvu1
        //logger.print_banner("GEMV tests: mvu0 -> mvu1");
        //gemvTests(.mvu(0), .omvu({1}), .scaler(1));

        // Repeat the unsigned gemv tests, mvu2 -> mvu3
        //logger.print_banner("GEMV tests: mvu2 -> mvu3");
        //gemvTests(.mvu(2), .omvu({3}), .scaler(1));

        // Repeat the unsigned gemv tests, mvu3-> mvu2
        //logger.print_banner("GEMV tests: mvu3 -> mvu2");
        //gemvTests(.mvu(3), .omvu({2}), .scaler(1));

        // Repeat the unsigned gemv tests, mvu7-> mvu0
        // Blank out mvu0's memory banks first
        //logger.print_banner("GEMV tests: mvu7 -> mvu0");
        //writeDataRepeat(0, 'h0000000000000000, 'h0000, 9, 1);
        //writeDataRepeat(0, 'h0000000000000000, {5'b00001, 10'b0000000000}, 9, 1);
        //writeDataRepeat(0, 'h0000000000000000, {5'b00010, 10'b0000000000}, 9, 1);
        //writeDataRepeat(0, 'h0000000000000000, {5'b00011, 10'b0000000000}, 9, 1);
        //gemvTests(.mvu(7), .omvu({0}), .scaler(1));

        //
        // Broadcast tests
        //

        // Repeat the unsigned gemv tests, mvu4-> mvu5, mvu6
        //logger.print_banner("GEMV tests: mvu4 -> mvu5,6");
        //gemvTests(.mvu(4), .omvu({5,6}), .scaler(1));

        endtask

    task report();
        super.report();
    endtask

endclass
