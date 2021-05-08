/**
 * Vector-Vector Product.
 */

`timescale 1ns/1ps
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

input  wire                     clk;
input  wire       [     1 : 0]  mode;
input  wire       [   n-1 : 0]  W;
input  wire       [ n-1 : 0]    D;

output wire signed[ a+2-1 : 0] S;


/* Locals */
wire signed       [ a+2-1 : 0] Si;
wire signed       [ar+2-1 : 0] Sr;
wire signed       [al+2-1 : 0] Sl;


/* Modal Multiplier Logic */
function signed[1:0] vvp_func(input[1:0] fmode,
                              input[0:0] fW,
//                              input[1:0] fD);
                              input[0:0] fD);
    reg signed[1:0] fD_extended;
begin
    fD_extended = {1'b0, fD};
    if         (fmode == 2'b00) begin /* Weights { 0, 0} */
        vvp_func = fW ? 2'b00 : 2'b00;
    end else if(fmode == 2'b01) begin /* Weights { 0,+1} */
        vvp_func = fW ? +fD_extended : 2'b00;
    end else if(fmode == 2'b10) begin /* Weights {+1,-1} */
        vvp_func = fW ? -fD_extended : +fD_extended;
    end else                    begin /* Weights { 0,-1} */
        vvp_func = fW ? -fD_extended : 2'b00;
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
    vvp #(nr, pr>>1) r (clk, mode, W[ 0 +: nr], D[  0  +: nr], Sr);
    vvp #(nl, pr>>1) l (clk, mode, W[nr +: nl], D[nr +: nl], Sl);
    assign Si = {{(a-al){Sl[al+1]}}, Sl} + {{(a-ar){Sr[ar+1]}}, Sr};
end endgenerate


/* Module end */
endmodule





/**** Test Module test_vvp ****/
module test_vvp();


/* Local parameters for test */
localparam n = 64;
localparam a = $clog2(n);


/* Create input registers and output wires */
reg                    clk = 0;
reg        [    1 : 0] mode;
reg        [  n-1 : 0] W;
reg  signed[2*n-1 : 0] D;
wire signed[a+2-1 : 0] S;
wire signed[a+2-1 : 0] C;


/* Create instances */
vvp #(n)            master  (clk, mode, W, D, S);
vvp #(n, 'b0010101) clocked (clk, mode, W, D, C);


/* Run test */
initial begin
    $display("Testing %1d-wide Vector-Vector Dot Product...", n);
    $display("Testing Mode 00 {+1,-1} ...");
    mode = 2'b00;
    W = {n{ 1'b0}};
    D = {n{-2'd1}}; #1; $display("+1 * -1 = -1 ? %d", S); #1;
    D = {n{+2'd0}}; #1; $display("+1 *  0 =  0 ? %d", S); #1;
    D = {n{+2'd1}}; #1; $display("+1 * +1 =  1 ? %d", S); #1;
    W = {n{ 1'b1}};
    D = {n{-2'd1}}; #1; $display("-1 * -1 =  1 ? %d", S); #1;
    D = {n{+2'd0}}; #1; $display("-1 *  0 =  0 ? %d", S); #1;
    D = {n{+2'd1}}; #1; $display("-1 * +1 = -1 ? %d", S); #1;
    
    $display("Testing Mode 01 { 0,+1} ...");
    mode = 2'b01;
    W = {n{ 1'b0}};
    D = {n{-2'd1}}; #1; $display(" 0 * -1 =  0 ? %d", S); #1;
    D = {n{+2'd0}}; #1; $display(" 0 *  0 =  0 ? %d", S); #1;
    D = {n{+2'd1}}; #1; $display(" 0 * +1 =  0 ? %d", S); #1;
    W = {n{ 1'b1}};
    D = {n{-2'd1}}; #1; $display("+1 * -1 = -1 ? %d", S); #1;
    D = {n{+2'd0}}; #1; $display("+1 *  0 =  0 ? %d", S); #1;
    D = {n{+2'd1}}; #1; $display("+1 * +1 =  1 ? %d", S); #1;
    
    $display("Testing Mode 10 { 0,-1} ...");
    mode = 2'b10;
    W = {n{ 1'b0}};
    D = {n{-2'd1}}; #1; $display(" 0 * -1 =  0 ? %d", S); #1;
    D = {n{+2'd0}}; #1; $display(" 0 *  0 =  0 ? %d", S); #1;
    D = {n{+2'd1}}; #1; $display(" 0 * +1 =  0 ? %d", S); #1;
    W = {n{ 1'b1}};
    D = {n{-2'd1}}; #1; $display("-1 * -1 =  1 ? %d", S); #1;
    D = {n{+2'd0}}; #1; $display("-1 *  0 =  0 ? %d", S); #1;
    D = {n{+2'd1}}; #1; $display("-1 * +1 = -1 ? %d", S); #1;
    
    $display("Testing Mode 11 { 0, 0} ...");
    mode = 2'b11;
    W = {n{ 1'b0}};
    D = {n{-2'd1}}; #1; $display(" 0 * -1 =  0 ? %d", S); #1;
    D = {n{+2'd0}}; #1; $display(" 0 *  0 =  0 ? %d", S); #1;
    D = {n{+2'd1}}; #1; $display(" 0 * +1 =  0 ? %d", S); #1;
    W = {n{ 1'b1}};
    D = {n{-2'd1}}; #1; $display(" 0 * -1 =  0 ? %d", S); #1;
    D = {n{+2'd0}}; #1; $display(" 0 *  0 =  0 ? %d", S); #1;
    D = {n{+2'd1}}; #1; $display(" 0 * +1 =  0 ? %d", S); #1;
    
    $display("");
    $display("Unclocked:");
    mode = 2'b00;
    W = {n{ 1'b0}};
    D = {n{-2'b1}};
    #1;
    $display("mode = '%b'", mode);
    $display("W    = '%b'", W);
    $display("D    = '%b'", D);
    $display("S    = '%d'", S);
    
    $display("");
    $display("Clocked:");
    mode = 2'b00;
    W = {n{ 1'b0}};
    D = {n{+2'b1}};
    #1;
    $display("mode = '%b'", mode);
    $display("W    = '%b'", W);
    $display("D    = '%b'", D);
    `define TICK                                                             \
            #1;                                                              \
            $display("%5t: C    = %3d = [%3d] <-  %3d  <- [%3d] <-  %3d  <- [%3d] <-  %3d  <-  %3d", \
                     $time,                                                  \
                     C,                                                      \
                     clocked.S,                                              \
                     clocked.redux.l.S,                                      \
                     clocked.redux.l.redux.l.S,                              \
                     clocked.redux.l.redux.l.redux.l.S,                      \
                     clocked.redux.l.redux.l.redux.l.redux.l.S,              \
                     clocked.redux.l.redux.l.redux.l.redux.l.redux.l.S,      \
                     clocked.redux.l.redux.l.redux.l.redux.l.redux.l.redux.l.S); \
            #1;                                                              \
            clk = 1;                                                         \
            #3;                                                              \
            clk = 0;                                                         \
            W = {n{1'b0}}; D = {n{2'b0}};                                    \
            #1
    `TICK;
    `TICK;
    `TICK;
    `TICK;
    `TICK;
    `TICK;
    `TICK;
end

endmodule
