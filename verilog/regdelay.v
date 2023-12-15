//
// Delay register based on 1-bit shift registers
//
// Provides a N-cycle delay for registers of size W.
//


module regdelay #(
    parameter W = 1,
    parameter N = 1
) (
    input   wire            clk,
    input   wire            clr,
    input   wire            step,
    input   wire[W-1 : 0]   in,
    output  wire[W-1 : 0]   out    
);

genvar i;

generate for(i=0; i < W; i=i+1) begin: delaysr_array

    shiftreg #(
        .N(N)
    ) sr (
        .clk    (clk), 
        .clr    (clr),
        .step   (1'b1),
        .in     (in[i]),
        .out    (out[i])        
    );

end endgenerate


endmodule