/**
 * Quantizer/Serializer
 *
 * An all-in-one quantizer and serializer!
 *
 */

`timescale 1ns/1ps

module quantser #(
    parameter BWIN      = 32,                       // Input data bit depth
    parameter BWMSBIDX  = $clog2(BWIN)              // Bitwidth of the MSB index position port
)
(
    input   wire                        clk,        // Clock
    input   wire                        clr,        // Clears the state and output reg
    input   wire  [   BWMSBIDX-1 : 0]   msbidx,     // Bit position of MSB in input
    input   wire                        load,       // Load the serializer from din
    input   wire                        step,       // Step serializing output
    input   wire  [       BWIN-1 : 0]   din,        // Input data
    output  wire                        dout        // Serialized output
);


// Internal registers
reg             [    BWIN-1 : 0]    sr;         // Shift register


// Shift register
always @(posedge clk) begin
    if (clr) begin
        sr <= 0;
    end else if (clk) begin
		if (load) begin
            sr <= din;
        end else if (step) begin
            sr <= sr << 1;
            sr[0] <= 1'b0;
        end       
    end 
end


/* Serialized Output */
assign dout = sr[msbidx];


/* Module end */
endmodule