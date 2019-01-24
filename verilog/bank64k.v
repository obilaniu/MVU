/**
 * Data Bank
 * 
 * 128-bit-wide access, 64kbit (8KB) total.
 */


/**** Module portmux ****/
module bank64k(clk,
               cselIC, cselMVU, cselCtrl,
               addrIC, addrMVU, addrCtrl,
               dataIC, dataMVU, dataCtrl,
               data,
               grntIC, grntMVU, grntCtrl);


/* Parameters */
parameter  a =   9;
parameter  w = 128;

input  wire          clk;
input  wire          cselIC;
input  wire          cselMVU;
input  wire          cselCtrl;
input  wire[a-1 : 0] addrIC;
input  wire[a-1 : 0] addrMVU;
input  wire[a-1 : 0] addrCtrl;
input  wire[w-1 : 0] dataIC;
input  wire[w-1 : 0] dataMVU;
input  wire[w-1 : 0] dataCtrl;

output wire[w-1 : 0] data;
output wire          grntIC;
output wire          grntMVU;
output wire          grntCtrl;

wire       [a-1 : 0] addr;


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


/* 64k internal BRAM */
bram64k b (clk, {w{1'b0}}, addr, addr, 1'b0, data);


/* Module end */
endmodule
