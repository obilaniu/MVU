/**
 * Fixed-point adder
 *
 * Used for scaling the output of the MVP
 *
 * out = a + b
 *
 * Notes:
 * 1. 
 *
 */

 module fixedpointadder #(
     BA     = 32,
     BB     = 32,
     BOUT   = 32
 )
 (
     input  logic                           clk,
     input  logic                           clr,
     input  logic   signed  [  BA-1 : 0]    a,
     input  logic   signed  [  BB-1 : 0]    b,
     output logic   signed  [BOUT-1 : 0]    out
 );


// Registers
logic signed [BOUT-1 : 0] out_q;


always @(posedge clk) begin
    if (clr) begin
        out_q <= 0;
    end else begin
        out_q <= a + b;
    end
end

endmodule