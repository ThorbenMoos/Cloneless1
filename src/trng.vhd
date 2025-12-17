library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity trng is
    Generic (ro1length : INTEGER := 1;
             ro2length : INTEGER := 3);
    Port ( ro1_en : in STD_LOGIC;
           ro2_en : in STD_LOGIC;
           rst : in STD_LOGIC;
           valid : out STD_LOGIC;
           raw_bit : out STD_LOGIC);
end trng;

architecture Behavioral of trng is
    
    component ringoscillator is
        Generic (size : positive := 1);
        Port ( ro_en : in STD_LOGIC;
               ro_out : out STD_LOGIC);
    end component;
    
    component tappeddelaychain is
        Port ( ro1_out : in STD_LOGIC;
               ro2_out : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               stage : out STD_LOGIC_VECTOR (2 downto 0));
    end component;
    
    component bitextractor is
        Port ( ro2_out : in STD_LOGIC;
               rst : in STD_LOGIC;
               stage : in STD_LOGIC_VECTOR (2 downto 0);
               valid : out STD_LOGIC;
               raw_bit : out STD_LOGIC);
    end component;

    signal ro1_out, ro2_out : STD_LOGIC;
    signal stage : STD_LOGIC_VECTOR (2 downto 0);
    
    attribute keep : STRING;
    attribute keep of ro1_out, ro2_out, stage : signal is "true";
    
begin

    -- instantiate ring oscillators
    ro1: ringoscillator Generic Map (ro1length) Port Map (ro1_en, ro1_out);
    ro2: ringoscillator Generic Map (ro2length) Port Map (ro2_en, ro2_out);
    
    -- instantiate tapped delay chain
    tdc: tappeddelaychain Port Map (ro1_out, ro2_out, rst, ro1_en, stage);
    
    -- instantiate bit extractor
    be: bitextractor Port Map (ro2_out, rst, stage, valid, raw_bit);

end Behavioral;
