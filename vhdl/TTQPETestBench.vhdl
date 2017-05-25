--Imports
library ieee;
library TTQPkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.TTQPkg.all;



-- TTQ PE Test Bench
entity TTQPETestBench is
end entity;
architecture TTQPETestBenchImpl of TTQPETestBench is
	component TTQPE is
		port(
			clk:   in  std_logic;
			Din:   in  unsigned(15 downto 0);
			Win:   in  unsigned(15 downto 0);
			SPin:  in  unsigned(15 downto 0);
			SNin:  in  unsigned(15 downto 0);
			Dout:  out unsigned(15 downto 0);
			Wout:  out unsigned(15 downto 0);
			SPout: out unsigned(15 downto 0);
			SNout: out unsigned(15 downto 0)
		);
	end component;
	signal clk:    std_logic;
	signal Din:    unsigned(15 downto 0);
	signal Win:    unsigned(15 downto 0);
	signal SPin:   unsigned(15 downto 0);
	signal SNin:   unsigned(15 downto 0);
	signal Dout:   unsigned(15 downto 0);
	signal Wout:   unsigned(15 downto 0);
	signal SPout:  unsigned(15 downto 0);
	signal SNout:  unsigned(15 downto 0);
begin
	-- Instantiate block
	TTQPE0      :  TTQPE        port map(clk, Din, Win, SPin, SNin, Dout, Wout, SPout, SNout);
	
	-- Run test over a few nanoseconds.
	process begin
		-- Reset
		clk   <= '0';
		Din   <= B"00_00_00_00_00_00_00_00";
		Win   <= B"00_00_00_00_00_00_00_00";
		SPin  <= B"00_00_00_00_00_00_00_00";
		SNin  <= B"00_00_00_00_00_00_00_00";
		wait for 1 ns;
		-- Set up data for rising edge
		Din   <= B"00_01_11_01_01_11_01_01";
		Win   <= B"00_01_11_01_01_01_01_01"; --   0  +  (+0+1+1+1+1-1+1+1) = 6-1 = 5
		wait for 1 ns;
		clk   <= '1';
		wait for 1 ns;
		-- Loop back output sums to input
		SPin  <= SPout;
		SNin  <= SNout;
		clk   <= '0';
		-- Set up data for rising edge
		Din   <= B"11_01_11_00_01_00_11_01";
		Win   <= B"01_00_00_11_00_01_11_11"; --  6-1 +  (-1+0+0+0+0+0+1-1) = 7-3 = 4
		wait for 1 ns;
		clk   <= '1';
		wait for 1 ns;
		-- There should be SPout = 7 and SNout = 3 at this stage.
		wait;
	end process;
end architecture;
