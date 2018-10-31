/**
 * Interconnect between MVUs
 */

module interconn (clk, rst,
                  sendValid, sendAddr, sendMsg,
                  recvValid, recvMsg);

parameter   n = 32;
parameter   w = 96;

localparam  a = $clog2(n);

input  wire             clk;
input  wire             rst;
input  wire [n-1   : 0] sendValid;
input  wire [n*a-1 : 0] sendAddr;
input  wire [n*w-1 : 0] sendMsg;

output wire [n-1   : 0] recvValid;
output wire [n*w-1 : 0] recvMsg;

genvar i;

generate for(i=0;i<n;i=i+1) begin:xbarloop
	wire [a-1:0] addr;
	assign addr                  = sendAddr [i*a+a-1    -: a];
	assign recvValid[i]          = sendValid[addr];
	assign recvMsg[i*w+w-1 -: w] = sendMsg  [addr*w+w-1 -: w];
end endgenerate

endmodule




/**
 * Testbench for Interconnect
 */

module test_interconn;

localparam n = 32;
localparam w = 16;
localparam a = $clog2(n);

reg              clk;
reg              rst;
reg  [n-1   : 0] sendValid;
reg  [n*a-1 : 0] sendAddr;
reg  [n*w-1 : 0] sendMsg;
wire [n-1   : 0] recvValid;
wire [n*w-1 : 0] recvMsg;

/* Spawn an interconnect block */
interconn #(n,w) ic (clk, rst, sendValid, sendAddr, sendMsg, recvValid, recvMsg);

/* Run the clock */
always begin clk <= 0; #0.5; clk <= 1; #0.5; end

/* Feed interconnect some inputs and see how it responds. */
initial begin
	rst <= 1;
	#5;
	rst <= 0;
	#1;
	sendValid[0]   <= 1;
	sendValid[1]   <= 1;
	sendValid[2]   <= 1;
	sendMsg[15: 0] <= 16'h0000;
	sendMsg[31:16] <= 16'hDEAD;
	sendMsg[47:32] <= 16'hBEEF;
	sendAddr[n*a-1:0] <= 0;
	sendAddr[19:15] <= 5'd1;
	sendAddr[24:20] <= 5'd0;
	sendAddr[29:25] <= 5'd2;
	#1;
	$display("Crossbar result");
	$display({" 0 | %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x\n",
	          "16 | %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x %4x"},
	         recvMsg[ 15:  0],
	         recvMsg[ 31: 16],
	         recvMsg[ 47: 32],
	         recvMsg[ 63: 48],
	         recvMsg[ 79: 64],
	         recvMsg[ 95: 80],
	         recvMsg[111: 96],
	         recvMsg[127:112],
	         recvMsg[143:128],
	         recvMsg[159:144],
	         recvMsg[175:160],
	         recvMsg[191:176],
	         recvMsg[207:192],
	         recvMsg[223:208],
	         recvMsg[239:224],
	         recvMsg[255:240],
	         recvMsg[271:256],
	         recvMsg[287:272],
	         recvMsg[303:288],
	         recvMsg[319:304],
	         recvMsg[335:320],
	         recvMsg[351:336],
	         recvMsg[367:352],
	         recvMsg[383:368],
	         recvMsg[399:384],
	         recvMsg[415:400],
	         recvMsg[431:416],
	         recvMsg[447:432],
	         recvMsg[463:448],
	         recvMsg[479:464],
	         recvMsg[495:480],
	         recvMsg[511:496]);
	$display("Simulation End Time: %t", $time);
	$finish();
end

endmodule
