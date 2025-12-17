library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mid_pSquare_dSHARES_IPM is
    Generic (bits : INTEGER := 31;
             d : INTEGER := 2);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           coefficients : in UNSIGNED (d*bits-1 downto 0);
           coef0_inverse : in UNSIGNED (bits-1 downto 0);
           plaintext : in UNSIGNED (4*d*bits-1 downto 0);
           key : in UNSIGNED (4*d*bits-1 downto 0);
           fresh_randomness : in UNSIGNED (d*(d-1)*bits-1 downto 0);
           ciphertext : out UNSIGNED (4*d*bits-1 downto 0);
           done : out STD_LOGIC);
end mid_pSquare_dSHARES_IPM;

architecture Behavioral of mid_pSquare_dSHARES_IPM is
    
    component SQ_dSHARE_IPM is
        Generic (bits : INTEGER := 31;
                 d : INTEGER := 2);
        Port ( clk : in STD_LOGIC;
               en : in STD_LOGIC;
               a : in UNSIGNED (d*bits-1 downto 0);
               c : in UNSIGNED (d*bits-1 downto 0);
               r : in UNSIGNED (d*(d-1)*bits-1 downto 0);
               b : out UNSIGNED (d*bits-1 downto 0));
    end component;
    
    component AddModMersenne is
        Generic ( bits : INTEGER := 31);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : out UNSIGNED (bits-1 downto 0));
    end component;
    
    component MulAddModMersenne is
        Generic ( bits : INTEGER := 31);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : in UNSIGNED (bits-1 downto 0);
               d : out UNSIGNED (bits-1 downto 0));
    end component;
    
    component FF is
        Generic ( bits : INTEGER := 31);
        Port ( clk : in STD_LOGIC;
               en : in STD_LOGIC;
               inpt : in UNSIGNED ((bits-1) downto 0);
               outpt : out UNSIGNED ((bits-1) downto 0));
    end component;
    
    signal round_input, round_tweakey_input, art_output, round_output, round_reg1, round_reg2, round_reg3, round_reg4 : UNSIGNED (4*d*bits-1 downto 0);
    signal sq_in, sq_out, sq1_in, sq1_in_reg1, sq1_in_reg2, mds_in, mds_low, mds_high, mds_high_reg1, mds_high_reg2, sq2_in, sq2_in_reg1, sq2_in_reg2, f_out_high : UNSIGNED (d*bits-1 downto 0);
    signal round_constants1, round_constants2, round_constants2_reg1, round_constants2_reg2 : UNSIGNED (bits-1 downto 0);
    constant r : UNSIGNED(bits-1 downto 0) := ("011" & x"FFFFFFF");
    constant pi : STD_LOGIC_VECTOR(63 downto 0) := x"C90FDAA22168C234";
    signal rot_pi : STD_LOGIC_VECTOR(63 downto 0);
    signal tweakey_active, reg_enable, sq_select : STD_LOGIC;

begin

    -- Round-Input and Round-Tweakey Addition
    ARK_words: for i in 0 to 3 generate
        ARK_shares: for j in 0 to d-1 generate
            ADD: AddModMersenne Generic Map (bits) Port Map (round_input((i*d+j+1)*bits-1 downto (i*d+j)*bits), round_tweakey_input((i*d+j+1)*bits-1 downto (i*d+j)*bits), art_output((i*d+j+1)*bits-1 downto (i*d+j)*bits));
        end generate;
   end generate;
    
    -- Round-Constant Partitioning and Addition
    round_constants1 <= unsigned(rot_pi(bits-1 downto 0));
    round_constants2 <= unsigned(rot_pi(32+bits-1 downto 32));
    ADDrc1: MulAddModMersenne Generic Map (bits) Port Map (round_constants1, coef0_inverse, art_output((d*2+1)*bits-1 downto d*2*bits), sq1_in(bits-1 downto 0));
    sq1_in(d*bits-1 downto bits) <= art_output(d*3*bits-1 downto (d*2+1)*bits);
    FF1: FF Generic Map (bits) Port Map (clk, reg_enable, sq1_in(bits-1 downto 0), sq1_in_reg1(bits-1 downto 0));
    sq1_in_reg1(d*bits-1 downto bits) <= round_reg1(d*3*bits-1 downto (d*2+1)*bits);
    FF2: FF Generic Map (bits) Port Map (clk, reg_enable, sq1_in_reg1(bits-1 downto 0), sq1_in_reg2(bits-1 downto 0));
    sq1_in_reg2(d*bits-1 downto bits) <= round_reg2(d*3*bits-1 downto (d*2+1)*bits);
    FF3: FF Generic Map (bits) Port Map (clk, reg_enable, round_constants2, round_constants2_reg1);
    FF4: FF Generic Map (bits) Port Map (clk, reg_enable, round_constants2_reg1, round_constants2_reg2);
    ADDrc2: MulAddModMersenne Generic Map (bits) Port Map (round_constants2_reg2, coef0_inverse, mds_low(bits-1 downto 0), sq2_in(bits-1 downto 0));
    sq2_in(d*bits-1 downto bits) <= mds_low(d*bits-1 downto bits);
    
    -- F-Function
    sq_in <= sq1_in when (sq_select = '0') else sq2_in;
    SQ: SQ_dSHARE_IPM Generic Map (bits, d) Port Map (clk, reg_enable, sq_in, coefficients, fresh_randomness, sq_out);
    MDS: for i in 0 to d-1 generate
        ADD_f1: AddModMersenne Generic Map (bits) Port Map (sq_out((i+1)*bits-1 downto i*bits), round_reg2((d*3+i+1)*bits-1 downto (d*3+i)*bits), mds_in((i+1)*bits-1 downto i*bits));
        ADD_f2: AddModMersenne Generic Map (bits) Port Map (mds_in((i+1)*bits-1 downto i*bits), sq1_in_reg2((i+1)*bits-1 downto i*bits), mds_low((i+1)*bits-1 downto i*bits));
        ADD_f3: AddModMersenne Generic Map (bits) Port Map (mds_low((i+1)*bits-1 downto i*bits), mds_in((i+1)*bits-1 downto i*bits), mds_high((i+1)*bits-1 downto i*bits));
        ADD_f4: AddModMersenne Generic Map (bits) Port Map (mds_high_reg2((i+1)*bits-1 downto i*bits), sq_out((i+1)*bits-1 downto i*bits), f_out_high((i+1)*bits-1 downto i*bits));
        ADD_f5: AddModMersenne Generic Map (bits) Port Map (round_reg4((d+i+1)*bits-1 downto (d+i)*bits), sq2_in_reg2((i+1)*bits-1 downto i*bits), round_output((d*3+i+1)*bits-1 downto (d*3+i)*bits));
        ADD_f6: AddModMersenne Generic Map (bits) Port Map (round_reg4((i+1)*bits-1 downto i*bits), f_out_high((i+1)*bits-1 downto i*bits), round_output((d*2+i+1)*bits-1 downto (d*2+i)*bits));
        FF_f1: FF Generic Map (bits) Port Map (clk, reg_enable, mds_high((i+1)*bits-1 downto i*bits), mds_high_reg1((i+1)*bits-1 downto i*bits));
        FF_f2: FF Generic Map (bits) Port Map (clk, reg_enable, mds_high_reg1((i+1)*bits-1 downto i*bits), mds_high_reg2((i+1)*bits-1 downto i*bits));
        FF_f3: FF Generic Map (bits) Port Map (clk, reg_enable, sq2_in((i+1)*bits-1 downto i*bits), sq2_in_reg1((i+1)*bits-1 downto i*bits));
        FF_f4: FF Generic Map (bits) Port Map (clk, reg_enable, sq2_in_reg1((i+1)*bits-1 downto i*bits), sq2_in_reg2((i+1)*bits-1 downto i*bits));
    end generate;
    round_output(d*2*bits-1 downto 0) <= round_reg4(d*4*bits-1 downto d*2*bits);
    
    -- Round Tweakey Addition only active every N_r Rounds
    round_tweakey_input <= key when (tweakey_active = '1') else (others => '0');

    -- Round Input Mux
    round_input <= plaintext when (rst = '1') else round_output;
    
    -- State Machine
    FSM: process(clk)
        variable stepcounter : integer range 0 to 15;
        variable roundcounter : integer range 0 to 13;
        variable doneflag : integer range 0 to 1;
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                round_reg1                      <= art_output;
                round_reg2                      <= round_reg1;
                round_reg3                      <= round_reg2;
                round_reg4                      <= round_reg3;
                rot_pi                          <= pi;
                stepcounter                     := 0;
                roundcounter                    := 0;
                doneflag                        := 0;
                done                            <= '0';
                tweakey_active                  <= '1';
                reg_enable                      <= '1';
                sq_select                       <= '0';
                ciphertext                      <= (others => '0');
            else
                if(doneflag = 0) then
                    round_reg1                  <= art_output;
                    round_reg2                  <= round_reg1;
                    round_reg3                  <= round_reg2;
                    round_reg4                  <= round_reg3;
                    reg_enable                  <= '1';
                    if ((stepcounter mod 2) = 0) then
                        sq_select               <= sq_select XOR '1';
                        if (sq_select = '1') then
                            rot_pi              <= rot_pi(62 downto 0) & rot_pi(63);
                        end if;
                    end if;
                    if (stepcounter < 12) then
                        stepcounter             := stepcounter + 1;
                        tweakey_active          <= '0';
                    else
                        if (stepcounter < 14) then
                            stepcounter         := stepcounter + 1;
                            tweakey_active      <= '1';
                        elsif (stepcounter = 14) then
                            stepcounter         := stepcounter + 1;
                            if (roundcounter = 13) then
                                done            <= '1';
                                reg_enable      <= '0';
                                doneflag        := 1;
                            end if;
                        else
                            if (roundcounter < 13) then
                                stepcounter     := 0;
                                roundcounter    := roundcounter + 1;
                            end if;
                        end if;
                    end if;
                else
                    ciphertext                  <= art_output;
                end if;
            end if;
        end if;
    end process;

end Behavioral;