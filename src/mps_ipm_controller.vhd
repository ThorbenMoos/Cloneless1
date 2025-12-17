library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mps_ipm_controller is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           core_done : in STD_LOGIC;
           trng_puf_config : in STD_LOGIC_VECTOR (1 downto 0);
           seed : in STD_LOGIC_VECTOR (159 downto 0);
           const_key : in STD_LOGIC_VECTOR (247 downto 0);
           trv_keys : out STD_LOGIC_VECTOR (159 downto 0);
           key : out STD_LOGIC_VECTOR (247 downto 0);
           ciphertext_register_parallel_enable : out STD_LOGIC;
           core_rst : out STD_LOGIC;
           done : out STD_LOGIC);
end mps_ipm_controller;

architecture Behavioral of mps_ipm_controller is

    component es_trng is
        Generic (bits : INTEGER := 128;
                 ro1length : INTEGER := 1;
                 ro2length : INTEGER := 3;
                 factor : INTEGER := 3);
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               outpt : out STD_LOGIC_VECTOR (bits-1 downto 0);
               done : out STD_LOGIC);
    end component;

    component ro_puf is
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
    end component;
    
    signal ipm_estrng_rst, ipm_estrng_en, ipm_estrng_done, ipm_estrng1_done, ipm_estrng2_done : STD_LOGIC;
    signal ipm_ropuf_rst, ipm_ropuf_en, ipm_ropuf_done, ipm_ropuf1_done, ipm_ropuf2_done : STD_LOGIC;
    signal ipm_estrng1_outpt, ipm_estrng2_outpt : STD_LOGIC_VECTOR (79 downto 0);
    signal ipm_ropuf1_outpt, ipm_ropuf2_outpt : STD_LOGIC_VECTOR (15 downto 0);
    
    type states is (S_RESET, S_TRNG, S_PUF, S_COMPUTE, S_OUTPT, S_DONE);
    signal state : states;

begin

    ESTRNG1: es_trng Generic Map (80, 23, 47, 3) Port Map (clk, ipm_estrng_rst, ipm_estrng_en, ipm_estrng1_outpt, ipm_estrng1_done);
    ESTRNG2: es_trng Generic Map (80, 23, 47, 3) Port Map (clk, ipm_estrng_rst, ipm_estrng_en, ipm_estrng2_outpt, ipm_estrng2_done);
    ipm_estrng_done <= ipm_estrng1_done AND ipm_estrng2_done;
    
    ROPUF1: ro_puf Generic Map (16, 4, 47, 16383, 7) Port Map (clk, ipm_ropuf_rst, ipm_ropuf_en, ipm_ropuf1_outpt, ipm_ropuf1_done);
    ROPUF2: ro_puf Generic Map (16, 4, 47, 16383, 7) Port Map (clk, ipm_ropuf_rst, ipm_ropuf_en, ipm_ropuf2_outpt, ipm_ropuf2_done);
    ipm_ropuf_done <= ipm_ropuf1_done AND ipm_ropuf2_done;

    -- State Machine
    FSM: process(clk)
        variable counter : integer range 0 to 7;
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                ipm_estrng_rst                          <= '0';
                ipm_estrng_en                           <= '0';
                ipm_ropuf_rst                           <= '0';
                ipm_ropuf_en                            <= '0';
                trv_keys                                <= (others => '0');
                key                                     <= (others => '0');
                ciphertext_register_parallel_enable     <= '0';
                core_rst                                <= '0';
                done                                    <= '0';
                counter                                 := 0;
                STATE                                   <= S_RESET;
            else
                if (en = '1') then
                    case state is

                        when S_RESET =>         core_rst                                <= '1';
                                                ipm_estrng_rst                          <= '1';
                                                ipm_ropuf_rst                           <= '1';
                                                counter                                 := counter + 1;
                                                if (counter = 7) then
                                                    counter                             := 0;
                                                    if (trng_puf_config = "00") then
                                                        trv_keys                        <= seed;
                                                        key                             <= const_key;
                                                        state                           <= S_COMPUTE;
                                                    elsif (trng_puf_config(0) = '1') then
                                                        state                           <= S_TRNG;
                                                    elsif (trng_puf_config(1) = '1') then
                                                        trv_keys                        <= seed;
                                                        state                           <= S_PUF;
                                                    end if;
                                                end if;

                        when S_TRNG =>          ipm_estrng_rst                          <= '0';
                                                ipm_estrng_en                           <= '1';
                                                if (ipm_estrng_done = '1') then
                                                    ipm_estrng_en                       <= '0';
                                                    trv_keys                            <= ipm_estrng1_outpt & ipm_estrng2_outpt;
                                                    if (trng_puf_config(1) = '1') then
                                                        state                           <= S_PUF;
                                                    else
                                                        key                             <= const_key;
                                                        state                           <= S_COMPUTE;
                                                    end if;
                                                end if;

                        when S_PUF =>           ipm_ropuf_rst                           <= '0';
                                                ipm_ropuf_en                            <= '1';
                                                if (ipm_ropuf_done = '1') then
                                                    ipm_ropuf_en                        <= '0';
                                                    key                                 <=  const_key(247 downto 221) & ipm_ropuf1_outpt(15 downto 12) & const_key(216 downto 190) & ipm_ropuf1_outpt(11 downto 8) & const_key(185 downto 159) & ipm_ropuf1_outpt(7 downto 4) & const_key(154 downto 128) & ipm_ropuf1_outpt(3 downto 0) & const_key(123 downto 97) & ipm_ropuf2_outpt(15 downto 12) & const_key(92 downto 66) & ipm_ropuf2_outpt(11 downto 8) & const_key(61 downto 35) & ipm_ropuf2_outpt(7 downto 4) & const_key(30 downto 4) & ipm_ropuf2_outpt(3 downto 0);
                                                    state                               <= S_COMPUTE;
                                                end if;

                        when S_COMPUTE =>       core_rst                                <= '0';
                                                if (core_done = '1') then
                                                    state                               <= S_OUTPT;
                                                end if;

                        when S_OUTPT =>         ciphertext_register_parallel_enable     <= '1';
                                                counter                                 := counter + 1;
                                                if (counter = 3) then
                                                    counter                             := 0;
                                                    state                               <= S_DONE;
                                                end if;

                        when S_DONE =>          ciphertext_register_parallel_enable     <= '0';
                                                done                                    <= '1';

                    end case;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
