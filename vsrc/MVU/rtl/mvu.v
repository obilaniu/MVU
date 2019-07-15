/**
 * Matrix-Vector Unit
 * 
 * Signals needed for each MVU:
 *     | Signal   | Description                 | Direction | Bits 
 *     +----------+-----------------------------+-----------+------
 *     | clk      | Clock                       |   Input   | 1    
 *     | mul_mode | Multiply Mode               |   Input   | 2    
 *     | acc_clr  | Accumulator Clear           |   Input   | 1    
 *     | acc_sh   | Accumulator Shift           |   Input   | 1    
 *     | max_en   | Maxpooling Enable           |   Input   | 1    
 *     | max_clr  | Maxpooling Clear            |   Input   | 1    
 *     | max_pool | Maxpooling Pool/Copy        |   Input   | 1    
 *     |          |                             |   Input   |      
 *     | rdw_addr | Read  Weights      Address  |   Input   | 9    
 *     |          |                             |   Input   |      
 *     | rdd_en   | Read  Data         Enable   |   Input   | 1    
 *     | rdd_grnt | Read  Data         Grant    |   Output  | 1    
 *     | rdd_addr | Read  Data         Address  |   Input   | 5+9  
 *     | wrd_en   | Write Data         Enable   |   Input   | 1    
 *     | wrd_grnt | Write Data         Grant    |   Input   | 1    
 *     | wrd_addr | Write Data         Address  |   Input   | 5+9  
 *     |          |                             |   Input   |      
 *     | rdi_en   | Read  Interconnect Enable   |   Input   | 1    
 *     | rdi_grnt | Read  Interconnect Grant    |   Input   | 1    
 *     | rdi_addr | Read  Interconnect Address  |   Input   | 5+9  
 *     | rdi_word | Read  Interconnect Word     |   Input   | 128  
 *     | wri_en   | Write Interconnect Enable   |   Input   | 1    
 *     | wri_grnt | Write Interconnect Grant    |   Input   | 1    
 *     | wri_addr | Write Interconnect Address  |   Input   | 5+9  
 *     | wri_word | Write Interconnect Word     |   Input   | 128  
 *     |          |                             |   Input   |      
 *     | rdc_en   | Read  Controller   Enable   |   Input   | 1    
 *     | rdc_grnt | Read  Controller   Grant    |   Input   | 1    
 *     | rdc_addr | Read  Controller   Address  |   Input   | 5+9  
 *     | rdc_word | Read  Controller   Word     |   Input   | 128  
 *     | wrc_en   | Write Controller   Enable   |   Input   | 1    
 *     | wrc_grnt | Write Controller   Grant    |   Input   | 1    
 *     | wrc_addr | Write Controller   Address  |   Input   | 5+9  
 *     | wrc_word | Write Controller   Word     |   Input   | 128  
 *     +----------+-----------------------------+-----------+------
 *     | TOTAL                                                625
 */

`timescale 1 ps / 1 ps
/**** Module mvu ****/
module mvu(clk,
           mul_mode,
           acc_clr,
           acc_sh,
           max_en,
           max_clr,
           max_pool,
           rdw_addr,
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
           wrc_word);


/* Parameters */
parameter  N       = 64;   /* N x N matrix-vector product size. Power-of-2. */
parameter  NDBANK  = 32;   /* Number of 2N-bit, 512-element Data BANK. */

localparam CLOG2N      = $clog2(N);     /* clog2(N) */

localparam BWBANKA     = 9;             /* Bitwidth of Weights BANK Address */
localparam BWBANKW     = N*N;           /* Bitwidth of Weights BANK Word */
localparam BDBANKABS   = $clog2(NDBANK);/* Bitwidth of Data    BANK Address Bank Select */
localparam BDBANKAWS   = 9;             /* Bitwidth of Data    BANK Address Word Select */
localparam BDBANKA     = BDBANKABS+     /* Bitwidth of Data    BANK Address */
                         BDBANKAWS;
localparam BDBANKW     = 2*N;           /* Bitwidth of Data    BANK Word */
localparam BSUM        = CLOG2N+2;      /* Bitwidth of Sums */
localparam BACC        = 32;            /* Bitwidth of Accumulators */


/* Interface */
input  wire                clk;
input  wire[        1 : 0] mul_mode;
input  wire                acc_clr;
input  wire                acc_sh;
input  wire                max_en;
input  wire                max_clr;
input  wire                max_pool;

input  wire[BWBANKA-1 : 0] rdw_addr;

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

/* Generation Variables */
genvar i, j;


/* Local Wires */
wire                rd_en;
wire[1 : 0]         rd_muxcode;
wire[BDBANKA-1 : 0] rd_addr;
wire                wr_en;
wire[1 : 0]         wr_muxcode;
wire[BDBANKA-1 : 0] wr_addr;

wire[BWBANKW-1 : 0] core_weights;
wire[BDBANKW-1 : 0] core_data;
wire[BSUM*N-1  : 0] core_out;
wire[BACC*N-1  : 0] acc_out;
wire[BACC*N-1  : 0] pool_out;
wire[BDBANKW-1 : 0] quant_out;
reg [BDBANKW-1 : 0] rdd_word;
wire[BDBANKW-1 : 0] wrd_word;

wire[NDBANK*BDBANKW-1 : 0] rdd_words;
wire[NDBANK*BDBANKW-1 : 0] rdi_words;
wire[NDBANK*BDBANKW-1 : 0] rdc_words;
wire[BDBANKW*NDBANK-1 : 0] rdd_words_t;
wire[BDBANKW*NDBANK-1 : 0] rdi_words_t;
wire[BDBANKW*NDBANK-1 : 0] rdc_words_t;



/* Wiring */
cdru    #(BDBANKABS)    read_cdu     (rdi_en, rdi_addr, rdi_grnt,
                                      rdd_en, rdd_addr, rdd_grnt,
                                      rdc_en, rdc_addr, rdc_grnt,
                                      rd_en , rd_addr , rd_muxcode);
cdwu    #(BDBANKABS)    write_cdu    (wri_en, wri_addr, wri_grnt,
                                      wrd_en, wrd_addr, wrd_grnt,
                                      wrc_en, wrc_addr, wrc_grnt,
                                      wr_en , wr_addr , wr_muxcode);
bram2m                  weights_bank (clk, {BWBANKW{1'b0}}, rdw_addr, {BWBANKA{1'b0}}, 1'b0, core_weights);
mvp     #(N, 'b0010101) matrix_core  (clk, mul_mode, core_weights, core_data, core_out);


generate for(i=0;i<N;i=i+1) begin:shaccarray
    shacc   #(BACC, BSUM) accumulator(clk, acc_clr, acc_sh,
                                      core_out[i*BSUM +: BSUM],
                                      acc_out [i*BACC +: BACC]);
end endgenerate


generate for(i=0;i<N;i=i+1) begin:poolarray
    maxpool #(BACC)       pooler     (clk, max_clr, max_en, max_pool,
                                      acc_out [i*BACC +: BACC],
                                      pool_out[i*BACC +: BACC]);
end endgenerate


generate for(i=0;i<N;i=i+1) begin:quantarray
    assign quant_out[i*2 +: 2] = {pool_out[i*BACC + 31],
                                  pool_out[i*BACC +  0]};
end endgenerate

// NDBANK    = 32                       Number of 2N-bit, 512-element Data BANK. 
// BDBANKW   = 2*N                      Bitwidth of Data    BANK Word 
// BDBANKAWS = 9.                       Bitwidth of Data    BANK Address Word Select 
// BDBANKABS = $clog2(NDBANK)->5        Bitwidth of Data    BANK Address Bank Select 
// BDBANKA   = BDBANKABS+BDBANKAWS->14  Bitwidth of Data    BANK Address 

// wire                rd_en;
// wire[BDBANKA-1 : 0] rd_addr;
// wire[1 : 0]         rd_muxcode;
// wire                wr_en;
// wire[BDBANKA-1 : 0] wr_addr;
// wire[1 : 0]         wr_muxcode;

generate for(i=0;i<NDBANK;i=i+1) begin:bankarray
    bank64k #(BDBANKW, BDBANKAWS) db 
                                    (
                                        .clk       (clk                                           ),// input  clk       ;
                                        .rd_en     (rd_en & (rd_addr[BDBANKAWS +: BDBANKABS] == i)),// input  rd_en     ;
                                        .rd_addr   (rd_addr[0 +: BDBANKAWS]                       ),// input  rd_addr   ;
                                        .rd_muxcode(rd_muxcode                                    ),// input  rd_muxcode;
                                        .wr_en     (wr_en & (wr_addr[BDBANKAWS +: BDBANKABS] == i)),// input  wr_en     ;
                                        .wr_addr   (wr_addr[0 +: BDBANKAWS]                       ),// input  wr_addr   ;
                                        .wr_muxcode(wr_muxcode                                    ),// input  wr_muxcode;
                                        .rdi_word  (rdi_words[i*BDBANKW +: BDBANKW]               ),// output rdi_word  ;
                                        .wri_word  (wri_word                                      ),// input  wri_word  ;
                                        .rdd_word  (rdd_words[i*BDBANKW +: BDBANKW]               ),// output rdd_word  ;
                                        .wrd_word  (wrd_word                                      ),// input  wrd_word  ;
                                        .rdc_word  (rdc_words[i*BDBANKW +: BDBANKW]               ),// output rdc_word  ;
                                        .wrc_word  (wrc_word                                      ) // input  wrc_word  ;
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



/* Module end */
endmodule
