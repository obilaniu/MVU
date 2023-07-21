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
localparam MVU_INTERCONN_DLY = 1;

localparam PIPELINE_DLY  = VVPSTAGES + SCALERLATENCY + HPADDERLATENCY + MAXPOOLSTAGES + MEMRDLATENCY;


localparam BDBANKABS = $clog2(NDBANK);  // Bitwidth of Data    BANK Address Bank Select 
localparam BDBANKAWS = 10;              // Bitwidth of Data    BANK Address Word Select

// Scalar and Bias memory bank parameters
localparam BSBANKA     = 6;             // Bitwidth of Scaler BANK address
localparam BSBANKW     = BSCALERB*N;    // Bitwidth of Scaler BANK word
localparam BBBANKA     = 6;             // Bitwidth of Bias BANK address
localparam BBBANKW     = BBIAS*N;       // Bitwidth of Bias BANK word

// APB simulation and synthesis parameter
localparam APB_ADDR_WIDTH = 15;  // $clog2(4KB CSR x 8 MVUs)
localparam APB_DATA_WIDTH = 32;  // Working with 32bit registers
localparam APB_STRB_WIDTH = cf_math_pkg::ceil_div(APB_DATA_WIDTH, 8);

localparam time APB_ApplTime  = 2ns; // taken from https://github.com/pulp-platform/apb/blob/master/test/tb_apb_regs.sv#L31
localparam time APB_TestTime  = 8ns; //


typedef enum logic [11:0] {
	CSR_MVUWBASEPTR=12'hf20,//Base address for weight memory
	CSR_MVUIBASEPTR=12'hf21,//Base address for input memory
	CSR_MVUSBASEPTR=12'hf22,//Base address for scaler memory (6 bits)
	CSR_MVUBBASEPTR=12'hf23,//Base address for bias memory (6 bits)
	CSR_MVUOBASEPTR=12'hf24,//Output base address
	CSR_MVUWJUMP_0=12'hf25,//Weight address jumps in loops 0
	CSR_MVUWJUMP_1=12'hf26,//Weight address jumps in loops 1
	CSR_MVUWJUMP_2=12'hf27,//Weight address jumps in loops 2
	CSR_MVUWJUMP_3=12'hf28,//Weight address jumps in loops 3
	CSR_MVUWJUMP_4=12'hf29,//Weight address jumps in loops 4
	CSR_MVUIJUMP_0=12'hf2a,//Input data address jumps in loops 0
	CSR_MVUIJUMP_1=12'hf2b,//Input data address jumps in loops 1
	CSR_MVUIJUMP_2=12'hf2c,//Input data address jumps in loops 2
	CSR_MVUIJUMP_3=12'hf2d,//Input data address jumps in loops 3
	CSR_MVUIJUMP_4=12'hf2e,//Input data address jumps in loops 4
	CSR_MVUSJUMP_0=12'hf2f,//Scaler memory address jumps (6 bits)
	CSR_MVUSJUMP_1=12'hf30,//Scaler memory address jumps (6 bits)
	CSR_MVUSJUMP_2=12'hf31,//Scaler memory address jumps (6 bits)
	CSR_MVUSJUMP_3=12'hf32,//Scaler memory address jumps (6 bits)
	CSR_MVUSJUMP_4=12'hf33,//Scaler memory address jumps (6 bits)
	CSR_MVUBJUMP_0=12'hf34,//Bias memory address jumps (6 bits)
	CSR_MVUBJUMP_1=12'hf35,//Bias memory address jumps (6 bits)
	CSR_MVUBJUMP_2=12'hf36,//Bias memory address jumps (6 bits)
	CSR_MVUBJUMP_3=12'hf37,//Bias memory address jumps (6 bits)
	CSR_MVUBJUMP_4=12'hf38,//Bias memory address jumps (6 bits)
	CSR_MVUOJUMP_0=12'hf39,//Output data address jumps in loops 0
	CSR_MVUOJUMP_1=12'hf3a,//Output data address jumps in loops 1
	CSR_MVUOJUMP_2=12'hf3b,//Output data address jumps in loops 2
	CSR_MVUOJUMP_3=12'hf3c,//Output data address jumps in loops 3
	CSR_MVUOJUMP_4=12'hf3d,//Output data address jumps in loops 4
	CSR_MVUWLENGTH_0=12'hf3e,//Weight length in loops 0
	CSR_MVUWLENGTH_1=12'hf3f,//Weight length in loops 1
	CSR_MVUWLENGTH_2=12'hf40,//Weight length in loops 2
	CSR_MVUWLENGTH_3=12'hf41,//Weight length in loops 3
	CSR_MVUWLENGTH_4=12'hf42,//Weight length in loops 3
	CSR_MVUILENGTH_1=12'hf43,//Input data length in loops 0
	CSR_MVUILENGTH_2=12'hf44,//Input data length in loops 1
	CSR_MVUILENGTH_3=12'hf45,//Input data length in loops 2
	CSR_MVUILENGTH_4=12'hf46,//Input data length in loops 3
	CSR_MVUSLENGTH_1=12'hf47,//Scaler tensor length 15 bits
	CSR_MVUSLENGTH_2=12'hf48,//Scaler tensor length 15 bits
	CSR_MVUSLENGTH_3=12'hf49,//Scaler tensor length 15 bits
	CSR_MVUSLENGTH_4=12'hf4a,//Scaler tensor length 15 bits
	CSR_MVUBLENGTH_1=12'hf4b,//Bias tensor length 15 bits
	CSR_MVUBLENGTH_2=12'hf4c,//Bias tensor length 15 bits
	CSR_MVUBLENGTH_3=12'hf4d,//Bias tensor length 15 bits
	CSR_MVUBLENGTH_4=12'hf4e,//Bias tensor length 15 bits
	CSR_MVUOLENGTH_1=12'hf4f,//Output data length in loops 0
	CSR_MVUOLENGTH_2=12'hf50,//Output data length in loops 1
	CSR_MVUOLENGTH_3=12'hf51,//Output data length in loops 2
	CSR_MVUOLENGTH_4=12'hf52,//Output data length in loops 3
	CSR_MVUPRECISION=12'hf53,//Precision in bits for all tensors
	CSR_MVUSTATUS=12'hf54,//Status of MVU
	CSR_MVUCOMMAND=12'hf55,//Kick to send command.
	CSR_MVUQUANT=12'hf56,//MSB index position
	CSR_MVUSCALER =12'hf57,//fixed point operand for multiplicative scaling
	CSR_MVUCONFIG1=12'hf58,//Shift/accumulator load on jump select (only 0-4 valid) Pool/Activation clear on jump select (only 0-4 valid)
	CSR_MVUOMVUSEL=12'hf59,//MVU selector bits for output
	CSR_MVUIHPBASEADDR=12'hf5a,//high-precision data memory base address for input
	CSR_MVUOHPBASEADDR=12'hf5b,//high-precision data memory base address for output
	CSR_MVUOHPMVUSEL=12'hf5c,//MVU selector bits for high-precision output
	CSR_MVUHPJUMP_0=12'hf5d,//Input jumps
	CSR_MVUHPJUMP_1=12'hf5e,//Input jumps
	CSR_MVUHPJUMP_2=12'hf5f,//Input jumps
	CSR_MVUHPJUMP_3=12'hf60,//Input jumps
	CSR_MVUHPJUMP_4=12'hf61,//Input jumps
	CSR_MVUHPLENGTH_1=12'hf62,//Scaler length
	CSR_MVUHPLENGTH_2=12'hf63,//Scaler length
	CSR_MVUHPLENGTH_3=12'hf64,//Scaler length
	CSR_MVUHPLENGTH_4=12'hf65,//Scaler length
	CSR_MVUUSESCALER_MEM=12'hf66,//Use scalar mem if 1; otherwise use the scaler_b input for scaling
	CSR_MVUUSEBIAS_MEM=12'hf67,//Use the bias memory if 1; if not, not bias is added in the scaler
	CSR_MVUUSEPOOLER4HPOUT=12'hf68,//For the high-precision interconnect, use the output of pooler if 1, or use output of scaler1 if 0
	CSR_MVUUSEHPADDER=12'hf69//Use the hpadder if 1
} mvu_csr_t;

typedef logic [APB_ADDR_WIDTH-1:0] apb_addr_t;
typedef logic [APB_DATA_WIDTH-1:0] apb_data_t;
typedef logic [APB_STRB_WIDTH-1:0] apb_strb_t;

typedef logic [BWBANKW-1 : 0 ] w_data_t;
typedef w_data_t w_data_q_t[$];

typedef logic [BDBANKW-1 : 0 ] a_data_t;
typedef a_data_t a_data_q_t[$];

endpackage