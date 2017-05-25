--Imports
library ieee;
library TTQPkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.TTQPkg.all;


-- Low-precision Ternary Multiplier
--   Expected Cost: 0.5-1 ALM (2+2 bit inputs, 1+1 bit outputs) in Normal Mode
entity TTQMul is
	port(
		V1:    in  unsigned(1 downto 0);
		V2:    in  unsigned(1 downto 0);
		PP:    out unsigned(0 downto 0);
		PN:    out unsigned(0 downto 0)
	);
end entity;
architecture TTQMulImpl of TTQMul is
	signal V1i:  integer;
	signal V2i:  integer;
	signal PPi:  integer;
	signal PNi:  integer;
begin
	-- Multiplication
	--   We interpret the input signals V1 and V2 as 2's complement signed values.
	--   Namely, V1 and V2 are to be interpreted as:
	--     11: -1
	--     00: +0
	--     01: +1
	--     10: Invalid
	
	V1i   <= to_integer(signed(V1));
	V2i   <= to_integer(signed(V2));
	PPi   <= 1 when V1i  =  1 and V2i  =  1 else
	         1 when V1i  = -1 and V2i  = -1 else 0;
	PNi   <= 1 when V1i  =  1 and V2i  = -1 else
	         1 when V1i  = -1 and V2i  =  1 else 0;
	PP    <= to_unsigned(PPi, 1);
	PN    <= to_unsigned(PNi, 1);
end architecture;
