library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity nand2 is
    Port ( A1 : in STD_LOGIC;
           A2 : in STD_LOGIC;
           ZN : out STD_LOGIC);
end nand2;

architecture Behavioral of nand2 is

begin

    ZN <= A1 NAND A2;

end Behavioral;
