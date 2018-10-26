/**** Module dotp ****/
module dotp(W, D, mode, S);

/* Parameters */
parameter n=64;
parameter a=$clog2(n);

localparam nr = (1 << a)/2;
localparam nl = n-nr;

input  wire[    1 : 0] mode;
input  wire[  n-1 : 0] W;
input  wire[2*n-1 : 0] D;

output wire[  a+1 : 0] S;

wire       [    a : 0] Sr;
wire       [    a : 0] Sl;


/* Modal Multiplier Logic */
function dotp_func(input fW,
                   input fD,
                   input fmode);
begin
	if         (fmode == 2'b00) begin /* Weights {+1,-1} */
		dotp_func = fW ?   -fD :   +fD;
	end else if(fmode == 2'b01) begin /* Weights { 0,+1} */
		dotp_func = fW ?   +fD : 2'b00;
	end else if(fmode == 2'b10) begin /* Weights { 0,-1} */
		dotp_func = fW ?   -fD : 2'b00;
	end else                    begin /* Weights { 0, 0} */
		dotp_func = 2'b00;
	end
end
endfunction


/* Recursive Hardware Logic Generation */
generate if(n == 1) begin
	assign S = dotp_func(W,D,mode);
end else if(n >= 2) begin
	dotp #(nr, a-1) r (W[nr-1 : 0 ], D[2*nr-1 :    0], mode, Sr);
	dotp #(nl, a-1) l (W[n-1  : nr], D[2*n -1 : 2*nr], mode, Sl);
	assign S = {Sl[a], Sl} + {Sr[a], Sr};
end endgenerate

endmodule



/**** Test Module test_dotp ****/
module test_dotp();
localparam n = 64;
localparam a = $clog2(n);
reg [ n-1 : 0] W;
reg [2*n-1: 0] D;
reg [  1  : 0] mode;
wire[ a+1 : 0] S;
dotp #(n,a) test_instance (W,D,mode,S);
endmodule

/*

64x64=4096

ALMs | Purpose
-----+------------------------------------
2048 | Matrix transpose
2048 | 1st-stage multiply, output 2 bits signed
2048 | 1st-stage add, output 3 bits signed
1024 | 2nd-stage add, output 4 bits signed
1024 | 3rd-stage add, output 5 bits signed
 512 | 4th-stage add, output 6 bits signed
 256 | 5th-stage add, output 7 bits signed
 128 | 6th-stage add, output 8 bits signed



*/


