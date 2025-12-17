library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FF is
    Generic ( bits : INTEGER := 7);
    Port ( clk : in STD_LOGIC;
           en : in STD_LOGIC;
           inpt : in UNSIGNED ((bits-1) downto 0);
           outpt : out UNSIGNED ((bits-1) downto 0));
end FF;

architecture Behavioral of FF is

begin

    regpro: process(clk)
    begin
        if (rising_edge(clk)) then
            if (en = '1') then
                outpt <= inpt;
            end if;
        end if;
    end process;

end Behavioral;