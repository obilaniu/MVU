/***** Test Module quantser_tester *****/

/* Inports */
import utils::*;

/* Macros */
`timescale 1 ns / 100 ps
`define CLKPERIOD 10


module maxpool_tester();

/* Parameters */
parameter N = 32;

logic                 clk;
logic                 max_clr;
logic                 max_pool;
logic signed[N-1 : 0] I;
logic signed[N-1 : 0] O;

// DUT
maxpool #(
    .N(N)
) maxpool_dut (
    .clk(clk),
    .max_clr(max_clr),
    .max_pool(max_pool),
    .I(I),
    .O(O)
);

// Test logging
Logger logger;
string sim_log_file = "test.log";
test_stats_t test_stat;

// Test functions
task testRelu(int in, int expected);
    int out;
    string res_str;

    max_pool = 1;
    I = in;
    #(`CLKPERIOD*1);
    out = O;

    if (out == expected) begin
        res_str = "PASS";
        test_stat.pass_cnt+=1;
    end
    else begin
        res_str = "FAIL";
        test_stat.fail_cnt+=1;
    end

    // Print results
    logger.print($sformatf("in=%d, out=%d [%s]", in, out, res_str)); 
        
endtask


/* Clock */
initial begin 
    clk = 0;
    //#(`CLKPERIOD/2);
    forever begin
        #(`CLKPERIOD/2);
        clk = !clk;
    end
end

/* Main test process */
initial begin

    logger = new(sim_log_file);

    // Initialize signals
    max_clr = 1;
    max_pool = 0;
    I = 0;

    #(`CLKPERIOD*10);

    // Test 1: simple ReLU with 0
    testRelu(0, 0);
    #(`CLKPERIOD*1);

    // Test 2: simple ReLU with positive number
    testRelu(25, 25);
    #(`CLKPERIOD*1);

    // Test 3: simple ReLU with negative number
    testRelu(-45, 0);
    #(`CLKPERIOD*1);


    print_result(test_stat, VERB_LOW, logger);
    $finish();
end


endmodule