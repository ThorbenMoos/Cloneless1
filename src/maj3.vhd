library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity maj3 is
    Generic (bits : INTEGER := 128);
    Port ( a : in STD_LOGIC_VECTOR (bits-1 downto 0);
           b : in STD_LOGIC_VECTOR (bits-1 downto 0);
           c : in STD_LOGIC_VECTOR (bits-1 downto 0);
           d : out STD_LOGIC_VECTOR (bits-1 downto 0));
end maj3;

architecture Behavioral of maj3 is

begin

    d <= NOT ((a NAND b) AND (a NAND c) AND (b NAND c));

end Behavioral;
