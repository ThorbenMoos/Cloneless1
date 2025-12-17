library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity xor2 is
    Port ( A1 : in STD_LOGIC;
           A2 : in STD_LOGIC;
           Z : out STD_LOGIC);
end xor2;

architecture Behavioral of xor2 is

begin

    Z <= A1 XOR A2;

end Behavioral;
