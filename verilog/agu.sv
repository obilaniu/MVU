/**
 Address Generation Unit (AGU)

 Description:
  Computes an offset address based on a series of address jumps.
  This unit functions like a set of nexted loops. The outer loop
  is infinite and the output address offset jumps by j0. For the
  inner loops, the loop counts down from lX (length X) to 0, at
  which the loop counter is reset and passes to the next outer
  loop. In each iteration of each loop, the address offset
  jumps by jX, which is a signed integer.
 
 Psuedocode:
 
  while(1)
  {
      for (i1 = l1; i1 > 0; i1--)
      {
          for (i2 = l2; i2 > 0; i2--)
          {
              for (i3 = l3; i3 > 0; i3--)
              {
                  for (i4 = l4; i4 > 0; i4--)
                  {
                      addr_out += j4;
                  }
                  addr_out += j3;
              }
              addr_out += j2;
          }
          addr_out += j1;
      }
      addr_out += j0;
  }

 */

/**** Module ****/
module agu( clk,
            clr,
            step,
            l,
            j,
            addr_out,
            z_out,
            on_j
);

parameter BWADDR    = 21;             /* Bitwidth of Address */
parameter BWLENGTH  = 8;
parameter NJUMPS    = 5;              // Number of jumps


// Ports
input  wire                         clk;                // Clock
input  wire                         clr;                // Clear
input  wire                         step;               // Step
input  wire [      BWADDR-1 : 0]    j[NJUMPS-1 : 0];    // Address jumps
input  wire [    BWLENGTH-1 : 0]    l[NJUMPS-1 : 1];    // Lengths 
output reg  [      BWADDR-1 : 0]    addr_out;           // Address generated
output wire                         z_out[NJUMPS-1 : 1];// Signals when jump length X counter 
output wire [      NJUMPS-1 : 0]    on_j;               // Signals when and which jump occurs



/* Local wires */
wire                            z[NJUMPS-1 : 1];


/* Local registers */
reg        [    BWLENGTH-1 : 0] i[NJUMPS-1 : 1];



//
// Wire Assignments
//

// zX signals are checks for zero on the iX counters
assign z[1] = i[1] == 0;
assign z[2] = i[2] == 0;
assign z[3] = i[3] == 0;
assign z[4] = i[4] == 0;

// zX signals indicate when length counters hit zero
assign z_out[1] = step & z[1];
assign z_out[2] = step & z[2];
assign z_out[3] = step & z[3];
assign z_out[4] = step & z[4];

// on_jX signals indicate when a jump occurs
assign on_j[4] = step;                            // Always happening
assign on_j[3] = step & z[4];
assign on_j[2] = step & z[3] & z[4];
assign on_j[1] = step & z[2] & z[3] & z[4];
assign on_j[0] = step & z[1] & z[2] & z[3] & z[4];


// Index decrement & Address Bump logic
always @(posedge clk) begin
    if (clr) begin
        i <= l;
        addr_out <= 0;
    end else if (step) begin
        if (on_j[0]) begin
            addr_out <= addr_out+j[0];
            i        <= l;
        end else if (on_j[1]) begin
            addr_out <= addr_out+j[1];
            i[4:2]   <= l[4:2];
            i[1]     <= i[1] - 1;
        end else if (on_j[2]) begin
            addr_out <= addr_out+j[2];
            i[4:3]   <= l[4:3];
            i[2]     <= i[2] - 1;
        end else if (on_j[3]) begin
            addr_out <= addr_out+j[3];
            i[4]     <= l[4];
            i[3]     <= i[3] - 1;
        end else begin
            addr_out <= addr_out+j[4];
            i[4]     <= i[4] - 1;
        end
    end
end



/* Module end */
endmodule
