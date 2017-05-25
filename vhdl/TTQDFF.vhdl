--Imports
library ieee;
library TTQPkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.TTQPkg.all;



-- D Flip Flop
--   n-bit wide generic behavioural implementation of a D Flip-Flop.
entity TTQDFF is
	generic(
		n:  natural := 16
	);
	port(
		clk:   in  std_logic;
		Din:   in  unsigned(n-1 downto 0);
		Dout:  out unsigned(n-1 downto 0)
	);
end entity;
architecture TTQDFFImpl of TTQDFF is
	signal reg: unsigned(n-1 downto 0);
begin
	Dout <= reg;
	
	process(clk) begin
		if rising_edge(clk) then
			reg <= Din;
		end if;
	end process;
end architecture;
