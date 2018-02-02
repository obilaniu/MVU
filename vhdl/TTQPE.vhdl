--Imports
library ieee;
library TTQPkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.TTQPkg.all;


--
-- TTQ PE (Processing Element)
--
entity TTQPE is
	port(
		clk:         in  std_logic;
		modeCnnRnn:  in  std_logic;
		shiftLeft:   in  std_logic;
		Din:         in  unsigned(15 downto 0);
		Win:         in  unsigned(15 downto 0);
		Sin:         in  unsigned(31 downto 0);
		Dout:        out unsigned(15 downto 0);
		Wout:        out unsigned(15 downto 0);
		Sout:        out unsigned(31 downto 0)
	);
end entity;

architecture TTQPEImpl of TTQPE is
	component TTQDFF is
		generic(
			n:  natural := 16
		);
		port(
			clk:   in  std_logic;
			Din:   in  unsigned(n-1 downto 0);
			Dout:  out unsigned(n-1 downto 0)
		);
	end component;
	component TTQPEALU is
		port(
			modeCnnRnn:  in  std_logic;
			shiftLeft:   in  std_logic;
			D:           in  unsigned(15 downto 0);
			W:           in  unsigned(15 downto 0);
			Sin:         in  unsigned(31 downto 0);
			Sout:        out unsigned(31 downto 0)
		);
	end component;
	
	signal sumout:  unsigned(31 downto 0);
begin
	-- Processing Element ALU at front end:
	TTQPEALU0     : TTQPEALU    port map(modeCnnRnn, shiftLeft, Din, Win, Sin, sumout);

	-- PE "register file"
	--   Registers the data, weights and dot-product+partial accumulation this
	--   PE has computed within itself.
	--   Only stateful blocks within the PE.
	TTQDFFD       : TTQDFF      generic map(Din'length)  port map(clk, Din,    Dout);
	TTQDFFW       : TTQDFF      generic map(Win'length)  port map(clk, Win,    Wout);
	TTQDFFSout    : TTQDFF      generic map(Sin'length)  port map(clk, sumout, Sout);
end architecture;
