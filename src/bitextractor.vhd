library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bitextractor is
    Port ( ro2_out : in STD_LOGIC;
           rst : in STD_LOGIC;
           stage : in STD_LOGIC_VECTOR (2 downto 0);
           valid : out STD_LOGIC;
           raw_bit : out STD_LOGIC);
end bitextractor;

architecture Behavioral of bitextractor is
    
    component FF_arst is
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               inpt : in STD_LOGIC;
               outpt : out STD_LOGIC);
    end component;
                   
    signal connection : STD_LOGIC_VECTOR (10 downto 0);
    
    attribute keep : STRING;
    attribute keep of connection : signal is "true";

begin
    
    connection(0) <= stage(0);
    connection(1) <= stage(1);
    connection(2) <= stage(2);
    
    connection(3) <= connection(2) XOR connection(1);
    connection(4) <= NOT (connection(1) XOR connection(0));
    connection(5) <= connection(3) OR connection(4);
    connection(6) <= connection(5) when (connection(10) = '0') else connection(9);
    
    ff1: FF_arst Port Map (ro2_out, rst, '1', connection(6), connection(9));
    
    connection(7) <= connection(0) XOR connection(2);
    connection(8) <= connection(7) OR connection(10);
    
    ff2: FF_arst Port Map (ro2_out, rst, '1', connection(8), connection(10));
    
    raw_bit <= connection(9);
    valid <= connection(10);
    
end Behavioral;