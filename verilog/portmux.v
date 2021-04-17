/**
 * Port Multiplexer
 */
`timescale 1ns/1ps
/**** Module portmux ****/
module portmux(cselIC, cselMVU, cselCtrl,
               addrIC, addrMVU, addrCtrl,
               dataIC, dataMVU, dataCtrl,
               addr,
               data,
               grntIC, grntMVU, grntCtrl);


/* Parameters */
parameter  a =   9;
parameter  w = 128;

input  wire          cselIC;
input  wire          cselMVU;
input  wire          cselCtrl;
input  wire[a-1 : 0] addrIC;
input  wire[a-1 : 0] addrMVU;
input  wire[a-1 : 0] addrCtrl;
input  wire[w-1 : 0] dataIC;
input  wire[w-1 : 0] dataMVU;
input  wire[w-1 : 0] dataCtrl;

output wire[a-1 : 0] addr;
output wire[w-1 : 0] data;
output wire          grntIC;
output wire          grntMVU;
output wire          grntCtrl;


/* Wiring */
assign grntIC   =  cselIC;
assign grntMVU  = ~grntIC &  cselMVU;
assign grntCtrl = ~grntIC & ~grntMVU & cselCtrl;
assign addr     = (grntIC   ? addrIC   :
                  (grntMVU  ? addrMVU  :
                  (grntCtrl ? addrCtrl :
                              {a{1'bX}})));
assign data     = (grntIC   ? dataIC   :
                  (grntMVU  ? dataMVU  :
                  (grntCtrl ? dataCtrl :
                              {w{1'bX}})));


/* Module end */
endmodule
