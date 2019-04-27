/**
 * Matrix-Vector Product.
 */

`timescale 1 ps / 1 ps
/**** Module mvp ****/
module mvp(clk, mode, W, D, S);


/* Parameters */
parameter  n  = 64;
parameter  pr = 0;

localparam a = $clog2(n);

input  wire            clk;
input  wire[    1 : 0] mode;
input  wire[n*n-1 : 0] W;
input  wire[2*n-1 : 0] D;

output wire[n*(a+2)-1 : 0] S;


/* Locals */
genvar i;


/* Parallel Vector-Vector Dot-Products */
generate for(i=0;i<n;i=i+1) begin:vvparray
    vvp #(n, pr) p (clk, mode, W[i*n +: n], D, S[i*(a+2) +: a+2]);
end endgenerate


/* Module end */
endmodule



