//
// Variable size shift register
//

`timescale 1ns/1ps
module shiftreg #(
    parameter N = 1
) (
    input   wire    clk,
    input   wire    clr,
    input   wire    step,
    input   wire    in,
    output  wire    out
);


// Registers
reg [N-1 : 0] sr;

// Shifter
always @(posedge clk) begin
    if (clr) begin
        sr = 0;
    end else begin
        if (step) begin
            sr = sr << 1;
            sr[0] = in;
        end
    end
end

// Output
assign out = sr[N-1];


endmodule