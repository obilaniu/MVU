/**
 * Interconnect between MVUs
 */


/* Module */
module interconn (clk, clr,
                  send_en, send_word,
                  recv_from,
                  recv_en, recv_word);

/* Parameters */
parameter   N = 8;
parameter   W = 128;

localparam  A = $clog2(N);

input  wire             clk;
input  wire             clr;
input  wire [N-1   : 0] send_en;
input  wire [N*W-1 : 0] send_word;

input  wire [N*A-1 : 0] recv_from;
output reg  [N-1   : 0] recv_en;
output reg  [N*W-1 : 0] recv_word;

genvar i;


/* Logic */
generate if(N > 1) begin:multiple
    for(i=0;i<N;i=i+1) begin:xbarloop
        wire [A-1:0] addr;
        assign addr = recv_from[i*A +: A];
        
        always @(posedge clk or posedge clr) begin
            if(clr) begin
                recv_en   = 0;
                recv_word = 0;
            end
            if(clk) begin
                recv_en  [i]        = send_en  [addr];
                recv_word[i*W +: W] = send_word[addr*W +: W];
            end
        end
    end
end else begin:single
    always @(posedge clk or posedge clr) begin
        if(clr) begin
            recv_en   = 0;
            recv_word = 0;
        end
        if(clk) begin
            recv_en   = send_en;
            recv_word = send_word;
        end
    end
end endgenerate


/* Module end */
endmodule
