library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ro_cnt is
    Generic (rolength : INTEGER := 1);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           cnt_out : out UNSIGNED (15 downto 0));
end ro_cnt;

architecture Behavioral of ro_cnt is

    component ringoscillator is
        Generic (size : INTEGER := 1);
        Port ( ro_en : in STD_LOGIC;
               ro_out : out STD_LOGIC);
    end component;
    
    signal ro_clk : STD_LOGIC;
    signal cnt : UNSIGNED (15 downto 0);
    
    attribute keep : STRING;
    attribute keep of ro_clk, cnt : signal is "true";
    
begin

    -- instantiate ring oscillator
    ro: ringoscillator Generic Map (rolength) Port Map (en, ro_clk);

    -- counter process
    counter: process(ro_clk, rst)
    begin
        if (rst = '1') then
            cnt <= (others => '0');
        elsif rising_edge(ro_clk) then
            if (en = '1') then
                cnt <= cnt + 1;
            end if;
        end if;
    end process;
    
    -- synchronous output register
    out_reg: process(clk)
    begin
        if (rising_edge(clk)) then
            cnt_out <= cnt;
        end if;
    end process;
    
end Behavioral;
