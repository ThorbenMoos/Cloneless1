library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FF_srst is
    Generic ( bits : INTEGER := 4);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           inpt : in STD_LOGIC_VECTOR ((bits-1) downto 0);
           outpt : out STD_LOGIC_VECTOR ((bits-1) downto 0));
end FF_srst;

architecture Behavioral of FF_srst is

begin

    regpro: process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                outpt <= (others => '0');
            else
                if (en = '1') then
                    outpt <= inpt;
                end if;
            end if;
        end if;
    end process;

end Behavioral;