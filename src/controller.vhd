library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity controller is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           core_done : in STD_LOGIC;
           ciphertext_register_parallel_enable : out STD_LOGIC;
           core_rst : out STD_LOGIC;
           core_en : out STD_LOGIC;
           done : out STD_LOGIC);
end controller;

architecture Behavioral of controller is

    type states is (S_RESET, S_COMPUTE, S_OUTPUT, S_DONE);
    signal state : states;

begin

    -- State Machine
    FSM: process(clk)
        variable counter : integer range 0 to 7;
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                ciphertext_register_parallel_enable     <= '0';
                core_rst                                <= '0';
                core_en                                 <= '0';
                done                                    <= '0';
                counter                                 := 0;
                STATE                                   <= S_RESET;
            else
                if (en = '1') then
                    case state is

                        when S_RESET =>         core_rst                                <= '1';
                                                counter                                 := counter + 1;
                                                if (counter = 7) then
                                                    counter                             := 0;
                                                    state                               <= S_COMPUTE;
                                                end if;

                        when S_COMPUTE =>       core_rst                                <= '0';
                                                core_en                                 <= '1';
                                                if (core_done = '1') then
                                                    state                               <= S_OUTPUT;
                                                end if;

                        when S_OUTPUT =>        ciphertext_register_parallel_enable     <= '1';
                                                core_en                                 <= '0';
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
