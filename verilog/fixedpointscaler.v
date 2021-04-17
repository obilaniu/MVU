/**
 * Fixed-point scaler
 *
 * Used for scaling the output of the MVP
 *
 * out = (a+d)*b + c
 *
 * Notes:
 * 1. 
 *
 */


`timescale 1ns/1ps

 module fixedpointscaler #(
     BA     = 27,
     BB     = 16,
     BC     = 27,
     BD     = 27,
     BP     = 48
 )
 (
     input  wire                                clk,            // clock
     input  wire                                clr,            // clear/reset
     input  wire    signed      [BA-1 : 0]      a,
     input  wire    signed      [BB-1 : 0]      b,              // multiplier
     input  wire    signed      [BC-1 : 0]      c,
     input  wire    signed      [BD-1 : 0]      d,              // multiplicand
     output wire    signed      [BP-1 : 0]      p               // output product
 );

reg     signed      [BA-1 : 0]  a_q;
reg     signed      [BB-1 : 0]  b_q;                   // note: must be signed in order for DSP to asborb the pre-add
reg     signed      [BC-1 : 0]  c_q0;
reg     signed      [BC-1 : 0]  c_q1;
reg     signed      [BD-1 : 0]  d_q;
reg     signed      [BA-1 : 0]  preadd_q;
reg     signed      [BA+BB : 0]  m_q;
reg     signed      [BP-1 : 0]  p_q;


// Implicit definition
(* use_dsp48 = "yes" *) 
always @(posedge clk) begin
    if (clr) begin
        a_q <= 0;
        b_q <= 0;
        c_q0 <= 0;
        c_q1 <= 0;
        d_q <= 0;
        preadd_q <= 0;
        m_q <= 0;
        p_q <= 0;
    end else begin
        a_q <= a;
        b_q <= b;
        c_q0 <= c;
        c_q1 <= c_q0;
        d_q <= d;
        preadd_q <= a + d;
        m_q <= preadd_q * b_q;
        p_q <= m_q + c_q1;
    end
end

assign p = p_q;



 endmodule