`include "testbench_base.sv"

class highprecision_tester extends mvu_testbench_base;

    function new(Logger logger, virtual mvu_interface intf);
        super.new(logger, intf);
    endfunction

    //
    // Matrix-vector multiplication (GEMV) test
    //
    task gemvHPOutputTest(int mvu, int hpomvu, int usepooler4hpout=0, int scaler=1);

        // TEST 1
        // Expected result: accumulators get to value h480, output to data memory is b10 for each element
        // (i.e. [hffffffffffffffff, 0000000000000000, hffffffffffffffff, 0000000000000000, ...)
        // (i.e. d3*d3*d64*d2 = d1152 = h480)
        // Low-precision result output to bank 1 starting at address 0 of mvu.
        // High-precision result output to hpomvu starting at address 0 of high-precision memory
        logger.print("TEST gemv HP out: matrix-vector mult: 2x2 x 2 tiles, 2x2 => 2 bit precision, , input=all 1's");
        intf.ohpmvusel[mvu] = hpomvu;
        intf.usepooler4hpout[mvu] = usepooler4hpout;
        writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr('h0000), .size(4), .stride(1));
        writeWeightsRepeat(.mvu(mvu), .word({BWBANKW{1'b1}}), .startaddr('h0), .size(8), .stride(1));
        runGEMV(.mvu(mvu), .iprec(2), .wprec(2), .saddr(0), .baddr(0), .oprec(2), .omsb(10), 
                .iaddr(0), .waddr(0), .omvu(mvu), .obank(1), .oaddr(0), 
                .m_w(2), .m_h(2), .scaler(scaler));

    endtask


    task tb_setup();
        super.tb_setup();
    endtask

    task run();
        logger.print_banner("High-precision datapath testbench: run phase");

        //
        // High-precision nterconnect tests
        // 
        // Run a GEMV operation and send the resulting high-precision output
        // of scaler1 to another MVU
        // 

        // High-precision output test: mvu0 -> mvu1
        logger.print_banner("Test: mvu0 -> mvu1");
        gemvHPOutputTest(.mvu(0), .hpomvu('b00000010), .scaler(1));

        //
        // Broadcast tests
        //


        endtask

    task report();
        super.report();
    endtask

endclass
