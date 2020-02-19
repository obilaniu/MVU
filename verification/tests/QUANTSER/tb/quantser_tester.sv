/***** Test Module quantser_tester *****/

/* Inports */
import utils::*;

/* Macros */
`timescale 1 ns / 100 ps
`define CLKPERIOD 10

/* Test paramters */
`define NUM_TEST_VECS 10


module quantser_tester();


/* Module Parameters */
localparam  BDIN        = 32;                 // Input data bit depth
localparam  BDOUTMAX    = 32;                 // Maximum output data precision bit length (must be < BDIN)

/* Computed module parameters */
localparam  MAXBDIP   = $clog2(BDIN);       // 
localparam  MAXBDOP   = $clog2(BDOUTMAX);   // 

/* Signals for DUT */
reg                                    clk;        // Clock
reg                                    clr;        // Clears the state and output reg
reg    unsigned[    MAXBDIP-1 : 0]     msbidx;     // Bit position of MSB in input
reg    unsigned[    MAXBDOP-1 : 0]     bdout;      // Bit depth of output
reg                                    start;      // Pos-edge trigger to start serializing output
reg    unsigned[       BDIN-1 : 0]     din;        // Input data
wire                                   dout;       // Serialized output



/* Create Instace of DUT */
quantser #(
    .BDIN       (       BDIN),
    .BDOUTMAX   (   BDOUTMAX)
) dut (
    .clk        (        clk),
    .clr        (        clr),
    .msbidx     (     msbidx),
    .bdout      (      bdout),
    .start      (      start),
    .din        (        din),
    .dout       (       dout)
);


reg    unsigned[       BDIN-1 : 0]  test_out;   // deserialized output

/* Function: predict */
/* Predicts the expected output */
function int predict(int x, int bd, int msb);
    int mask = 32'hFFFFFFFF >> (32 - bd);
    int x_pred = (x >> (msb-bd+1)) & mask;
    return x_pred;
endfunction;


/* Macro: Quantization test block*/
`define testBlock(bd, msb, d) \
    test_out <= 0; \
    print($sformatf("Test: bdout=%2d,  msbidx=%2d,  din=b%b", bd, msb, d)); \
    if (msb<bd-1) begin \
        print("msbidx < bd! Wacky behaviour may ensue!", "WARNING"); \
    end \
    if (msb > BDOUTMAX-1 || bd > BDOUTMAX) begin \
        print($sformatf("msbidx or bd is out of range!"), "WARNING"); \
    end \
    din <= d; \
    bdout <= bd - 1; \
    msbidx <= msb; \
    start <= 1; \
    #(`CLKPERIOD); \
    start <= 0; \
    for (int i=0; i < bd; i++) begin \
        test_out <= test_out << 1; \
        test_out[0] <= dout; \
        #(`CLKPERIOD); \
    end \
    dout_pred = predict(d, bd, msb); \
    if (test_out == dout_pred) begin \
        res_str = "PASS"; \
        test_stat.pass_cnt+=1; \
    end \
    else begin \
        res_str = "FAIL"; \
        test_stat.fail_cnt+=1; \
    end \
    print($sformatf("  dout=b%32b (%d), Expected: %b [%s]", test_out[bd-1:0], test_out[bd-1:0], dout_pred, res_str));


/* Clock */
initial begin 
    clk = 0;
    //#(`CLKPERIOD/2);
    forever begin
        #(`CLKPERIOD/2);
        clk = !clk;
    end
end

/* Run Tests */
initial begin
    string msg;
    string res_str;
    int dout_pred;
    automatic test_stats test_stat;
    print_banner("Testing quantser");
 
    // Initialize signals
    clr <= 1;

    // Wait for signals to settle
    #(`CLKPERIOD*10);
    clr <= 0;

    // --------------
    // Boundary tests
    // --------------

    // Test 1-bit quantization
    `testBlock(1, 0, 1)
    `testBlock(1, 3, 1<<3)
    `testBlock(1, 31, 1<<31)
 
    // Test 2-bit quantization
    `testBlock(2, 1, 1<<1)
    `testBlock(2, 3, 1<<3)
    `testBlock(2, 31, 1<<31)

    // Test 32-bit quantization\
    `testBlock(32, 31, 5)


    // --------------
    // Random tests
    // --------------

    print_result(test_stat, VERB_LOW);
    $finish();
end

endmodule