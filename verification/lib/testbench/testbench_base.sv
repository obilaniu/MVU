`include "testbench_macros.svh"
`include "testbench_config.sv"

import utils::*;
import testbench_pkg::*;
import mvu_pkg::*;

class mvu_testbench_base extends BaseObj;

    string firmware;
    virtual mvu_interface intf;
    test_stats_t test_stat;
    tb_config cfg;

    function new (Logger logger, virtual mvu_interface intf);
        super.new(logger);
        cfg = new(logger);
        void'(cfg.parse_args());
        this.intf = intf;
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


    task checkmvu(int mvu);
        if (mvu > N) begin
            logger.print($sformatf("MVU specificed %d is greater than number of MVUs %d", mvu, N), "Error");
            $finish();
        end
    endtask

    task writeData(int mvu, unsigned[BDBANKW-1 : 0] word, unsigned[BDBANKA-1 : 0] addr);
        checkmvu(mvu);
        intf.wrc_addr = addr;
        intf.wrc_word = word;
        intf.wrc_en[mvu] = 1'b1;
        @(posedge intf.clk)
        intf.wrc_en[mvu] = 1'b0;
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
        intf.wrw_addr[mvu*BWBANKA +: BWBANKA] = addr;
        intf.wrw_word[mvu*BWBANKW +: BWBANKW] = word;
        intf.wrw_en[mvu] = 1'b1;
        @(posedge intf.clk)
        intf.wrw_en[mvu] = 1'b0;
    endtask

    task writeWeightsRepeat(int mvu, logic unsigned[BWBANKW-1 : 0] word, logic unsigned[BWBANKA-1 : 0] startaddr, int size, int stride=1);
        checkmvu(mvu);
        for (int i = 0; i < size; i++) begin
            writeWeights(.mvu(mvu), .word(word), .addr(startaddr));
            @(posedge intf.clk)
            startaddr = startaddr + stride;
        end
    endtask

    task automatic readData(int mvu, logic unsigned [BDBANKA-1 : 0] addr, ref logic unsigned [BDBANKW-1 : 0] word, ref logic unsigned [NMVU-1 : 0] grnt);
        checkmvu(mvu);
        intf.rdc_addr[mvu*BDBANKA +: BDBANKA] = addr;
        intf.rdc_en[mvu] = 1;
        @(posedge intf.clk)
        grnt[mvu] = intf.rdc_grnt[mvu];
        intf.rdc_en[mvu] = 0;
        @(posedge intf.clk)
        @(posedge intf.clk)
        word = intf.rdc_word[mvu*BDBANKW +: BDBANKW];
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
        intf.wprecision[mvu*BPREC +: BPREC] = wprec;
        intf.iprecision[mvu*BPREC +: BPREC] = iprec;
        intf.oprecision[mvu*BPREC +: BPREC] = oprec;
        intf.quant_msbidx[mvu*BQMSBIDX +: BQMSBIDX] = omsb;
        intf.wbaseaddr[mvu*BWBANKA +: BWBANKA] = waddr;
        intf.ibaseaddr[mvu*BDBANKA +: BDBANKA] = iaddr;
        intf.obaseaddr[mvu*BDBANKA +: BDBANKA] = {obank_sel, oword_sel};
        intf.omvusel[mvu*NMVU +: NMVU]         = omvu;                   // Set the output MVUs
        intf.wjump[mvu][0] = wprec;                        // move 1 tile ahead to next tile row
        intf.wjump[mvu][1] = -wprec*(m_w-1);               // Move back to tile 0 of current tile row
        intf.wjump[mvu][2] = wprec;                        // Move ahead one tile
        intf.wjump[mvu][3] = 0;                            // Don't need this for GEMV
        intf.wjump[mvu][4] = 0;                            // Don't need this for GEMV
        intf.ijump[mvu][0] = -iprec*(m_w-1);               // Move back to beginning vector 
        intf.ijump[mvu][1] = iprec;                        // Move ahead one tile
        intf.ijump[mvu][2] = 0;                            // Don't need this for GEMV
        intf.ijump[mvu][3] = 0;                            // Don't need this for GEMV
        intf.ijump[mvu][4] = 0;                            // Don't need this for GEMV
        intf.ojump[mvu][0] = 0;                            // Don't need this for GEMV
        intf.ojump[mvu][1] = 0;                            // Don't need this for GEMV
        intf.ojump[mvu][2] = 0;                            // Don't need this for GEMV
        intf.ojump[mvu][3] = 0;                            // Don't need this for GEMV
        intf.ojump[mvu][4] = 0;                            // Don't need this for GEMV
        intf.wlength[mvu][1] = wprec*iprec-1;              // number bit combinations minus 1
        intf.wlength[mvu][2] = m_w-1;                      // Number tiles in width minus 1
        intf.wlength[mvu][3] = 0;                          // Don't need this for GEMV
        intf.wlength[mvu][4] = 0;                          // Don't need this for GEMV
        intf.ilength[mvu][1] = m_h-1;                      // Number tiles in height minus 1
        intf.ilength[mvu][2] = 0;                          // Don't need this for GEMV
        intf.ilength[mvu][3] = 0;                          // Don't need this for GEMV
        intf.ilength[mvu][4] = 0;                          // Don't need this for GEMV
        intf.olength[mvu][1] = 1;                          // Write out sequentially
        intf.olength[mvu][2] = 0;                          // Don't need this for GEMV
        intf.olength[mvu][3] = 0;                          // Don't need this for GEMV
        intf.olength[mvu][4] = 0;                          // Don't need this for GEMV
        intf.d_signed[mvu] = isign;
        intf.w_signed[mvu] = wsign;
        intf.scaler_b[mvu*BSCALERB +: BSCALERB] = scaler;
        intf.shacc_load_sel[mvu] = 5'b00001;            // Load the shift/accumulator on when weight address jump 0 happens
        intf.zigzag_step_sel[mvu] = 5'b00011;           // Bump the zig-zag on weight jumps 1 and 0
        intf.countdown[mvu*BCNTDWN +: BCNTDWN] = countdown_val;

        // Run the GEMV
        intf.start[mvu] = 1'b1;
        @(posedge intf.clk)
        intf.start[mvu] = 1'b0;
        for(int i=0; i<cyclecount; i++) @(posedge intf.clk);

    endtask
// =================================================================================================
// Class based test
// =================================================================================================

    virtual task tb_setup();
        logger.print_banner("Testbench Setup Phase");
        // Put DUT to reset and relax memory interface
        logger.print("Putting DUT to reset mode");

        intf.rst_n = 0;
        intf.start = 0;
        intf.ic_clr = 0;      
        intf.mul_mode = {NMVU{2'b01}};
        intf.d_signed = 0;
        intf.w_signed = 0;
        intf.shacc_clr = 0;
        intf.max_en = 0;
        intf.max_clr = 0;
        intf.max_pool = 0;
        intf.rdc_en = 0;
        intf.rdc_addr = 0;
        intf.wrc_en = 0;
        intf.wrc_addr = 0;
        intf.wrc_word = 0;
        intf.quant_clr = 0;
        intf.quant_msbidx = 0;
        intf.countdown = 0;
        intf.wprecision = 0;
        intf.iprecision = 0;
        intf.oprecision = 0;
        intf.wbaseaddr = 0;
        intf.ibaseaddr = 0;
        intf.obaseaddr = 0;
        intf.omvusel = 0;

        // Initialize arrays
        for (int m = 0; m < NMVU; m++) begin
            // Initialize jumps
            for (int i = 0; i < NJUMPS; i++) begin
                intf.wjump[m][i] = 0;
                intf.ijump[m][i] = 0;
                intf.ojump[m][i] = 0;
            end

            // Initizalize lengths
            for (int i = 1; i < NJUMPS; i++) begin
                intf.wlength[m][i] = 0;
                intf.ilength[m][i] = 0;
                intf.olength[m][i] = 0;
            end

            intf.shacc_load_sel[m] = 0;
            intf.zigzag_step_sel[m] = 0;
        end
        
        intf.scaler_b = 1;
        intf.wrw_addr = 0;
        intf.wrw_word = 0;
        intf.wrw_en = 0;

        // #(`CLOCK_SPEED*10);
        for(int i=0; i<10; i++) @(posedge intf.clk);
        // Come out of reset
        intf.rst_n = 1'b1;
        // #(`CLOCK_SPEED*10);
        for(int i=0; i<10; i++) @(posedge intf.clk);
 
        // Turn some stuff on
        intf.max_en = 1;
        
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
