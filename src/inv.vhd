library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity inv is
    Port ( I : in STD_LOGIC;
           ZN : out STD_LOGIC);
end inv;

architecture Behavioral of inv is

begin

    ZN <= NOT I;

end Behavioral;
