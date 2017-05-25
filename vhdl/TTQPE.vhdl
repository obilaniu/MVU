--Imports
library ieee;
library TTQPkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.TTQPkg.all;



-- TTQ PE (Processing Element)
--   Cost:
entity TTQPE is
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
			D:     in  unsigned(15 downto 0);
			W:     in  unsigned(15 downto 0);
			SPin:  in  unsigned(15 downto 0);
			SNin:  in  unsigned(15 downto 0);
			SPout: out unsigned(15 downto 0);
			SNout: out unsigned(15 downto 0)
		);
	end component;
	
	signal sumP:  unsigned(15 downto 0);
	signal sumN:  unsigned(15 downto 0);
begin
	-- Processing Element ALU at front end:
	TTQPEALU0     : TTQPEALU    port map(Din, Win, SPin, SNin, sumP, sumN);

	-- PE "register file"
	--   Registers the data, weights and dot-product+partial accumulation this
	--   PE has computed within itself.
	--   Only stateful blocks within the PE.
	TTQDFFD       : TTQDFF      generic map(Din'length)  port map(clk, Din,  Dout);
	TTQDFFW       : TTQDFF      generic map(Win'length)  port map(clk, Win,  Wout);
	TTQDFFSPout   : TTQDFF      generic map(SPin'length) port map(clk, sumP, SPout);
	TTQDFFSNout   : TTQDFF      generic map(SNin'length) port map(clk, sumN, SNout);
end architecture;
