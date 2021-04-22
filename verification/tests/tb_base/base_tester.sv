
class base_tester extends testbench_base;

    function new(Logger logger, virtual mvu_interface inf);
        super.new(logger, inf);
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
