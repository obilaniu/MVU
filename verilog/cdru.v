/**
 * Conflict Detection Read Unit
 *
 * Receives enable and address signals and returns:
 *  - A grant signal
 *  - A chosen enable signal
 *  - A chosen address signal
 *  - A 2-bit mux code
 */

`timescale 1ns/1ps
module cdru(i_en, i_addr, i_grnt,
            d_en, d_addr, d_grnt,
            c_en, c_addr, c_grnt,
            o_en);


/* Parameters */
parameter  BANKBITS = 5;
parameter  WORDBITS = 10;


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


/* Local */
wire          id_conflict;
wire          ic_conflict;
wire          cd_conflict;


/* Wiring */
assign o_en        = i_en | d_en | c_en;
assign id_conflict = (i_addr[WORDBITS +: BANKBITS] == d_addr[WORDBITS +: BANKBITS]) & i_en & d_en;
assign ic_conflict = (i_addr[WORDBITS +: BANKBITS] == c_addr[WORDBITS +: BANKBITS]) & i_en & c_en;
assign cd_conflict = (c_addr[WORDBITS +: BANKBITS] == d_addr[WORDBITS +: BANKBITS]) & c_en & d_en;

assign i_grnt      = i_en;
assign d_grnt      = d_en & ~id_conflict;
assign c_grnt      = c_en & ~ic_conflict & ~cd_conflict;


/* Module end */
endmodule
