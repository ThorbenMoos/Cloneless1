library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MulAddMulModMersenne is
    Generic ( bits : INTEGER := 7);
    Port ( a : in UNSIGNED (bits-1 downto 0);
           b : in UNSIGNED (bits-1 downto 0);
           c : in UNSIGNED (bits-1 downto 0);
           d : in UNSIGNED (bits-1 downto 0);
           e : out UNSIGNED (bits-1 downto 0));
end MulAddMulModMersenne;

architecture Behavioral of MulAddMulModMersenne is
    
    signal cd, abcd : UNSIGNED(2*bits-1 downto 0);
    signal cd_r, abcd_r : UNSIGNED(bits downto 0);

begin

    cd <= c * d;
    cd_r <= ('0' & cd(bits-1 downto 0)) + ('0' & cd(2*bits-1 downto bits));
    
    abcd <= a * b + cd_r;
    abcd_r <= ('0' & abcd(bits-1 downto 0)) + ('0' & abcd(2*bits-1 downto bits));
    e <= abcd_r(bits-1 downto 0) + ((bits-2 downto 0 => '0') & abcd_r(bits));

end Behavioral;