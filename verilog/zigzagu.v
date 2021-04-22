`timescale 1ns/1ps
/**
 * Zig-Zag Address Generation Unit (Zig-ZAGU)
 */

/**** Module ****/
module zigzagu(clk, clr, step, pw, pd, sh, offw, offd);

parameter BWADDR = 21;             /* Bitwidth of Address */
parameter BPREC = 4;                // Bitwidth of the precision specifier

input  wire                     clk, clr, step;
input  wire[       BPREC-1 : 0] pw;/* Precision of weights */
input  wire[       BPREC-1 : 0] pd;/* Precision of data */

output reg                      sh;/* A shift was performed. */
output wire[       BPREC-1 : 0] offw;/* Additional Offset to Weights */
output wire[       BPREC-1 : 0] offd;/* Additional Offset to Data */


/* Local wires */
wire       [         BPREC : 0] sump;



/* Local registers */
reg        [         BPREC : 0] iw = 0;
reg        [         BPREC : 0] id = 0;



/* Logic */
assign sump = {1'b0, pw} + {1'b0, pd} - 1;
assign offw = iw[BPREC-1 : 0];
assign offd = id[BPREC-1 : 0];

/**
 *  123456789
 * A/////////
 * B/////////
 * C/////////
 * D/////////
 */

always @(posedge clk) begin
    /* Zig-zag Stepping Active */
    if(step == 1) begin
        /* Diagonal walk. */
        sh = ((iw == 0) | (id == pd-1));
        id = id+1;
        iw = iw-1;
        
        /* Perform shift if required. */
        if(sh != 0) begin
            iw = iw+id+1;
            id = 0;
            
            /* Shift may place iw out of bounds. Wrap or clamp. */
            if         (iw >= sump) begin
                /* Multiplication done. Wraparound to (0,0). */
                id = 0;
                iw = 0;
                sh = 0;
            end else if(iw >= pw)   begin
                /* We are deep enough in the multiplication that we must clamp. */
                id = iw-pw+1;
                iw = iw-id;
            end else if(id >= pd)   begin
                /* We are deep enough in the multiplication that we must clamp. */
                iw = id-pd+1;
                id = id-iw;
            end
        end
    end else begin
        sh = 0;
    end
    
    /* Clear Signal Active. Overrides other signals. */
    if(clr == 1) begin
        id = 0;
        iw = 0;
        sh = 0;
    end
end



/* Module end */
endmodule



/**** Test Module test_shacc ****/
module test_zigzagu();


/* Local parameters for test */
localparam w = 32;
localparam a = 8;


/* Create input registers and output wires */
reg                  clk  = 0;
reg                  clr  = 0;
reg                  step = 0;
reg           [3 : 0]pw   = 6;
reg           [3 : 0]pd   = 4;
wire                 sh;
wire          [3 : 0]offw;
wire          [3 : 0]offd;


/* Create instance */
zigzagu zz (clk, clr, step, pw, pd, sh, offw, offd);


/* Run test */
initial forever begin
    #10;
    $display("%t: clr=%d, sh=%d, offw=%2d, offd=%2d", $time, clr, sh, offw, offd);
end
always  begin clk=0; #5; clk=1; #5; end
initial begin
    step = 1;
    #40; clr = 1; #10; clr = 0;
    #300;
    $finish();
end


/* Module end */
endmodule
