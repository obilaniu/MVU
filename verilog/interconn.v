/**
 * Interconnect between MVUs
 */

`timescale 1 ps / 1 ps
/* Module */
module interconn (clk, clr,
                  send_to, send_en, send_addr, send_word, 
                  recv_from,
                  recv_en, recv_addr, recv_word);

/* Parameters */
parameter   N = 8;              // Number of MVUs
parameter   W = 64;             // Biwidth of the data words
parameter   BADDR = 15;         // Biwidth of the address words

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

genvar i, j;



/* Logic */
generate if(N > 1) begin:multiple
    for(i=0;i<N;i=i+1) begin:xbarloop

        // Signal assignments
        //wire [A-1:0] addr;
        //assign addr = recv_from[i*A +: A];

        for (j=0; j < N; j=j+1) begin: recvloop

            wire sel = send_to[j*N+i] & send_en[j];

            always @(posedge clk or posedge clr) begin
                if(clr) begin
                    recv_en  [i]        = 1'b0;
                    recv_addr[i*BADDR +: BADDR] = {BADDR{1'b0}};
                    recv_from[i*N +: N] = {N{1'b0}};
                    recv_word[i*W +: W] = {W{1'b0}};
                end else if(clk) begin
                    // TODO: do some arbitration; for now, just OR the selectors
                    recv_from[i*N + j] = sel ? send_to[j*N + i] : 0;
                    recv_en[i] = recv_en[i] | sel;
                    recv_addr[i*BADDR +: BADDR] = recv_addr[i*BADDR +: BADDR] | (sel ? send_addr[j*BADDR +: BADDR] : 0);
                    recv_word[i*W +: W] = recv_word[i*W +: W] | (sel ? send_word[j*W +: W] : 0);
                end
            end
        end
    end
end else begin:single
    always @(posedge clk or posedge clr) begin
        if(clr) begin
            recv_en   = 1'b0;
            recv_from = 1'b0;
            recv_addr = {BADDR{1'b0}};
            recv_word = {W{1'b0}};
        end else if(clk) begin
            recv_from = send_to;
            recv_en   = send_en;
            recv_addr = send_addr;
            recv_word = send_word;
        end
    end
end endgenerate


/* Module end */
endmodule
