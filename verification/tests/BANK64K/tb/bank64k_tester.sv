//
// Testbench for bank64k component
//
// Sean Wagner
// wagnerse@ca.ibm.com
//
// This runs a simple test to write data into and out of BRAMs. Tests pass if the data written
// into a particular address location is read out with the same value.
//


`timescale 1 ns / 100 ps
import utils::*;

`define SIM_TIMEOUT 1 //us
`define CLKPERIOD 10 //ns

/**** Test Module bank64k_tester ****/
module bank64k_tester();

//
// Parameters
//

// Data bus width
parameter  w = 64;

// Address width
parameter  a =   10;

// Switch for dual-port BRAM collision warnings in simulation.
// The warnings make the output too verbose, such that it's makes it hard to find the pass/fail counts print out
// 1 = no warnings, 0 = get warnings
parameter C_DISABLE_WARN_BHV_COLL = 1;


// Create input signals
/* Interface */
reg          clk;

reg          rd_en;
reg[a-1 : 0] rd_addr;
reg[  1 : 0] rd_muxcode;
reg          wr_en;
reg[a-1 : 0] wr_addr;
reg[  1 : 0] wr_muxcode;

wire[w-1 : 0] rdi_word;
wire[w-1 : 0] rdd_word;
wire[w-1 : 0] rdc_word;

reg[w-1 : 0] wri_word;
reg[w-1 : 0] wrd_word;
reg[w-1 : 0] wrc_word;


// Create instance
bank64k #(w, a, C_DISABLE_WARN_BHV_COLL) dut (
    clk,
    rd_en,    rd_addr, rd_muxcode,
    wr_en,    wr_addr, wr_muxcode,
    rdi_word, wri_word,
    rdd_word, wrd_word,
    rdc_word, wrc_word
);


//
// Helper functions/macros
//

// Macro: readWriteTest
`define readWriteTest(addr, wr_word_reg, rd_word_reg) \
    std::randomize(wr_word_reg); \
 //   $display("w_word=0x%H", wr_word_reg); \
    wr_addr = addr; \
    wr_en = 1'b1; \
    #`CLKPERIOD; \
    wr_en = 1'b0; \
    rd_addr = addr; \
    #(`CLKPERIOD*3); \
 //   $display("r_word=0x%H", rd_word_reg); \
    if (rd_word_reg == wr_word_reg) begin \
        test_stat.pass_cnt += 1; \
    end \
    else begin \
        test_stat.fail_cnt += 1; \
    end



// Clock
initial begin 
    clk = 0;
    #(`CLKPERIOD/2);
    forever begin
        #(`CLKPERIOD/2);
        clk = !clk;
    end
end


//
// Run tests
//
initial begin
    // Variables for the tests
    automatic test_stats test_stat;

    print_banner("Testing bank64k");

    // Initialize signals
    rd_en = 1'b0;
    rd_addr = {a{1'b0}};
    rd_muxcode = 2'b00;
    wr_en = 1'b0;
    wr_addr = {a{1'b0}};
    wr_muxcode = 2'b00;
    wri_word = {w{1'b0}};
    wrd_word = {w{1'b0}};
    wrc_word = {w{1'b0}};

    // Wait for signals to settle
    #(`CLKPERIOD*10);

    // Do tests with each set of r/w interfaces
    // Start with wri/rdi interface
    print("Testing wri/rdi...");
    for (int i=0; i < 2**a; i++) begin
        `readWriteTest(i, wri_word, rdi_word)
    end
    print("wri/rdi results:");
    print_result(test_stat, VERB_LOW);
    resetTestStats(test_stat);

    // Now do wrd/rdd interface
    print("Testing wri/rdi...");
    rd_muxcode = 2'b01;
    wr_muxcode = 2'b01;
    for (int i=0; i < 2**a; i++) begin
        `readWriteTest(i, wrd_word, rdd_word)
    end
    print("wrd/rdd results:");
    print_result(test_stat, VERB_LOW);
    resetTestStats(test_stat);

    // Now do wrc/rdc interface
    print("Testing wri/rdi...");
    rd_muxcode = 2'b10;
    wr_muxcode = 2'b10;
    for (int i=0; i < 2**a; i++) begin
        `readWriteTest(i, wrc_word, rdc_word)
    end
    print("wrc/rdc results:");
    print_result(test_stat, VERB_LOW);
    resetTestStats(test_stat);

    // End test
    #(`SIM_TIMEOUT*1us);

    $finish();
end

endmodule