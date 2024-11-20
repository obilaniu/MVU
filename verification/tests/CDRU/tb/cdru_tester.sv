`include "testbench_base.sv"
`include "testbench_macros.svh"

class cdru_tester extends mvu_testbench_base;

    function new(Logger logger, virtual MVU_EXT_INTERFACE mvu_ext_if,  virtual APB_DV apb);
        super.new(logger, mvu_ext_if, apb);
    endfunction

    // --------------------------------
    // MAIN TESTBENCH RUN FUNCTION
    // --------------------------------
    task run();

        int mvu = 0;
        logic [BDBANKW-1 : 0] cword_out;
        logic [NMVU-1 : 0] cgrnt;
        int omvu[] = {0};
        int scaler = 0;
        int m_w; 
        int m_h;
        int oprec;
        int omsb;
        int obank;
        int oaddr;
        int cbank;
        int dbank;
        logic [BDBANKA-1 : 0] caddr;
        logic [BDBANKA-1 : 0] daddr;

        int jobread_latency = MEMRDLATENCY + 2;


        // Test 1 - read data on same MVU but different banks
        //
        // Setup:
        //      - one read comes from MVU itself over rdd port
        //      - one read comes from controller over rdc port
        //
        // Expected result: 
        //      - both MVU and controller are granted access
        //
        logger.print("TEST cdru 1: MVU and controller access different data banks");
        m_w = 1; 
        m_h = 1;
        oprec = 1;
        omsb = 0;
        obank = 1;
        oaddr = 0;
        dbank = 0;
        cbank = 1;
        daddr = calc_addr(dbank, 0);
        caddr = calc_addr(cbank, 0);
        writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr(daddr), .size(1), .stride(1));
        writeDataRepeat(.mvu(mvu), .word('haaaaaaaaaaaaaaaa), .startaddr(caddr), .size(1), .stride(1));
        setupGEMV(.mvu(mvu), .iprec(1), .wprec(1), .oprec(oprec), 
                .omsb(omsb), .iaddr(daddr), .waddr(0), .saddr(0), .baddr(0), .omvu(omvu), .obank(obank), .oaddr(oaddr), 
                .m_w(m_w), .m_h(m_h), .scaler(scaler));
        fork
            // Thread 1: run GEMV operation, which will do memory bank reads
            begin
                runGEMV(.mvu(mvu), .iprec(1), .wprec(1), .oprec(oprec), 
                        .omvu(omvu), .m_w(m_w), .m_h(m_h));
            end
            // Thread 2: controller reads data
            begin
                repeat (jobread_latency) @(posedge mvu_ext_if.clk);
                readData(mvu, caddr, cword_out, cgrnt);
            end
            // Thread 3: check signals and data
            begin
                
                repeat (jobread_latency+1) @(posedge mvu_ext_if.clk);
                if (peek_rdd_grnt(mvu) == 1 && peek_rdc_grnt(mvu) == 1) begin
                    logger.print("PASS");
                    test_stat.pass_cnt += 1;
                end
                else begin
                    logger.print($sformatf("FAIL: rdd_grnt and rdc_grnt signals are not both active"), "ERROR");
                    test_stat.fail_cnt += 1;
                end
            end
        join

        // Test 2 - read data on same MVU but same bank
        //
        // Setup:
        //      - one read comes from MVU itself over rdd port
        //      - one read comes from controller over rdc port
        //
        // Expected result:
        //      - one of the ports will not be granted access
        //
        logger.print("TEST cdru 2: MVU and controller access same data bank");
        m_w = 1; 
        m_h = 1;
        oprec = 1;
        omsb = 0;
        obank = 1;
        oaddr = 0;
        dbank = 0;
        cbank = 0;
        daddr = calc_addr(dbank, 0);
        caddr = calc_addr(cbank, 0);
        writeDataRepeat(.mvu(mvu), .word('hffffffffffffffff), .startaddr(daddr), .size(1), .stride(1));
        writeDataRepeat(.mvu(mvu), .word('haaaaaaaaaaaaaaaa), .startaddr(caddr), .size(1), .stride(1));
        setupGEMV(.mvu(mvu), .iprec(1), .wprec(1), .oprec(oprec), 
                .omsb(omsb), .iaddr(daddr), .waddr(0), .saddr(0), .baddr(0), .omvu(omvu), .obank(obank), .oaddr(oaddr), 
                .m_w(m_w), .m_h(m_h), .scaler(scaler));
        fork
            // Thread 1: run GEMV operation, which will do memory bank reads
            begin
                runGEMV(.mvu(mvu), .iprec(1), .wprec(1), .oprec(oprec), 
                        .omvu(omvu), .m_w(m_w), .m_h(m_h));
            end
            // Thread 2: controller reads data
            begin
                repeat (jobread_latency) @(posedge mvu_ext_if.clk);
                readData(mvu, caddr, cword_out, cgrnt);
            end
            // Thread 3: check signals and data
            begin
                
                repeat (jobread_latency+1) @(posedge mvu_ext_if.clk);
                if (peek_rdd_grnt(mvu) == 1 && peek_rdc_grnt(mvu) == 0) begin
                    logger.print("PASS");
                    test_stat.pass_cnt += 1;
                end
                else begin
                    logger.print($sformatf("FAIL: rdd_grnt=%b and rdc_grnt=%b.  Signals are not correct", peek_rdd_grnt(mvu), peek_rdc_grnt(mvu)), "ERROR");
                    test_stat.fail_cnt += 1;
                end
            end
        join


    endtask

endclass
