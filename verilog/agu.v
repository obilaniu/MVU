/**
 * Address Generation Unit (AGU)
 */

/**** Module ****/
module agu( clk,
            l0,
			l1,
			l2,
			j0,
			j1,
			j2,
			j3,
            addr_out);
           
parameter BWADDR    = 21;             /* Bitwidth of Address */
parameter BWLENGTH  = 8;


// Ports
input  wire                      clk;					// Clock
input  wire [      BWADDR-1 : 0] j0;					// Address jump: dimension 0
input  wire [      BWADDR-1 : 0] j1;					// Address jump: dimension 1
input  wire [      BWADDR-1 : 0] j2;					// Address jump: dimension 2
input  wire [      BWADDR-1 : 0] j3;					// Address jump: dimension 3
input  wire [    BWLENGTH-1 : 0] l0;					// Length: dimension 0
input  wire [    BWLENGTH-1 : 0] l1;					// Length: dimension 1
input  wire [    BWLENGTH-1 : 0] l2;					// Length: dimension 2
output reg  [      BWADDR-1 : 0] addr_out = 0;			// Address generated


/* Local wires */
wire                            z0;
wire                            z1;
wire                            z2;



/* Local registers */
reg        [    BWLENGTH-1 : 0] i0 = 0;
reg        [    BWLENGTH-1 : 0] i1 = 0;
reg        [    BWLENGTH-1 : 0] i2 = 0;



/* Logic */
assign z0 = i0 == 0;
assign z1 = i1 == 0;
assign z2 = i2 == 0;


always @(posedge clk) begin
    /* Index decrement & Address Bump logic */
    if (z0 && z1 && z2) begin
        addr_out <= addr_out+j3;
        i0       <= l0;
        i1       <= l1;
        i2       <= l2;
    end else if(z0 && z1) begin
        addr_out <= addr_out+j2;
        i0       <= l0;
        i1       <= l1;
        i2       <= i2 - 1;
    end else if(z0) begin
        addr_out <= addr_out+j1;
        i0       <= l0;
        i1       <= i1 - 1;
    end else begin
        addr_out <= addr_out+j0;
        i0       <= i0 - 1;
    end
end



/* Module end */
endmodule
