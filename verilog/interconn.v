/**
 * Interconnect between MVUs
 */

`timescale 1ns/1ps
/* Module */
module interconn (clk, clr,
                  send_to, send_en, send_addr, send_word, 
                  recv_from,
                  recv_en, recv_addr, recv_word);

/* Parameters */
parameter   N = 8;              // Number of MVUs
parameter   W = 64;             // Biwidth of the data words
parameter   BADDR = 15;         // Biwidth of the address words

// Port
input  wire                     clk;
input  wire                     clr;
input  wire [N*N-1   : 0]       send_to;        // MVUs to send to (selectors bits)
input  wire [N-1   : 0]         send_en;
input  wire [N*BADDR-1   : 0]   send_addr;      // Memory address to write to
input  wire [N*W-1 : 0]         send_word;      // Data to send
output reg  [N*N-1 : 0]         recv_from;      // Receive from MVU ID
output reg  [N-1   : 0]         recv_en;        // 
output reg  [N*BADDR-1   : 0]   recv_addr;      // Memory address to write to
output reg  [N*W-1 : 0]         recv_word;      // Data received

// Internal signals and registers
wire  [N-1 : 0] send_to_bo [N-1 : 0];                   // Breakout of send_to
wire  [BADDR-1 : 0] send_addr_xb [N-1 : 0][N-1 :0];     // Array [source][destination]
wire  [N-1 : 0] send_addr_t [N-1 : 0][BADDR-1 : 0];     // Transpose of send_addr
wire  [W-1 : 0] send_word_xb [N-1 : 0][N-1 : 0];
wire  [N-1 : 0] send_word_t [N-1 : 0][W-1 : 0];
wire  [N-1 : 0] recv_from_c [N-1 : 0];                  // Receive from MVU ID
wire  [N-1 : 0] recv_en_c;                              // 
wire  [BADDR-1 : 0] recv_addr_c [N-1 : 0];              // Memory address to write to
wire  [W-1 : 0] recv_word_c [N-1 : 0];                  // Data received
wire  [N-1 : 0] switch [N-1 : 0];                       // Switch controls in crossbar
wire  [N-1 : 0] switch_t [N-1 : 0];                     // Switch controls in crossbar transposed

genvar i, j, k;


//
// Crossbar Logic
//

// If there is more than one port, generate a crossbar
generate if(N > 1) begin: multiple

    // Breakout the send_to bus
    for (i=0; i < N; i=i+1) begin: loop_send_to
        assign send_to_bo[i] = send_to[i*N +: N];
    end

    // Generate the outgoing busses at the switch points in the crossbar
    // The 'i' busses are the source, the 'j' busses are the destination
    // The switch control is the sel signal at the cross point.
    for (i=0; i < N; i=i+1) begin: loop_busses_xb_i
        for (j=0; j < N; j=j+1) begin: loop_busses_xb_j
            assign switch[i][j] = send_to_bo[i][j] & send_en[i];
            assign send_addr_xb[i][j] = switch[i][j] ? send_addr[i*BADDR +: BADDR] : 0;
            assign send_word_xb[i][j] = switch[i][j] ? send_word[i*W +: W] : 0;
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
                recv_addr[i*BADDR +: BADDR] <= 0;
                recv_from[i*N +: N] <= 0;
                recv_word[i*W +: W] <= 0;
            end else if(clk) begin
                recv_from[i*N +: N] <= recv_from_c[i];
                recv_en[i] <= recv_en_c[i];
                recv_addr[i*BADDR +: BADDR] <= recv_addr_c[i];
                recv_word[i*W +: W] <= recv_word_c[i];
            end
        end
    end


// ...otherwise, just connect the signals directly
end else begin:single
    always @(posedge clk or posedge clr) begin
        if(clr) begin
            recv_en <= 0;
            recv_addr <= 0;
            recv_from <= 0;
            recv_word <= 0;
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
