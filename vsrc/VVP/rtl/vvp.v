/**
 * Vector-Vector Product.
 */

`timescale 1 ps / 1 ps
/**** Module vvp ****/
module vvp(clk, mode, W, D, S);


/* Parameters */
parameter  n  = 64;
parameter  pr = 0;

localparam a  = $clog2(n);
localparam nr = (1 << a)/2;
localparam nl = n-nr;
localparam ar = $clog2(nr);
localparam al = $clog2(nl);

input  wire                    clk;
input  wire       [     1 : 0] mode;
input  wire       [   n-1 : 0] W;
input  wire       [ 2*n-1 : 0] D;

output wire signed[ a+2-1 : 0] S;


/* Locals */
wire signed       [ a+2-1 : 0] Si;
wire signed       [ar+2-1 : 0] Sr;
wire signed       [al+2-1 : 0] Sl;


/* Modal Multiplier Logic */
function signed[1:0] vvp_func(input[1:0] fmode,
                              input[0:0] fW,
                              input[1:0] fD);
begin
    if         (fmode == 2'b00) begin /* Weights { 0, 0} */
        vvp_func = fW ? 2'b00 : 2'b00;
    end else if(fmode == 2'b01) begin /* Weights { 0,+1} */
        vvp_func = fW ?   +fD : 2'b00;
    end else if(fmode == 2'b10) begin /* Weights {+1,-1} */
        vvp_func = fW ?   -fD :   +fD;
    end else                    begin /* Weights { 0,-1} */
        vvp_func = fW ?   -fD : 2'b00;
    end
end
endfunction


/* Pipeline Register Insertion */
generate if(pr & 1) begin:pipe
    reg [ a+2-1 : 0] R = 0;
    always @(posedge clk) R <= Si;
    assign S = R;
end else begin:nopipe
    assign S = Si;
end endgenerate


/* Recursive Hardware Logic Generation */
generate if(n == 1) begin:base
    assign Si = vvp_func(mode, W, D);
end else if(n >= 2) begin:redux
    vvp #(nr, pr>>1) r (clk, mode, W[ 0 +: nr], D[  0  +: 2*nr], Sr);
    vvp #(nl, pr>>1) l (clk, mode, W[nr +: nl], D[2*nr +: 2*nl], Sl);
    assign Si = {{(a-al){Sl[al+1]}}, Sl} + {{(a-ar){Sr[ar+1]}}, Sr};
end endgenerate


/* Module end */
endmodule


