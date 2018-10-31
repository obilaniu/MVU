.PHONY: all mkdir vvp mvp interconn run test

mkdir:
	@ mkdir -p bin

all: vvp mvp shacc interconn
	@ true

vvp: mkdir vvp.v
	@ iverilog -g2005 -s test_vvp       -o bin/test_vvp       *.v

mvp: mkdir vvp mvp.v
	@ iverilog -g2005 -s test_mvp       -o bin/test_mvp       *.v

shacc: mkdir shacc.v
	@ iverilog -g2005 -s test_shacc     -o bin/test_shacc     *.v

interconn: mkdir interconn.v
	@ iverilog -g2005 -s test_interconn -o bin/test_interconn *.v

run: all
	@ bin/test_vvp
	@ bin/test_mvp
	@ bin/test_shacc
	@ bin/test_interconn
