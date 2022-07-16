add_wave_group mvu
    add_wave -into mvu {{/testbench_top/mvutop_wrapper/mvu_ext_if/clk}}
    add_wave_group -into mvu mvu0
        add_wave_group -into mvu0 input_ram
            add_wave -into input_ram {{/testbench_top/mvutop_wrapper/mvu/\mvuarray[0].mvunit /\bankarray[0].db /b/inst/\native_mem_module.blk_mem_gen_v8_4_3_inst /memory}}
        add_wave_group -into mvu0 output_ram
            add_wave -into output_ram {{/testbench_top/mvutop_wrapper/mvu/\mvuarray[0].mvunit /\bankarray[1].db /b/inst/\native_mem_module.blk_mem_gen_v8_4_3_inst /memory}}
        add_wave_group -into mvu0 pipeline
            add_wave -into pipeline {{/testbench_top/mvutop_wrapper/mvu/\mvuarray[0].mvunit /core_data}}
            add_wave -into pipeline {{/testbench_top/mvutop_wrapper/mvu/\mvuarray[0].mvunit /core_weights}}
            add_wave -into pipeline {{/testbench_top/mvutop_wrapper/mvu/\mvuarray[0].mvunit /core_out}}
            add_wave -into pipeline {{/testbench_top/mvutop_wrapper/mvu/\mvuarray[0].mvunit /shacc_out}}
            add_wave -into pipeline {{/testbench_top/mvutop_wrapper/mvu/\mvuarray[0].mvunit /scaler_out}}
            add_wave -into pipeline {{/testbench_top/mvutop_wrapper/mvu/\mvuarray[0].mvunit /pool_out}}
            add_wave -into pipeline {{/testbench_top/mvutop_wrapper/mvu/\mvuarray[0].mvunit /quant_out}}
        add_wave_group -into mvu0 configs
            add_wave -into configs {{/testbench_top/mvutop_wrapper/mvu/iprecision_q}}
            add_wave -into configs {{/testbench_top/mvutop_wrapper/mvu/wprecision_q}}
            add_wave -into configs {{/testbench_top/mvutop_wrapper/mvu/oprecision_q}}
            add_wave -into configs {{/testbench_top/mvutop_wrapper/mvu/quant_msbidx_q}}
            add_wave -into configs {{/testbench_top/mvutop_wrapper/mvu/countdown_q}}
            add_wave -into configs {{/testbench_top/mvutop_wrapper/mvu/\mvuarray[0].mvunit /mul_mode}}
            add_wave -into configs {{/testbench_top/mvutop_wrapper/mvu/\mvuarray[0].mvunit /scaler_b}}
add_wave_group mvu_ext
    add_wave -into mvu_ext {{/testbench_top/mvutop_wrapper/mvu_ext_if/start}}
    add_wave -into mvu_ext {{/testbench_top/mvutop_wrapper/mvu_ext_if/irq}}
    add_wave -into mvu_ext {{/testbench_top/mvutop_wrapper/mvu_ext_if/done}}

set_property display_limit 40000000 [current_wave_config]