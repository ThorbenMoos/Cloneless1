library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity maj5 is
    Generic (bits : INTEGER := 128);
    Port ( a : in STD_LOGIC_VECTOR (bits-1 downto 0);
           b : in STD_LOGIC_VECTOR (bits-1 downto 0);
           c : in STD_LOGIC_VECTOR (bits-1 downto 0);
           d : in STD_LOGIC_VECTOR (bits-1 downto 0);
           e : in STD_LOGIC_VECTOR (bits-1 downto 0);
           f : out STD_LOGIC_VECTOR (bits-1 downto 0));
end maj5;

architecture Behavioral of maj5 is

    component maj3 is
        Generic (bits : INTEGER := 128);
        Port ( a : in STD_LOGIC_VECTOR (bits-1 downto 0);
               b : in STD_LOGIC_VECTOR (bits-1 downto 0);
               c : in STD_LOGIC_VECTOR (bits-1 downto 0);
               d : out STD_LOGIC_VECTOR (bits-1 downto 0));
    end component;
    
    signal mo1, mo2, mo3 : STD_LOGIC_VECTOR (bits-1 downto 0);

begin

    m1: maj3 Generic Map (bits) Port Map (c, d, e, mo1);
    m2: maj3 Generic Map (bits) Port Map (b, d, e, mo2);
    m3: maj3 Generic Map (bits) Port Map (b, c, mo2, mo3);
    m4: maj3 Generic Map (bits) Port Map (a, mo1, mo3, f);

end Behavioral;