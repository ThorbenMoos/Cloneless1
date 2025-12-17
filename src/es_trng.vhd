library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity es_trng is
    Generic (bits : INTEGER := 128;
             ro1length : INTEGER := 1;
             ro2length : INTEGER := 3;
             factor : INTEGER := 3);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           outpt : out STD_LOGIC_VECTOR (bits-1 downto 0);
           done : out STD_LOGIC);
end es_trng;

architecture Behavioral of es_trng is

    component trng is
        Generic (ro1length : INTEGER := 1;
                 ro2length : INTEGER := 3);
        Port ( ro1_en : in STD_LOGIC;
               ro2_en : in STD_LOGIC;
               rst : in STD_LOGIC;
               valid : out STD_LOGIC;
               raw_bit : out STD_LOGIC);
    end component;
    
    signal ro1_enable, ro2_enable, trng_reset, valid, raw_bit : STD_LOGIC;
    signal raw_outpt : STD_LOGIC_VECTOR (factor*bits-1 downto 0);
    signal raw_outpt_t : STD_LOGIC_VECTOR ((factor-1)*bits-1 downto 0);

    type states is (S_START, S_ENABLE_OSC1, S_ENABLE_OSC2, S_SAMPLE, S_DONE);
    signal state : states;

begin

    -- instantiate trng
    trng_inst: trng Generic Map (ro1length, ro2length) Port Map (ro1_enable, ro2_enable, trng_reset, valid, raw_bit);

	-- fsm process
    fsm: process(clk)
        variable counter : INTEGER range 0 to 15;
        variable bitcounter : INTEGER range 0 to (factor*bits+1);
    begin
        if rising_edge(clk) then
            if (rst = '1') then

                ro1_enable      <= '0';
                ro2_enable      <= '0';
                trng_reset      <= '1';

                counter         := 0;
                bitcounter      := 0;
                
                raw_outpt      <= (others => '0');
                done            <= '0';
                
                state           <= S_START;

            else
                if (en = '1') then
                    case state is

                        when S_START        =>  ro1_enable          <= '0';
                                                ro2_enable          <= '0';
                                                trng_reset          <= '1';
                                                state               <= S_ENABLE_OSC1;

                        when S_ENABLE_OSC1  =>  ro1_enable          <= '1';
                                                trng_reset          <= '0';
                                                counter             := counter + 1;
                                                if (counter = 15) then
                                                    counter         := 0;
                                                    state           <= S_ENABLE_OSC2;
                                                end if;

                        when S_ENABLE_OSC2  =>  ro2_enable          <= '1';
                                                state               <= S_SAMPLE;

                        when S_SAMPLE       =>  if (valid = '1') then
                                                    raw_outpt(bitcounter) <= raw_bit;
                                                    bitcounter      := bitcounter + 1;
                                                    if (bitcounter = (factor*bits+1)) then
                                                        state       <= S_DONE;
                                                    else
                                                        state       <= S_START;
                                                    end if;
                                                end if;

                        when S_DONE         =>  ro1_enable          <= '0';
                                                ro2_enable          <= '0';
                                                bitcounter          := 0;
                                                done                <= '1';

                    end case;
                end if;
            end if;
        end if;
    end process;

    com_se11: if (factor = 1) generate
        outpt <= raw_outpt;
    end generate;
    com_se1n: if (factor > 1) generate
        -- combine multiple consecutive raw output bits into one output bit
        gen: for i in 0 to bits-1 generate
            raw_outpt_t((factor-1)*i) <= raw_outpt(factor*i) XOR raw_outpt(factor*i+1);
            com: for j in 0 to factor-3 generate
                raw_outpt_t((factor-1)*i+j+1) <= raw_outpt_t((factor-1)*i+j) XOR raw_outpt(factor*i+j+2);
            end generate;
            outpt(i) <= raw_outpt_t((factor-1)*(i+1)-1);
        end generate;
    end generate;
    
end Behavioral;
