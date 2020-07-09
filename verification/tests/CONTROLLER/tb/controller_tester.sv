//
// Testbench for controller
//

import utils::*;

// Clock parameters
`define SIM_TIMEOUT 1
`define CLKPERIOD 10ns

`timescale 1 ps / 1 ps


module controller_tester;

// Parameters
localparam              BCNTDWN = 29;       // Bitwidth of countdown counter

// Wires
reg                     clk;                // Clock signal
reg                     clr;                // Clears the internal state
reg                     start;              // Pulse to start the MVU task
reg[BCNTDWN-1 : 0]      countdown;          // Number of clock cycles for the task
reg                     step;               // Count down if 1. Used for stalling.
wire                    run;                // Indicates that the task is running
wire                    done;               // Indicates that the task is done
wire                    irq;                 // Interrupt request to the embedded CPU


// DUT
controller #(
    .BCNTDWN    (BCNTDWN)
) dut (
    .clk        (clk),
    .clr        (clr),
    .start      (start),
    .countdown  (countdown),
    .step       (step),
    .run        (run),
    .done       (done),
    .irq        (irq)
);


// Clock generator
initial begin 
    clk = 0;
    #(`CLKPERIOD/2);
    forever begin
        #(`CLKPERIOD/2);
        clk = !clk;
    end
end

//
// Tests
//
initial begin
    
    // Initialize signals
    assign clr = 1;
    assign start = 0; 
    assign countdown = 0;
    assign step = 0;

    #(`CLKPERIOD*10);

    // Release the clr
    assign clr = 0;
    #(`CLKPERIOD*2);

    // Test 1: trigger start with countdown at 0
    // Should cause the state machine to get stuck in run state
    assign start = 1;
    #(`CLKPERIOD);
    assign start = 0;
    #(`CLKPERIOD*10);
    assign clr = 1;
    #(`CLKPERIOD);
    assign clr = 0;
    #(`CLKPERIOD*2);

    // Test 2: set countdown of 10 and trigger start
    assign countdown = 10;
    assign step = 1;
    assign start = 1;
    #(`CLKPERIOD);
    assign start = 0;
    #(`CLKPERIOD*12);

    // Test 3: set countdown of 20 and trigger start
    assign countdown = 20;
    assign step = 1;
    assign start = 1;
    #(`CLKPERIOD);
    assign start = 0;
    #(`CLKPERIOD*22);    


    print_banner($sformatf("Simulation done."));
    $finish();
end


endmodule