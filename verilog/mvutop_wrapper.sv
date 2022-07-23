module mvutop_wrapper import mvu_pkg::*;import apb_pkg::*;(
        MVU_EXT_INTERFACE mvu_ext_if,
        APB apb
);
MVU_CFG_INTERFACE mvu_cfg_if();
mvutop mvu(
    mvu_ext_if.mvu_ext,
    mvu_cfg_if.mvu_cfg
);

logic [mvu_pkg::APB_ADDR_WIDTH - 1:0] register_adr;
logic [mvu_pkg::BMVUA-1 : 0] mvu_id;
logic apb_write;

assign register_adr  = apb.paddr;
assign mvu_id = register_adr[APB_ADDR_WIDTH-1:12];
assign apb_write = apb.psel && apb.penable && apb.pwrite;

// APB to register conversion
always_comb begin
    // APB register write logic
    if (apb_write) begin
        unique case (mvu_pkg::mvu_csr_t'(register_adr[11:0]))
            mvu_pkg::CSR_MVUWBASEPTR : mvu_cfg_if.wbaseaddr[mvu_id] = apb.pwdata[BBWADDR-1 : 0];
            mvu_pkg::CSR_MVUIBASEPTR : mvu_cfg_if.ibaseaddr[mvu_id] = apb.pwdata[BBDADDR-1 : 0];
            mvu_pkg::CSR_MVUSBASEPTR : mvu_cfg_if.sbaseaddr[mvu_id] = apb.pwdata[BSBANKA-1 : 0];
            mvu_pkg::CSR_MVUBBASEPTR : mvu_cfg_if.bbaseaddr[mvu_id] = apb.pwdata[BBBANKA-1 : 0];
            mvu_pkg::CSR_MVUOBASEPTR : mvu_cfg_if.obaseaddr[mvu_id] = apb.pwdata[BBDADDR-1 : 0];
            mvu_pkg::CSR_MVUWJUMP_0  : mvu_cfg_if.wjump[mvu_id][0]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUWJUMP_1  : mvu_cfg_if.wjump[mvu_id][1]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUWJUMP_2  : mvu_cfg_if.wjump[mvu_id][2]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUWJUMP_3  : mvu_cfg_if.wjump[mvu_id][3]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUWJUMP_4  : mvu_cfg_if.wjump[mvu_id][4]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUIJUMP_0  : mvu_cfg_if.ijump[mvu_id][0]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUIJUMP_1  : mvu_cfg_if.ijump[mvu_id][1]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUIJUMP_2  : mvu_cfg_if.ijump[mvu_id][2]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUIJUMP_3  : mvu_cfg_if.ijump[mvu_id][3]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUIJUMP_4  : mvu_cfg_if.ijump[mvu_id][4]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUSJUMP_0  : mvu_cfg_if.sjump[mvu_id][0]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUSJUMP_1  : mvu_cfg_if.sjump[mvu_id][1]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUSJUMP_2  : mvu_cfg_if.sjump[mvu_id][2]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUSJUMP_3  : mvu_cfg_if.sjump[mvu_id][3]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUSJUMP_4  : mvu_cfg_if.sjump[mvu_id][4]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUBJUMP_0  : mvu_cfg_if.bjump[mvu_id][0]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUBJUMP_1  : mvu_cfg_if.bjump[mvu_id][1]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUBJUMP_2  : mvu_cfg_if.bjump[mvu_id][2]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUBJUMP_3  : mvu_cfg_if.bjump[mvu_id][3]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUBJUMP_4  : mvu_cfg_if.bjump[mvu_id][4]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUOJUMP_0  : mvu_cfg_if.ojump[mvu_id][0]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUOJUMP_1  : mvu_cfg_if.ojump[mvu_id][1]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUOJUMP_2  : mvu_cfg_if.ojump[mvu_id][2]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUOJUMP_3  : mvu_cfg_if.ojump[mvu_id][3]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUOJUMP_4  : mvu_cfg_if.ojump[mvu_id][4]  = apb.pwdata[BJUMP-1 : 0];
            mvu_pkg::CSR_MVUWLENGTH_1: mvu_cfg_if.wlength[mvu_id][1]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUWLENGTH_2: mvu_cfg_if.wlength[mvu_id][2]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUWLENGTH_3: mvu_cfg_if.wlength[mvu_id][3]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUWLENGTH_4: mvu_cfg_if.wlength[mvu_id][4]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUILENGTH_1: mvu_cfg_if.ilength[mvu_id][1]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUILENGTH_2: mvu_cfg_if.ilength[mvu_id][2]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUILENGTH_3: mvu_cfg_if.ilength[mvu_id][3]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUILENGTH_4: mvu_cfg_if.ilength[mvu_id][4]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUSLENGTH_1: mvu_cfg_if.slength[mvu_id][1]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUSLENGTH_2: mvu_cfg_if.slength[mvu_id][1]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUSLENGTH_3: mvu_cfg_if.slength[mvu_id][1]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUSLENGTH_4: mvu_cfg_if.slength[mvu_id][1]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUBLENGTH_1: mvu_cfg_if.blength[mvu_id][1]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUBLENGTH_2: mvu_cfg_if.blength[mvu_id][1]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUBLENGTH_3: mvu_cfg_if.blength[mvu_id][1]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUBLENGTH_4: mvu_cfg_if.blength[mvu_id][1]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUOLENGTH_1: mvu_cfg_if.olength[mvu_id][1]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUOLENGTH_2: mvu_cfg_if.olength[mvu_id][2]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUOLENGTH_3: mvu_cfg_if.olength[mvu_id][3]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUOLENGTH_4: mvu_cfg_if.olength[mvu_id][4]= apb.pwdata[BLENGTH-1 : 0];
            mvu_pkg::CSR_MVUPRECISION: begin
                mvu_cfg_if.wprecision[mvu_id] = apb.pwdata[BPREC-1 : 0];
                mvu_cfg_if.iprecision[mvu_id] = apb.pwdata[2*BPREC-1 : BPREC];
                mvu_cfg_if.oprecision[mvu_id] = apb.pwdata[3*BPREC-1 : 2*BPREC];
                mvu_cfg_if.w_signed[mvu_id]   = apb.pwdata[24];
                mvu_cfg_if.d_signed[mvu_id]   = apb.pwdata[25];
            end
            mvu_pkg::CSR_MVUSTATUS   : begin
                $display("CSR_MVUSTATUS functionality has not been declared!");
            end
            mvu_pkg::CSR_MVUCOMMAND  : begin
                mvu_cfg_if.countdown[mvu_id] = apb.pwdata[BCNTDWN-1 : 0];
                mvu_cfg_if.max_en[mvu_id]    = apb.pwdata[29];
                mvu_cfg_if.max_clr[mvu_id]   = 0;
                mvu_cfg_if.max_pool[mvu_id]  = 0;
                mvu_cfg_if.quant_clr[mvu_id] = 0;
                mvu_cfg_if.mul_mode[mvu_id]  = apb.pwdata[31:30];
            end
            mvu_pkg::CSR_MVUQUANT    : begin
                mvu_cfg_if.quant_msbidx[mvu_id] = apb.pwdata[BQMSBIDX-1 : 0];
            end
            mvu_pkg::CSR_MVUSCALER   : begin
                mvu_cfg_if.scaler_b[mvu_id] = apb.pwdata[BSCALERB-1 : 0];
                // mvu_cfg_if.scaler1_b[mvu_id] = apb.pwdata[BSCALERB-1 : 0];
                // mvu_cfg_if.scaler2_b[mvu_id] = apb.pwdata[2*BSCALERB-1 : BSCALERB];
            end
            mvu_pkg::CSR_MVUCONFIG1  : begin
                mvu_cfg_if.shacc_load_sel[mvu_id] = apb.pwdata[NJUMPS-1 : 0];
                mvu_cfg_if.zigzag_step_sel[mvu_id]= apb.pwdata[2*NJUMPS-1 : NJUMPS];
            end
            mvu_pkg::CSR_MVUOMVUSEL         : mvu_cfg_if.omvusel[mvu_id] = apb.pwdata[NMVU-1:0];
            mvu_pkg::CSR_MVUIHPBASEADDR     : mvu_cfg_if.ihpbaseaddr[mvu_id] = apb.pwdata[BBDADDR-1:0];
            mvu_pkg::CSR_MVUOHPBASEADDR     : mvu_cfg_if.ohpbaseaddr[mvu_id] = apb.pwdata[BBDADDR-1:0];
            mvu_pkg::CSR_MVUOHPMVUSEL       : mvu_cfg_if.ohpmvusel[mvu_id] = apb.pwdata[0];
            mvu_pkg::CSR_MVUHPJUMP_0        : mvu_cfg_if.hpjump[mvu_id][0] = apb.pwdata[BJUMP-1:0];
            mvu_pkg::CSR_MVUHPJUMP_1        : mvu_cfg_if.hpjump[mvu_id][1] = apb.pwdata[BJUMP-1:0];
            mvu_pkg::CSR_MVUHPJUMP_2        : mvu_cfg_if.hpjump[mvu_id][2] = apb.pwdata[BJUMP-1:0];
            mvu_pkg::CSR_MVUHPJUMP_3        : mvu_cfg_if.hpjump[mvu_id][3] = apb.pwdata[BJUMP-1:0];
            mvu_pkg::CSR_MVUHPJUMP_4        : mvu_cfg_if.hpjump[mvu_id][4] = apb.pwdata[BJUMP-1:0];
            mvu_pkg::CSR_MVUHPLENGTH_1      : mvu_cfg_if.hplength[mvu_id][1] = apb.pwdata[BJUMP-1:0];
            mvu_pkg::CSR_MVUHPLENGTH_2      : mvu_cfg_if.hplength[mvu_id][2] = apb.pwdata[BJUMP-1:0];
            mvu_pkg::CSR_MVUHPLENGTH_3      : mvu_cfg_if.hplength[mvu_id][3] = apb.pwdata[BJUMP-1:0];
            mvu_pkg::CSR_MVUHPLENGTH_4      : mvu_cfg_if.hplength[mvu_id][4] = apb.pwdata[BJUMP-1:0];
            mvu_pkg::CSR_MVUUSESCALER_MEM   : mvu_cfg_if.usescaler_mem[mvu_id] = apb.pwdata[0];
            mvu_pkg::CSR_MVUUSEBIAS_MEM     : mvu_cfg_if.usebias_mem[mvu_id] = apb.pwdata[0];
            mvu_pkg::CSR_MVUUSEPOOLER4HPOUT : mvu_cfg_if.usepooler4hpout[mvu_id] = apb.pwdata[0];
            mvu_pkg::CSR_MVUUSEHPADDER      : mvu_cfg_if.usehpadder[mvu_id] = apb.pwdata[0];
        endcase
    end
end

    // APB logic: we are always ready to capture the data into our regs
    // not supporting transfare failure
    assign apb.pready  = 1'b1;
    assign apb.pslverr = 1'b0;

    // Circuit for generating start Signal
    always @(posedge mvu_ext_if.clk) begin
        if (~mvu_ext_if.rst_n) begin
            mvu_ext_if.start <= 1'b0;
        end else begin
            if (apb_write) begin
                if (((mvu_pkg::mvu_csr_t'(register_adr[11:0])) == mvu_pkg::CSR_MVUCOMMAND) && (mvu_ext_if.start==1'b0)) begin
                    mvu_ext_if.start <= 1'b1;
                end else begin
                    mvu_ext_if.start <= 1'b0;
                end
            end else begin
                mvu_ext_if.start <= 1'b0;
            end
        end
    end

endmodule

