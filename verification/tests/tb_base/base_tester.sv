
`include "testbench_base.sv"

class base_tester extends mvu_testbench_base;

    function new(Logger logger, virtual MVU_EXT_INTERFACE mvu_ext_if,  virtual APB_DV#(.ADDR_WIDTH(mvu_pkg::APB_ADDR_WIDTH), .DATA_WIDTH(mvu_pkg::APB_DATA_WIDTH))  apb);
        super.new(logger, mvu_ext_if, apb);
    endfunction

    task tb_setup();
        super.tb_setup();
    endtask

    task run();
        logger.print_banner("Testbench Run phase");
    endtask

    task report();
        super.report();
    endtask

endclass
