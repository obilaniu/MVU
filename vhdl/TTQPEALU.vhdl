--Imports
library ieee;
library TTQPkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.TTQPkg.all;


--
-- PE (Processing Element) ALU (Arithmetic Logic Unit)
--

entity TTQPEALU is
	port(
		modeCnnRnn:  in  std_logic;
		shiftLeft:   in  std_logic;
		D:           in  unsigned(15 downto 0);
		W:           in  unsigned(15 downto 0);
		Sin:         in  unsigned(31 downto 0);
		Sout:        out unsigned(31 downto 0)
	);
end entity;

architecture TTQPEALUImpl of TTQPEALU is
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
	
	signal PP:        unsigned( 7 downto 0);
	signal PN:        unsigned( 7 downto 0);
	signal pcntP:     unsigned( 3 downto 0);
	signal pcntN:     unsigned( 3 downto 0);
	signal unshifted: unsigned(31 downto 0);
begin
	-- Eight 2-bit-by-2-bit multipliers with two 1-bit results.
	--   The 1-bit signal PP indicates "Product Positive"
	--   The 1-bit signal PN indicates "Product Negative"
	TTQMul0       : TTQMul      port map(D( 1 downto  0), W( 1 downto  0), PP(0 downto 0), PN(0 downto 0));
	TTQMul1       : TTQMul      port map(D( 3 downto  2), W( 3 downto  2), PP(1 downto 1), PN(1 downto 1));
	TTQMul2       : TTQMul      port map(D( 5 downto  4), W( 5 downto  4), PP(2 downto 2), PN(2 downto 2));
	TTQMul3       : TTQMul      port map(D( 7 downto  6), W( 7 downto  6), PP(3 downto 3), PN(3 downto 3));
	TTQMul4       : TTQMul      port map(D( 9 downto  8), W( 9 downto  8), PP(4 downto 4), PN(4 downto 4));
	TTQMul5       : TTQMul      port map(D(11 downto 10), W(11 downto 10), PP(5 downto 5), PN(5 downto 5));
	TTQMul6       : TTQMul      port map(D(13 downto 12), W(13 downto 12), PP(6 downto 6), PN(6 downto 6));
	TTQMul7       : TTQMul      port map(D(15 downto 14), W(15 downto 14), PP(7 downto 7), PN(7 downto 7));
	
	-- Population count (Hamming Weight)
	--   Sum eight 1-bit values together into 4-bit integer
	TTQPopcountP  : TTQPopcount port map(PP, pcntP);
	TTQPopcountN  : TTQPopcount port map(PN, pcntN);
	
	-- Accumulation/Subtraction of popcount or D into running sum
	--   Requires zero-extending the 4-bit popcounts to 16 bits
	unshifted <= to_unsigned(to_integer(SPin)  +
	                         to_integer(pcntP) -
	                         to_integer(pcntN),
	                         unshifted'length)
	             when modeCnnRnn = '1' else
	             to_unsigned(to_integer(SPin)  +
	                         to_integer(signed(D)) when W(0) = 0 else 0,
	                         unshifted'length);
	
	-- Conditional shift
	--   (Implemented with addition, which is equivalent)
	Sout <= shift_left(unshifted, 1) when shiftLeft = '1' else unshifted;
	
	-- Sout will be latched into the register.
end architecture;
