library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2 is
    Port ( I0 : in STD_LOGIC;
           I1 : in STD_LOGIC;
           S : in STD_LOGIC;
           Z : out STD_LOGIC);
end mux2;

architecture Behavioral of mux2 is

begin

    Z <= I0 when (S = '0') else I1;

end Behavioral;
