/**
 * Top-Level
 */

/**** Module toplevel ****/
module toplevel(clk, clr, sh, mulmode, Raddr, Waddr, Wen, D, O);


/* Parameters */
parameter  N =  8;
parameter  n = 64;
parameter  w = 32;

localparam a = $clog2(n);

input  wire                clk;
input  wire[      N-1 : 0] clr;
input  wire[      N-1 : 0] sh;
input  wire[    2*N-1 : 0] mulmode;
input  wire[    9*N-1 : 0] Raddr;
input  wire[    9*N-1 : 0] Waddr;
input  wire[      N-1 : 0] Wen;
input  wire[  2*N*n-1 : 0] D;

output wire[  N*n*w-1 : 0] O;

genvar i;


/* Wiring */
/* Multiple MVUs */
generate for(i=0;i<N;i=i+1) begin:shaccarray
	mvu #(n, w) mvunit (clk, clr,
	                    sh[i],
	                    mulmode[2*i +: 2],
	                    Raddr[9*i +: 9],
	                    Waddr[9*i +: 9],
	                    Wen[i],
	                    D[2*n*i +: 2*n],
	                    O[n*w*i +: n*w]);
end endgenerate


/* Module end */
endmodule
