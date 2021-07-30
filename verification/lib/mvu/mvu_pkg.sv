package mvu_pkg;

// Parameters 
localparam NMVU    =  8;   // Number of MVUs. Ideally a Power-of-2. 
localparam N       = 64;   // N x N matrix-vector product size. Power-of-2. 
localparam NDBANK  = 32;   // Number of N-bit, 1024-element Data BANK. 

localparam BMVUA   = $clog2(NMVU);  // Bitwidth of MVU          Address 
localparam BWBANKA = 9;             // Bitwidth of Weights BANK Address 
localparam BWBANKW = 4096;          // Bitwidth of Weights BANK Word
localparam BDBANKA = 15;            // Bitwidth of Data    BANK Address 
localparam BDBANKW = N;             // Bitwidth of Data    BANK Word 

localparam BACC    = 27;            // Bitwidth of Accumulators 
localparam BSCALERP = 48;               // Bitwidth of the scaler output

// Quantizer parameters
localparam BQMSBIDX = $clog2(BSCALERP); // Bitwidth of the quantizer MSB location specifier
localparam BQBOUT   = $clog2(BSCALERP); // Bitwidth of the quantizer 
localparam QBWOUTBD = $clog2(BSCALERP); // Bitwidth of the quantizer bit-depth out specifier

// Other Parameters
localparam BCNTDWN       = 29; // Bitwidth of the countdown ports
localparam BPREC         = 6;  // Bitwidth of the precision ports
localparam BBWADDR       = 9;  // Bitwidth of the weight base address ports
localparam BBDADDR       = 15; // Bitwidth of the data base address ports
localparam BJUMP         = 15; // Bitwidth of the stride ports
localparam BLENGTH       = 15; // Bitwidth of the length ports
localparam BSCALERB      = 16; // Bitwidth of the scaler parameter
localparam VVPSTAGES     = 3;  // Number of stages in the VVP pipeline
localparam SCALERLATENCY = 3;  // Number of stages in the scaler pipeline
localparam MAXPOOLSTAGES = 1;  // Number of max pool pipeline stages
localparam MEMRDLATENCY  = 2;  // Memory read latency
localparam NJUMPS        = 5;  // Number of address jump parameters available

localparam BDBANKABS = $clog2(NDBANK);  // Bitwidth of Data    BANK Address Bank Select 
localparam BDBANKAWS = 10;              // Bitwidth of Data    BANK Address Word Select 

typedef logic [BWBANKW-1 : 0 ] w_data_t;
typedef w_data_t w_data_q_t[$];

typedef logic [BDBANKW-1 : 0 ] a_data_t;
typedef a_data_t a_data_q_t[$];
endpackage
