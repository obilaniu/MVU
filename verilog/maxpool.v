/**
 * Max-Pooling
 */

`timescale 1ns/1ps
/**** Module ****/
module maxpool(clk, max_clr, max_pool, I, O);


/* Parameters */
parameter N = 32;

input  wire                 clk;
input  wire                 max_clr;
input  wire                 max_pool;
input  wire signed[N-1 : 0] I;
output reg  signed[N-1 : 0] O = 0;


/* Logic */
always @(posedge clk) begin
    if(max_clr) begin
        O <= 0;
    end else if(clk) begin
        if(max_pool) begin
            if(I>O) begin
                O <= I;/* O = max(O,I) */
            end else begin
                O <= I;    /* Plain set */
            end
        end else begin
            O <= I;
        end
    end
end


/* Module end */
endmodule



/**** Test Module ****/
module test_maxpool();


/* Local parameters for test */
localparam N = 32;


/* Create input registers and output wires */
reg                  clk      = 0;
reg                  max_en   = 0;
reg                  max_clr  = 0;
reg                  max_pool = 0;
reg  signed[N-1 : 0] I        = 0;
wire signed[N-1 : 0] O;


/* Create instance */
maxpool #(N) master (clk, max_en, max_clr, max_pool, I, O);


/* Run test */
initial forever begin #10; $display("%t: %9d", $time, O); end
always  begin clk=0; #5; clk=1; #5;                       end
initial begin
	I= 0; max_en=1; max_clr=1; max_pool=0; #10;
	I= 1; max_en=1; max_clr=0; max_pool=0; #10;
	I= 0; max_en=1; max_clr=0; max_pool=0; #10;
	I=-4; max_en=1; max_clr=0; max_pool=0; #10;
	I=+5; max_en=1; max_clr=0; max_pool=0; #10;
	I= 0; max_en=1; max_clr=0; max_pool=1; #10;
	I=+1; max_en=1; max_clr=0; max_pool=1; #10;
	I=+9; max_en=1; max_clr=0; max_pool=1; #10;
	I=+1; max_en=1; max_clr=0; max_pool=1; #10;
	I=-1; max_en=1; max_clr=1; max_pool=1; #10;
	$finish();
end

endmodule
