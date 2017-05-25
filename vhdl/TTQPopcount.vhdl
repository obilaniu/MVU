--Imports
library ieee;
library TTQPkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.TTQPkg.all;



-- 8-1 Popcount
--   Expected Cost: 1-2 ALMs (8 bit inputs, 4 bit outputs) in Arithmetic Mode
entity TTQPopcount is
	port(
		D:  in  unsigned(7 downto 0);
		S:  out unsigned(3 downto 0)
	);
end entity;
architecture TTQPopcountImpl of TTQPopcount is
begin
	S <= to_unsigned(to_integer(D(0 downto 0)) +
	                 to_integer(D(1 downto 1)) +
	                 to_integer(D(2 downto 2)) +
	                 to_integer(D(3 downto 3)) +
	                 to_integer(D(4 downto 4)) +
	                 to_integer(D(5 downto 5)) +
	                 to_integer(D(6 downto 6)) +
	                 to_integer(D(7 downto 7)), 4);
end architecture;
