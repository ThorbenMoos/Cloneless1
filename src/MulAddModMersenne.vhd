library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MulAddModMersenne is
    Generic ( bits : INTEGER := 7);
    Port ( a : in UNSIGNED (bits-1 downto 0);
           b : in UNSIGNED (bits-1 downto 0);
           c : in UNSIGNED (bits-1 downto 0);
           d : out UNSIGNED (bits-1 downto 0));
end MulAddModMersenne;

architecture Behavioral of MulAddModMersenne is

    signal abc : UNSIGNED(2*bits-1 downto 0);
    signal abc_r : UNSIGNED(bits downto 0);

begin

    abc <= a * b + c;
    abc_r <= ('0' & abc(bits-1 downto 0)) + ('0' & abc(2*bits-1 downto bits));
    d <= abc_r(bits-1 downto 0) + ((bits-2 downto 0 => '0') & abc_r(bits));

end Behavioral;