/**
 * Matrix-Vector Product.
 */

`timescale 1ns/1ps
/**** Module mvp ****/
module mvp(clk, mode, W, D, S);


/* Parameters */
parameter  n  = 64;
parameter  pr = 0;

localparam a = $clog2(n);

input  wire            	clk;
input  wire[    1 : 0] 	mode;
input  wire[n*n-1 : 0] 	W;
input  wire[n-1 : 0] 	D;

output wire[n*(a+2)-1 : 0] S;


/* Locals */
genvar i;


/* Parallel Vector-Vector Dot-Products */
generate for(i=0;i<n;i=i+1) begin:vvparray
	vvp #(n, pr) p (clk, mode, W[i*n +: n], D, S[i*(a+2) +: a+2]);
end endgenerate


/* Module end */
endmodule



/**** Test Module test_mvp ****/
module test_mvp();


/* Local parameters for test */
localparam n = 64;
localparam a = $clog2(n);


/* Create input registers and output wires */
reg                  clk = 0;
reg [     n*n-1 : 0] W;
reg [     2*n-1 : 0] D;
reg [         1 : 0] mode;
wire[ n*(a+2)-1 : 0] S;


integer i;


/* Create instance */
mvp #(n) master (clk, mode, W, D, S);


/* Run test */
initial begin
	assign mode = 2'b00;
	assign W = {n*n{ 1'b0}};
	assign D = {n{+2'b1}};
	#1;
	for(i=0;i<n;i=i+1) begin
		$write(" %4d", $signed(S[i*(a+2) +: a+2]));
	end
	$display("");
end

endmodule
