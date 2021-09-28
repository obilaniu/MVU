/**
 * Interconnect between MVUs
 */

`timescale 1ns/1ps
/* Module */
module interconn_new (clk, clr,
                  send_to, send_en, send_addr, send_word, 
                  recv_from,
                  recv_en, recv_addr, recv_word);

/* Parameters */
parameter   N = 8;              // Number of MVUs
parameter   W = 64;             // Bitwidth of the data words
parameter   BADDR = 15;         // Bitwidth of the address words

// Port
input  logic                     clk;
input  logic                     clr;
input  logic [  N-1   : 0]       send_to [N-1 : 0];        // MVUs to send to (selectors bits)
input  logic                     send_en [N-1 : 0];
input  logic [  BADDR-1   : 0]   send_addr [N-1 : 0];      // Memory address to write to
input  logic [  W-1 : 0]         send_word [N-1 : 0];      // Data to send
output logic [  N-1 : 0]         recv_from [N-1 : 0];      // Receive from MVU ID
output logic                     recv_en [N-1 : 0];        // 
output logic [  BADDR-1   : 0]   recv_addr [N-1 : 0];      // Memory address to write to
output logic [  W-1 : 0]         recv_word [N-1 : 0];      // Data received

// Internal signals and registers
logic  [N-1 : 0] send_to_bo [N-1 : 0];                   // Breakout of send_to
logic  [BADDR-1 : 0] send_addr_xb [N-1 : 0][N-1 :0];     // Array [source][destination]
logic  [N-1 : 0] send_addr_t [N-1 : 0][BADDR-1 : 0];     // Transpose of send_addr
logic  [W-1 : 0] send_word_xb [N-1 : 0][N-1 : 0];
logic  [N-1 : 0] send_word_t [N-1 : 0][W-1 : 0];
logic  [N-1 : 0] recv_from_c [N-1 : 0];                  // Receive from MVU ID
logic  [N-1 : 0] recv_en_c;                              // 
logic  [BADDR-1 : 0] recv_addr_c [N-1 : 0];              // Memory address to write to
logic  [W-1 : 0] recv_word_c [N-1 : 0];                  // Data received
logic  [N-1 : 0] switch [N-1 : 0];                       // Switch controls in crossbar
logic  [N-1 : 0] switch_t [N-1 : 0];                     // Switch controls in crossbar transposed

genvar i, j, k;


//
// Crossbar Logic
//

// If there is more than one port, generate a crossbar
generate if(N > 1) begin: multiple

    // Breakout the send_to bus
    for (i=0; i < N; i=i+1) begin: loop_send_to
        assign send_to_bo[i] = send_to[i];
    end

    // Generate the outgoing busses at the switch points in the crossbar
    // The 'i' busses are the source, the 'j' busses are the destination
    // The switch control is the sel signal at the cross point.
    for (i=0; i < N; i=i+1) begin: loop_busses_xb_i
        for (j=0; j < N; j=j+1) begin: loop_busses_xb_j
            assign switch[i][j] = send_to_bo[i][j] & send_en[i];
            assign send_addr_xb[i][j] = switch[i][j] ? send_addr[i] : 0;
            assign send_word_xb[i][j] = switch[i][j] ? send_word[i] : 0;
            assign recv_from_c[j][i] = switch[i][j];
        end
    end


    // Transpose the switch outgoing buses
    // The 'i' busses are the source, the 'j' busses are the destination
    for (i=0; i < N; i=i+1) begin: loop_transpose_bus_i
        for (j=0; j < N; j=j+1) begin: loop_transpose_bus_j

            // Address busses
            for (k=0; k < BADDR; k=k+1) begin: loop_transpose_addr_k
                assign send_addr_t[j][k][i] = send_addr_xb[i][j][k];
            end

            // Data word busses
            for  (k=0; k < W; k=k+1) begin: loop_transpose_word_k
                assign send_word_t[j][k][i] = send_word_xb[i][j][k];
            end

            // Transpose the switch enables
            assign switch_t[j][i] = switch[i][j];
        end
    end

    // Reduce the signals for each destination bus
    for (i=0; i < N; i=i+1) begin: loop_reduxaddr_i

        // Address busses
        for (j=0; j < BADDR; j=j+1) begin: loop_reduxaddr_j
            assign recv_addr_c[i][j] = |send_addr_t[i][j];
        end

        // Data word busses
        for (j=0; j < W; j=j+1) begin: loop_reduxword_j
            assign recv_word_c[i][j] = |send_word_t[i][j];
        end

        // Receive enables
        assign recv_en_c[i] = |switch_t[i];
    end

    for (i=0; i < N; i=i+1) begin: loop_output_regs
        always @(posedge clk or posedge clr) begin
            if(clr) begin
                recv_en[i] <= 0;
                recv_addr[i] <= 0;
                recv_from[i] <= 0;
                recv_word[i] <= 0;
            end else if(clk) begin
                recv_from[i] <= recv_from_c[i];
                recv_en[i] <= recv_en_c[i];
                recv_addr[i] <= recv_addr_c[i];
                recv_word[i] <= recv_word_c[i];
            end
        end
    end


// ...otherwise, just connect the signals directly
end else begin:single
    always @(posedge clk or posedge clr) begin
        if(clr) begin
            recv_en[0] <= 0;
            recv_addr[0] <= 0;
            recv_from [0]<= 0;
            recv_word[0] <= 0;
        end else if(clk) begin
            recv_from <= send_to;
            recv_en <= send_en;
            recv_addr <= send_addr;
            recv_word <= send_word;
        end
    end
end endgenerate


/* Module end */
endmodule
