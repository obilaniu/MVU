/**
 * Conflict Detection Write Unit
 *
 * Receives enable and address signals and returns:
 *  - A grant signal
 *  - A chosen enable signal
 *  - A chosen address signal
 *  - A 2-bit mux code
 */

`timescale 1ns/1ps
module cdwu(i_en, i_addr, i_grnt,
            d_en, d_addr, d_grnt,
            c_en, c_addr, c_grnt,
            o_en, o_addr, muxcode);
            

/* Parameters */
parameter  BANKBITS = 5;
parameter  WORDBITS = 9;


/* Local Parameters */
localparam a = BANKBITS+WORDBITS;


/* Interface */
input  wire          i_en;
input  wire[a-1 : 0] i_addr;
output wire          i_grnt;

input  wire          d_en;
input  wire[a-1 : 0] d_addr;
output wire          d_grnt;

input  wire          c_en;
input  wire[a-1 : 0] c_addr;
output wire          c_grnt;

output wire          o_en;
output wire[a-1 : 0] o_addr;
output wire[1 : 0]   muxcode;


/* Wiring */
assign o_en        = i_en | d_en | c_en;

assign o_addr      = i_en ? i_addr : (d_en ? d_addr : c_addr);
assign muxcode     = i_en ?   2'd0 : (d_en ?   2'd1 :   2'd2);

assign i_grnt      = i_en;
assign d_grnt      = d_en & ~i_en;
assign c_grnt      = c_en & ~i_en & ~d_en;


/* Module end */
endmodule
