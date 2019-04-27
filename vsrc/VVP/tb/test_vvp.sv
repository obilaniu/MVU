`timescale 1 ps / 1 ps
import utils::*;
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
    print_banner($sformatf("Testing %1d-wide Vector-Vector Dot Product...", n));
    print("Testing Mode 00 {+1,-1} ...");
    assert(std::randomize(W));
    assert(std::randomize(D));
    mode = 2'b00;
    #1;
     print($sformatf("mode=%2d W=%b    D=%b    S=%b    ", mode, W,D,S)); #1;

    #1;
    mode = 2'b01;
    #1;
     print($sformatf("mode=%2d W=%b    D=%b    S=%b    ", mode, W,D,S)); #1;

    #1;
    mode = 2'b10;
    #1;
     print($sformatf("mode=%2d W=%b    D=%b    S=%b    ", mode, W,D,S)); #1;

    #1;
    mode = 2'b11;
    #1;
     print($sformatf("mode=%2d W=%b    D=%b    S=%b    ", mode, W,D,S)); #1;
    // W = {n{ 1'b0}};
    // D = {n{-2'd1}}; #1; $display("+1 * -1 = -1 ? %b", S); #1;
    // D = {n{+2'd0}}; #1; $display("+1 *  0 =  0 ? %b", S); #1;
    // D = {n{+2'd1}}; #1; $display("+1 * +1 =  1 ? %b", S); #1;
    // W = {n{ 1'b1}};
    // D = {n{-2'd1}}; #1; $display("-1 * -1 =  1 ? %b", S); #1;
    // D = {n{+2'd0}}; #1; $display("-1 *  0 =  0 ? %b", S); #1;
    // D = {n{+2'd1}}; #1; $display("-1 * +1 = -1 ? %b", S); #1;
    
    // $display("Testing Mode 01 { 0,+1} ...");
    // mode = 2'b01;
    // W = {n{ 1'b0}};
    // D = {n{-2'd1}}; #1; $display(" 0 * -1 =  0 ? %b", S); #1;
    // D = {n{+2'd0}}; #1; $display(" 0 *  0 =  0 ? %b", S); #1;
    // D = {n{+2'd1}}; #1; $display(" 0 * +1 =  0 ? %b", S); #1;
    // W = {n{ 1'b1}};
    // D = {n{-2'd1}}; #1; $display("+1 * -1 = -1 ? %b", S); #1;
    // D = {n{+2'd0}}; #1; $display("+1 *  0 =  0 ? %b", S); #1;
    // D = {n{+2'd1}}; #1; $display("+1 * +1 =  1 ? %b", S); #1;
    
    // $display("Testing Mode 10 { 0,-1} ...");
    // mode = 2'b10;
    // W = {n{ 1'b0}};
    // D = {n{-2'd1}}; #1; $display(" 0 * -1 =  0 ? %b", S); #1;
    // D = {n{+2'd0}}; #1; $display(" 0 *  0 =  0 ? %b", S); #1;
    // D = {n{+2'd1}}; #1; $display(" 0 * +1 =  0 ? %b", S); #1;
    // W = {n{ 1'b1}};
    // D = {n{-2'd1}}; #1; $display("-1 * -1 =  1 ? %b", S); #1;
    // D = {n{+2'd0}}; #1; $display("-1 *  0 =  0 ? %b", S); #1;
    // D = {n{+2'd1}}; #1; $display("-1 * +1 = -1 ? %b", S); #1;
    
    // $display("Testing Mode 11 { 0, 0} ...");
    // mode = 2'b11;
    // W = {n{ 1'b0}};
    // D = {n{-2'd1}}; #1; $display(" 0 * -1 =  0 ? %b", S); #1;
    // D = {n{+2'd0}}; #1; $display(" 0 *  0 =  0 ? %b", S); #1;
    // D = {n{+2'd1}}; #1; $display(" 0 * +1 =  0 ? %b", S); #1;
    // W = {n{ 1'b1}};
    // D = {n{-2'd1}}; #1; $display(" 0 * -1 =  0 ? %b", S); #1;
    // D = {n{+2'd0}}; #1; $display(" 0 *  0 =  0 ? %b", S); #1;
    // D = {n{+2'd1}}; #1; $display(" 0 * +1 =  0 ? %b", S); #1;
    
    // $display("");
    // $display("Unclocked:");
    // mode = 2'b00;
    // W = {n{ 1'b0}};
    // D = {n{-2'b1}};
    // #1;
    // $display("mode = '%b'", mode);
    // $display("W    = '%b'", W);
    // $display("D    = '%b'", D);
    // $display("S    = '%b'", S);
    
    // $display("");
    // $display("Clocked:");
    // mode = 2'b00;
    // W = {n{ 1'b0}};
    // D = {n{+2'b1}};
    // #1;
    // $display("mode = '%b'", mode);
    // $display("W    = '%b'", W);
    // $display("D    = '%b'", D);
    // `define TICK                                                             \
    //         #1;                                                              \
    //         $display("%5t: C    = %3d = [%3d] <-  %3d  <- [%3d] <-  %3d  <- [%3d] <-  %3d  <-  %3d", \
    //                  $time,                                                  \
    //                  C,                                                      \
    //                  clocked.S,                                              \
    //                  clocked.redux.l.S,                                      \
    //                  clocked.redux.l.redux.l.S,                              \
    //                  clocked.redux.l.redux.l.redux.l.S,                      \
    //                  clocked.redux.l.redux.l.redux.l.redux.l.S,              \
    //                  clocked.redux.l.redux.l.redux.l.redux.l.redux.l.S,      \
    //                  clocked.redux.l.redux.l.redux.l.redux.l.redux.l.redux.l.S); \
    //         #1;                                                              \
    //         clk = 1;                                                         \
    //         #3;                                                              \
    //         clk = 0;                                                         \
    //         W = {n{1'b0}}; D = {n{2'b0}};                                    \
    //         #1
    // `TICK;
    // `TICK;
    // `TICK;
    // `TICK;
    // `TICK;
    // `TICK;
    // `TICK;
end

endmodule
