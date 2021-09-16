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
    logic[  NMVU*BSBANKA-1 : 0] sbaseaddr;            // Config: scaler memory base address
    logic[  NMVU*BBBANKA-1 : 0] bbaseaddr;            // Config: bias memory base address
    logic[  NMVU*BBDADDR-1 : 0] obaseaddr;            // Config: data memory base address for output
    logic[     NMVU*NMVU-1 : 0] omvusel;              // Config: MVU selector bits for output
    logic[  NMVU*BBDADDR-1 : 0] ihpbaseaddr;          // Config: high-precision data memory base address for input
    logic[  NMVU*BBDADDR-1 : 0] ohpbaseaddr;          // Config: high-precision data memory base address for output
    logic[     NMVU*NMVU-1 : 0] ohpmvusel;            // Config: MVU selector bits for high-precision output
    logic[         BJUMP-1 : 0] wjump[NMVU-1 : 0][NJUMPS-1 : 0];            // Config: weight jumps
    logic[         BJUMP-1 : 0] ijump[NMVU-1 : 0][NJUMPS-1 : 0];            // Config: input jumps
    logic[         BJUMP-1 : 0] hpjump[NMVU-1 : 0][NJUMPS-1 : 0];           // Config: input jumps
    logic[         BJUMP-1 : 0] sjump[NMVU-1 : 0][NJUMPS-1 : 0];            // Config: scaler jumps
    logic[         BJUMP-1 : 0] bjump[NMVU-1 : 0][NJUMPS-1 : 0];            // Config: bias jumps
    logic[         BJUMP-1 : 0] ojump[NMVU-1 : 0][NJUMPS-1 : 0];            // Config: output jumps
    logic[       BLENGTH-1 : 0] wlength[NMVU-1 : 0][NJUMPS-1 : 1];          // Config: weight lengths
    logic[       BLENGTH-1 : 0] ilength[NMVU-1 : 0][NJUMPS-1 : 1];          // Config: input length
    logic[       BLENGTH-1 : 0] hplength[NMVU-1 : 0][NJUMPS-1 : 1];         // Config: scaler length
    logic[       BLENGTH-1 : 0] slength[NMVU-1 : 0][NJUMPS-1 : 1];          // Config: scaler length
    logic[       BLENGTH-1 : 0] blength[NMVU-1 : 0][NJUMPS-1 : 1];          // Config: bias length
    logic[       BLENGTH-1 : 0] olength[NMVU-1 : 0][NJUMPS-1 : 1];          // Config: output length
    logic[ NMVU*BSCALERB-1 : 0] scaler1_b;                                  // Config: multiplicative scaler (operand 'b')
    logic[ NMVU*BSCALERB-1 : 0] scaler2_b;                                  // Config: multiplicative scaler (operand 'b')
    logic                       usescaler_mem[NMVU-1 : 0];                  // Config: use scalar mem if 1; otherwise use the scaler_b input for scaling
    logic                       usebias_mem[NMVU-1 : 0];                    // Config: use the bias memory if 1; if not, not bias is added in the scaler
    logic                       usepooler4hpout[NMVU-1 : 0];                // Config: for the high-precision interconnect, use the output of pooler if 1, or use output of scaler1 if 0
    logic                       usehpadder[NMVU-1 : 0];                     // Config: use the hpadder if 1
    logic[        NJUMPS-1 : 0] shacc_load_sel[NMVU-1 : 0];                 // Config: select jump trigger for shift/accumultor load
    logic[        NJUMPS-1 : 0] zigzag_step_sel[NMVU-1 : 0];                // Config: select jump trigger for stepping the zig-zag address generator  
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
    logic[          NMVU-1 : 0] wrs_en;               // Scaler memory: write enable
    logic[       BSBANKA-1 : 0] wrs_addr;             // Scaler memory: write address
    logic[       BSBANKW-1 : 0] wrs_word;             // Scaler memory: write word
    logic[          NMVU-1 : 0] wrb_en;               // Bias memory: write enable
    logic[       BBBANKA-1 : 0] wrb_addr;             // Bias memory: write address
    logic[       BBBANKW-1 : 0] wrb_word;             // Bias memory: write word

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
                        input  sbaseaddr,
                        input  bbaseaddr,
                        input  obaseaddr,
                        input  omvusel,
                        input  ihpbaseaddr,
                        input  ohpbaseaddr,
                        input  ohpmvusel,
                        input  wjump,
                        input  ijump,
                        input  hpjump,
                        input  sjump,
                        input  bjump,
                        input  ojump,
                        input  wlength,
                        input  ilength,
                        input  hplength,
                        input  slength,
                        input  blength,
                        input  olength,
                        input  scaler1_b,
                        input  scaler2_b,
                        input  usescaler_mem,
                        input  usebias_mem,
                        input  usepooler4hpout,
                        input  usehpadder,
                        input  shacc_load_sel,
                        input  zigzag_step_sel,
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
                        input  wrc_word,
                        input  wrs_en,
                        input  wrs_addr,
                        input  wrs_word,
                        input  wrb_en,
                        input  wrb_addr,
                        input  wrb_word
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
                           input  sbaseaddr,
                           input  bbaseaddr,
                           input  obaseaddr,
                           input  omvusel,
                           input  ihpbaseaddr,
                           input  ohpbaseaddr,
                           input  ohpmvusel,
                           input  wjump,
                           input  ijump,
                           input  hpjump,
                           input  sjump,
                           input  bjump,
                           input  ojump,
                           input  wlength,
                           input  ilength,
                           input  hplength,
                           input  slength,
                           input  blength,
                           input  olength,
                           input  scaler1_b,
                           input  scaler2_b,
                           input  usescaler_mem,
                           input  usebias_mem,
                           input  usepooler4hpout,
                           input  usehpadder,
                           input  shacc_load_sel,
                           input  zigzag_step_sel,
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
                           input  wrc_word,
                           input  wrs_en,
                           input  wrs_addr,
                           input  wrs_word,
                           input  wrb_en,
                           input  wrb_addr,
                           input  wrb_word
);

endinterface