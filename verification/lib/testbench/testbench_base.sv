`include "testbench_macros.svh"
`include "testbench_config.sv"

import utils::*;
import testbench_pkg::*;
import mvu_pkg::*;

class mvu_testbench_base extends BaseObj;

    string firmware;
    virtual APB_DV #(
      .ADDR_WIDTH(mvu_pkg::APB_ADDR_WIDTH),
      .DATA_WIDTH(mvu_pkg::APB_DATA_WIDTH)
    ) apb_slave_dv;
    apb_test::apb_driver #(
        .ADDR_WIDTH(mvu_pkg::APB_ADDR_WIDTH),
        .DATA_WIDTH(mvu_pkg::APB_DATA_WIDTH),
        .TA        (mvu_pkg::APB_ApplTime  ),
        .TT        (mvu_pkg::APB_TestTime  )
    ) apb_master;
    virtual MVU_EXT_INTERFACE mvu_ext_if;
    test_stats_t test_stat;
    tb_config cfg;

    // APB signals
    logic               apb_resp;
    mvu_pkg::apb_addr_t apb_addr;
    mvu_pkg::apb_data_t apb_data;
    mvu_pkg::apb_strb_t apb_strb;

    function new (Logger logger, virtual MVU_EXT_INTERFACE mvu_ext_if, virtual APB_DV apb_slave_dv);
        super.new(logger);
        cfg = new(logger);
        void'(cfg.parse_args());
        this.apb_slave_dv = apb_slave_dv;
        this.apb_master = new(this.apb_slave_dv);
        this.mvu_ext_if = mvu_ext_if;
    endfunction

// =================================================================================================
// Utility Tasks
// =================================================================================================

    task controllerMemTest();
        logic unsigned [BDBANKW-1 : 0] word;
        logic unsigned [NMVU-1 : 0] grnt;
        logger.print_banner("Controller memory access test");
        // Read/Write tests
        writeData(0, 'hdeadbeefdeadbeef, 0);
        readData(0, 0, word, grnt);
        logger.print($sformatf("word=%x, grnt=%b", word, grnt));
        writeData(0, 'hbeefdeadbeefdead, 1);
        readData(0, 1, word, grnt);
        logger.print($sformatf("word=%x, grnt=%b", word, grnt));
    endtask

    //
    // Scaler memory write test
    //
    task scalerMemTest();
        logger.print_banner("Scaler memory write test");
        writeScalersRepeat(0, {(BSBANKW/32){'hdeadbeef}}, 0, 4, 1);
        for(int i=0; i<10; i++) @(posedge mvu_ext_if.clk);
    endtask

    //
    // Bias memory write test
    //
    task biasMemTest();
        logger.print_banner("Bias memory write test");
        writeBiasesRepeat(0, {(BBBANKW/32){'hdeadbeef}}, 0, 4, 1);
    endtask


    task checkmvu(int mvu);
        if (mvu > N) begin
            logger.print($sformatf("MVU specificed %d is greater than number of MVUs %d", mvu, N), "Error");
            $finish();
        end
    endtask

    task writeData(int mvu, unsigned[BDBANKW-1 : 0] word, unsigned[BDBANKA-1 : 0] addr);
        checkmvu(mvu);
        mvu_ext_if.wrc_addr = addr;
        mvu_ext_if.wrc_word = word;
        mvu_ext_if.wrc_en[mvu] = 1'b1;
        @(posedge mvu_ext_if.clk)
        mvu_ext_if.wrc_en[mvu] = 1'b0;
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
        mvu_ext_if.wrw_addr[mvu*BWBANKA +: BWBANKA] = addr;
        mvu_ext_if.wrw_word[mvu*BWBANKW +: BWBANKW] = word;
        mvu_ext_if.wrw_en[mvu] = 1'b1;
        @(posedge mvu_ext_if.clk)
        mvu_ext_if.wrw_en[mvu] = 1'b0;
    endtask

    task writeWeightsRepeat(int mvu, logic unsigned[BWBANKW-1 : 0] word, logic unsigned[BWBANKA-1 : 0] startaddr, int size, int stride=1);
        checkmvu(mvu);
        for (int i = 0; i < size; i++) begin
            writeWeights(.mvu(mvu), .word(word), .addr(startaddr));
            @(posedge mvu_ext_if.clk)
            startaddr = startaddr + stride;
        end
    endtask

    task writeScalers(int mvu, unsigned[BSBANKW-1 : 0] word, unsigned[BSBANKA-1 : 0] addr);
        checkmvu(mvu);
        mvu_ext_if.wrs_addr[mvu*BSBANKA +: BSBANKA] = addr;
        mvu_ext_if.wrs_word[mvu*BSBANKW +: BSBANKW] = word;
        mvu_ext_if.wrs_en[mvu] = 1'b1;
        @(posedge mvu_ext_if.clk)
        mvu_ext_if.wrs_en[mvu] = 1'b0;
    endtask

    task writeScalersRepeat(int mvu, logic unsigned[BSBANKW-1 : 0] word, logic unsigned[BSBANKA-1 : 0] startaddr, int size, int stride=1);
        checkmvu(mvu);
        for (int i = 0; i < size; i++) begin
            writeScalers(.mvu(mvu), .word(word), .addr(startaddr));
            @(posedge mvu_ext_if.clk)
            startaddr = startaddr + stride;
        end
    endtask

    task writeBiases(int mvu, unsigned[BBBANKW-1 : 0] word, unsigned[BBBANKA-1 : 0] addr);
        checkmvu(mvu);
        mvu_ext_if.wrb_addr[mvu*BBBANKA +: BBBANKA] = addr;
        mvu_ext_if.wrb_word[mvu*BBBANKW +: BBBANKW] = word;
        mvu_ext_if.wrb_en[mvu] = 1'b1;
        @(posedge mvu_ext_if.clk)
        mvu_ext_if.wrb_en[mvu] = 1'b0;
    endtask

    task writeBiasesRepeat(int mvu, logic unsigned[BBBANKW-1 : 0] word, logic unsigned[BBBANKA-1 : 0] startaddr, int size, int stride=1);
        checkmvu(mvu);
        for (int i = 0; i < size; i++) begin
            writeBiases(.mvu(mvu), .word(word), .addr(startaddr));
            @(posedge mvu_ext_if.clk)
            startaddr = startaddr + stride;
        end
    endtask

    task automatic readData(int mvu, logic unsigned [BDBANKA-1 : 0] addr, ref logic unsigned [BDBANKW-1 : 0] word, ref logic unsigned [NMVU-1 : 0] grnt);
        checkmvu(mvu);
        mvu_ext_if.rdc_addr[mvu*BDBANKA +: BDBANKA] = addr;
        mvu_ext_if.rdc_en[mvu] = 1;
        @(posedge mvu_ext_if.clk)
        grnt[mvu] = mvu_ext_if.rdc_grnt[mvu];
        mvu_ext_if.rdc_en[mvu] = 0;
        @(posedge mvu_ext_if.clk)
        @(posedge mvu_ext_if.clk)
        word = mvu_ext_if.rdc_word[mvu*BDBANKW +: BDBANKW];
    endtask

    // Initialize scaler and bias memories
    task scalerMemInit(int mvu);
        writeScalersRepeat(.mvu(mvu), .word({(BSBANKW){16'h0001}}), .startaddr(0), .size(2**BSBANKA));
    endtask

    task biasMemInit(int mvu);
        writeBiasesRepeat(.mvu(mvu), .word({(BBBANKW){32'h00000000}}), .startaddr(0), .size(2**BBBANKA));
    endtask


// Executes a GMEV
    // task automatic runGEMV(
    //     int mvu,            // MVU number to execute on
    //     int iprec,
    //     int wprec,
    //     int oprec,
    //     int omsb,
    //     int iaddr,
    //     int waddr,
    //     byte omvu,          // output mvus
    //     int obank,
    //     int oaddr,
    //     int m_w,            // Matrix width / vector length
    //     int m_h,            // Matrix height
    //     int saddr = 0,
    //     int baddr = 0,
    //     logic isign = 0,    // True if input data are signed
    //     logic wsign = 0,    // True if weights are signed
    //     int scaler = 1,
    //     logic usescalarmem = 0,
    //     logic usebiasmem = 0
    // );

    //     logic [BDBANKABS-1 : 0]     obank_sel = obank;
    //     logic [BDBANKAWS-1 : 0]     oword_sel = oaddr;

    //     int countdown_val = m_w * m_h * iprec * wprec;
    //     int pipeline_latency = 9;
    //     int buffer_cycles = 10;
    //     int cyclecount = countdown_val + pipeline_latency + oprec + buffer_cycles;

    //     // Check that the MVU number is okay
    //     checkmvu(mvu);

    //     // Configure paramters on the port of the DUT
    //     intf.wprecision[mvu*BPREC +: BPREC] = wprec;
    //     intf.iprecision[mvu*BPREC +: BPREC] = iprec;
    //     intf.oprecision[mvu*BPREC +: BPREC] = oprec;
    //     intf.quant_msbidx[mvu*BQMSBIDX +: BQMSBIDX] = omsb;
    //     intf.wbaseaddr[mvu*BWBANKA +: BWBANKA] = waddr;
    //     intf.ibaseaddr[mvu*BDBANKA +: BDBANKA] = iaddr;
    //     intf.sbaseaddr[mvu*BSBANKA +: BSBANKA] = saddr;
    //     intf.bbaseaddr[mvu*BBBANKA +: BBBANKA] = baddr;
    //     intf.obaseaddr[mvu*BDBANKA +: BDBANKA] = {obank_sel, oword_sel};
    //     intf.omvusel[mvu*NMVU +: NMVU]         = omvu;                   // Set the output MVUs
    //     intf.wjump[mvu][0] = wprec;                        // move 1 tile ahead to next tile row
    //     intf.wjump[mvu][1] = -wprec*(m_w-1);               // Move back to tile 0 of current tile row
    //     intf.wjump[mvu][2] = wprec;                        // Move ahead one tile
    //     intf.wjump[mvu][3] = 0;                            // Don't need this for GEMV
    //     intf.wjump[mvu][4] = 0;                            // Don't need this for GEMV
    //     intf.ijump[mvu][0] = -iprec*(m_w-1);               // Move back to beginning vector 
    //     intf.ijump[mvu][1] = iprec;                        // Move ahead one tile
    //     intf.ijump[mvu][2] = 0;                            // Don't need this for GEMV
    //     intf.ijump[mvu][3] = 0;                            // Don't need this for GEMV
    //     intf.ijump[mvu][4] = 0;                            // Don't need this for GEMV
    //     intf.ojump[mvu][0] = 0;                            // Don't need this for GEMV
    //     intf.ojump[mvu][1] = 0;                            // Don't need this for GEMV
    //     intf.ojump[mvu][2] = 0;                            // Don't need this for GEMV
    //     intf.ojump[mvu][3] = 0;                            // Don't need this for GEMV
    //     intf.ojump[mvu][4] = 0;                            // Don't need this for GEMV
    //     intf.wlength[mvu][1] = wprec*iprec-1;              // number bit combinations minus 1
    //     intf.wlength[mvu][2] = m_w-1;                      // Number tiles in width minus 1
    //     intf.wlength[mvu][3] = 0;                          // Don't need this for GEMV
    //     intf.wlength[mvu][4] = 0;                          // Don't need this for GEMV
    //     intf.ilength[mvu][1] = m_h-1;                      // Number tiles in height minus 1
    //     intf.ilength[mvu][2] = 0;                          // Don't need this for GEMV
    //     intf.ilength[mvu][3] = 0;                          // Don't need this for GEMV
    //     intf.ilength[mvu][4] = 0;                          // Don't need this for GEMV
    //     intf.olength[mvu][1] = 1;                          // Write out sequentially
    //     intf.olength[mvu][2] = 0;                          // Don't need this for GEMV
    //     intf.olength[mvu][3] = 0;                          // Don't need this for GEMV
    //     intf.olength[mvu][4] = 0;                          // Don't need this for GEMV
    //     intf.d_signed[mvu] = isign;
    //     intf.w_signed[mvu] = wsign;
    //     intf.scaler1_b[mvu] = scaler;
    //     intf.shacc_load_sel[mvu] = 5'b00001;            // Load the shift/accumulator on when weight address jump 0 happens
    //     intf.zigzag_step_sel[mvu] = 5'b00011;           // Bump the zig-zag on weight jumps 1 and 0
    //     intf.countdown[mvu*BCNTDWN +: BCNTDWN] = countdown_val;

    //     // Scaler and bias memory parameters
    //     if (usescalarmem) begin
    //         intf.usescaler_mem[mvu] = 1;
    //         intf.sjump[mvu][0] = 1;
    //         intf.sjump[mvu][1] = 0;
    //         intf.sjump[mvu][2] = 0;
    //         intf.sjump[mvu][3] = 0;
    //         intf.sjump[mvu][4] = 0;
    //         intf.slength[mvu][1] = 0;
    //         intf.slength[mvu][2] = 0;
    //         intf.slength[mvu][3] = 0;
    //         intf.slength[mvu][4] = 0;
    //     end else begin
    //         intf.usescaler_mem[mvu] = 0;
    //     end
    //     if (usebiasmem) begin
    //         intf.usebias_mem[mvu] = 1;
    //         intf.bjump[mvu][0] = 1;
    //         intf.bjump[mvu][1] = 0;
    //         intf.bjump[mvu][2] = 0;
    //         intf.bjump[mvu][3] = 0;
    //         intf.bjump[mvu][4] = 0;
    //         intf.blength[mvu][1] = 0;
    //         intf.blength[mvu][2] = 0;
    //         intf.blength[mvu][3] = 0;
    //         intf.blength[mvu][4] = 0;
    //     end else begin
    //         intf.usebias_mem[mvu] = 0;
    //     end

    //     // Run the GEMV
    //     intf.start[mvu] = 1'b1;
    //     @(posedge intf.clk)
    //     intf.start[mvu] = 1'b0;
    //     for(int i=0; i<cyclecount; i++) @(posedge intf.clk);

    // endtask
// =================================================================================================
// Class based test
// =================================================================================================

    virtual task tb_setup();
        logger.print_banner("Testbench Setup Phase");
        // Put DUT to reset and relax memory interface
        logger.print("Putting DUT to reset mode");
        // reset dut
        apb_master.reset_master();
        repeat (10); @(posedge mvu_ext_if.clk);

        mvu_ext_if.rst_n = 0;

        mvu_ext_if.start = 0;
        mvu_ext_if.ic_clr = 0;
        mvu_ext_if.shacc_clr = 0;
        mvu_ext_if.wrw_addr = 0;
        mvu_ext_if.wrw_word = 0;
        mvu_ext_if.wrw_en = 0;
        mvu_ext_if.rdc_en = 0;
        mvu_ext_if.rdc_addr = 0;
        mvu_ext_if.wrc_en = 0;
        mvu_ext_if.wrc_addr = 0;
        mvu_ext_if.wrc_word = 0;
        mvu_ext_if.wrs_en = 0;
        mvu_ext_if.wrs_addr = 0;
        mvu_ext_if.wrs_word = 0;
        mvu_ext_if.wrb_en = 0;
        mvu_ext_if.wrb_addr = 0;
        mvu_ext_if.wrb_word = 0;

        // #(`CLOCK_SPEED*10);
        repeat (10); @(posedge mvu_ext_if.clk);
        // Come out of reset
        mvu_ext_if.rst_n = 1'b1;
        // #(`CLOCK_SPEED*10);
        repeat (10); @(posedge mvu_ext_if.clk);
 
        // Initialize scaler and bias memories
        scalerMemInit(0);
        biasMemInit(0);
        repeat (10); @(posedge mvu_ext_if.clk);

        // // Turn some stuff on
        for (int i=0; i<NMVU; i++) begin
            apb_addr = apb_addr_t'({3'(i), mvu_pkg::CSR_MVUCOMMAND});
            apb_strb = apb_strb_t'(4'hF);
            apb_master.write(apb_addr, apb_data_t'(1), apb_strb, apb_resp);
        end
        
        logger.print("Setup Phase Done ...");
    endtask

    virtual task run();
        logger.print_banner("Testbench Run phase");
        logger.print("Run method is not implemented");
        logger.print("Run phase done ...");
    endtask 

    virtual task report();
        test_stats_t test_stat;
        test_stat = '{pass_cnt: 0, fail_cnt: 0};
        logger.print_banner("Testbench Report phase");
        print_result(test_stat, VERB_LOW, logger);
    endtask 

endclass