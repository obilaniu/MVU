//
// Output data memory address generation unit
//
// Generates the address to write the output of the MVU quantizer into the local data memory.
// It expects a signal called "step" that will trigger the 
//
//
`timescale 1ns/1ps
module outagu(clk, clr, step, load, baseaddr, addrout);

// Parameters
parameter  BDBANKA = 15;

// Ports
input  wire                 clk;
input  wire                 clr;
input  wire                 step;
input  wire                 load;
input  wire[BDBANKA-1 : 0]  baseaddr;
output wire[BDBANKA-1 : 0]  addrout;

// Local registers
reg  [BDBANKA-1 : 0] addr;


// Load and increment the address counter
always @(posedge clk) begin
    if (clr) begin
        addr <= 0;
    end else begin
        if (load) begin
            addr <= baseaddr;
        end else begin
            if (step) begin
                addr <= addr + 1;
            end
        end
    end
end

// Assign the address counter to the output address
assign addrout = addr;

endmodule
