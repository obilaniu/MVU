/**
 * Matrix-Vector Unit
 */


/**** Module mvu ****/
module mvu(clk, clr, sh, mulmode,
           Raddr, Waddr, Wen,
           D, O);


/* Parameters */
parameter  n = 64;
parameter  w = 32;

localparam a = $clog2(n);

input  wire                clk;
input  wire                clr;
input  wire                sh;
input  wire[        1 : 0] mulmode;
input  wire[        8 : 0] Raddr;
input  wire[        8 : 0] Waddr;
input  wire                Wen;
input  wire[    2*n-1 : 0] D;

output wire[    n*w-1 : 0] O;

wire       [    n*n-1 : 0] W;
wire       [n*(a+2)-1 : 0] S;

genvar i;


/* Wiring */
/*     Matrix Multiplier */
mvp #(n) matrixcore (mulmode, W, D, S);
/*     Accumulators */
generate for(i=0;i<n;i=i+1) begin:shaccarray
	shacc #(w,a+2) p (clk, clr, sh, S[i*(a+2) +: a+2], O[i*w +: w]);
end endgenerate
/*     Block RAM accesses */
generate for(i=0;i<n*n;i=i+32) begin:bramarray
	bram16k b (clk, D[0 +: 32], Raddr, Waddr, Wen, W[i +: 32]);
end endgenerate


/* Module end */
endmodule
