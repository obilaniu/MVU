.PHONY: all mkdir vvp mvp interconn toplevel run test

all: vvp mvp shacc interconn toplevel

mkdir:
	@ mkdir -p bin

vvp: mkdir vvp.v
	@ iverilog -g2005 -s test_vvp       -o bin/test_vvp       vvp.v

mvp: mkdir vvp mvp.v
	@ iverilog -g2005 -s test_mvp       -o bin/test_mvp       vvp.v mvp.v

shacc: mkdir shacc.v
	@ iverilog -g2005 -s test_shacc     -o bin/test_shacc     shacc.v

interconn: mkdir interconn.v
	@ iverilog -g2005 -s test_interconn -o bin/test_interconn interconn.v

toplevel: mkdir test_bram16k.v
	@ iverilog -g2005 $(QUARTUS_SIMLIB)/altera_mf.v -s toplevel -o bin/test_toplevel  vvp.v mvp.v shacc.v bram16k.v bram2m.v bank64k.v bram64k.v mvu.v decoder.v maxpool.v interconn.v toplevel.v

mvu: mkdir mvp shacc bank64k mvu.v decoder.v maxpool.v
	@ iverilog -g2005 $(QUARTUS_SIMLIB)/altera_mf.v -s mvu    -o bin/test_mvu  vvp.v mvp.v shacc.v bram16k.v bram2m.v bank64k.v bram64k.v mvu.v decoder.v maxpool.v

portmux: mkdir portmux.v
	@ iverilog -g2005 -s portmux        -o bin/test_portmux portmux.v

bank64k: mkdir bank64k.v
	@ iverilog -g2005 $(QUARTUS_SIMLIB)/altera_mf.v -s bank64k        -o bin/test_bank64k bank64k.v portmux.v bram64k.v

run: all
	@ bin/test_portmux
	@ bin/test_vvp
	@ bin/test_mvp
	@ bin/test_shacc
	@ bin/test_interconn
	@ bin/toplevel
