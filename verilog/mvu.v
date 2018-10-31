/**
 * Matrix-Vector Unit
 */


/**** Module mvu ****/
module mvu(clk, clr, sh, mode, W, D, O);


/* Parameters */
parameter  n = 64;
parameter  w = 32;

localparam a = $clog2(n);

input  wire                clk;
input  wire                clr;
input  wire                sh;
input  wire[        1 : 0] mode;
input  wire[    n*n-1 : 0] W;
input  wire[    2*n-1 : 0] D;

output wire[    n*w-1 : 0] O;

wire       [n*(a+2)-1 : 0] S;

genvar i;

/* Wiring */
mvp #(n) matrixcore (mode, W, D, S);
generate for(i=0;i<n;i=i+1) begin:shaccarray
	shacc #(w,a+2) p (clk, clr, sh, S[i*(a+2) +: a+2], O[i*w +: w]);
end endgenerate


/* Module end */
endmodule
