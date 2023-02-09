//================================================================
// Simulation macros
//================================================================
`define hdl_path_mvu_top            testbench_top.mvutop_wrapper
`define hdl_path_top_mvu0_irq       `hdl_path_mvu_top.mvu_ext_if.irq[0]
`define hdl_path_top_mvu1_irq       `hdl_path_mvu_top.mvu_ext_if.irq[1]
`define hdl_path_top_mvu2_irq       `hdl_path_mvu_top.mvu_ext_if.irq[2]
`define hdl_path_top_mvu3_irq       `hdl_path_mvu_top.mvu_ext_if.irq[3]
`define hdl_path_top_mvu4_irq       `hdl_path_mvu_top.mvu_ext_if.irq[4]
`define hdl_path_top_mvu5_irq       `hdl_path_mvu_top.mvu_ext_if.irq[5]
`define hdl_path_top_mvu6_irq       `hdl_path_mvu_top.mvu_ext_if.irq[6]
`define hdl_path_top_mvu7_irq       `hdl_path_mvu_top.mvu_ext_if.irq[7]

//================================================================
// hard coded HDL paths for verification 
//================================================================


// ===============================================================
// MVU Data memory access macros
// ===============================================================
`define hdl_path_mvu_data_mem(mvu_num) `hdl_path_mvu_top.mvu.mvuarray[mvu_num]
`define hdl_path_mvu_data_mem_bank(mvu_num, bank) `hdl_path_mvu_data_mem(mvu_num).mvuunit.bankarray[bank]
`define hdl_path_mvu_data_mem_word(mvu_num, bank, addr) `hdl_path_mvu_data_mem_bank(mvu_num, bank).db.data_ram.mem[addr]