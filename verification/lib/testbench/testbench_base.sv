`include "testbench_macros.svh"
`include "testbench_config.sv"

import utils::*;
import testbench_pkg::*;
import mvu_pkg::*;

class mvu_testbench_base extends BaseObj;

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
        while (1) begin
            @(posedge mvu_ext_if.clk);
            if (mvu_ext_if.wrc_grnt[mvu] == 1) begin
                break;
            end else begin
                logger.print($sformatf("writeData: did not get grant signal for MVU %0d for address %x, so waiting until next cycle.", mvu, addr));
            end
        end
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

    // Back-door function to read MVU data memory
    function logic[BWBANKW-1: 0] peekData(int mvu, int bank, int addr);
        case (mvu)
            0 : begin
                case (bank)
                    0:      return `hdl_path_mvu_data_mem_bank_ram(0, 0)[addr];
                    1:      return `hdl_path_mvu_data_mem_bank_ram(0, 1)[addr];
                    2:      return `hdl_path_mvu_data_mem_bank_ram(0, 2)[addr];
                    3:      return `hdl_path_mvu_data_mem_bank_ram(0, 3)[addr];
                    4:      return `hdl_path_mvu_data_mem_bank_ram(0, 4)[addr];
                    5:      return `hdl_path_mvu_data_mem_bank_ram(0, 5)[addr];
                    6:      return `hdl_path_mvu_data_mem_bank_ram(0, 6)[addr];
                    7:      return `hdl_path_mvu_data_mem_bank_ram(0, 7)[addr];
                    8:      return `hdl_path_mvu_data_mem_bank_ram(0, 8)[addr];
                    9:      return `hdl_path_mvu_data_mem_bank_ram(0, 9)[addr];
                    10:     return `hdl_path_mvu_data_mem_bank_ram(0, 10)[addr];
                    11:     return `hdl_path_mvu_data_mem_bank_ram(0, 11)[addr];
                    12:     return `hdl_path_mvu_data_mem_bank_ram(0, 12)[addr];
                    13:     return `hdl_path_mvu_data_mem_bank_ram(0, 13)[addr];
                    14:     return `hdl_path_mvu_data_mem_bank_ram(0, 14)[addr];
                    15:     return `hdl_path_mvu_data_mem_bank_ram(0, 15)[addr];
                    16:     return `hdl_path_mvu_data_mem_bank_ram(0, 16)[addr];
                    17:     return `hdl_path_mvu_data_mem_bank_ram(0, 17)[addr];
                    18:     return `hdl_path_mvu_data_mem_bank_ram(0, 18)[addr];
                    19:     return `hdl_path_mvu_data_mem_bank_ram(0, 19)[addr];
                    20:     return `hdl_path_mvu_data_mem_bank_ram(0, 20)[addr];
                    21:     return `hdl_path_mvu_data_mem_bank_ram(0, 21)[addr];
                    22:     return `hdl_path_mvu_data_mem_bank_ram(0, 22)[addr];
                    23:     return `hdl_path_mvu_data_mem_bank_ram(0, 23)[addr];
                    24:     return `hdl_path_mvu_data_mem_bank_ram(0, 24)[addr];
                    25:     return `hdl_path_mvu_data_mem_bank_ram(0, 25)[addr];
                    26:     return `hdl_path_mvu_data_mem_bank_ram(0, 26)[addr];
                    27:     return `hdl_path_mvu_data_mem_bank_ram(0, 27)[addr];
                    28:     return `hdl_path_mvu_data_mem_bank_ram(0, 28)[addr];
                    29:     return `hdl_path_mvu_data_mem_bank_ram(0, 29)[addr];
                    30:     return `hdl_path_mvu_data_mem_bank_ram(0, 30)[addr];
                    31:     return `hdl_path_mvu_data_mem_bank_ram(0, 31)[addr];
                    default:
                        $error("Invalid address");
                endcase
            end
            1: begin
                case (bank)
                    0:      return `hdl_path_mvu_data_mem_bank_ram(1, 0)[addr];
                    1:      return `hdl_path_mvu_data_mem_bank_ram(1, 1)[addr];
                    2:      return `hdl_path_mvu_data_mem_bank_ram(1, 2)[addr];
                    3:      return `hdl_path_mvu_data_mem_bank_ram(1, 3)[addr];
                    4:      return `hdl_path_mvu_data_mem_bank_ram(1, 4)[addr];
                    5:      return `hdl_path_mvu_data_mem_bank_ram(1, 5)[addr];
                    6:      return `hdl_path_mvu_data_mem_bank_ram(1, 6)[addr];
                    7:      return `hdl_path_mvu_data_mem_bank_ram(1, 7)[addr];
                    8:      return `hdl_path_mvu_data_mem_bank_ram(1, 8)[addr];
                    9:      return `hdl_path_mvu_data_mem_bank_ram(1, 9)[addr];
                    10:     return `hdl_path_mvu_data_mem_bank_ram(1, 10)[addr];
                    11:     return `hdl_path_mvu_data_mem_bank_ram(1, 11)[addr];
                    12:     return `hdl_path_mvu_data_mem_bank_ram(1, 12)[addr];
                    13:     return `hdl_path_mvu_data_mem_bank_ram(1, 13)[addr];
                    14:     return `hdl_path_mvu_data_mem_bank_ram(1, 14)[addr];
                    15:     return `hdl_path_mvu_data_mem_bank_ram(1, 15)[addr];
                    16:     return `hdl_path_mvu_data_mem_bank_ram(1, 16)[addr];
                    17:     return `hdl_path_mvu_data_mem_bank_ram(1, 17)[addr];
                    18:     return `hdl_path_mvu_data_mem_bank_ram(1, 18)[addr];
                    19:     return `hdl_path_mvu_data_mem_bank_ram(1, 19)[addr];
                    20:     return `hdl_path_mvu_data_mem_bank_ram(1, 20)[addr];
                    21:     return `hdl_path_mvu_data_mem_bank_ram(1, 21)[addr];
                    22:     return `hdl_path_mvu_data_mem_bank_ram(1, 22)[addr];
                    23:     return `hdl_path_mvu_data_mem_bank_ram(1, 23)[addr];
                    24:     return `hdl_path_mvu_data_mem_bank_ram(1, 24)[addr];
                    25:     return `hdl_path_mvu_data_mem_bank_ram(1, 25)[addr];
                    26:     return `hdl_path_mvu_data_mem_bank_ram(1, 26)[addr];
                    27:     return `hdl_path_mvu_data_mem_bank_ram(1, 27)[addr];
                    28:     return `hdl_path_mvu_data_mem_bank_ram(1, 28)[addr];
                    29:     return `hdl_path_mvu_data_mem_bank_ram(1, 29)[addr];
                    30:     return `hdl_path_mvu_data_mem_bank_ram(1, 30)[addr];
                    31:     return `hdl_path_mvu_data_mem_bank_ram(1, 31)[addr];
                    default:
                        $error("Invalid address");
                endcase
            end
            2: begin
                case (bank)
                    0:      return `hdl_path_mvu_data_mem_bank_ram(2, 0)[addr];
                    1:      return `hdl_path_mvu_data_mem_bank_ram(2, 1)[addr];
                    2:      return `hdl_path_mvu_data_mem_bank_ram(2, 2)[addr];
                    3:      return `hdl_path_mvu_data_mem_bank_ram(2, 3)[addr];
                    4:      return `hdl_path_mvu_data_mem_bank_ram(2, 4)[addr];
                    5:      return `hdl_path_mvu_data_mem_bank_ram(2, 5)[addr];
                    6:      return `hdl_path_mvu_data_mem_bank_ram(2, 6)[addr];
                    7:      return `hdl_path_mvu_data_mem_bank_ram(2, 7)[addr];
                    8:      return `hdl_path_mvu_data_mem_bank_ram(2, 8)[addr];
                    9:      return `hdl_path_mvu_data_mem_bank_ram(2, 9)[addr];
                    10:     return `hdl_path_mvu_data_mem_bank_ram(2, 10)[addr];
                    11:     return `hdl_path_mvu_data_mem_bank_ram(2, 11)[addr];
                    12:     return `hdl_path_mvu_data_mem_bank_ram(2, 12)[addr];
                    13:     return `hdl_path_mvu_data_mem_bank_ram(2, 13)[addr];
                    14:     return `hdl_path_mvu_data_mem_bank_ram(2, 14)[addr];
                    15:     return `hdl_path_mvu_data_mem_bank_ram(2, 15)[addr];
                    16:     return `hdl_path_mvu_data_mem_bank_ram(2, 16)[addr];
                    17:     return `hdl_path_mvu_data_mem_bank_ram(2, 17)[addr];
                    18:     return `hdl_path_mvu_data_mem_bank_ram(2, 18)[addr];
                    19:     return `hdl_path_mvu_data_mem_bank_ram(2, 19)[addr];
                    20:     return `hdl_path_mvu_data_mem_bank_ram(2, 20)[addr];
                    21:     return `hdl_path_mvu_data_mem_bank_ram(2, 21)[addr];
                    22:     return `hdl_path_mvu_data_mem_bank_ram(2, 22)[addr];
                    23:     return `hdl_path_mvu_data_mem_bank_ram(2, 23)[addr];
                    24:     return `hdl_path_mvu_data_mem_bank_ram(2, 24)[addr];
                    25:     return `hdl_path_mvu_data_mem_bank_ram(2, 25)[addr];
                    26:     return `hdl_path_mvu_data_mem_bank_ram(2, 26)[addr];
                    27:     return `hdl_path_mvu_data_mem_bank_ram(2, 27)[addr];
                    28:     return `hdl_path_mvu_data_mem_bank_ram(2, 28)[addr];
                    29:     return `hdl_path_mvu_data_mem_bank_ram(2, 29)[addr];
                    30:     return `hdl_path_mvu_data_mem_bank_ram(2, 30)[addr];
                    31:     return `hdl_path_mvu_data_mem_bank_ram(2, 31)[addr];
                    default:
                        $error("Invalid address");
                endcase
            end
            3: begin
                case (bank)
                    0:      return `hdl_path_mvu_data_mem_bank_ram(3, 0)[addr];
                    1:      return `hdl_path_mvu_data_mem_bank_ram(3, 1)[addr];
                    2:      return `hdl_path_mvu_data_mem_bank_ram(3, 2)[addr];
                    3:      return `hdl_path_mvu_data_mem_bank_ram(3, 3)[addr];
                    4:      return `hdl_path_mvu_data_mem_bank_ram(3, 4)[addr];
                    5:      return `hdl_path_mvu_data_mem_bank_ram(3, 5)[addr];
                    6:      return `hdl_path_mvu_data_mem_bank_ram(3, 6)[addr];
                    7:      return `hdl_path_mvu_data_mem_bank_ram(3, 7)[addr];
                    8:      return `hdl_path_mvu_data_mem_bank_ram(3, 8)[addr];
                    9:      return `hdl_path_mvu_data_mem_bank_ram(3, 9)[addr];
                    10:     return `hdl_path_mvu_data_mem_bank_ram(3, 10)[addr];
                    11:     return `hdl_path_mvu_data_mem_bank_ram(3, 11)[addr];
                    12:     return `hdl_path_mvu_data_mem_bank_ram(3, 12)[addr];
                    13:     return `hdl_path_mvu_data_mem_bank_ram(3, 13)[addr];
                    14:     return `hdl_path_mvu_data_mem_bank_ram(3, 14)[addr];
                    15:     return `hdl_path_mvu_data_mem_bank_ram(3, 15)[addr];
                    16:     return `hdl_path_mvu_data_mem_bank_ram(3, 16)[addr];
                    17:     return `hdl_path_mvu_data_mem_bank_ram(3, 17)[addr];
                    18:     return `hdl_path_mvu_data_mem_bank_ram(3, 18)[addr];
                    19:     return `hdl_path_mvu_data_mem_bank_ram(3, 19)[addr];
                    20:     return `hdl_path_mvu_data_mem_bank_ram(3, 20)[addr];
                    21:     return `hdl_path_mvu_data_mem_bank_ram(3, 21)[addr];
                    22:     return `hdl_path_mvu_data_mem_bank_ram(3, 22)[addr];
                    23:     return `hdl_path_mvu_data_mem_bank_ram(3, 23)[addr];
                    24:     return `hdl_path_mvu_data_mem_bank_ram(3, 24)[addr];
                    25:     return `hdl_path_mvu_data_mem_bank_ram(3, 25)[addr];
                    26:     return `hdl_path_mvu_data_mem_bank_ram(3, 26)[addr];
                    27:     return `hdl_path_mvu_data_mem_bank_ram(3, 27)[addr];
                    28:     return `hdl_path_mvu_data_mem_bank_ram(3, 28)[addr];
                    29:     return `hdl_path_mvu_data_mem_bank_ram(3, 29)[addr];
                    30:     return `hdl_path_mvu_data_mem_bank_ram(3, 30)[addr];
                    31:     return `hdl_path_mvu_data_mem_bank_ram(3, 31)[addr];
                    default:
                        $error("Invalid address");
                endcase
            end
            4: begin
                case (bank)
                    0:      return `hdl_path_mvu_data_mem_bank_ram(4, 0)[addr];
                    1:      return `hdl_path_mvu_data_mem_bank_ram(4, 1)[addr];
                    2:      return `hdl_path_mvu_data_mem_bank_ram(4, 2)[addr];
                    3:      return `hdl_path_mvu_data_mem_bank_ram(4, 3)[addr];
                    4:      return `hdl_path_mvu_data_mem_bank_ram(4, 4)[addr];
                    5:      return `hdl_path_mvu_data_mem_bank_ram(4, 5)[addr];
                    6:      return `hdl_path_mvu_data_mem_bank_ram(4, 6)[addr];
                    7:      return `hdl_path_mvu_data_mem_bank_ram(4, 7)[addr];
                    8:      return `hdl_path_mvu_data_mem_bank_ram(4, 8)[addr];
                    9:      return `hdl_path_mvu_data_mem_bank_ram(4, 9)[addr];
                    10:     return `hdl_path_mvu_data_mem_bank_ram(4, 10)[addr];
                    11:     return `hdl_path_mvu_data_mem_bank_ram(4, 11)[addr];
                    12:     return `hdl_path_mvu_data_mem_bank_ram(4, 12)[addr];
                    13:     return `hdl_path_mvu_data_mem_bank_ram(4, 13)[addr];
                    14:     return `hdl_path_mvu_data_mem_bank_ram(4, 14)[addr];
                    15:     return `hdl_path_mvu_data_mem_bank_ram(4, 15)[addr];
                    16:     return `hdl_path_mvu_data_mem_bank_ram(4, 16)[addr];
                    17:     return `hdl_path_mvu_data_mem_bank_ram(4, 17)[addr];
                    18:     return `hdl_path_mvu_data_mem_bank_ram(4, 18)[addr];
                    19:     return `hdl_path_mvu_data_mem_bank_ram(4, 19)[addr];
                    20:     return `hdl_path_mvu_data_mem_bank_ram(4, 20)[addr];
                    21:     return `hdl_path_mvu_data_mem_bank_ram(4, 21)[addr];
                    22:     return `hdl_path_mvu_data_mem_bank_ram(4, 22)[addr];
                    23:     return `hdl_path_mvu_data_mem_bank_ram(4, 23)[addr];
                    24:     return `hdl_path_mvu_data_mem_bank_ram(4, 24)[addr];
                    25:     return `hdl_path_mvu_data_mem_bank_ram(4, 25)[addr];
                    26:     return `hdl_path_mvu_data_mem_bank_ram(4, 26)[addr];
                    27:     return `hdl_path_mvu_data_mem_bank_ram(4, 27)[addr];
                    28:     return `hdl_path_mvu_data_mem_bank_ram(4, 28)[addr];
                    29:     return `hdl_path_mvu_data_mem_bank_ram(4, 29)[addr];
                    30:     return `hdl_path_mvu_data_mem_bank_ram(4, 30)[addr];
                    31:     return `hdl_path_mvu_data_mem_bank_ram(4, 31)[addr];
                    default:
                        $error("Invalid address");
                endcase
            end
            5: begin
                case (bank)
                    0:      return `hdl_path_mvu_data_mem_bank_ram(5, 0)[addr];
                    1:      return `hdl_path_mvu_data_mem_bank_ram(5, 1)[addr];
                    2:      return `hdl_path_mvu_data_mem_bank_ram(5, 2)[addr];
                    3:      return `hdl_path_mvu_data_mem_bank_ram(5, 3)[addr];
                    4:      return `hdl_path_mvu_data_mem_bank_ram(5, 4)[addr];
                    5:      return `hdl_path_mvu_data_mem_bank_ram(5, 5)[addr];
                    6:      return `hdl_path_mvu_data_mem_bank_ram(5, 6)[addr];
                    7:      return `hdl_path_mvu_data_mem_bank_ram(5, 7)[addr];
                    8:      return `hdl_path_mvu_data_mem_bank_ram(5, 8)[addr];
                    9:      return `hdl_path_mvu_data_mem_bank_ram(5, 9)[addr];
                    10:     return `hdl_path_mvu_data_mem_bank_ram(5, 10)[addr];
                    11:     return `hdl_path_mvu_data_mem_bank_ram(5, 11)[addr];
                    12:     return `hdl_path_mvu_data_mem_bank_ram(5, 12)[addr];
                    13:     return `hdl_path_mvu_data_mem_bank_ram(5, 13)[addr];
                    14:     return `hdl_path_mvu_data_mem_bank_ram(5, 14)[addr];
                    15:     return `hdl_path_mvu_data_mem_bank_ram(5, 15)[addr];
                    16:     return `hdl_path_mvu_data_mem_bank_ram(5, 16)[addr];
                    17:     return `hdl_path_mvu_data_mem_bank_ram(5, 17)[addr];
                    18:     return `hdl_path_mvu_data_mem_bank_ram(5, 18)[addr];
                    19:     return `hdl_path_mvu_data_mem_bank_ram(5, 19)[addr];
                    20:     return `hdl_path_mvu_data_mem_bank_ram(5, 20)[addr];
                    21:     return `hdl_path_mvu_data_mem_bank_ram(5, 21)[addr];
                    22:     return `hdl_path_mvu_data_mem_bank_ram(5, 22)[addr];
                    23:     return `hdl_path_mvu_data_mem_bank_ram(5, 23)[addr];
                    24:     return `hdl_path_mvu_data_mem_bank_ram(5, 24)[addr];
                    25:     return `hdl_path_mvu_data_mem_bank_ram(5, 25)[addr];
                    26:     return `hdl_path_mvu_data_mem_bank_ram(5, 26)[addr];
                    27:     return `hdl_path_mvu_data_mem_bank_ram(5, 27)[addr];
                    28:     return `hdl_path_mvu_data_mem_bank_ram(5, 28)[addr];
                    29:     return `hdl_path_mvu_data_mem_bank_ram(5, 29)[addr];
                    30:     return `hdl_path_mvu_data_mem_bank_ram(5, 30)[addr];
                    31:     return `hdl_path_mvu_data_mem_bank_ram(5, 31)[addr];
                    default:
                        $error("Invalid address");
                endcase
            end
            6: begin
                case (bank)
                    0:      return `hdl_path_mvu_data_mem_bank_ram(6, 0)[addr];
                    1:      return `hdl_path_mvu_data_mem_bank_ram(6, 1)[addr];
                    2:      return `hdl_path_mvu_data_mem_bank_ram(6, 2)[addr];
                    3:      return `hdl_path_mvu_data_mem_bank_ram(6, 3)[addr];
                    4:      return `hdl_path_mvu_data_mem_bank_ram(6, 4)[addr];
                    5:      return `hdl_path_mvu_data_mem_bank_ram(6, 5)[addr];
                    6:      return `hdl_path_mvu_data_mem_bank_ram(6, 6)[addr];
                    7:      return `hdl_path_mvu_data_mem_bank_ram(6, 7)[addr];
                    8:      return `hdl_path_mvu_data_mem_bank_ram(6, 8)[addr];
                    9:      return `hdl_path_mvu_data_mem_bank_ram(6, 9)[addr];
                    10:     return `hdl_path_mvu_data_mem_bank_ram(6, 10)[addr];
                    11:     return `hdl_path_mvu_data_mem_bank_ram(6, 11)[addr];
                    12:     return `hdl_path_mvu_data_mem_bank_ram(6, 12)[addr];
                    13:     return `hdl_path_mvu_data_mem_bank_ram(6, 13)[addr];
                    14:     return `hdl_path_mvu_data_mem_bank_ram(6, 14)[addr];
                    15:     return `hdl_path_mvu_data_mem_bank_ram(6, 15)[addr];
                    16:     return `hdl_path_mvu_data_mem_bank_ram(6, 16)[addr];
                    17:     return `hdl_path_mvu_data_mem_bank_ram(6, 17)[addr];
                    18:     return `hdl_path_mvu_data_mem_bank_ram(6, 18)[addr];
                    19:     return `hdl_path_mvu_data_mem_bank_ram(6, 19)[addr];
                    20:     return `hdl_path_mvu_data_mem_bank_ram(6, 20)[addr];
                    21:     return `hdl_path_mvu_data_mem_bank_ram(6, 21)[addr];
                    22:     return `hdl_path_mvu_data_mem_bank_ram(6, 22)[addr];
                    23:     return `hdl_path_mvu_data_mem_bank_ram(6, 23)[addr];
                    24:     return `hdl_path_mvu_data_mem_bank_ram(6, 24)[addr];
                    25:     return `hdl_path_mvu_data_mem_bank_ram(6, 25)[addr];
                    26:     return `hdl_path_mvu_data_mem_bank_ram(6, 26)[addr];
                    27:     return `hdl_path_mvu_data_mem_bank_ram(6, 27)[addr];
                    28:     return `hdl_path_mvu_data_mem_bank_ram(6, 28)[addr];
                    29:     return `hdl_path_mvu_data_mem_bank_ram(6, 29)[addr];
                    30:     return `hdl_path_mvu_data_mem_bank_ram(6, 30)[addr];
                    31:     return `hdl_path_mvu_data_mem_bank_ram(6, 31)[addr];
                    default:
                        $error("Invalid address");
                endcase
            end
            7: begin
                case (bank)
                    0:      return `hdl_path_mvu_data_mem_bank_ram(7, 0)[addr];
                    1:      return `hdl_path_mvu_data_mem_bank_ram(7, 1)[addr];
                    2:      return `hdl_path_mvu_data_mem_bank_ram(7, 2)[addr];
                    3:      return `hdl_path_mvu_data_mem_bank_ram(7, 3)[addr];
                    4:      return `hdl_path_mvu_data_mem_bank_ram(7, 4)[addr];
                    5:      return `hdl_path_mvu_data_mem_bank_ram(7, 5)[addr];
                    6:      return `hdl_path_mvu_data_mem_bank_ram(7, 6)[addr];
                    7:      return `hdl_path_mvu_data_mem_bank_ram(7, 7)[addr];
                    8:      return `hdl_path_mvu_data_mem_bank_ram(7, 8)[addr];
                    9:      return `hdl_path_mvu_data_mem_bank_ram(7, 9)[addr];
                    10:     return `hdl_path_mvu_data_mem_bank_ram(7, 10)[addr];
                    11:     return `hdl_path_mvu_data_mem_bank_ram(7, 11)[addr];
                    12:     return `hdl_path_mvu_data_mem_bank_ram(7, 12)[addr];
                    13:     return `hdl_path_mvu_data_mem_bank_ram(7, 13)[addr];
                    14:     return `hdl_path_mvu_data_mem_bank_ram(7, 14)[addr];
                    15:     return `hdl_path_mvu_data_mem_bank_ram(7, 15)[addr];
                    16:     return `hdl_path_mvu_data_mem_bank_ram(7, 16)[addr];
                    17:     return `hdl_path_mvu_data_mem_bank_ram(7, 17)[addr];
                    18:     return `hdl_path_mvu_data_mem_bank_ram(7, 18)[addr];
                    19:     return `hdl_path_mvu_data_mem_bank_ram(7, 19)[addr];
                    20:     return `hdl_path_mvu_data_mem_bank_ram(7, 20)[addr];
                    21:     return `hdl_path_mvu_data_mem_bank_ram(7, 21)[addr];
                    22:     return `hdl_path_mvu_data_mem_bank_ram(7, 22)[addr];
                    23:     return `hdl_path_mvu_data_mem_bank_ram(7, 23)[addr];
                    24:     return `hdl_path_mvu_data_mem_bank_ram(7, 24)[addr];
                    25:     return `hdl_path_mvu_data_mem_bank_ram(7, 25)[addr];
                    26:     return `hdl_path_mvu_data_mem_bank_ram(7, 26)[addr];
                    27:     return `hdl_path_mvu_data_mem_bank_ram(7, 27)[addr];
                    28:     return `hdl_path_mvu_data_mem_bank_ram(7, 28)[addr];
                    29:     return `hdl_path_mvu_data_mem_bank_ram(7, 29)[addr];
                    30:     return `hdl_path_mvu_data_mem_bank_ram(7, 30)[addr];
                    31:     return `hdl_path_mvu_data_mem_bank_ram(7, 31)[addr];
                    default:
                        $error("Invalid address");
                endcase
            end
            default:
                $error("Invalid MVU value.");
        endcase
    endfunction

    //
    //function logic[BWBANKW-1: 0] peekData(int mvu, int addr);
    //    int bank = addr >> BDBANKAWS;
    //    return peekData(mvu, bank, addr);
    //endfunction

    task wait_for_pipeline_after_irq(int oprec);
        repeat (PIPELINE_DLY + oprec); @(posedge mvu_ext_if.clk);
    endtask

    task wait_for_irq(int mvu_id);
    // Vivado hdl hierarchy can be built only at compile time,
    // no dynamic referencing is allowed, so:
        logger.print($sformatf("Waiting for an interrupt from MVU[%0d] ...", mvu_id));
        if (mvu_id==0) begin
            @(`hdl_path_top_mvu0_irq);
        end else if (mvu_id==1) begin
            @(`hdl_path_top_mvu1_irq);
        end else if (mvu_id==2) begin
            @(`hdl_path_top_mvu2_irq);
        end else if (mvu_id==3) begin
            @(`hdl_path_top_mvu3_irq);
        end else if (mvu_id==4) begin
            @(`hdl_path_top_mvu4_irq);
        end else if (mvu_id==5) begin
            @(`hdl_path_top_mvu5_irq);
        end else if (mvu_id==6) begin
            @(`hdl_path_top_mvu6_irq);
        end else if (mvu_id==7) begin
            @(`hdl_path_top_mvu7_irq);
        end
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
        int saddr = 0,
        int baddr = 0,
        logic isign = 0,    // True if input data are signed
        logic wsign = 0,    // True if weights are signed
        int scaler = 1,
        logic usescalarmem = 0,
        logic usebiasmem = 0
    );  
        logic maxpool_en;
        logic [1:0] mul_mode;
        logic [BDBANKABS-1 : 0]     obank_sel = obank;
        logic [BDBANKAWS-1 : 0]     oword_sel = oaddr;

        int countdown_val = m_w * m_h * iprec * wprec;
        int pipeline_latency = 9;
        int buffer_cycles = 10;
        int cyclecount = countdown_val + pipeline_latency + oprec + buffer_cycles;

        apb_strb = apb_strb_t'(4'hF);

        // Check that the MVU number is okay
        checkmvu(mvu);

        // Configure paramters on the port of the DUT

        apb_data = apb_data_t'({6'b0, isign, wsign, 6'b0, BPREC'(oprec),BPREC'(iprec),BPREC'(wprec)});
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUPRECISION});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'({BQMSBIDX'(omsb)});
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUQUANT});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(BWBANKA'(waddr));
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUWBASEPTR});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(BDBANKA'(iaddr));
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUIBASEPTR});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(BSBANKA'(saddr));
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUSBASEPTR});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(BBBANKA'(baddr));
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUBBASEPTR});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'({BDBANKA'({obank_sel, oword_sel})});
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUOBASEPTR});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'({NMVU'(omvu)});
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUOMVUSEL});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'({BJUMP'(wprec)});
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUWJUMP_0});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'({BJUMP'(-wprec*(m_w-1))});
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUWJUMP_1});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'({BJUMP'(wprec)});
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUWJUMP_2});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
        
        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUWJUMP_3});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
        
        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUWJUMP_4});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'({BJUMP'(-iprec*(m_w-1))});
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUIJUMP_0});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'({BJUMP'(iprec)});
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUIJUMP_1});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUIJUMP_2});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
        
        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUIJUMP_3});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
        
        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUIJUMP_4});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUOJUMP_0});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUOJUMP_1});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUOJUMP_2});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
        
        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUOJUMP_3});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
        
        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUOJUMP_4});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);


        apb_data = apb_data_t'(BLENGTH'(wprec*iprec-1));
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUWLENGTH_1});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(BLENGTH'(m_w-1));
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUWLENGTH_2});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUWLENGTH_3});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUWLENGTH_4});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);


        apb_data = apb_data_t'(BLENGTH'(m_h-1));
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUILENGTH_1});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(BLENGTH'(0));
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUILENGTH_2});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUILENGTH_3});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUILENGTH_4});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);


        apb_data = apb_data_t'(BLENGTH'(1));
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUOLENGTH_1});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(BLENGTH'(0));
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUOLENGTH_2});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUOLENGTH_3});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(0);
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUOLENGTH_4});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        apb_data = apb_data_t'(BSCALERB'(scaler));
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUSCALER});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

        
        // Load the shift/accumulator on when weight address jump 0 happens
        // Bump the zig-zag on weight jumps 1 and 0
        apb_data = apb_data_t'({NJUMPS'(5'b00011), NJUMPS'(5'b00001)});
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUCONFIG1});
        apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

    // Scaler and bias memory parameters
        if (usescalarmem) begin
            
            apb_data = apb_data_t'(1'b1);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUUSESCALER_MEM});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

            apb_data = apb_data_t'(1'b1);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUSJUMP_0});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUSJUMP_1});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUSJUMP_2});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUSJUMP_3});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUSJUMP_4});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUSLENGTH_1});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUSLENGTH_2});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUSLENGTH_3});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUSLENGTH_4});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
        end else begin
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUUSESCALER_MEM});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
        end
        if (usebiasmem) begin
            apb_data = apb_data_t'(1'b1);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUUSEBIAS_MEM});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

            apb_data = apb_data_t'(1'b1);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUBJUMP_0});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUBJUMP_1});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUBJUMP_2});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUBJUMP_3});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUBJUMP_4});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);

            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUBLENGTH_1});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUBLENGTH_2});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUBLENGTH_3});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUBLENGTH_4});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
        end else begin
            apb_data = apb_data_t'(1'b0);
            apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUUSEBIAS_MEM});
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
        end

        // Run the GEMV
        maxpool_en = 1'b1;
        mul_mode = 2'b01;
        apb_data = apb_data_t'({ mul_mode, maxpool_en ,BCNTDWN'(countdown_val)});
        apb_addr = apb_addr_t'({3'(mvu), mvu_pkg::CSR_MVUCOMMAND});
        fork
            apb_master.write(apb_addr, apb_data, apb_strb, apb_resp);
            wait_for_irq(mvu);
        join
        wait_for_pipeline_after_irq(oprec);
    endtask
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
        // for (int i=0; i<NMVU; i++) begin
        //     apb_addr = apb_addr_t'({3'(i), mvu_pkg::CSR_MVUCOMMAND});
        //     apb_strb = apb_strb_t'(4'hF);
        //     apb_master.write(apb_addr, apb_data_t'(1), apb_strb, apb_resp);
        // end
        
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