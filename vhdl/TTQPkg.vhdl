--Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Package
package TTQPkg is
	function to_std_logic(L: boolean) return std_logic;
	function xor_reduce(u : in std_logic_vector) return std_logic;
	function or_reduce (u : in std_logic_vector) return std_logic;

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
	
	component TTQMul is
		port(
			V1:    in  unsigned(1 downto 0);
			V2:    in  unsigned(1 downto 0);
			PP:    out unsigned(0 downto 0);
			PN:    out unsigned(0 downto 0)
		);
	end component;
	
	component TTQPopcount is
		port(
			D:  in  unsigned(7 downto 0);
			S:  out unsigned(3 downto 0)
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
	
	component TTQPE is
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
	end component;
	
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
end package TTQPkg;

package body TTQPkg is
	function to_std_logic(L: boolean) return std_logic is
	begin
		if L then
			return ('1');
		else
			return ('0');
		end if;
	end function to_std_logic;
	
	function xor_reduce(u : in std_logic_vector) return std_logic is
		variable x : std_logic := '0';
	begin
		for i in u'range loop
			x := x xor u(i);
		end loop;
		return x;
	end function;
	
	function or_reduce(u : in std_logic_vector) return std_logic is
		variable x : std_logic := '0';
	begin
		for i in u'range loop
			x := x or u(i);
		end loop;
		return x;
	end function;
end package body TTQPkg;

