library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity maj7 is
    Generic (bits : INTEGER := 128);
    Port ( a : in STD_LOGIC_VECTOR (bits-1 downto 0);
           b : in STD_LOGIC_VECTOR (bits-1 downto 0);
           c : in STD_LOGIC_VECTOR (bits-1 downto 0);
           d : in STD_LOGIC_VECTOR (bits-1 downto 0);
           e : in STD_LOGIC_VECTOR (bits-1 downto 0);
           f : in STD_LOGIC_VECTOR (bits-1 downto 0);
           g : in STD_LOGIC_VECTOR (bits-1 downto 0);
           h : out STD_LOGIC_VECTOR (bits-1 downto 0));
end maj7;

architecture Behavioral of maj7 is

    component maj3 is
        Generic (bits : INTEGER := 128);
        Port ( a : in STD_LOGIC_VECTOR (bits-1 downto 0);
               b : in STD_LOGIC_VECTOR (bits-1 downto 0);
               c : in STD_LOGIC_VECTOR (bits-1 downto 0);
               d : out STD_LOGIC_VECTOR (bits-1 downto 0));
    end component;

    signal mo1, mo2, mo3, mo4, mo5, mo6 : STD_LOGIC_VECTOR (bits-1 downto 0);

begin

    m1: maj3 Generic Map (bits) Port Map (a, c, d, mo1);
    m2: maj3 Generic Map (bits) Port Map (e, f, g, mo2);
    m3: maj3 Generic Map (bits) Port Map (f, g, mo1, mo3);
    m4: maj3 Generic Map (bits) Port Map (a, c, mo2, mo4);
    m5: maj3 Generic Map (bits) Port Map (e, mo1, mo3, mo5);
    m6: maj3 Generic Map (bits) Port Map (d, mo2, mo4, mo6);
    m7: maj3 Generic Map (bits) Port Map (b, mo5, mo6, h);

end Behavioral;