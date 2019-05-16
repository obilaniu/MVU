/**
 * Address Generation Unit (AGU)
 */

/**** Module ****/
module agu(clk,
           addr_out);
           
localparam BWADDR = 21;             /* Bitwidth of Address */

input  wire                     clk;

output reg [      BWADDR-1 : 0] addr_out = 0;


/* Local wires */
wire                            z0;
wire                            z1;
wire                            z2;



/* Local registers */
reg        [             7 : 0] i0 = 0;
reg        [             7 : 0] i1 = 0;
reg        [             7 : 0] i2 = 0;
reg        [      BWADDR-1 : 0] j0 = 0;
reg        [      BWADDR-1 : 0] j1 = 0;
reg        [      BWADDR-1 : 0] j2 = 0;
reg        [      BWADDR-1 : 0] j3 = 0;
reg        [             7 : 0] l0 = 8;
reg        [             7 : 0] l1 = 8;
reg        [             7 : 0] l2 = 128;



/* Logic */
assign z0 = i0 == 0;
assign z1 = i1 == 0;
assign z2 = i2 == 0;

always @(posedge clk) begin
    /* Index decrement & Address Bump logic */
    if     (z0 and z1 and z2) begin
        addr_out <= addr_out+j3;
        i0       <= l0;
        i1       <= l1;
        i2       <= l2;
    else if(z0 and z1) begin
        addr_out <= addr_out+j2;
        i0       <= l0;
        i1       <= l1;
        i2       <= i2 - 1;
    end
    else if(z0) begin
        addr_out <= addr_out+j1;
        i0       <= l0;
        i1       <= i1 - 1;
    else begin
        addr_out <= addr_out+j0;
        i0       <= i0 - 1;
    end
end



/* Module end */
endmodule
