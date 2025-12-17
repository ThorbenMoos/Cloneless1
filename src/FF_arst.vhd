library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FF_arst is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           inpt : in STD_LOGIC;
           outpt : out STD_LOGIC);
end FF_arst;

architecture Behavioral of FF_arst is

begin

    regpro: process(clk, rst)
    begin
        if (rst = '1') then
            outpt <= '0';
        elsif (rising_edge(clk)) then
            if (en = '1') then
                outpt <= inpt;
            end if;
        end if;
    end process;

end Behavioral;