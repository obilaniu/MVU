//
// Test Module interconn_tester
//
// Notes:
// * For wlength_X and ilength_X parameters, the value to is actual_length - 1.
//


import utils::*;

// Clock parameters
`define SIM_TIMEOUT 1
`define CLKPERIOD 10ns

`timescale 1 ps / 1 ps


module interconn_tester();

/* Parameters */
parameter   N = 8;              // Number of MVUs
parameter   W = 64;             // Biwidth of the data words
parameter   BADDR = 15;         // Biwidth of the address words

reg                     clk;
reg                     clr;
reg [N*N-1   : 0]       send_to;        // MVUs to send to (selectors bits)
reg [N-1   : 0]         send_en;
reg [N*BADDR-1   : 0]   send_addr;      // Memory address to write to
reg [N*W-1 : 0]         send_word;      // Data to send

reg [N*N-1 : 0]         recv_from;      // Receive from MVU ID
reg [N-1   : 0]         recv_en;        // 
reg [N*BADDR-1   : 0]   recv_addr;      // Memory address to write to
reg [N*W-1 : 0]         recv_word;      // Data received



//
// DUT
//
interconn #(
    .N(N),
    .W(W),
    .BADDR(BADDR)
) dut (
    .clk(clk),
    .clr(clr),
    .send_to(send_to),
    .send_en(send_en),
    .send_addr(send_addr),
    .send_word(send_word), 
    .recv_from(recv_from),
    .recv_en(recv_en),
    .recv_addr(recv_addr),
    .recv_word(recv_word)
);


// Variables
test_stats test_stat;


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
    print_banner($sformatf("Simulation took more time than expected ( more than %0dms)", `SIM_TIMEOUT), "ERROR");
    $finish();
end


// =================================================================================================
// Tasks and functions
task sendData(int from, int to, logic[BADDR-1 : 0] addr, logic[W-1 : 0] word);

    send_to = 1 << (from*N + to);
    send_addr[from*BADDR +: BADDR] = addr;
    send_word[from*W +: W] = word;
    send_en = 1 << from;
    #(`CLKPERIOD);

endtask

task sendDataAndCheck(int from, int to, logic[BADDR-1 : 0] addr, logic[W-1 : 0] word);
    string res_str;
    logic [W-1 : 0] word_out;
    logic [BADDR-1 : 0] addr_out;
    logic en_out;
    logic [N-1 : 0] from_out;

    sendData(from, to, addr, word);

    #(`CLKPERIOD);

    word_out = (recv_word >> to*W);
    addr_out = (recv_addr >> to*BADDR);
    en_out = (recv_en >> to);
    from_out = (recv_from >> to*N);
    
    if ((word == word_out[W-1 : 0]) && (addr == addr_out) && en_out && (from_out == (1 << from))) begin
        res_str = "PASS";
        test_stat.pass_cnt+=1;
    end
    else begin
        res_str = "FAIL";
        test_stat.fail_cnt+=1;       
    end

    print($sformatf("from=%d, to=%d, addr=%x, word=%x %s", from, to, addr, word, res_str));
    //print($sformatf("from_out=%b, en_out=%b, addr_out=%x, word_out=%x", from_out, en_out, addr_out, word_out));
    //print($sformatf("recv_from=%b, recv_en=%b, recv_addr=%x, recv_word=%x", recv_from, recv_en, recv_addr, recv_word));

endtask;



// =================================================================================================
// Main test thread

initial begin

    // Initialize signals
    clr = 1;
    send_to = 0;
    send_en = 0;
    send_addr = 0;
    send_word = 0;

    #(`CLKPERIOD*10);

    // Come out of reset
    clr = 0;
    #(`CLKPERIOD*10);

    // Test all permutations for 1-to-1
    for (int i = 0; i < N; i++) begin
        for (int j = 0; j < N; j++) begin
            if (i != j) begin
                sendDataAndCheck(i, j, 7, 'hdeadbeefdeadbeef);
            end
        end
    end



    // End
    print_result(test_stat, VERB_LOW);

    print_banner($sformatf("Simulation done."));
    $finish();


end


endmodule