library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ringoscillator is
    Generic (size : INTEGER := 1);
    Port ( ro_en : in STD_LOGIC;
           ro_out : out STD_LOGIC);
end ringoscillator;

architecture Behavioral of ringoscillator is

    component inv is
        Port ( I : in STD_LOGIC;
               ZN : out STD_LOGIC);
    end component;
    
    component nand2 is
        Port ( A1 : in STD_LOGIC;
               A2 : in STD_LOGIC;
               ZN : out STD_LOGIC);
    end component;
    
    signal connection : STD_LOGIC_VECTOR (size-1 downto 0);
    
    attribute keep : STRING;
    attribute keep of connection : signal is "true";

begin

    -- inverter chain
    chain: for i in 0 to (size-2) generate
        ro: inv Port Map (connection(i), connection(i+1));
    end generate;

    -- feedback
    nd: nand2 Port Map (connection(size-1), ro_en, connection(0));
 
    -- output
    ro_out <= connection(0);
    
end Behavioral;