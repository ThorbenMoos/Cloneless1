library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_Cloneless_mid_pSquare_dSHARES_IPM_kRED is
end TB_Cloneless_mid_pSquare_dSHARES_IPM_kRED;

architecture Behavioral of TB_Cloneless_mid_pSquare_dSHARES_IPM_kRED is

    component Cloneless is
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               read : in STD_LOGIC;
               write : in STD_LOGIC;
               address : in STD_LOGIC_VECTOR (2 downto 0);
               data_in : in STD_LOGIC_VECTOR (3 downto 0);
               data_out : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
    
    type states is (S_RESET, S_CONFIG, S_PLAINTEXT, S_SEED, S_STARTCORE, S_READSTATUS, S_ADDRCHANGE, S_READRESULT, S_CHECK, S_FINAL);
    signal state : states := S_RESET;
    
    signal clk, rst, read, write : STD_LOGIC;
    signal address : STD_LOGIC_VECTOR (2 downto 0);
    signal data_in, data_out : STD_LOGIC_VECTOR (3 downto 0);
    signal plaintext, ciphertext : STD_LOGIC_VECTOR (123 downto 0);
    signal seed : STD_LOGIC_VECTOR (159 downto 0);
    constant clk_period : time := 10 ns;
    
begin
    
    -- Unit Under Test
    UUT: Cloneless Port Map (clk, rst, read, write, address, data_in, data_out);
    
    -- Test Vector
    plaintext   <= x"F00CDAD7A2893AD16895566C2BB7DF4";
    seed        <= x"C4C1E9A9DB026CCA5B1F2835A77D200C2F1197C4";
    
    -- Clock Process
    clk_proc: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    -- Stimulation Process
    stim_proc: process(clk)
        variable counter : integer range 0 to 40;
    begin
        if rising_edge(clk) then
            case state is

                when S_RESET =>         rst                                     <= '1';
                                        read                                    <= '0';
                                        write                                   <= '0';
                                        address                                 <= "000";
                                        data_in                                 <= "0000";
                                        ciphertext                              <= (others => '0');
                                        counter                                 := 0;
                                        state                                   <= S_CONFIG;

                when S_CONFIG =>        rst                                     <= '0';
                                        write                                   <= '1';
                                        data_in                                 <= "1000";
                                        state                                   <= S_PLAINTEXT;

                when S_PLAINTEXT =>     address                                 <= "010";
                                        data_in                                 <= plaintext(123-counter*4 downto 120-counter*4);
                                        counter                                 := counter + 1;
                                        if (counter = 31) then
                                            counter                             := 0;
                                            state                               <= S_SEED;
                                        end if;

                when S_SEED =>          address                                 <= "011";
                                        data_in                                 <= seed(159-counter*4 downto 156-counter*4);
                                        counter                                 := counter + 1;
                                        if (counter = 40) then
                                            counter                             := 0;
                                            state                               <= S_STARTCORE;
                                        end if;

                when S_STARTCORE =>     address                                 <= "000";
                                        data_in                                 <= "0100";
                                        state                                   <= S_READSTATUS;

                when S_READSTATUS =>    read                                    <= '1';
                                        write                                   <= '0';
                                        address                                 <= "100";
                                        if (data_out(3) = '1') then
                                            state                               <= S_ADDRCHANGE;
                                        end if;

                when S_ADDRCHANGE =>    address                                 <= "101";
                                        state                                   <= S_READRESULT;

                when S_READRESULT =>    ciphertext(123-counter*4 downto 120-counter*4) <= data_out;
                                        counter                                 := counter + 1;
                                        if (counter = 31) then
                                            counter                             := 0;
                                            state                               <= S_CHECK;
                                        end if;

                when S_CHECK =>         read                                    <= '0';
                                        address                                 <= "000";
                                        data_in                                 <= "0000";
                                        if (ciphertext = x"1D209E842606FF65984DCD619F408FF") then
                                            report "SUCCESS";
                                        else
                                            report "FAILURE";
                                        end if;
                                        state                                   <= S_FINAL;

                when S_FINAL =>         rst                                     <= '1';

            end case;
        end if;
    end process;

end Behavioral;
