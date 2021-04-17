/**
 * Shifter-Accumulator.
 */

`timescale 1ns/1ps
/**** Module shacc ****/
module shacc(clk, clr, load, acc, sh, I, O);


/* Parameters */
parameter  w = 32;
parameter  a = w;

input  wire                 clk;
input  wire                 clr;
input  wire                 load;
input  wire                 acc;
input  wire                 sh;
input  wire signed[a-1 : 0] I;

output reg  signed[w-1 : 0] O = 0;


/* Logic */
always @(posedge clk) begin
	if(clr) begin
		O = 0;
	end else if(clk) begin
        if (load) begin
            O = I;
        end else if (acc) begin
            if(sh) O = O+O+I; /* Shift left of accumulator */
            else   O = O+I;   /* Plain accumulate */
        end
	end
end


/* Module end */
endmodule



/**** Test Module test_shacc ****/
module test_shacc();


/* Local parameters for test */
localparam w = 32;
localparam a = 8;


/* Create input registers and output wires */
reg                  clk = 0;
reg                  clr = 0;
reg                  sh  = 0;
reg  signed[a-1 : 0] I   = 0;
wire signed[w-1 : 0] O;


/* Create instance */
shacc #(w,a) master (clk, clr, sh, I, O);


/* Run test */
initial forever begin #10; $display("%t: %9d", $time, O); end
always  begin clk=0; #5; clk=1; #5;                       end
initial begin
	I= 0; clr=0; sh=0; #10;
	I= 1; clr=0; sh=0; #10;
	I= 0; clr=0; sh=0; #10;
	I=-4; clr=0; sh=0; #10;
	I=+9; clr=0; sh=0; #10;
	I= 0; clr=0; sh=1; #10;
	I=+1; clr=0; sh=1; #10;
	I=+1; clr=1; sh=1; #10;
	I=+1; clr=1; sh=0; #10;
	I= 1; clr=0; sh=0; #10;
	$finish();
end

endmodule
