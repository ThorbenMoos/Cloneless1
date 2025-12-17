library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MulModMersenne is
    Generic ( bits : INTEGER := 7);
    Port ( a : in UNSIGNED (bits-1 downto 0);
           b : in UNSIGNED (bits-1 downto 0);
           c : out UNSIGNED (bits-1 downto 0));
end MulModMersenne;

architecture Behavioral of MulModMersenne is

    signal ab : UNSIGNED(2*bits-1 downto 0);
    signal ab_r : UNSIGNED(bits downto 0);

begin

    ab <= a * b;
    ab_r <= ('0' & ab(bits-1 downto 0)) + ('0' & ab(2*bits-1 downto bits));
    c <= ab_r(bits-1 downto 0) + ((bits-2 downto 0 => '0') & ab_r(bits));

end Behavioral;