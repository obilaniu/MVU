`timescale 1ns/1ps

`ifdef TB_GEMV
    `include "gemv_tester.sv"
`elsif TB_SCALARBIAS
    `include "scalar_bias_tester.sv"
`else
    `include "base_tester.sv"
`endif

`include "mvu_inf.svh"

module testbench_top import utils::*;import testbench_pkg::*; ();
//==================================================================================================
// Test variables
    Logger logger;
    string sim_log_file = "test.log";
//==================================================================================================
    logic clk;
    mvu_interface mvu_inf(clk);
    mvutop mvu(mvu_inf.system_interface);

    // Select which testbench to run
`ifdef TB_GEMV 
    gemv_tester tb;
`elsif TB_SCALARBIAS
    scalar_bias_tester tb;
`else
    base_tester tb;
`endif

    initial begin
        logger = new(sim_log_file);
        tb = new(logger, mvu_inf.tb_interface);

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
