`include "testbench_base.sv"
`include "testbench_macros.svh"

class cdru_tester extends mvu_testbench_base;

    function new(Logger logger, virtual MVU_EXT_INTERFACE mvu_ext_if,  virtual APB_DV apb);
        super.new(logger, mvu_ext_if, apb);
    endfunction

    // Function: Calculate the flat address for data banks
    //
    function logic[BDBANKA-1 : 0] calc_addr(int bank, int offset);
        return 1024*bank + offset;
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
        int ibank;
        logic [BDBANKA-1 : 0] caddr;
        logic [BDBANKA-1 : 0] iaddr;

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
        ibank = 0;
        cbank = 1;
        iaddr = calc_addr(ibank, 0);
        caddr = calc_addr(cbank, 0);
        runGEMV(.mvu(mvu), .iprec(1), .wprec(1), .oprec(oprec), 
                .omsb(omsb), .iaddr(0), .waddr(0), .saddr(0), .baddr(0), .omvu(omvu), .obank(obank), .oaddr(oaddr), 
                .m_w(m_w), .m_h(m_h), .scaler(scaler));
        readData(mvu, caddr, cword_out, cgrnt);

        // Test 2 - read data on same MVU but same bank
        //
        // Setup:
        //      - one read comes from MVU itself over rdd port
        //      - one read comes from controller over rdc port
        //
        // Expected result:
        //      - one of the ports will not be granted access
        //

        

    endtask

endclass
