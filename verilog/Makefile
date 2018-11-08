.PHONY: all mkdir vvp mvp interconn toplevel run test

mkdir:
	@ mkdir -p bin

all: vvp mvp shacc interconn toplevel

vvp: mkdir vvp.v
	@ iverilog -g2005 -s test_vvp       -o bin/test_vvp       vvp.v

mvp: mkdir vvp mvp.v
	@ iverilog -g2005 -s test_mvp       -o bin/test_mvp       vvp.v mvp.v

shacc: mkdir shacc.v
	@ iverilog -g2005 -s test_shacc     -o bin/test_shacc     shacc.v

interconn: mkdir interconn.v
	@ iverilog -g2005 -s test_interconn -o bin/test_interconn interconn.v

toplevel: mkdir test_bram16k.v
	@ iverilog -g2005 $(QUARTUS_SIMLIB)/altera_mf.v -s test_bram16k    -o bin/test_bram16k  test_bram16k.v bram16k.v

mvu: mkdir mvp mvu.v
	@ iverilog -g2005 $(QUARTUS_SIMLIB)/altera_mf.v -s mvu    -o bin/test_mvu  vvp.v mvp.v shacc.v bram16k.v bram2m.v mvu.v

run: all
	@ bin/test_vvp
	@ bin/test_mvp
	@ bin/test_shacc
	@ bin/test_interconn
	@ bin/toplevel
