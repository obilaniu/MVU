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
localparam BSCALERP = 27;               // Bitwidth of the scaler output

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
localparam HPADDERLATENCY= 1;  // Latency of fixed point adder module
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

// APB simulation and synthesis parameter
localparam APB_ADDR_WIDTH = 15;  // 4KB CSR x 8 MVUs
localparam APB_DATA_WIDTH = 32;  // 4KB CSR x 8 MVUs
localparam APB_STRB_WIDTH = cf_math_pkg::ceil_div(APB_DATA_WIDTH, 8);

localparam time APB_ApplTime  = 2ns; // taken from https://github.com/pulp-platform/apb/blob/master/test/tb_apb_regs.sv#L31
localparam time APB_TestTime  = 8ns; //

typedef enum logic [11:0] {

    // MVU CSRs            
    CSR_MVUWBASEPTR        = 12'hF20, // Base address for weight memory
    CSR_MVUIBASEPTR        = 12'hF21, // Base address for input memory
    CSR_MVUSBASEPTR        = 12'hF22, // Base address for scaler memory (6 bits)
    CSR_MVUBBASEPTR        = 12'hF23, // Base address for bias memory (6 bits)
    CSR_MVUOBASEPTR        = 12'hF24, // Output base address
    CSR_MVUWJUMP_0         = 12'hF25, // Weight address jumps in loops 0
    CSR_MVUWJUMP_1         = 12'hF26, // Weight address jumps in loops 1
    CSR_MVUWJUMP_2         = 12'hF27, // Weight address jumps in loops 2
    CSR_MVUWJUMP_3         = 12'hF28, // Weight address jumps in loops 3
    CSR_MVUWJUMP_4         = 12'hF29, // Weight address jumps in loops 4
    CSR_MVUIJUMP_0         = 12'hF2A, // Input data address jumps in loops 0
    CSR_MVUIJUMP_1         = 12'hF2B, // Input data address jumps in loops 1
    CSR_MVUIJUMP_2         = 12'hF2C, // Input data address jumps in loops 2
    CSR_MVUIJUMP_3         = 12'hF2D, // Input data address jumps in loops 3
    CSR_MVUIJUMP_4         = 12'hF2E, // Input data address jumps in loops 4
    CSR_MVUSJUMP_0         = 12'hF2F, // Scaler memory address jumps (6 bits)
    CSR_MVUSJUMP_1         = 12'hF30, // Scaler memory address jumps (6 bits)
    CSR_MVUBJUMP_0         = 12'hF31, // Bias memory address jumps (6 bits)
    CSR_MVUBJUMP_1         = 12'hF32, // Bias memory address jumps (6 bits)
    CSR_MVUOJUMP_0         = 12'hF33, // Output data address jumps in loops 0
    CSR_MVUOJUMP_1         = 12'hF34, // Output data address jumps in loops 1
    CSR_MVUOJUMP_2         = 12'hF35, // Output data address jumps in loops 2
    CSR_MVUOJUMP_3         = 12'hF36, // Output data address jumps in loops 3
    CSR_MVUOJUMP_4         = 12'hF37, // Output data address jumps in loops 4
    CSR_MVUWLENGTH_1       = 12'hF38, // Weight length in loops 0
    CSR_MVUWLENGTH_2       = 12'hF39, // Weight length in loops 1
    CSR_MVUWLENGTH_3       = 12'hF3A, // Weight length in loops 2
    CSR_MVUWLENGTH_4       = 12'hF3B, // Weight length in loops 3
    CSR_MVUILENGTH_1       = 12'hF3C, // Input data length in loops 0
    CSR_MVUILENGTH_2       = 12'hF3D, // Input data length in loops 1
    CSR_MVUILENGTH_3       = 12'hF3E, // Input data length in loops 2
    CSR_MVUILENGTH_4       = 12'hF3F, // Input data length in loops 3
    CSR_MVUSLENGTH_1       = 12'hF40, // Scaler tensor length 15 bits
    CSR_MVUBLENGTH_1       = 12'hF41, // Bias tensor length 15 bits
    CSR_MVUOLENGTH_1       = 12'hF42, // Output data length in loops 0
    CSR_MVUOLENGTH_2       = 12'hF43, // Output data length in loops 1
    CSR_MVUOLENGTH_3       = 12'hF44, // Output data length in loops 2
    CSR_MVUOLENGTH_4       = 12'hF45, // Output data length in loops 3
    CSR_MVUPRECISION       = 12'hF46, // Precision in bits for all tensors
    CSR_MVUSTATUS          = 12'hF47, // Status of MVU
    CSR_MVUCOMMAND         = 12'hF48, // Kick to send command.
    CSR_MVUQUANT           = 12'hF49, // MSB index position
    CSR_MVUSCALER          = 12'hF4A, // fixed point operand for multiplicative scaling
    CSR_MVUCONFIG1         = 12'hF4B, // Shift/accumulator load on jump select (only 0-4 valid) Pool/Activation clear on jump select (only 0-4 valid)
    CSR_MVUOMVUSEL         = 12'hF4C, // MVU selector bits for output
    CSR_MVUIHPBASEADDR     = 12'hF4D, // high-precision data memory base address for input
    CSR_MVUOHPBASEADDR     = 12'hF4E, // high-precision data memory base address for output
    CSR_MVUOHPMVUSEL       = 12'hF4F, // MVU selector bits for high-precision output
    CSR_MVUHPJUMP_0        = 12'hF50, // Input jumps
    CSR_MVUHPJUMP_1        = 12'hF51, // Input jumps
    CSR_MVUHPJUMP_2        = 12'hF52, // Input jumps
    CSR_MVUHPJUMP_3        = 12'hF53, // Input jumps
    CSR_MVUHPJUMP_4        = 12'hF54, // Input jumps

    CSR_MVUHPLENGTH_1      = 12'hF55, // Scaler length
    CSR_MVUHPLENGTH_2      = 12'hF56, // Scaler length
    CSR_MVUHPLENGTH_3      = 12'hF57, // Scaler length
    CSR_MVUHPLENGTH_4      = 12'hF58, // Scaler length

    CSR_MVUUSESCALER_MEM   = 12'hF59, // Use scalar mem if 1; otherwise use the scaler_b input for scaling
    CSR_MVUUSEBIAS_MEM     = 12'hF5A, // Use the bias memory if 1; if not, not bias is added in the scaler
    CSR_MVUUSEPOOLER4HPOUT = 12'hF5B, // For the high-precision interconnect, use the output of pooler if 1, or use output of scaler1 if 0
    CSR_MVUUSEHPADDER      = 12'hF5C // Use the hpadder if 1
} mvu_csr_t;


typedef logic [APB_ADDR_WIDTH-1:0] apb_addr_t;
typedef logic [APB_DATA_WIDTH-1:0] apb_data_t;
typedef logic [APB_DATA_WIDTH-1:0] apb_strb_t;

endpackage