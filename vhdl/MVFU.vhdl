--Imports
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


--
-- MVFU (Matrix-Vector Functional Unit)
--
-- 32x32 matrix by 32-vector.
--

entity MVFU is
	port(
		clk:         in  std_logic;
		trans:       in  std_logic;
		Win:         in  unsigned(1023 downto 0); -- Weights Matrix Tile.
		Din:         in  unsigned(  31 downto 0); -- Data Vector Input.
		Dout:        out unsigned(  31 downto 0)  -- Data Vector Output.
	);
end entity;


architecture MVFUImpl of MVFU is
	component TTQDFF is
		port(
			clk:   in  std_logic;
			Din:   in  unsigned(n-1 downto 0);
			Dout:  out unsigned(n-1 downto 0)
		);
	end component;
	
	signal W:      unsigned(Win'length-1     downto 0);
	signal eprod:  unsigned(W'length-1       downto 0);
	signal Dp:     unsigned(Dout'length*8-1  downto 0);
	signal ACCin:  unsigned(32*Din'length-1  downto 0);
	signal ACCout: unsigned(32*Din'length-1  downto 0);
begin
	-- FU "register file"
	ACC     : TTQDFF      generic map(32*Din'length)   port map(clk, ACCin, ACCout);
	
	--
	-- Transpose.
	--
	-- The W signal is the Win signal, conditionally transposed.
	transposeRows: for r in 0 to 31 generate
		transposeCols: for c in 0 to 31 generate
			W(r*32+c) <= Tin(r*32+c) when trans = '0' else Tin(c*32+r);
		end generate transposeCols;
	end generate transposeRows;
	
	--
	-- Matrix-Vector multiplication.
	--
	-- Binary
	gemvRows: for r in 0 to 31 generate
		eprod <= W(r*32+31 downto r*32) xor not Din;
		Dp(r*8+7 downto r*8) <= to_signed(to_integer(unsigned(eprod( 0 downto  0))) +
		                                  to_integer(unsigned(eprod( 1 downto  1))) +
		                                  to_integer(unsigned(eprod( 2 downto  2))) +
		                                  to_integer(unsigned(eprod( 3 downto  3))) +
		                                  to_integer(unsigned(eprod( 4 downto  4))) +
		                                  to_integer(unsigned(eprod( 5 downto  5))) +
		                                  to_integer(unsigned(eprod( 6 downto  6))) +
		                                  to_integer(unsigned(eprod( 7 downto  7))) +
		                                  to_integer(unsigned(eprod( 8 downto  8))) +
		                                  to_integer(unsigned(eprod( 9 downto  9))) +
		                                  to_integer(unsigned(eprod(10 downto 10))) +
		                                  to_integer(unsigned(eprod(11 downto 11))) +
		                                  to_integer(unsigned(eprod(12 downto 12))) +
		                                  to_integer(unsigned(eprod(13 downto 13))) +
		                                  to_integer(unsigned(eprod(14 downto 14))) +
		                                  to_integer(unsigned(eprod(15 downto 15))) +
		                                  to_integer(unsigned(eprod(16 downto 16))) +
		                                  to_integer(unsigned(eprod(17 downto 17))) +
		                                  to_integer(unsigned(eprod(18 downto 18))) +
		                                  to_integer(unsigned(eprod(19 downto 19))) +
		                                  to_integer(unsigned(eprod(20 downto 20))) +
		                                  to_integer(unsigned(eprod(21 downto 21))) +
		                                  to_integer(unsigned(eprod(22 downto 22))) +
		                                  to_integer(unsigned(eprod(23 downto 23))) +
		                                  to_integer(unsigned(eprod(24 downto 24))) +
		                                  to_integer(unsigned(eprod(25 downto 25))) +
		                                  to_integer(unsigned(eprod(26 downto 26))) +
		                                  to_integer(unsigned(eprod(27 downto 27))) +
		                                  to_integer(unsigned(eprod(28 downto 28))) +
		                                  to_integer(unsigned(eprod(29 downto 29))) +
		                                  to_integer(unsigned(eprod(30 downto 30))) +
		                                  to_integer(unsigned(eprod(31 downto 31))), 8);
	end generate gemvRows;
	
	--
	-- Accumulation 8-bit to 32-bit.
	--
	accRows: for r in 0 to 31 generate
		ACCin(r*32+31 downto r*32) <= to_unsigned(to_integer(ACCin(r*32+31 downto r*32)) + 
		                                          to_integer(Dp   (r* 8+7  downto r* 8)), 32);
	end generate accRows;
	
	--
	-- Output
	--
	-- For now, only connect sign bit to output. Later, add thresholder signal.
	outRows: for r in 0 to 31 generate
		Dout(r) <= ACCout(r*32+31);
	end generate outRows;
end architecture;
