package mvu_pkg;

// Parameters 
localparam NMVU    =  8;   // Number of MVUs. Ideally a Power-of-2. 
localparam N       = 64;   // N x N matrix-vector product size. Power-of-2. 
localparam NDBANK  = 32;   // Number of N-bit, 1024-element Data BANK.
localparam BBIAS   = 32;   // Bitwidth of bias values 

localparam BMVUA   = $clog2(NMVU);  // Bitwidth of MVU          Address 
localparam BWBANKA = 9;             // Bitwidth of Weights BANK Address 
localparam BWBANKW = 4096;          // Bitwidth of Weights BANK Word
localparam BDBANKA = 15;            // Bitwidth of Data    BANK Address 
localparam BDBANKW = N;             // Bitwidth of Data    BANK Word 

localparam BACC     = 27;               // Bitwidth of Accumulators 
localparam BSCALERP = 48;               // Bitwidth of the scaler output

localparam BDHPBANKW    = 32;           // Bitwidth of high-precision data bank word
localparam BDHPBUSW     = BDHPBANKW*N;  // Bitwidth of high-precision data word bus
localparam BDHPBANKA    = 12;           // Bitwidth of high-precision data bank address

// Quantizer parameters
localparam BQMSBIDX     = $clog2(BSCALERP); // Bitwidth of the quantizer MSB location specifier
localparam BQBOUT       = $clog2(BSCALERP); // Bitwidth of the quantizer 
localparam QBWOUTBD     = $clog2(BSCALERP); // Bitwidth of the quantizer bit-depth out specifier

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

// Scalar and Bias memory bank parameters
localparam BSBANKA     = 6;             // Bitwidth of Scaler BANK address
localparam BSBANKW     = BSCALERB*N;    // Bitwidth of Scaler BANK word
localparam BBBANKA     = 6;             // Bitwidth of Scaler BANK address
localparam BBBANKW     = BBIAS*N;       // Bitwidth of Scaler BANK word

endpackage