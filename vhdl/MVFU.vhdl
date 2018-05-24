--Imports
library ieee;
library TTQPkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.TTQPkg.all;


--
-- MVFU (Matrix-Vector Functional Unit)
--
-- Current: 32x32 matrix by 32-vector.
--

entity MVFU is
	port(
		clk:         in  std_logic;
		latch:       in  std_logic;
		swap:        in  std_logic;
		Din:         in  unsigned(  31 downto 0);
		Win:         in  unsigned(  31 downto 0);
		Sout:        out unsigned(1023 downto 0)
	);
end entity;


architecture MVFUImpl of MVFU is
	component TTQDFF is
		generic(
			n:  natural := 32
		);
		port(
			clk:   in  std_logic;
			Din:   in  unsigned(n-1 downto 0);
			Dout:  out unsigned(n-1 downto 0)
		);
	end component;
	
	signal D0in:  unsigned(Din'length-1  downto 0);
	signal D0out: unsigned(Din'length-1  downto 0);
	signal D1in:  unsigned(Din'length-1  downto 0);
	signal D1out: unsigned(Din'length-1  downto 0);
	signal S0in:  unsigned(Sout'length-1 downto 0);
	signal S0out: unsigned(Sout'length-1 downto 0);
	signal S1in:  unsigned(Sout'length-1 downto 0);
	signal S1out: unsigned(Sout'length-1 downto 0);
begin
	-- FU "register file"
	D0      : TTQDFF      generic map(Din'length)   port map(clk, D0in, D0out);
	D1      : TTQDFF      generic map(Din'length)   port map(clk, D1in, D1out);
	S0      : TTQDFF      generic map(Sout'length)  port map(clk, S0in, S0out);
	S1      : TTQDFF      generic map(Sout'length)  port map(clk, S1in, S1out);
	
	
	-- Action on every clock cycle
	process(clk) is
	begin
		if rising_edge(clk) then
			if swap = '0' then
				if latch = '1' then
					D0in <= Din;
				end if;
				
				Sout <= S1out;
				
				-- Linear math
				-- Vector S0 += D0*Win
				genFMA0: for r in 0 to 31 generate
					S0in(32*(r+1) downto 31*r) <= S0in(32*(r+1) downto 31*r) + D0in(r)*Win(r);
				end generate genFMA0
			else
				if latch = '1' then
					D1in <= Din;
				end if;
				
				Sout <= S0out;
				
				-- Linear math
				-- Vector S1 += D1*Win
				genFMA1: for r in 0 to 31 generate
					S1in(32*(r+1) downto 31*r) <= S1in(32*(r+1) downto 31*r) + D1in(r)*Win(r);
				end generate genFMA1
			end if;
		end if;
	end process;
end architecture;
