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


//==================================================================================================
// Signals
reg                                clk;            // clock
reg                                clr;            // clear/reset
reg    signed      [BA-1 : 0]      a;
reg                [BB-1 : 0]      b;              // multiplier
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

    print_banner($sformatf("Simulation done."));
    $finish();

end


endmodule