`timescale 1ns/1ps
module test_bram16k();

reg clock = 0;
reg [31:0]  data = 0;
reg [8:0]   rdaddress = 0;
reg [8:0]   wraddress = 0;
reg wren = 0;
wire [31:0] q;

bram16k ram(clock, data, rdaddress, wraddress, wren, q);

initial forever begin clock = 0; #5; clock = 1; #5; end
initial begin
	$display("%t: q=%x", $time, q);
	data = 'hDEADBEEF;
	wren = 1;
	#10;
	$display("%t: q=%x", $time, q);
	#10;
	$display("%t: q=%x", $time, q);
	$finish();
end

endmodule
