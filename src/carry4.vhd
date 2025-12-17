library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity carry4 is
    Port ( co : out STD_LOGIC_VECTOR (3 downto 0);
           o : out STD_LOGIC_VECTOR (3 downto 0);
           di : in STD_LOGIC_VECTOR (3 downto 0);
           se : in STD_LOGIC_VECTOR (3 downto 0));
end carry4;

architecture Behavioral of carry4 is
    
    component xor2 is
        Port ( A1 : in STD_LOGIC;
               A2 : in STD_LOGIC;
               Z : out STD_LOGIC);
    end component;
    
    component mux2 is
        Port ( I0 : in STD_LOGIC;
               I1 : in STD_LOGIC;
               S : in STD_LOGIC;
               Z : out STD_LOGIC);
    end component;
    
    signal co_t, o_t : STD_LOGIC_VECTOR (3 downto 0);
    
    attribute keep : STRING;
    attribute keep of co_t, o_t : signal is "true";
    
begin
    
    m1: mux2 Port Map (di(0), '0', se(0), co_t(0));
    m2: mux2 Port Map (di(1), co_t(0), se(1), co_t(1));
    m3: mux2 Port Map (di(2), co_t(1), se(2), co_t(2));
    m4: mux2 Port Map (di(3), co_t(2), se(3), co_t(3));
    
    x1: xor2 Port Map (se(0), '0', o_t(0));
    x2: xor2 Port Map (se(1), co_t(0), o_t(1));
    x3: xor2 Port Map (se(2), co_t(1), o_t(2));
    x4: xor2 Port Map (se(3), co_t(2), o_t(3));
    
    co  <= co_t;
    o   <= o_t;

end Behavioral;
