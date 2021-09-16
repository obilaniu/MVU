/**
 * Matrix-Vector Unit
 * 
 * Signals needed for each MVU:
 *     | Signal   | Description                 | Bits
 *     +----------+-----------------------------+-------
 *     | clk      | Clock                       | 1
 *     | mul_mode | Multiply Mode               | 2
 *     | acc_clr  | Accumulator Clear           | 1
 *     | acc_sh   | Accumulator Shift           | 1
 *     | max_en   | Maxpooling Enable           | 1
 *     | max_clr  | Maxpooling Clear            | 1
 *     | max_pool | Maxpooling Pool/Copy        | 1
 *     |          |                             |
 *     | rdw_addr | Read  Weights      Address  | 9
 *     |          |                             |
 *     | rdd_en   | Read  Data         Enable   | 1
 *     | rdd_grnt | Read  Data         Grant    | 1
 *     | rdd_addr | Read  Data         Address  | 5+9
 *     | wrd_en   | Write Data         Enable   | 1
 *     | wrd_grnt | Write Data         Grant    | 1
 *     | wrd_addr | Write Data         Address  | 5+9
 *     |          |                             |
 *     | rdi_en   | Read  Interconnect Enable   | 1
 *     | rdi_grnt | Read  Interconnect Grant    | 1
 *     | rdi_addr | Read  Interconnect Address  | 5+9
 *     | rdi_word | Read  Interconnect Word     | 128
 *     | wri_en   | Write Interconnect Enable   | 1
 *     | wri_grnt | Write Interconnect Grant    | 1
 *     | wri_addr | Write Interconnect Address  | 5+9
 *     | wri_word | Write Interconnect Word     | 128
 *     |          |                             |
 *     | rdc_en   | Read  Controller   Enable   | 1
 *     | rdc_grnt | Read  Controller   Grant    | 1
 *     | rdc_addr | Read  Controller   Address  | 5+9
 *     | rdc_word | Read  Controller   Word     | 128
 *     | wrc_en   | Write Controller   Enable   | 1
 *     | wrc_grnt | Write Controller   Grant    | 1
 *     | wrc_addr | Write Controller   Address  | 5+9
 *     | wrc_word | Write Controller   Word     | 128
 *     +----------+-----------------------------+-------
 *     | TOTAL                                    625
 */

`timescale 1 ns / 1 ps
/**** Module mvu ****/
module mvu( clk,
            mul_mode,
            neg_acc,
            shacc_clr,
            shacc_load,
            shacc_acc,
            shacc_sh,
            scaler1_clr,
            scaler1_b,
            usescaler_mem,
            usebias_mem,
            usehpadder,
            usepooler4hpout,
            hpadder_clr,
            max_en,
            max_clr,
            max_pool,
            scaler2_clr,
            scaler2_b,
            quant_clr,
            quant_msbidx,
			quant_step,
            quant_load,
            rdw_addr,
			wrw_addr,
			wrw_word,
			wrw_en,
            rdd_en,
            rdd_grnt,
            rdd_addr,
            wrd_en,
            wrd_grnt,
            wrd_addr,
            rdi_en,
            rdi_grnt,
            rdi_addr,
            rdi_word,
            wri_en,
            wri_grnt,
            wri_addr,
            wri_word,
            rdc_en,
            rdc_grnt,
            rdc_addr,
            rdc_word,
            wrc_en,
            wrc_grnt,
            wrc_addr,
            wrc_word,
            mvu_word_out,
            rddhp_addr,
            wrihp_en,
            wrihp_addr,
            wrihp_word,
            mvu_word_outhp,
            rds_en,
            rds_addr,
            wrs_en,
            wrs_addr,   
            wrs_word,
            rdb_en,
            rdb_addr,
            wrb_en,
            wrb_addr,
            wrb_word
);


/* Parameters */
parameter  N          = 64;   /* N x N matrix-vector product size. Power-of-2. */
parameter  NDBANK     = 32;   /* Number of N-bit, 1024-element Data BANK. */

parameter  BDHPBANKW  = 32;    // Bitwidth of high-precision data bank word
parameter  BDHPBANKA  = 9;     // Bitwidth of high-precision data bank address

parameter  BBIAS   = 32;   // Bit witdh of the bias values

localparam CLOG2N      = $clog2(N);     /* clog2(N) */

localparam BWBANKA     = 9;             /* Bitwidth of Weights BANK Address */
localparam BWBANKW     = N*N;           /* Bitwidth of Weights BANK Word */
localparam BDBANKABS   = $clog2(NDBANK);/* Bitwidth of Data    BANK Address Bank Select */
localparam BDBANKAWS   = 10;            /* Bitwidth of Data    BANK Address Word Select */
localparam BDBANKA     = BDBANKABS+     /* Bitwidth of Data    BANK Address */
                         BDBANKAWS;
localparam BDBANKW     = N;             /* Bitwidth of Data    BANK Word */
localparam BSUM        = CLOG2N+2;      /* Bitwidth of Sums */
localparam BACC        = 27;            /* Bitwidth of Accumulators */

localparam BSCALERA    = BACC;
localparam BSCALERB    = 16;
localparam BSCALERC    = 27;
localparam BSCALERD    = 27;
localparam BSCALERP    = 27;

localparam BSBANKA     = 6;             // Bitwidth of Scaler BANK address
localparam BSBANKW     = BSCALERB*N;    // Bitwidth of Scaler BANK word
localparam BBBANKA     = 6;             // Bitwidth of Scaler BANK address
localparam BBBANKW     = BBIAS*N;       // Bitwidth of Scaler BANK word


// Quantizer parameters
parameter  QMSBLOCBD  = $clog2(BSCALERP);   // Bitwidth of the quantizer MSB location specifier

/* Interface */
input  wire                 clk;
input  wire[        1 : 0]  mul_mode;
input  wire                 neg_acc;                 // Negate the inputs to the accumulators
input  wire                 shacc_clr;
input  wire                 shacc_load;
input  wire                 shacc_acc;
input  wire                 shacc_sh;
input  wire                 scaler1_clr;             // Scaler1: clear/reset
input  wire[BSCALERB-1 : 0] scaler1_b;               // Scaler1: multiplier operand
input  wire                 usescaler_mem;
input  wire                 usebias_mem;
input  wire                 usehpadder;
input  wire                 hpadder_clr;             // Adder: clear/reset
input  wire                 max_en;
input  wire                 max_clr;
input  wire                 max_pool;
input  wire                 usepooler4hpout;         // When 1, use the pooler to output to high-precision interconnect; otherwise take output from scaler1
input  wire                 scaler2_clr;             // Scaler2: clear/reset
input  wire[BSCALERB-1 : 0] scaler2_b;               // Scaler2: multiplier operand

// Quantizer input signals
input  wire                  quant_clr;
input  wire[QMSBLOCBD-1 : 0] quant_msbidx;
input  wire                  quant_load;
input  wire                  quant_step;

// Weight memory signals
input  wire[  BWBANKA-1 : 0]	rdw_addr;
input  wire[  BWBANKA-1 : 0]	wrw_addr;			// Weight memory: write address
input  wire[  BWBANKW-1 : 0]	wrw_word;			// Weight memory: write word
input  wire						wrw_en;				// Weight memory: write enable

// Scaler memory signals
input   wire                rds_en;                 // Scaler memory: read enable
input   wire[BSBANKA-1 : 0] rds_addr;               // Scaler memory: read address
input   wire                wrs_en;                 // Scaler memory: write enable
input   wire[BSBANKA-1 : 0] wrs_addr;               // Scaler memory: write address
input   wire[BSBANKW-1 : 0] wrs_word;               // Scaler memory: write word

// Bias memory signals
input   wire                rdb_en;                 // Bias memory: read enable
input   wire[BBBANKA-1 : 0] rdb_addr;               // Bias memory: read address
input   wire                wrb_en;                 // Bias memory: write enable
input   wire[BBBANKA-1 : 0] wrb_addr;               // Bias memory: write address
input   wire[BBBANKW-1 : 0] wrb_word;               // Bias memory: write word

input  wire                rdd_en;
output wire                rdd_grnt;
input  wire[BDBANKA-1 : 0] rdd_addr;
input  wire                wrd_en;
output wire                wrd_grnt;
input  wire[BDBANKA-1 : 0] wrd_addr;

input  wire                rdi_en;
output wire                rdi_grnt;
input  wire[BDBANKA-1 : 0] rdi_addr;
output reg [BDBANKW-1 : 0] rdi_word;
input  wire                wri_en;
output wire                wri_grnt;
input  wire[BDBANKA-1 : 0] wri_addr;
input  wire[BDBANKW-1 : 0] wri_word;

input  wire                rdc_en;
output wire                rdc_grnt;
input  wire[BDBANKA-1 : 0] rdc_addr;
output reg [BDBANKW-1 : 0] rdc_word;
input  wire                wrc_en;
output wire                wrc_grnt;
input  wire[BDBANKA-1 : 0] wrc_addr;
input  wire[BDBANKW-1 : 0] wrc_word;

output wire[BDBANKW-1 : 0] mvu_word_out;

input  wire[  BDHPBANKA-1 : 0] rddhp_addr;          // High-precision data local read address
input  wire                    wrihp_en;            // High-precision data interconnect write enable
input  wire[N*BDHPBANKW-1 : 0] wrihp_word;          // High-precision data interconnect write word
input  wire[  BDHPBANKA-1 : 0] wrihp_addr;          // High-precision data interconnect write address
output wire[N*BDHPBANKW-1 : 0] mvu_word_outhp;      // High-precision data output word (composed of N words)

/* Generation Variables */
genvar i, j;


/* Local Wires */
wire                rd_en;
wire[1 : 0]         rd_muxcode;
wire[BDBANKA-1 : 0] rd_addr;
wire                wr_en;
wire[1 : 0]         wr_muxcode;
wire[BDBANKA-1 : 0] wr_addr;

wire[BWBANKW-1 : 0]     core_weights;
wire[BDBANKW-1 : 0]     core_data;
wire[BSUM*N-1  : 0]     core_out;
wire signed[BSUM-1 : 0] core_out_signed [N-1 : 0];
wire signed[BSUM-1 : 0] shacc_in        [N-1 : 0];
wire[BACC-1  : 0]       shacc_out       [N-1 : 0];
wire[BSCALERP-1 : 0]    scaler1_out     [N-1 : 0];
wire[BDHPBANKW-1 : 0]   hpadder_b_in    [N-1 : 0];
wire[BSCALERP-1 : 0]    hpadder_out     [N-1 : 0];
wire[BSCALERP-1 : 0]    pool_out        [N-1 : 0];
wire[BSCALERP-1 : 0]    scaler2_out     [N-1 : 0];
wire[BDBANKW-1 : 0]     quant_out;
reg [BDBANKW-1 : 0]     rdd_word;
wire[BDBANKW-1 : 0]     wrd_word;

wire[NDBANK*BDBANKW-1 : 0] rdd_words;
wire[NDBANK*BDBANKW-1 : 0] rdi_words;
wire[NDBANK*BDBANKW-1 : 0] rdc_words;
wire[BDBANKW*NDBANK-1 : 0] rdd_words_t;
wire[BDBANKW*NDBANK-1 : 0] rdi_words_t;
wire[BDBANKW*NDBANK-1 : 0] rdc_words_t;

wire[   N*BDHPBANKW-1 : 0] rddhp_word;              // High-precision data memory word bus

wire[BSBANKW-1 : 0]        rds_word;                // Scaler memory: read word
wire[BBBANKW-1 : 0]        rdb_word;                // Bias memory: read word
wire[BSCALERB-1 : 0]       scaler1_mult_op[N-1 : 0]; // Scaler input multiplier operand
wire[BSCALERC-1 : 0]       scaler1_post_op[N-1 : 0]; // Scaler input postadd operand



/* Wiring */
cdru    #(BDBANKABS, BDBANKAWS)    read_cdu     (rdi_en, rdi_addr, rdi_grnt,
                                      rdd_en, rdd_addr, rdd_grnt,
                                      rdc_en, rdc_addr, rdc_grnt,
                                      rd_en,  rd_addr,  rd_muxcode);

cdwu    #(BDBANKABS, BDBANKAWS)    write_cdu    (wri_en, wri_addr, wri_grnt,
                                      wrd_en, wrd_addr, wrd_grnt,
                                      wrc_en, wrc_addr, wrc_grnt,
                                      wr_en,  wr_addr,  wr_muxcode);


/* Matrix-vector product unit */
mvp     #(N, 'b0010101) matrix_core  (clk, mul_mode, core_weights, core_data, core_out);


/* Weight memory banks */
`ifdef INTEL
    bram2m          weights_bank (clk, {BWBANKW{1'b0}}, rdw_addr, {BWBANKA{1'b0}}, 1'b0, core_weights);
`elsif XILINX
    bram2m_xilinx   weights_bank (
        .clka	(clk),			// input wire clka
        .ena    (1'b1),         // always enable
        .wea	(wrw_en),		// write enable from outside world
        .addra	(wrw_addr),		// write address from outside world
        .dina	(wrw_word),		// write word from outside world
        .clkb	(clk),			// input wire clkb
        .enb	(1'b1),			// always enable the read port
        .addrb	(rdw_addr),		// read address from address generator
        .doutb	(core_weights)	// weight word to MVU core        
    );
 `else
    $display("ERROR: INTEL or XILINX macro not defined!");
 `endif


// Scaler memory bank
//      Used to store batch norm weights and/or quantization scalers
 ram_simple2port #(
    .BDADDR(BSBANKA),
    .BDWORD(BSBANKW)
 ) scaler_bank (
    .clk(clk),
    .rd_en(rds_en),
    .rd_addr(rds_addr),
    .rd_word(rds_word),
    .wr_en(wrs_en),
    .wr_addr(wrs_addr),
    .wr_word(wrs_word)
 );


 // Bias memory bank
 //     Stores bias values from conv/fc/bn layers
// Scaler memory bank
//      Used to store batch norm weights and/or quantization scalers
 ram_simple2port #(
    .BDADDR(BBBANKA),
    .BDWORD(BBBANKW)
 ) bias_bank (
    .clk(clk),
    .rd_en(rdb_en),
    .rd_addr(rdb_addr),
    .rd_word(rdb_word),
    .wr_en(wrb_en),
    .wr_addr(wrb_addr),
    .wr_word(wrb_word)
 );


// Negate the core output before accumulation, if the negation control is set to 1
generate for (i=0; i < N; i=i+1) begin: acc_in_array
    assign core_out_signed[i] = core_out[i*BSUM +: BSUM];
    assign shacc_in[i] = neg_acc ? -core_out_signed[i] : core_out_signed[i];
end endgenerate

/* Shift/Accumulators */
generate for(i=0;i<N;i=i+1) begin:shaccarray
    shacc   #(BACC, BSUM) accumulator(clk, shacc_clr, shacc_load, shacc_acc, shacc_sh,
                                      shacc_in[i],
                                      shacc_out[i]);
end endgenerate

/* First Scalers */
generate for (i=0; i < N; i=i+1) begin: scaler1array
    
    assign scaler1_mult_op[i] = usescaler_mem ? rds_word[i*BSCALERB +: BSCALERB] : scaler1_b;
    assign scaler1_post_op[i] = usebias_mem ? rdb_word[i*BBIAS +: BSCALERC] : 0;

    fixedpointscaler #(
        .BA(BSCALERA),
        .BB(BSCALERB),
        .BC(BSCALERC),
        .BD(BSCALERD),
        .BP(BSCALERP)
    ) scaler1 (
        .clk(clk),
        .clr(scaler1_clr),
        .a(shacc_out[i]),
        .b(scaler1_mult_op[i]),
        .c(scaler1_post_op[i]),
        .d({BSCALERD{1'b0}}),
        .p(scaler1_out[i])
    );
end endgenerate

/* Fixed point high-precision adders */
generate for (i=0; i < N; i=i+1) begin: hpadderarray

    // If usehpadder is 1, then take the input operand from the high-precision memory, otherwise input zero
    assign hpadder_b_in[i] = usehpadder ? rddhp_word[i*BDHPBANKW +: BDHPBANKW] : 0;

    fixedpointadder #(
        .BA(BSCALERP),
        .BB(BDHPBANKW),
        .BOUT(BSCALERP)
    ) hpadder (
        .clk(clk),
        .clr(hpadder_clr),
        .a(scaler1_out[i]),
        .b(hpadder_b_in[i]),
        .out(hpadder_out[i])
    );
end endgenerate


/* Max poolers */
generate for(i=0;i<N;i=i+1) begin:poolarray
    maxpool #(BSCALERP)       pooler (clk, max_clr, max_pool,
                                      scaler1_out [i],
                                      pool_out[i]);
end endgenerate


/* Second Scalers */
generate for (i=0; i < N; i=i+1) begin: scaler2array  
    fixedpointscaler #(
        .BA(BSCALERA),
        .BB(BSCALERB),
        .BC(BSCALERC),
        .BD(BSCALERD),
        .BP(BSCALERP)
    ) scaler2 (
        .clk(clk),
        .clr(scaler2_clr),
        .a(pool_out[i]),
        .b(scaler2_b),
        .c({BSCALERC{1'b0}}),
        .d({BSCALERD{1'b0}}),
        .p(scaler2_out[i])
    );
end endgenerate


/* Quantizers */
generate for(i=0;i<N;i=i+1) begin:quantarray
    quantser #(
        .BWIN       (BSCALERP)
    ) quantser_unit (
        .clk        (clk),
        .clr        (quant_clr),
        .msbidx     (quant_msbidx),
        .load       (quant_load),
        .step       (quant_step),
        .din        (scaler2_out[i]),
        .dout       (quant_out[i])
    );
end endgenerate


/* Data Banks */
generate for(i=0;i<NDBANK;i=i+1) begin:bankarray
    bank64k #(BDBANKW, BDBANKAWS) db (clk,
        rd_en & (rd_addr[BDBANKAWS +: BDBANKABS] == i), rd_addr[0 +: BDBANKAWS], rd_muxcode,
        wr_en & (wr_addr[BDBANKAWS +: BDBANKABS] == i), wr_addr[0 +: BDBANKAWS], wr_muxcode,
        rdi_words[i*BDBANKW +: BDBANKW], wri_word,
        rdd_words[i*BDBANKW +: BDBANKW], wrd_word,
        rdc_words[i*BDBANKW +: BDBANKW], wrc_word
    );
    for(j=0;j<BDBANKW;j=j+1) begin:transposej
        assign rdd_words_t[j*NDBANK+i] = rdd_words[i*BDBANKW+j];
        assign rdi_words_t[j*NDBANK+i] = rdi_words[i*BDBANKW+j];
        assign rdc_words_t[j*NDBANK+i] = rdc_words[i*BDBANKW+j];
    end
end endgenerate
generate for(i=0;i<BDBANKW;i=i+1) begin:reduxrdwords
    always @(posedge clk) begin
        if(clk) begin
            rdd_word[i] <= |rdd_words_t[i*NDBANK +: NDBANK];
            rdi_word[i] <= |rdi_words_t[i*NDBANK +: NDBANK];
            rdc_word[i] <= |rdc_words_t[i*NDBANK +: NDBANK];
        end
    end
end endgenerate


assign core_data = rdd_word;
assign wrd_word  = quant_out;
assign mvu_word_out = quant_out;

// Select either the pooler output or the scaler1 output to drive the high-performance interconnect output
generate for (i=0; i < N; i = i+1) begin: word_outhp
    assign mvu_word_outhp[i*BDHPBANKW +: BDHPBANKW] = usepooler4hpout ? pool_out[i] : scaler1_out[i];
end endgenerate


// High-precision data bank
 ram_simple2port #(
    .BDADDR(BDHPBANKA),
    .BDWORD(N*BDHPBANKW)
 ) dbhp (
    .clk(clk),
    .rd_en(1'b1),
    .rd_addr(rddhp_addr), 
    .rd_word(rddhp_word),
    .wr_en(wrihp_en),
    .wr_addr(wrihp_addr),
    .wr_word(wrihp_word)
 );



/* Module end */
endmodule
