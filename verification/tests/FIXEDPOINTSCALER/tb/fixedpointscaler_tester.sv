//
// Test Module fixedpointscaler_tester
//
//

import utils::*;

// Clock parameters
`define SIM_TIMEOUT 1
`define CLKPERIOD 10ns

`timescale 1 ps / 1 ps


module fixedpointscaler_tester();

//==================================================================================================
// Parameters
localparam BA     = 27;
localparam BB     = 16;
localparam BC     = 27;
localparam BD     = 27;
localparam BP     = 45;

// =================================================================================================
// Typedefs
typedef logic signed [BA-1 : 0]     a_type;
typedef logic signed [BA+BB : 0]    m_type;
typedef logic signed [BP-1 : 0]     p_type;


//==================================================================================================
// Signals
reg                                clk;            // clock
reg                                clr;            // clear/reset
reg    signed      [BA-1 : 0]      a;
reg    signed      [BB-1 : 0]      b;              // multiplier
reg    signed      [BC-1 : 0]      c;
reg    signed      [BD-1 : 0]      d;              // multiplicand
reg    signed      [BP-1 : 0]      p;              // output product

//==================================================================================================
// DUT
fixedpointscaler #(
    .BA(BA),
    .BB(BB),
    .BC(BC),
    .BD(BD),
    .BP(BP)
) dut
(
    .clk(clk),
    .clr(clr),
    .a(a),
    .b(b),
    .c(c),
    .d(d),
    .p(p)
 );


//==================================================================================================
// Simulation specific Threads

// Clock generator
initial begin 
    clk = 0;
    #(`CLKPERIOD/2);
    forever begin
         #(`CLKPERIOD/2);
         clk = !clk;
    end
end

// Simulation timeout
initial begin
    #(`SIM_TIMEOUT*1ms);
    print_banner($sformatf("Simulation took more than expected ( more than %0dms)", `SIM_TIMEOUT), "ERROR");
    $finish();
end


// =================================================================================================
// Utility functions

task print_signals();
    print($sformatf("a=%d, b=%d, c=%d, d=%d, p=%d", a, b, c, d, p));
endtask


task random_tests(int count);
    string res_str;
    automatic longint expected = 0;
    automatic test_stats test_stat;

    for (int i = 0; i < count; i++) begin
        std::randomize(a);
        std::randomize(b);
        std::randomize(c);
        std::randomize(d);
        expected = p_type'(m_type'((a_type'(a+d))*(int'(b))) + int'(c)); // + longint'(c);

        #(`CLKPERIOD*4);

        if (expected == p) begin
            res_str = "PASS";
            test_stat.pass_cnt+=1;
        end else begin
            res_str = "FAIL";
            test_stat.fail_cnt += 1;
        end
        print($sformatf("a=%d, b=%d, c=%d, d=%d, p=%d, expected=%d [%s]", a, b, c, d, p, expected, res_str));
    end
    print_result(test_stat, VERB_LOW);

endtask

// =================================================================================================
// Main test thread

initial begin

    // Initialize signals
    clr = 1;
    a = 0;
    b = 0;
    c = 0;
    d = 0;

    #(`CLKPERIOD*10);

    // Come out of reset
    clr = 0;
    #(`CLKPERIOD*10);


    //-------------------
    // Simple tests

    print_banner("Simple tests");

    // Set b to 1, expect 0 at output
    b = 1;
    #(`CLKPERIOD*4);
    print_signals();

    // Set a to 1, expect 1 at output
    a = 1;
    #(`CLKPERIOD*4);
    print_signals();

    // Set a to 2, expect 2 at output
    a = 2;
    #(`CLKPERIOD*4);
    print_signals();

    // Set b to 2, expect 4 at output
    b = 2;
    #(`CLKPERIOD*4);
    print_signals();

    // Set c to 1, expect 5 at output
    c = 1;
    #(`CLKPERIOD*4);
    print_signals();

    // Set d to 1, expect 7 at output
    d = 1;
    #(`CLKPERIOD*4);
    print_signals();


    //-----------------------------
    // Random tests
    print_banner("Random tests");
    random_tests(20);


    print_banner($sformatf("Simulation done."));
    $finish();

end


endmodule