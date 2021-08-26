//
// Address generation for the input data
//
//

`timescale 1 ps / 1 ps

module inagu(
    clk,
    clr,
    en,
    iprecision,
    ijump,
    ilength,
    ibaseaddr,
    wprecision,
    wjump,
    wlength,
    wbaseaddr,
    zigzag_step_sel,
    iaddr_out,
    waddr_out,
    imsb,
    wmsb,
    sh_out,
    wagu_on_j,
);

// Parameters
parameter BPREC     = 6;                    // Bitwidth of Precision
parameter BWBANKA   = 9;                    // Bitwidth of weight memory address
parameter BDBANKA   = 15;                   // Bitwidth of data memory address
parameter BWLENGTH  = 8;                    // Bitwidth of Length
parameter NJUMPS    = 5;                    // Number of jumps

// Ports
input  wire                 clk;            // Clock
input  wire                 clr;            // Clear
input  wire                 en;             // Enable
input  wire[   BPREC-1 : 0] iprecision;     // Input Data Precision
input  wire[   BPREC-1 : 0] wprecision;     // Weight Precision
input  wire[ BDBANKA-1 : 0] ijump[NJUMPS-1 : 0];         // Input Data jumps
input  wire[BWLENGTH-1 : 0] ilength[NJUMPS-1 : 1];       // Input Data Length
input  wire[ BDBANKA-1 : 0] ibaseaddr;                   // Input data Base address
input  wire[ BWBANKA-1 : 0] wjump[NJUMPS-1 : 0];         // Weight jump: 0
input  wire[BWLENGTH-1 : 0] wlength[NJUMPS-1 : 1];       // Weight Length: 1
input  wire[ BWBANKA-1 : 0] wbaseaddr;      // Weight Base address
input  wire[  NJUMPS-1 : 0] zigzag_step_sel;// Select the weight address jump on which the zig-zag should be stepped
output wire[ BDBANKA-1 : 0] iaddr_out;      // Input Data Address generated
output wire[ BWBANKA-1 : 0] waddr_out;      // Weight Address generated
output wire                 imsb;           // Input data is address currently on MSB
output wire                 wmsb;           // Weight address is currently on MSB
output wire                 sh_out;         // Shift occurred
output wire  [NJUMPS-1 : 0] wagu_on_j;      // Weight address jumps happened


// AGU wires
wire  [ BDBANKA-1 : 0]  dagu_addr_out;
wire  [ BWBANKA-1 : 0]  wagu_addr_out;
wire                    dagu_step;
wire                    wagu_step;

// Zig-zag wires
wire  [   BPREC-1 : 0]  zigzag_offd;
wire  [   BPREC-1 : 0]  zigzag_offw;
wire                    zigzagu_step;

// Assignments
assign dagu_step = en;
assign wagu_step = en;


// Address generation unit for the input data
agu #(
    .BWADDR     (BDBANKA),
    .BWLENGTH   (BWLENGTH)
) dagu_unit (
    .clk        (clk),
    .clr        (clr),
    .step       (dagu_step),
    .l          (ilength),
    .j          (ijump),
    .addr_out   (dagu_addr_out),
    .z_out      (),
    .on_j       ()
);

// Address generation unit for the weights
agu #(
    .BWADDR     (BWBANKA),
    .BWLENGTH   (BWLENGTH)
) wagu_unit (
    .clk        (clk),
    .clr        (clr),
    .step       (wagu_step),
    .l          (wlength),
    .j          (wjump),
    .addr_out   (wagu_addr_out),
    .z_out      (),
    .on_j       (wagu_on_j)
);

// Zig-zag address pattern generators
zigzagu #(
    .BPREC     (BPREC)
) zigzagu_unit (
    .clk        (clk),
    .clr        (clr),
    .step       (zigzagu_step),
    .pw         (wprecision),
    .pd         (iprecision),
    .sh         (sh_out),
    .offw       (zigzag_offw),
    .offd       (zigzag_offd)
);

// Add up the final address
assign iaddr_out = ibaseaddr + dagu_addr_out + zigzag_offd;
assign waddr_out = wbaseaddr + wagu_addr_out + zigzag_offw;

// Signal when to step the zigzag and when to cycle out the accumulator
assign zigzagu_step = en && (zigzag_step_sel & wagu_on_j);

// Indicate when address is an MSB
assign imsb = zigzag_offd == 0;
assign wmsb = zigzag_offw == 0;


endmodule