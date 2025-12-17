library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FF_serpar_srst is
    Generic ( ser_bits : INTEGER := 4;
              par_bits : INTEGER := 124);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           sel : in STD_LOGIC;
           ser_inpt : in STD_LOGIC_VECTOR ((ser_bits-1) downto 0);
           par_inpt : in STD_LOGIC_VECTOR ((par_bits-1) downto 0);
           ser_outpt : out STD_LOGIC_VECTOR ((ser_bits-1) downto 0);
           par_outpt : out STD_LOGIC_VECTOR ((par_bits-1) downto 0));
end FF_serpar_srst;

architecture Behavioral of FF_serpar_srst is

    component FF_srst is
        Generic ( bits : INTEGER := 4);
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               inpt : in STD_LOGIC_VECTOR ((bits-1) downto 0);
               outpt : out STD_LOGIC_VECTOR ((bits-1) downto 0));
    end component;
    
    signal par_inpt_t, par_outpt_t : STD_LOGIC_VECTOR ((par_bits-1) downto 0);
    
begin

    par_inpt_t <= par_outpt_t((par_bits-ser_bits-1) downto 0) & ser_inpt when (sel = '0') else par_inpt;
    
    FFreg: FF_srst Generic Map (par_bits) Port Map (clk, rst, en, par_inpt_t, par_outpt_t);
    
    ser_outpt <= par_outpt_t(par_bits-1 downto (par_bits-ser_bits));
    par_outpt <= par_outpt_t;

end Behavioral;