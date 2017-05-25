--Imports
library ieee;
library TTQPkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.TTQPkg.all;



-- TTQ Finalizer
--
-- Combines the positive and negative sums into one and accumulates a bias.
entity TTQFinalizer is
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
end entity;
architecture TTQFinalizerImpl of TTQFinalizer is
begin
	genrows: for r in 0 to ROW-1 generate
		signal Swide:       unsigned(31 downto 0);
		signal Bwide:       unsigned(31 downto 0);
		signal bitsBelow:   std_logic;
		signal tied:        std_logic;
		signal rndUp:       unsigned(15 downto 0);
	begin
		Bwide     <= B (r*16+15 downto r*16) & x"0000";
		Swide     <= SP(r*16+15 downto r*16)*WP(r*16+15 downto r*16)-
		             SN(r*16+15 downto r*16)*WN(r*16+15 downto r*16)+
		             Bwide;
		
		-- Round-to-Even, Ties-To-Even on Swide to 16 bits.
		--   Note: Rounding up a tied odd number makes it even.
		bitsBelow <= or_reduce(std_logic_vector(Swide(14 downto 0)));
		tied      <= Swide(15) and not bitsBelow;
		rndUp     <= "000000000000000" & ((not tied and Swide(15)) or
		                                  (    tied and Swide(16)));
		S(r*16+15 downto r*16) <= signed(Swide(31 downto 16) + rndUp);
	end generate genrows;
end architecture;
