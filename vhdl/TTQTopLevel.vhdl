--Imports
library ieee;
library TTQPkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.TTQPkg.all;


-- TTQ Top Level
entity TTQTopLevel is
	port(
		clk:     in  std_logic;
		dummiD:  in  std_logic;
		dummiW:  in  std_logic;
		dummiSP: in  std_logic;
		dummiSN: in  std_logic;
		dummiWP: in  std_logic;
		dummiWN: in  std_logic;
		dummiB:  in  std_logic;
		dummo:   out std_logic
	);
end entity;
architecture TTQTopLevelImpl of TTQTopLevel is
	component TTQPELattice is
		generic(
			ROW:   natural := 64;
			COL:   natural := 32
		);
		
		port(
			clk:   in  std_logic;
			Din:   in  unsigned(COL*16-1 downto 0);
			Win:   in  unsigned((ROW+COL-1)*16-1 downto 0);
			SPin:  in  unsigned(ROW*16-1 downto 0);
			SNin:  in  unsigned(ROW*16-1 downto 0);
			Dout:  out unsigned(COL*16-1 downto 0);
			Wout:  out unsigned((ROW+COL-1)*16-1 downto 0);
			SPout: out unsigned(ROW*16-1 downto 0);
			SNout: out unsigned(ROW*16-1 downto 0)
		);
	end component;
	
	component TTQFinalizer is
		generic(
			ROW:   natural := 64
		);
		
		port(
			SP:    in  unsigned(ROW*16-1 downto 0);
			SN:    in  unsigned(ROW*16-1 downto 0);
			WP:    in  unsigned(ROW*16-1 downto 0);
			WN:    in  unsigned(ROW*16-1 downto 0);
			B:     in  unsigned(ROW*16-1 downto 0);
			S:     out signed  (ROW*16-1 downto 0)
		);
	end component;
	
	constant ROW: natural := 64;
	constant COL: natural := 32;
	
	signal Din:   unsigned(COL*16-1 downto 0);
	signal Win:   unsigned((ROW+COL-1)*16-1 downto 0);
	signal WP:    unsigned(ROW*16-1 downto 0);
	signal WN:    unsigned(ROW*16-1 downto 0);
	signal B:     unsigned(ROW*16-1 downto 0);
	signal S:     signed  (ROW*16-1 downto 0);
	signal SPin:  unsigned(ROW*16-1 downto 0);
	signal SNin:  unsigned(ROW*16-1 downto 0);
	signal Dout:  unsigned(COL*16-1 downto 0);
	signal Wout:  unsigned((ROW+COL-1)*16-1 downto 0);
	signal SPout: unsigned(ROW*16-1 downto 0);
	signal SNout: unsigned(ROW*16-1 downto 0);
begin
	TTQPELattice0 : TTQPELattice generic map(ROW, COL)
	                             port    map(clk, Din,  Win,  SPin,  SNin,
	                                              Dout, Wout, SPout, SNout);
	TTQFinalizer0 : TTQFinalizer generic map(ROW)
	                             port    map(SPout, SNout, WP, WN, B, S);

	dummo<= xor_reduce(std_logic_vector(Dout))  xor
	        xor_reduce(std_logic_vector(Wout))  xor
	        xor_reduce(std_logic_vector(S));
	
	process(clk) begin
		if rising_edge(clk) then
			Din  <= Din (Din 'length-2 downto 0) & dummiD;
			Win  <= Win (Win 'length-2 downto 0) & dummiW;
			SPin <= SPin(SPin'length-2 downto 0) & dummiSP;
			SNin <= SPin(SNin'length-2 downto 0) & dummiSN;
			WP   <= WP  (WP'  length-2 downto 0) & dummiWP;
			WN   <= WP  (WN'  length-2 downto 0) & dummiWN;
			B    <= B   (B'   length-2 downto 0) & dummiB;
		end if;
	end process;
end architecture;
