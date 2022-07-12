`timescale 1ns/1ps

`ifdef TB_GEMV
    `include "gemv_tester.sv"
// `elsif TB_SCALARBIAS
//     `include "scalar_bias_tester.sv"
// `elsif TB_HIGHPREC
//     `include "highprecision_tester.sv"
// `else
//     `include "base_tester.sv"
`endif

`include "assign.svh"

module testbench_top import utils::*;import testbench_pkg::*; ();
//==================================================================================================
// Test variables
    Logger logger;
    string sim_log_file = "test.log";
//==================================================================================================
    logic clk;

    APB_DV #(
        .ADDR_WIDTH(mvu_pkg::APB_ADDR_WIDTH), 
        .DATA_WIDTH(mvu_pkg::APB_DATA_WIDTH)
    ) apb_slave_dv(clk);
    APB #(
        .ADDR_WIDTH(mvu_pkg::APB_ADDR_WIDTH), 
        .DATA_WIDTH(mvu_pkg::APB_DATA_WIDTH)
    ) apb_slave();
    `APB_ASSIGN ( apb_slave, apb_slave_dv )
    
    MVU_EXT_INTERFACE mvu_ext(clk);
    mvutop_wrapper mvutop_wrapper(mvu_ext, apb_slave);

    // Select which testbench to run
`ifdef TB_GEMV 
    gemv_tester tb;
// `elsif TB_SCALARBIAS
//     scalar_bias_tester tb;
// `elsif TB_HIGHPREC
//     highprecision_tester tb;
// `else
//     base_tester tb;
`endif

    initial begin
        logger = new(sim_log_file);
        tb = new(logger, mvu_ext, apb_slave_dv);

        tb.tb_setup();
        tb.run();
        tb.report();
        $finish();

    end

//==================================================================================================
// Simulation specific Threads

    initial begin 
        $timeformat(-9, 2, " ns", 12);
        clk = 0;
        forever begin
            #((CLOCK_SPEED)*1ns) clk = !clk;
        end
    end

    initial begin
        #((TB_TIME_OUT_MS)*1ms);
        $display("Simulation took more than expected ( more than 1ms)");
        $finish();
    end
endmodule
