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
            l1,
            l2,
            l3,
            l4,
            j0,
            j1,
            j2,
            j3,
            j4,
            addr_out,
            z1_out,
            z2_out,
            z3_out,
            z4_out,
            on_j0,
            on_j1,
            on_j2,
            on_j3,
            on_j4
);

parameter BWADDR    = 21;             /* Bitwidth of Address */
parameter BWLENGTH  = 8;


// Ports
input  wire                         clk;                // Clock
input  wire                         clr;                // Clear
input  wire                         step;               // Step
input  wire [      BWADDR-1 : 0]    j0;                 // Address jump: 0
input  wire [      BWADDR-1 : 0]    j1;                 // Address jump: 1
input  wire [      BWADDR-1 : 0]    j2;                 // Address jump: 2
input  wire [      BWADDR-1 : 0]    j3;                 // Address jump: 3
input  wire [      BWADDR-1 : 0]    j4;                 // Address jump: 4
input  wire [    BWLENGTH-1 : 0]    l1;                 // Length: 1
input  wire [    BWLENGTH-1 : 0]    l2;                 // Length: 2
input  wire [    BWLENGTH-1 : 0]    l3;                 // Length: 3
input  wire [    BWLENGTH-1 : 0]    l4;                 // Length: 4
output reg  [      BWADDR-1 : 0]    addr_out;           // Address generated
output wire                         z1_out;             // Signals when jump length 1 counter is 0
output wire                         z2_out;             // Signals when jump length 2 counter is 0
output wire                         z3_out;             // Signals when jump length 3 counter is 0
output wire                         z4_out;             // Signals when jump length 4 counter is 0
output wire                         on_j0;
output wire                         on_j1;
output wire                         on_j2;
output wire                         on_j3;
output wire                         on_j4;



/* Local wires */
wire                            z1;
wire                            z2;
wire                            z3;
wire                            z4;


/* Local registers */
reg        [    BWLENGTH-1 : 0] i1 = 0;
reg        [    BWLENGTH-1 : 0] i2 = 0;
reg        [    BWLENGTH-1 : 0] i3 = 0;
reg        [    BWLENGTH-1 : 0] i4 = 0;



//
// Wire Assignments
//

// zX signals are checks for zero on the iX counters
assign z1 = i1 == 0;
assign z2 = i2 == 0;
assign z3 = i3 == 0;
assign z4 = i4 == 0;

// zX signals indicate when length counters hit zero
assign z1_out = step & z1;
assign z2_out = step & z2;
assign z3_out = step & z3;
assign z4_out = step & z4;

// on_jX signals indicate when a jump occurs
assign on_j4 = step;                            // Always happening
assign on_j3 = step & z4;
assign on_j2 = step & z3 & z4;
assign on_j1 = step & z2 & z3 & z4;
assign on_j0 = step & z1 & z2 & z3 & z4;


// Index decrement & Address Bump logic
always @(posedge clk) begin
    if (clr) begin
        i1 <= l1;
        i2 <= l2;
        i3 <= l3;
        i4 <= l4;
        addr_out <= 0;
    end else if (step) begin
        if (on_j0) begin // (z4 && z2 && z2 && z1) begin
            addr_out <= addr_out+j0;
            i4       <= l4;
            i3       <= l3;
            i2       <= l2;
            i1       <= l1;
        end else if (on_j1) begin // (z4 && z3 && z2) begin
            addr_out <= addr_out+j1;
            i4       <= l4;
            i3       <= l3;
            i2       <= l2;
            i1       <= i1 - 1;
        end else if (on_j2) begin // (z4 && z3) begin
            addr_out <= addr_out+j2;
            i4       <= l4;
            i3       <= l3;
            i2       <= i2 - 1;
        end else if (on_j3) begin // (z4) begin
            addr_out <= addr_out+j3;
            i4       <= l4;
            i3       <= i3 - 1;
        end else begin
            addr_out <= addr_out+j4;
            i4       <= i4 - 1;
        end
    end
end



/* Module end */
endmodule
