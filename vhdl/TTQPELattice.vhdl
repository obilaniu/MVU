--Imports
library ieee;
library TTQPkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.TTQPkg.all;



-- TTQ PE (Processing Element) Lattice
--
-- In this design,
--     1. Partial sums go   Left-to-Right (to meet the DSP slices).
--     2. Data         goes Top-to-Bottom (across the partial sum stream).
--     3. Weights      go   Top-Left-to-Bottom-Right.
entity TTQPELattice is
	generic(
		ROW:   natural := 64;
		COL:   natural := 32
	);
	
	port(
		clk:         in  std_logic;
		modeCnnRnn:  in  std_logic;
		shiftLeft:   in  std_logic;
		Din:         in  unsigned(COL*16-1 downto 0);
		Win:         in  unsigned((ROW+COL-1)*16-1 downto 0);
		Sin:         in  unsigned(ROW*16-1 downto 0);
		Dout:        out unsigned(COL*16-1 downto 0);
		Wout:        out unsigned((ROW+COL-1)*16-1 downto 0);
		Sout:        out unsigned(ROW*16-1 downto 0)
	);
end entity;
architecture TTQPELatticeImpl of TTQPELattice is
	component TTQPE is
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
	end component;
	
	signal D:     unsigned((ROW+1)*(COL+1)*16-1 downto 0);
	signal W:     unsigned((ROW+1)*(COL+1)*16-1 downto 0);
	signal S:     unsigned((ROW+1)*(COL+1)*16-1 downto 0);
begin
	genrows: for r in 0 to ROW-1 generate
		gencols: for c in 0 to COL-1 generate
			constant curr      : natural := (r+0)*(COL+1)+(c+0);
			constant nextRight : natural := (r+0)*(COL+1)+(c+1);
			constant nextBelow : natural := (r+1)*(COL+1)+(c+0);
		begin
			TTQPErc : TTQPE port map(clk, modeCnnRnn, shiftLeft,
			                         D(curr     *16+15 downto curr     *16),
			                         W(curr     *16+15 downto curr     *16),
			                         S(curr     *16+15 downto curr     *16),
			                         D(nextBelow*16+15 downto nextBelow*16),
			                         W(nextRight*16+15 downto nextRight*16),
			                         S(nextRight*16+15 downto nextRight*16));
			
			-- Edge cases...
			topRow:     if r = 0 generate
				D    (curr     *16+15 downto curr     *16) <= Din (c        *16+15 downto c        *16);
			end generate topRow;
			bottomRow:  if r = ROW-1 generate
				Dout (c        *16+15 downto c        *16) <= D   (nextBelow*16+15 downto nextBelow*16);
			end generate bottomRow;
			leftCol:    if c = 0 generate
				S    (curr     *32+31 downto curr     *32) <= Sin (r        *32+31 downto r        *32);
			end generate leftCol;
			rightCol:   if c = COL-1 generate
				Sout (r        *32+31 downto r        *32) <= S   (nextRight*32+31 downto nextRight*32);
			end generate rightCol;
			topEdge:    if r = 0 generate
				W    (curr     *16+15 downto curr     *16) <= Win (c        *16+15 downto c        *16);
			end generate topEdge;
			leftEdge:   if r > 0 and c = 0 generate
				W    (curr     *16+15 downto curr     *16) <= Win ((COL+c-1)*16+15 downto (COL+c-1)*16);
			end generate leftEdge;
			rightEdge:  if c = COL-1 generate
				Wout (r        *16+15 downto r        *16) <= W   (nextRight*16+15 downto nextRight*16);
			end generate rightEdge;
			bottomEdge: if c < COL-1 and r = ROW-1 generate
				Wout ((ROW+c-0)*16+15 downto (ROW+c-0)*16) <= W   (nextRight*16+15 downto nextRight*16);
			end generate bottomEdge;
		end generate gencols;
	end generate genrows;
end architecture;
