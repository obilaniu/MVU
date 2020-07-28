//
// Address generation for the input data
//
//


module inagu(
	clk,
    clr,
	en,
	iprecision,
    istride0,
	istride1,
	istride2,
	ilength0,
	ilength1,
	ilength2,
	ibaseaddr,
	wprecision,
	wstride0,
	wstride1,
	wstride2,
	wlength0,
	wlength1,
	wlength2,
	wbaseaddr,
	iaddr_out,
	waddr_out,
	sh_out,
    shacc_done
);

// Parameters
parameter BPREC     = 6;					// Bitwidth of Precision
parameter BWBANKA   = 9;             		// Bitwidth of weight memory address
parameter BDBANKA   = 15;                   // Bitwidth of data memory address
parameter BWLENGTH  = 8;					// Bitwidth of Length

// Ports
input  wire                 clk;			// Clock
input  wire                 clr;            // Clear
input  wire                 en;				// Enable
input  wire[   BPREC-1 : 0] iprecision;		// Input Data Precision
input  wire[   BPREC-1 : 0] wprecision;		// Weight Precision
input  wire[ BDBANKA-1 : 0] istride0;		// Input Data Stride: dimension 0
input  wire[ BDBANKA-1 : 0] istride1;		// Input Data Stride: dimension 1
input  wire[ BDBANKA-1 : 0] istride2;		// Input Data Stride: dimension 2
input  wire[BWLENGTH-1 : 0] ilength0;		// Input Data Length: dimension 0
input  wire[BWLENGTH-1 : 0] ilength1;		// Input Data Length: dimension 1
input  wire[BWLENGTH-1 : 0] ilength2;		// Input Data Length: dimension 2
input  wire[ BDBANKA-1 : 0] ibaseaddr;		// Input data Base address
input  wire[ BWBANKA-1 : 0] wstride0;		// Weight Stride: dimension 0
input  wire[ BWBANKA-1 : 0] wstride1;		// Weight Stride: dimension 1
input  wire[ BWBANKA-1 : 0] wstride2;		// Weight Stride: dimension 2
input  wire[BWLENGTH-1 : 0] wlength0;		// Weight Length: dimension 0
input  wire[BWLENGTH-1 : 0] wlength1;		// Weight Length: dimension 1
input  wire[BWLENGTH-1 : 0] wlength2;		// Weight Length: dimension 2
input  wire[ BWBANKA-1 : 0] wbaseaddr;		// Weight Base address
output wire[ BDBANKA-1 : 0] iaddr_out;		// Input Data Address generated
output wire[ BWBANKA-1 : 0] waddr_out;		// Weight Address generated
output wire                 sh_out;         // Shift occurred
output wire                 shacc_done;     // Accumulation done


// AGU wires
wire  [ BDBANKA-1 : 0]  dagu_addr_out;
wire  [ BWBANKA-1 : 0]  wagu_addr_out;
wire  [ BDBANKA-1 : 0]  dagu_j0;
wire  [ BWBANKA-1 : 0]  wagu_j0;
wire                    dagu_step;
wire                    wagu_step;

// Zig-zag wires
wire  [   BPREC-1 : 0]  zigzag_offd;
wire  [   BPREC-1 : 0]  zigzag_offw;
wire                    wagu_z0_out;
wire                    wagu_z1_out;
wire                    zigzagu_step;

// Assignments
assign dagu_j0 = {{BDBANKA-BPREC{1'b0}}, iprecision};
assign wagu_j0 = {{BWBANKA-BPREC{1'b0}}, wprecision};
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
    .l0         (ilength0),
	.l1         (ilength1),
	.l2         (ilength2),
	.j0         (dagu_j0),
	.j1         (istride0),
	.j2         (istride1), 
	.j3         (istride2),
    .addr_out   (dagu_addr_out),
    .z0_out     (),
    .z1_out     (),
    .z2_out     ()
);

// Address generation unit for the weights
agu #(
	.BWADDR     (BWBANKA),
	.BWLENGTH   (BWLENGTH)
) wagu_unit (
    .clk        (clk),
    .clr        (clr),
    .step       (wagu_step),
    .l0         (wlength0),
	.l1         (wlength1),
	.l2         (wlength2),
	.j0         (wagu_j0),
	.j1         (wstride0),
	.j2         (wstride1), 
	.j3         (wstride2),
    .addr_out   (wagu_addr_out),
    .z0_out     (wagu_z0_out),
    .z1_out     (wagu_z1_out),
    .z2_out     ()
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
assign zigzagu_step = en & wagu_z0_out;
assign shacc_done = en & wagu_z1_out & wagu_z0_out;


endmodule