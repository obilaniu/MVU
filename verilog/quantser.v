/**
 * Quantizer/Serializer
 *
 * An all-in-one quantizer and serializer!
 *
 */

`timescale 1 ns / 1 ps

module quantser(clk, clr, msbidx, bdout, start, din, dout);

/* Parameters */
parameter BDIN        = 32;                 // Input data bit depth
parameter BDOUTMAX    = 32;                 // Maximum output data precision bit length (must be < BDIN)
localparam  MAXBDIP   = $clog2(BDIN);       // 
localparam  MAXBDOP   = $clog2(BDOUTMAX);   // 


/* Ports */
input   wire                                    clk;        // Clock
input   wire                                    clr;        // Clears the state and output reg
input   wire            [    MAXBDIP-1 : 0]     msbidx;     // Bit position of MSB in input
input   wire            [    MAXBDOP-1 : 0]     bdout;      // Bit depth of output
input   wire                                    start;      // Pos-edge trigger to start serializing output
input   wire            [       BDIN-1 : 0]     din;        // Input data
output  wire                                    dout;       // Serialized output


/* Internal registers */
reg             [    BDIN-1 : 0]    sr;         // Shift register
reg unsigned    [ MAXBDOP-1 : 0]    cntdwn;     // Serializer countdown



/* Shift register */
always @(posedge clk or posedge clr) begin
    if (clr) begin
        sr <= 0;
        cntdwn <= 0;
    end else if (clk) begin
        if (cntdwn != 0) begin
            //sr <= {sr[BDIN-2:1], 1'b0};
            sr <= sr << 1;
            sr[0] <= 1'b0;
            cntdwn <= cntdwn-1;
        end else begin
            if (start == 1) begin
                cntdwn <= bdout;
                sr <= din; 
            end else begin
                cntdwn <= 0;
                sr <= sr; 
            end
        end       
    end 
end


/* Serialized Output */
assign dout = sr[msbidx];


/* Module end */
endmodule