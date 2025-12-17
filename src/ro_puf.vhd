library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ro_puf is
    Generic (bits : INTEGER := 128;
             parallel : INTEGER := 32;
             rolength : INTEGER := 1;
             cycles : INTEGER := 3000;
             factor : INTEGER := 3);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           outpt : out STD_LOGIC_VECTOR (bits-1 downto 0);
           done : out STD_LOGIC);
end ro_puf;

architecture Behavioral of ro_puf is

    component ro_puf_cell is
        Generic (rolength : INTEGER := 1;
                 cycles : INTEGER := 3000);
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               raw_bit : out STD_LOGIC;
               done : out STD_LOGIC);
    end component;
    
    component maj3 is
        Generic (bits : INTEGER := 128);
        Port ( a : in STD_LOGIC_VECTOR (bits-1 downto 0);
               b : in STD_LOGIC_VECTOR (bits-1 downto 0);
               c : in STD_LOGIC_VECTOR (bits-1 downto 0);
               d : out STD_LOGIC_VECTOR (bits-1 downto 0));
    end component;
    
    component maj5 is
        Generic (bits : INTEGER := 128);
        Port ( a : in STD_LOGIC_VECTOR (bits-1 downto 0);
               b : in STD_LOGIC_VECTOR (bits-1 downto 0);
               c : in STD_LOGIC_VECTOR (bits-1 downto 0);
               d : in STD_LOGIC_VECTOR (bits-1 downto 0);
               e : in STD_LOGIC_VECTOR (bits-1 downto 0);
               f : out STD_LOGIC_VECTOR (bits-1 downto 0));
    end component;
    
    component maj7 is
        Generic (bits : INTEGER := 128);
        Port ( a : in STD_LOGIC_VECTOR (bits-1 downto 0);
               b : in STD_LOGIC_VECTOR (bits-1 downto 0);
               c : in STD_LOGIC_VECTOR (bits-1 downto 0);
               d : in STD_LOGIC_VECTOR (bits-1 downto 0);
               e : in STD_LOGIC_VECTOR (bits-1 downto 0);
               f : in STD_LOGIC_VECTOR (bits-1 downto 0);
               g : in STD_LOGIC_VECTOR (bits-1 downto 0);
               h : out STD_LOGIC_VECTOR (bits-1 downto 0));
    end component;
    
    component FF_serpar_srst is
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
    end component;
    
    signal rst_group, en_group, done_group : STD_LOGIC_VECTOR ((bits/parallel)-1 downto 0);
    signal long_done, raw_outpt : STD_LOGIC_VECTOR (bits-1 downto 0);
    signal raw_outpt_storage : STD_LOGIC_VECTOR (factor*bits-1 downto 0);
    signal raw_outpt_storage_en : STD_LOGIC;

begin

    ser_cells: for i in 0 to (bits/parallel)-1 generate
        par_cells: for j in 0 to parallel-1 generate
            cell: ro_puf_cell Generic Map (rolength, cycles) Port Map (clk, rst_group(i), en_group(i), raw_outpt(i*parallel+j), long_done(i*parallel+j));
        end generate;
        done_group(i) <= '1' when (long_done((i+1)*parallel-1 downto i*parallel) = (parallel-1 downto 0 => '1')) else '0';
    end generate;
    
    maj_sel1: if (factor = 1) generate
        outpt <= raw_outpt_storage;
    end generate;
    maj_sel3: if (factor = 3) generate
        maj: maj3 Generic Map (bits) Port Map (raw_outpt_storage(bits-1 downto 0), raw_outpt_storage(2*bits-1 downto bits), raw_outpt_storage(3*bits-1 downto 2*bits), outpt);
    end generate;
    maj_sel5: if (factor = 5) generate
        maj: maj5 Generic Map (bits) Port Map (raw_outpt_storage(bits-1 downto 0), raw_outpt_storage(2*bits-1 downto bits), raw_outpt_storage(3*bits-1 downto 2*bits), raw_outpt_storage(4*bits-1 downto 3*bits), raw_outpt_storage(5*bits-1 downto 4*bits), outpt);
    end generate;
    maj_sel7: if (factor = 7) generate
        maj: maj7 Generic Map (bits) Port Map (raw_outpt_storage(bits-1 downto 0), raw_outpt_storage(2*bits-1 downto bits), raw_outpt_storage(3*bits-1 downto 2*bits), raw_outpt_storage(4*bits-1 downto 3*bits), raw_outpt_storage(5*bits-1 downto 4*bits), raw_outpt_storage(6*bits-1 downto 5*bits), raw_outpt_storage(7*bits-1 downto 6*bits), outpt);
    end generate;
    
    col_raw_out: FF_serpar_srst Generic Map (bits, factor*bits) Port Map (clk, rst, raw_outpt_storage_en, '0', raw_outpt, (others => '0'), open, raw_outpt_storage);

	-- fsm process
    fsm: process(clk)
        variable ser_cnt : INTEGER range 0 to (bits/parallel)-1;
        variable fac_cnt : INTEGER range 0 to factor-1;
        variable doneflag : INTEGER range 0 to 1;
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                rst_group                               <= (others => '1');
                en_group                                <= (others => '0');
                ser_cnt                                 := 0;
                fac_cnt                                 := 0;
                doneflag                                := 0;
                raw_outpt_storage_en                   <= '0';
                done                                    <= '0';
            else
                if (en = '1' AND doneflag = 0) then
                    rst_group(ser_cnt)                  <= '0';
                    en_group(ser_cnt)                   <= '1';
                    if (done_group(ser_cnt) = '1') then
                        en_group(ser_cnt)               <= '0';
                        if (ser_cnt < ((bits/parallel)-1)) then
                            raw_outpt_storage_en       <= '1';
                            ser_cnt                     := ser_cnt + 1;
                        else
                            if (fac_cnt < (factor-1)) then
                                raw_outpt_storage_en   <= '0';
                                ser_cnt                 := 0;
                                fac_cnt                 := fac_cnt + 1;
                            else
                                done                    <= '1';
                                doneflag                := 1;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;
