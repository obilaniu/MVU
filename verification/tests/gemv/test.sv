`timescale 1ns/1ps

`include "mvu_inf.svh"

module test();

    logic clk;
    mvu_interface mvu_inf(clk);
    mvutop mvu0(mvu_inf);

endmodule