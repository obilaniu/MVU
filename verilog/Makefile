.PHONY: all test

all:
	@ iverilog -o test_mvu -g2005 *.v
	@ iverilog -o test_interconn -s test_interconn -g2005 *.v

test: all
	@ ./test_mvu

interconn: all
	@ ./test_interconn
