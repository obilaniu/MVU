/**
 * Interconnect between MVUs with static priority arbitration
 *
 * This module implements an interconnect as a full crossbard with multi-cast capability.
 * 
 * 
 */

`timescale 1ns/1ps
/* Module */
module interconn_priority #(
        parameter   N = 8,              // Number of MVUs
        parameter   W = 64,             // Bitwidth of the data words
        parameter   BADDR = 15          // Bitwidth of the address words
)
(
        input  logic                     clk,
        input  logic                     clr,
        input  logic [  N-1   : 0]       send_to [N-1 : 0],         // MVUs to send to (selectors bits)
        input  logic                     send_en [N-1 : 0],         // Send enable
        input  logic [  BADDR-1   : 0]   send_addr [N-1 : 0],       // Memory address to write to
        input  logic [  W-1 : 0]         send_word [N-1 : 0],       // Data to send
        output logic [  N-1 : 0]         recv_from [N-1 : 0],       // Receive from MVU ID
        output logic                     recv_en [N-1 : 0],         // Receive enable
        output logic [  BADDR-1   : 0]   recv_addr [N-1 : 0],       // Memory address to write to
        output logic [  W-1 : 0]         recv_word [N-1 : 0]        // Data received
);

// Internal signals and registers
logic  [N-1 : 0] requests [N-1 : 0];                     // Request arrays

genvar i, j, k, m;
integer select [N-1 : 0];



//
// Crossbar Logic
//

// If there is more than one port, generate a crossbar
generate if(N > 1) begin: multiple

    // The 'i' busses are the source, the 'j' busses are the destination
    for (j=0; j < N; j=j+1) begin: loop_busses_xb_j

        // For the given destination, select the highest priority source
        // that is currently trying to send. Currenly, the sender with
        // highest priority is the same as the destination. Priority then
        // passes to the next sender in reverse numerical order.
        always_comb begin : select_priority_env
        // Generate the request arrays for the output ports
            for (int i=0; i < N; i=i+1) begin: req_i
                requests[j][i] = send_to[i][j] & send_en[i];
            end
            for (int k=0; k < N; k = k+1) begin: select_priority_enc_loop
                if (requests[j][(k+j+1) % N]) begin
                    select[j] = (k+j+1) % N;
                end
            end
        end

        // Mux in the selected source to the destination
        always @(posedge clk) begin
            if (clr) begin
                recv_en[j] = 0;
                recv_addr[j] = 0;
                recv_from[j] = 0;
                recv_word[j] = 0;
            end else begin
                recv_en[j] = requests[j][select[j]];
                if (requests[j][select[j]]) begin
                    recv_from[j] = 1 << select[j];
                    recv_addr[j] = send_addr[select[j]];
                    recv_word[j] = send_word[select[j]];
                end
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
            recv_from[0] <= send_to[0];
            recv_en[0] <= send_en[0];
            recv_addr[0] <= send_addr[0];
            recv_word[0] <= send_word[0];
        end
    end
end endgenerate


/* Module end */
endmodule
