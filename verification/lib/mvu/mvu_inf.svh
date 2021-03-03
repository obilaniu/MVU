interface mvu_interface(input logic clk);
    import mvu_pkg::*;
    logic                       rst_n;                // Global reset
    logic[          NMVU-1 : 0] start;                // Start the MVU job
    logic[          NMVU-1 : 0] done;                 // Indicates if a job is done
    logic[          NMVU-1 : 0] irq;                  // Interrupt request
    logic                       ic_clr;                               // Interconnect: clear
    logic[        2*NMVU-1 : 0] mul_mode;             // Config: multiply mode
    logic[          NMVU-1 : 0] d_signed;             // Config: input data signed
    logic[          NMVU-1 : 0] w_signed;             // Config: weights signed
    logic[          NMVU-1 : 0] shacc_clr;            // Control: accumulator clear
    logic[          NMVU-1 : 0] max_en;               // Config: max pool enable
    logic[          NMVU-1 : 0] max_clr;              // Config: max pool clear
    logic[          NMVU-1 : 0] max_pool;                 // Config: max pool mode
    logic[          NMVU-1 : 0] quant_clr;            // Quantizer: clear
    logic[ NMVU*BQMSBIDX-1 : 0] quant_msbidx;         // Quantizer: bit position index of the MSB
    logic[  NMVU*BCNTDWN-1 : 0] countdown;            // Config: number of clocks to countdown for given task
    logic[    NMVU*BPREC-1 : 0] wprecision;           // Config: weight precision
    logic[    NMVU*BPREC-1 : 0] iprecision;           // Config: input precision
    logic[    NMVU*BPREC-1 : 0] oprecision;           // Config: output precision
    logic[  NMVU*BBWADDR-1 : 0] wbaseaddr;            // Config: weight memory base address
    logic[  NMVU*BBDADDR-1 : 0] ibaseaddr;            // Config: data memory base address for input
    logic[  NMVU*BBDADDR-1 : 0] obaseaddr;            // Config: data memory base address for output
    logic[     NMVU*NMVU-1 : 0] omvusel;                      // Config: MVU selector bits for output
    logic[  NMVU*BSTRIDE-1 : 0] wstride_0;            // Config: weight stride in dimension 0 (x)
    logic[  NMVU*BSTRIDE-1 : 0] wstride_1;            // Config: weight stride in dimension 1 (y)
    logic[  NMVU*BSTRIDE-1 : 0] wstride_2;            // Config: weight stride in dimension 2 (z)
    logic[  NMVU*BSTRIDE-1 : 0] wstride_3;            // Config: weight stride in dimension 3 (w)
    logic[  NMVU*BSTRIDE-1 : 0] istride_0;            // Config: input stride in dimension 0 (x)
    logic[  NMVU*BSTRIDE-1 : 0] istride_1;            // Config: input stride in dimension 1 (y)
    logic[  NMVU*BSTRIDE-1 : 0] istride_2;            // Config: input stride in dimension 2 (z)
    logic[  NMVU*BSTRIDE-1 : 0] istride_3;            // Config: input stride in dimension 3 (w)
    logic[  NMVU*BSTRIDE-1 : 0] ostride_0;            // Config: output stride in dimension 0 (x)
    logic[  NMVU*BSTRIDE-1 : 0] ostride_1;            // Config: output stride in dimension 1 (y)
    logic[  NMVU*BSTRIDE-1 : 0] ostride_2;            // Config: output stride in dimension 2 (z)
    logic[  NMVU*BSTRIDE-1 : 0] ostride_3;            // Config: output stride in dimension 3 (w)
    logic[  NMVU*BLENGTH-1 : 0] wlength_0;            // Config: weight length in dimension 0 (x)
    logic[  NMVU*BLENGTH-1 : 0] wlength_1;            // Config: weight length in dimension 1 (y)
    logic[  NMVU*BLENGTH-1 : 0] wlength_2;            // Config: weight length in dimension 2 (z)
    logic[  NMVU*BLENGTH-1 : 0] wlength_3;            // Config: weight length in dimension 3 (w)
    logic[  NMVU*BLENGTH-1 : 0] ilength_0;            // Config: input length in dimension 0 (x)
    logic[  NMVU*BLENGTH-1 : 0] ilength_1;            // Config: input length in dimension 1 (y)
    logic[  NMVU*BLENGTH-1 : 0] ilength_2;            // Config: input length in dimension 2 (z)
    logic[  NMVU*BLENGTH-1 : 0] ilength_3;            // Config: input length in dimension 3 (w)
    logic[  NMVU*BLENGTH-1 : 0] olength_0;            // Config: output length in dimension 0 (x)
    logic[  NMVU*BLENGTH-1 : 0] olength_1;            // Config: output length in dimension 1 (y)
    logic[  NMVU*BLENGTH-1 : 0] olength_2;            // Config: output length in dimension 2 (z)
    logic[  NMVU*BLENGTH-1 : 0] olength_3;            // Config: output length in dimension 3 (w)
    logic[ NMVU*BSCALERB-1 : 0] scaler_b;             // Config: multiplicative scaler (operand 'b')
    logic[   NMVU*NJUMPS-1 : 0] shacc_load_sel;       // Config: select jump trigger for shift/accumultor load
    logic[  NMVU*BWBANKA-1 : 0] wrw_addr;             // Weight memory: write address
    logic[  NMVU*BWBANKW-1 : 0] wrw_word;             // Weight memory: write word
    logic[          NMVU-1 : 0] wrw_en;               // Weight memory: write enable
    logic[          NMVU-1 : 0] rdc_en;               // Data memory: controller read enable
    logic[          NMVU-1 : 0] rdc_grnt;             // Data memory: controller read grant
    logic[  NMVU*BDBANKA-1 : 0] rdc_addr;             // Data memory: controller read address
    logic[  NMVU*BDBANKW-1 : 0] rdc_word;             // Data memory: controller read word
    logic[          NMVU-1 : 0] wrc_en;               // Data memory: controller write enable
    logic[          NMVU-1 : 0] wrc_grnt;             // Data memory: controller write grant
    logic[       BDBANKA-1 : 0] wrc_addr;             // Data memory: controller write address
    logic[       BDBANKW-1 : 0] wrc_word;             // Data memory: controller write word


//=================================================
// Modport for Testbench interface 
//=================================================
modport  tb_interface (
                        input   clk,
                        input   rst_n,
                        input  start,
                        output done,
                        output irq,
                        input  ic_clr,
                        input  mul_mode,
                        input  d_signed,
                        input  w_signed,
                        input  shacc_clr,
                        input  max_en,
                        input  max_clr,
                        input  max_pool,
                        input  quant_clr,
                        input  quant_msbidx,
                        input  countdown,
                        input  wprecision,
                        input  iprecision,
                        input  oprecision,
                        input  wbaseaddr,
                        input  ibaseaddr,
                        input  obaseaddr,
                        input  omvusel,
                        input  wstride_0,
                        input  wstride_1,
                        input  wstride_2,
                        input  wstride_3,
                        input  istride_0,
                        input  istride_1,
                        input  istride_2,
                        input  istride_3,
                        input  ostride_0,
                        input  ostride_1,
                        input  ostride_2,
                        input  ostride_3,
                        input  wlength_0,
                        input  wlength_1,
                        input  wlength_2,
                        input  wlength_3,
                        input  ilength_0,
                        input  ilength_1,
                        input  ilength_2,
                        input  ilength_3,
                        input  olength_0,
                        input  olength_1,
                        input  olength_2,
                        input  olength_3,
                        input  scaler_b,
                        input  shacc_load_sel,
                        input  wrw_addr,
                        input  wrw_word,
                        input  wrw_en,
                        input  rdc_en,
                        output rdc_grnt,
                        input  rdc_addr,
                        output rdc_word,
                        input  wrc_en,
                        output wrc_grnt,
                        input  wrc_addr,
                        input  wrc_word
);

//=================================================
// Modport for System interface 
//=================================================
modport  system_interface (
                           input   clk,
                           input   rst_n,
                           input  start,
                           output done,
                           output irq,
                           input  ic_clr,
                           input  mul_mode,
                           input  d_signed,
                           input  w_signed,
                           input  shacc_clr,
                           input  max_en,
                           input  max_clr,
                           input  max_pool,
                           input  quant_clr,
                           input  quant_msbidx,
                           input  countdown,
                           input  wprecision,
                           input  iprecision,
                           input  oprecision,
                           input  wbaseaddr,
                           input  ibaseaddr,
                           input  obaseaddr,
                           input  omvusel,
                           input  wstride_0,
                           input  wstride_1,
                           input  wstride_2,
                           input  wstride_3,
                           input  istride_0,
                           input  istride_1,
                           input  istride_2,
                           input  istride_3,
                           input  ostride_0,
                           input  ostride_1,
                           input  ostride_2,
                           input  ostride_3,
                           input  wlength_0,
                           input  wlength_1,
                           input  wlength_2,
                           input  wlength_3,
                           input  ilength_0,
                           input  ilength_1,
                           input  ilength_2,
                           input  ilength_3,
                           input  olength_0,
                           input  olength_1,
                           input  olength_2,
                           input  olength_3,
                           input  scaler_b,
                           input  shacc_load_sel,
                           input  wrw_addr,
                           input  wrw_word,
                           input  wrw_en,
                           input  rdc_en,
                           output rdc_grnt,
                           input  rdc_addr,
                           output rdc_word,
                           input  wrc_en,
                           output wrc_grnt,
                           input  wrc_addr,
                           input  wrc_word
);

endinterface