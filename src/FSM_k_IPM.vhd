library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FSM_k_IPM is
    Generic (bits : INTEGER := 31;
             d : INTEGER := 2;
             k : INTEGER := 2);
    Port (  clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            coeffs0 : in UNSIGNED ((d-1)*bits-1 downto 0);
            inv_coeff00 : in UNSIGNED (bits-1 downto 0);
            coeffs : in UNSIGNED (k*d*bits-1 downto 0);
            plaintext : in STD_LOGIC_VECTOR (4*bits-1 downto 0);
            key : in STD_LOGIC_VECTOR (4*d*bits-1 downto 0);
            mps_ciphertexts : in UNSIGNED (k*4*d*bits-1 downto 0);
            mps_dones : in STD_LOGIC_VECTOR (k-1 downto 0);
            trv_out : in STD_LOGIC_VECTOR (2*(d-1)*bits-1 downto 0);
            mps_rst : out STD_LOGIC;
            mps_plaintext : out STD_LOGIC_VECTOR (4*d*bits-1 downto 0);
            mps_key : out STD_LOGIC_VECTOR (4*d*bits-1 downto 0);
            trv_rst : out STD_LOGIC;
            trv_en : out STD_LOGIC;
            ciphertext : out UNSIGNED (4*bits-1 downto 0);
            done : out STD_LOGIC);
end FSM_k_IPM;

architecture Behavioral of FSM_k_IPM is

    component MulAddModMersenne is
        Generic ( bits : INTEGER := 31);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : in UNSIGNED (bits-1 downto 0);
               d : out UNSIGNED (bits-1 downto 0));
    end component;
    
    component MulModMersenne is
        Generic ( bits : INTEGER := 31);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : out UNSIGNED (bits-1 downto 0));
    end component;
    
    component SubModMersenne is
        Generic ( bits : INTEGER := 31);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : out UNSIGNED (bits-1 downto 0));
    end component;
    
    signal rnd, maskaddup : UNSIGNED (4*(d-1)*bits-1 downto 0);
    signal lastmask : UNSIGNED (4*bits-1 downto 0);
    signal shared_plaintext : UNSIGNED (4*d*bits-1 downto 0);
    signal shared_ciphertexts : UNSIGNED (k*4*d*bits-1 downto 0);
    signal ciphertexts_t : UNSIGNED (k*4*d*bits-1 downto 0);
    signal ciphertexts : UNSIGNED (k*4*bits-1 downto 0);
    signal ciphertexts_comp : STD_LOGIC_VECTOR (k-2 downto 0);
    
    type states is (S_RNG, S_RND1, S_RND2, S_SHAREINPUTS, S_HOLD, S_ENCRYPT, S_UNSHAREOUTS, S_COMPOUTS, S_IDLE);
    signal state : states;

begin

    MPTw: for i in 0 to 3 generate
        MPTs: for j in 0 to d-2 generate
            shared_plaintext((i*d+j+2)*bits-1 downto (i*d+j+1)*bits) <= rnd((i*(d-1)+j+1)*bits-1 downto (i*(d-1)+j)*bits);
            MAU: if j < (d-2) generate
                MulAdd: MulAddModMersenne Generic Map (bits) Port Map (shared_plaintext((i*d+j+3)*bits-1 downto (i*d+j+2)*bits), coeffs0((j+2)*bits-1 downto (j+1)*bits), maskaddup((i*(d-1)+j+1)*bits-1 downto (i*(d-1)+j)*bits), maskaddup((i*(d-1)+j+2)*bits-1 downto (i*(d-1)+j+1)*bits));
            end generate;
        end generate;
        Mul1: MulModMersenne Generic Map (bits) Port Map (shared_plaintext((i*d+2)*bits-1 downto (i*d+1)*bits), coeffs0(bits-1 downto 0), maskaddup((i*(d-1)+1)*bits-1 downto (i*(d-1))*bits));
        Sub: SubModMersenne Generic Map (bits) Port Map (UNSIGNED(plaintext((i+1)*bits-1 downto i*bits)), maskaddup((i*(d-1)+d-1)*bits-1 downto (i*(d-1)+d-2)*bits), lastmask((i+1)*bits-1 downto i*bits));
        Mul2: MulModMersenne Generic Map (bits) Port Map (lastmask((i+1)*bits-1 downto i*bits), inv_coeff00, shared_plaintext((i*d+1)*bits-1 downto i*d*bits));
    end generate;
    
    UCTk: for r in 0 to k-1 generate
        UCTw: for i in 0 to 3 generate
            Mul: MulModMersenne Generic Map (bits) Port Map (shared_ciphertexts((r*4*d+i*d+1)*bits-1 downto (r*4*d+i*d)*bits), coeffs((r*d+1)*bits-1 downto r*d*bits), ciphertexts_t((r*4*d+i*d+1)*bits-1 downto (r*4*d+i*d)*bits));
            UCTs: for j in 0 to d-2 generate
                MulAdd: MulAddModMersenne Generic Map (bits) Port Map (shared_ciphertexts((r*4*d+i*d+j+2)*bits-1 downto (r*4*d+i*d+j+1)*bits), coeffs((r*d+j+2)*bits-1 downto (r*d+j+1)*bits), ciphertexts_t((r*4*d+i*d+j+1)*bits-1 downto (r*4*d+i*d+j)*bits), ciphertexts_t((r*4*d+i*d+j+2)*bits-1 downto (r*4*d+i*d+j+1)*bits));
            end generate;
            ciphertexts((r*4+i+1)*bits-1 downto (r*4+i)*bits) <= ciphertexts_t((r*4+i+1)*d*bits-1 downto ((r*4+i+1)*d-1)*bits);
        end generate;
    end generate;
    
    CMP: for i in 1 to k-1 generate
        ciphertexts_comp(i-1) <= '1' when (ciphertexts(4*bits-1 downto 0) = ciphertexts((i+1)*4*bits-1 downto i*4*bits)) else '0';
    end generate;

    -- State Machine
    FSM: process(clk)
        variable counter : integer range 0 to 7;
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                mps_rst                                 <= '1';
                trv_rst                                 <= '1';
                trv_en                                  <= '0';
                mps_plaintext                           <= (others => '0');
                mps_key                                 <= (others => '0');
                shared_ciphertexts                      <= (others => '0');
                ciphertext                              <= (others => '0');
                done                                    <= '0';
                counter                                 := 0;
                state                                   <= S_RNG;
            else
                case state is
                
                    when S_RNG =>           trv_rst                                 <= '0';
                                            trv_en                                  <= '1';
                                            counter                                 := counter + 1;
                                            if (counter = 7) then
                                                counter                             := 0;
                                                state                               <= S_RND1;
                                            end if;
                                            
                    when S_RND1 =>          rnd(2*(d-1)*bits-1 downto 0)            <= UNSIGNED(trv_out);
                                            state                                   <= S_RND2;
                                            
                    when S_RND2 =>          rnd(4*(d-1)*bits-1 downto 2*(d-1)*bits) <= UNSIGNED(trv_out);
                                            state                                   <= S_SHAREINPUTS;
                                            
                    when S_SHAREINPUTS =>   mps_plaintext                           <= STD_LOGIC_VECTOR(shared_plaintext);
                                            mps_key                                 <= key;
                                            state                                   <= S_HOLD;
                                            
                    when S_HOLD =>          counter                                 := counter + 1;
                                            if (counter = 7) then
                                                counter                             := 0;
                                                state                               <= S_ENCRYPT;
                                            end if;

                    when S_ENCRYPT =>       mps_rst                                 <= '0';
                                            if (mps_dones = (k-1 downto 0 => '1')) then
                                                state                               <= S_UNSHAREOUTS;
                                            end if;

                    when S_UNSHAREOUTS =>   shared_ciphertexts                      <= mps_ciphertexts;
                                            state                                   <= S_COMPOUTS;

                    when S_COMPOUTS =>      if (ciphertexts_comp = (k-2 downto 0 => '1')) then
                                                ciphertext                          <= ciphertexts(4*bits-1 downto 0);
                                            else
                                                ciphertext                          <= (others => '0');
                                            end if;
                                            state                                   <= S_IDLE;

                    when S_IDLE =>          mps_rst                                 <= '1';
                                            trv_rst                                 <= '1';
                                            trv_en                                  <= '0';
                                            mps_plaintext                           <= (others => '0');
                                            mps_key                                 <= (others => '0');
                                            shared_ciphertexts                      <= (others => '0');
                                            done                                    <= '1';
                                            
                end case;
            end if;
        end if;
    end process;
    
end Behavioral;
