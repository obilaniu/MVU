//
// MVU quantizer/serializer controller
//

`timescale 1 ns / 1 ps
module quantser_ctrl #(
    parameter BWOUT     = 32,               // Max output bitwidth
    parameter BWBWOUT   = $clog2(BWOUT)     // Bitwidth of the bwout port
) (
    input   wire                    clk,     // Clock
    input   wire                    clr,     // Clear
    input   wire [BWBWOUT-1 : 0]    bwout,   // Output bitwidth
    input   wire                    start,   // Start the serializer
    input   wire                    stall,   // Stall
    output  wire                    load,    // Load the output shift register
    output  wire                    step     // Step the output shift register
);


// Internal registers
reg     [BWBWOUT-1 : 0]   counter;          // Countdown counter


// Countdown counter
always @(posedge clk) begin
    if (clr) begin
        counter <= 0;
    end else begin
        if (!stall) begin
            if (start) begin
                // Load the counter
                counter <= bwout;
            end else begin
                if (counter != 0) begin
                    counter <= counter - 1;
                end
            end
        end
    end
end

// Signal assignments
assign step = !stall & counter != 0;
assign load = start;


endmodule