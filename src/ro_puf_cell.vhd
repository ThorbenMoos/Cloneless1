library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ro_puf_cell is
    Generic (rolength : INTEGER := 1;
             cycles : INTEGER := 3000);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           raw_bit : out STD_LOGIC;
           done : out STD_LOGIC);
end ro_puf_cell;

architecture Behavioral of ro_puf_cell is

    component ro_cnt is
        Generic (rolength : INTEGER := 1);
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               cnt_out : out UNSIGNED (15 downto 0));
    end component;

    signal rocnt_rst, rocnt_en : STD_LOGIC;
    signal rocnt1_out, rocnt2_out : UNSIGNED (15 downto 0);
    
    attribute keep : STRING;
    attribute keep of rocnt_rst, rocnt_en, rocnt1_out, rocnt2_out : signal is "true";

begin

    -- instantiate ring oscillators
    rocnt1: ro_cnt Generic Map (rolength) Port Map (clk, rocnt_rst, rocnt_en, rocnt1_out);
    rocnt2: ro_cnt Generic Map (rolength) Port Map (clk, rocnt_rst, rocnt_en, rocnt2_out);
    
	-- fsm process
    fsm: process(clk)
        variable cnt : INTEGER range 0 to cycles;
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                rocnt_rst           <= '1';
                rocnt_en            <= '0';
                raw_bit             <= '0';
                done                <= '0';
                cnt                 := 0;
            else
                if (en = '1') then
                    rocnt_rst           <= '0';
                    rocnt_en            <= '1';
                    cnt                 := cnt + 1;
                    if (cnt = cycles) then
                        rocnt_en        <= '0';
                        if (rocnt1_out >= rocnt2_out) then
                            raw_bit     <= '0';
                            done        <= '1';
                        else
                            raw_bit     <= '1';
                            done        <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
