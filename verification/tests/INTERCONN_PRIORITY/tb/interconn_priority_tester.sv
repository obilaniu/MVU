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


module interconn_priority_tester();

/* Parameters */
parameter   N = 8;              // Number of MVUs
parameter   W = 64;          // Biwidth of the data words
parameter   BADDR = 15;         // Biwidth of the address words


// DUT port signals
logic                     clk;
logic                     clr;
logic [N-1   : 0]         send_to [N-1 : 0];        // MVUs to send to (selectors bits)
logic                     send_en [N-1 : 0];
logic [BADDR-1   : 0]     send_addr [N-1 : 0];      // Memory address to write to
logic [W-1 : 0]           send_word [N-1 : 0];      // Data to send

logic [N-1 : 0]           recv_from [N-1 : 0];      // Receive from MVU ID
logic                     recv_en [N-1 : 0];        // 
logic [BADDR-1   : 0]     recv_addr [N-1 : 0];      // Memory address to write to
logic [W-1 : 0]           recv_word [N-1 : 0];      // Data received

// Testbench signals
logic [W-1 : 0]           testword;



//
// DUT
//
interconn_priority #(
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
test_stats_t test_stat;
Logger logger;
string sim_log_file = "test.log";

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
    logger.print_banner($sformatf("Simulation took more time than expected ( more than %0dms)", `SIM_TIMEOUT), "ERROR");
    $finish();
end


// =================================================================================================
// Tasks and functions
task sendData(int from[], int to[], logic[BADDR-1 : 0] addr, logic[W-1 : 0] word);

    foreach (from[j]) begin
        send_to[from[j]] = 0;
        foreach (to[i]) begin
            send_to[from[j]] |= 1 << to[i];
        end
        send_addr[from[j]] = addr;
        send_word[from[j]] = word;
        send_en[from[j]] = 1;
    end
    #(`CLKPERIOD);
    foreach (from[j]) begin
        send_en[from[j]] = 0;
    end

endtask

task sendDataAndCheck(int from[], int to[], logic[BADDR-1 : 0] addr, logic[W-1 : 0] word);
    string res_str;
    logic [W-1 : 0] word_out;
    logic [BADDR-1 : 0] addr_out;
    logic en_out;
    logic [N-1 : 0] from_out;

    sendData(from, to, addr, word);

    // Check the output
    foreach (from[j]) begin
        foreach (to[i]) begin
            word_out = recv_word[to[i]];
            addr_out = recv_addr[to[i]];
            en_out = recv_en[to[i]];
            from_out = recv_from[to[i]];
            if ((word == word_out[W-1 : 0]) && (addr == addr_out) && en_out && (from_out == (1 << from[j]))) begin
                res_str = "PASS";
            end
            else begin
                res_str = "FAIL";
                break;    
            end
        end
    end

    if (res_str == "PASS") begin
        test_stat.pass_cnt+=1;  
    end else begin
        test_stat.fail_cnt+=1;    
    end

    logger.print($sformatf("from=%d, to=%s, addr=%x, word=%x %s", from, array2str(to), addr, word, res_str));

endtask;



// =================================================================================================
// Main test thread

initial begin

    logger = new(sim_log_file);

    // Initialize signals
    clr = 1;

    for (int i = 0; i < N; i++) begin
        send_to[i] = 0;
        send_en[i] = 0;
        send_addr[i] = 0;
        send_word[i] = 0;
    end

    #(`CLKPERIOD*10);

    // Come out of reset
    clr = 0;
    #(`CLKPERIOD*10);

    // Test all permutations for 1-to-1
    logger.print_banner($sformatf("1-1 tests"));
    for (int i = 0; i < N; i++) begin
        if (i % 2) begin
            testword = 'hdeadbeefdeadbeef;
        end else begin
            testword = 'hbeefdeadbeefdead;
        end
        for (int j = 0; j < N; j++) begin
            sendDataAndCheck('{i}, '{j}, i+j+1, testword);
        end
    end

    // Test broadcasting
    logger.print_banner($sformatf("Broadcast tests: send to 2 neighbouring destinations."));
    for (int i = 0; i < N; i++) begin
         if (i % 2) begin
            testword = 'hdeadbeefdeadbeef;
        end else begin
            testword = 'hbeefdeadbeefdead;
        end
        for (int j = 0; j < N; j++) begin
            sendDataAndCheck('{i}, '{j,(j+1)%N}, i+j+1, testword);
        end
    end

    // Test broadcasting
    logger.print_banner($sformatf("Broadcast tests: send to 3 neighbouring destinations."));
    for (int i = 0; i < N; i++) begin
         if (i % 2) begin
            testword = 'hdeadbeefdeadbeef;
        end else begin
            testword = 'hbeefdeadbeefdead;
        end
        for (int j = 0; j < N; j++) begin
            sendDataAndCheck('{i}, '{j,(j+1)%N,(j+2)%N}, i+j+1, testword);
        end
    end

    // End
    print_result(test_stat, VERB_LOW, logger);

    logger.print_banner($sformatf("Simulation done."));
    $finish();


end


endmodule