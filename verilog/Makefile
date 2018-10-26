.PHONY: all test

all:
	@ mkdir -p bin
	@ iverilog -o bin/test_mvu -g2005 *.v
	@ iverilog -o bin/test_dotp -g2005 *.v
	@ iverilog -o bin/test_interconn -s test_interconn -g2005 *.v

dotp: all
	@ bin/test_dotp

test: all
	@ bin/test_mvu

interconn: all
	@ bin/test_interconn
