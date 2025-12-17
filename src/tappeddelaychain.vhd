library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tappeddelaychain is
    Port ( ro1_out : in STD_LOGIC;
           ro2_out : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           stage : out STD_LOGIC_VECTOR (2 downto 0));
end tappeddelaychain;

architecture Behavioral of tappeddelaychain is
    
    component carry4 is
        Port ( co : out STD_LOGIC_VECTOR (3 downto 0);
               o : out STD_LOGIC_VECTOR (3 downto 0);
               di : in STD_LOGIC_VECTOR (3 downto 0);
               se : in STD_LOGIC_VECTOR (3 downto 0));
    end component;
    
    component FF_arst is
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               inpt : in STD_LOGIC;
               outpt : out STD_LOGIC);
    end component;
    
    signal stage_reg, ro1_out_long : STD_LOGIC_VECTOR (3 downto 0);
    
    attribute keep : STRING;
    attribute keep of stage_reg, ro1_out_long : signal is "true";

begin

    ro1_out_long <= "000" & ro1_out;
    
    -- carry 4 instance for delay
    carry4_inst: carry4 Port Map (stage_reg, open, ro1_out_long, "1110");
    
    -- fcde instances for sampling
    gen: for i in 0 to 2 generate
        ff_inst: FF_arst Port Map (ro2_out, rst, en, stage_reg(i), stage(i));
    end generate;

end Behavioral;