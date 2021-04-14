/**
 * Decoder
 */


`timescale 1ns/1ps
/**** Module ****/
module decoder(addr, csel);


/* Parameters */
parameter  n  = 32;

localparam a  = $clog2(n);

input  wire[a-1:0] addr;
output wire[n-1:0] csel;

genvar i;


/* Logic */
generate for(i=0;i<n;i=i+1) begin:decode
    assign csel[i] = (addr == i);
end endgenerate


/* Module end */
endmodule





/**** Test Module ****/
module test_decoder();


/* Local parameters for test */
localparam n = 32;
localparam a = $clog2(n);


/* Create input registers and output wires */
reg [a-1:0] addr;
wire[n-1:0] csel;


/* Create instance */
decoder #(n) dec (addr, csel);


/* Run test */
initial begin
    $display("Testing Decoder...");
    addr <=  0; #1;
    $display("Bank  0: %b", csel);
    addr <=  1; #1;
    $display("Bank  1: %b", csel);
    addr <= 15; #1;
    $display("Bank 15: %b", csel);
end

/* Module end */
endmodule
