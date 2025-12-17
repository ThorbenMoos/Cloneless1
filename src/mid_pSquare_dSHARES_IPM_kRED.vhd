library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mid_pSquare_dSHARES_IPM_kRED is
    Generic (bits : INTEGER := 31;
             d : INTEGER := 2;
             k : INTEGER := 2);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           coeffs : in STD_LOGIC_VECTOR (k*d*bits-1 downto 0);
           inv_coeffs : in STD_LOGIC_VECTOR (k*d*bits-1 downto 0);
           plaintext : in STD_LOGIC_VECTOR (4*bits-1 downto 0);
           key : in STD_LOGIC_VECTOR (4*d*bits-1 downto 0);
           trv_keys : in STD_LOGIC_VECTOR (k*80-1 downto 0);
           trv_ivs : in STD_LOGIC_VECTOR (k*80-1 downto 0);
           ciphertext : out STD_LOGIC_VECTOR (4*bits-1 downto 0);
           done : out STD_LOGIC);
end mid_pSquare_dSHARES_IPM_kRED;

architecture Behavioral of mid_pSquare_dSHARES_IPM_kRED is

    component mid_pSquare_dSHARES_IPM is
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
    end component;
    
    component Trivium is
        Generic (output_bits : INTEGER := 64);
        Port (  clk : in STD_LOGIC;
                rst : in STD_LOGIC;
                en : in STD_LOGIC;
                key : in STD_LOGIC_VECTOR (79 downto 0);
                iv : in STD_LOGIC_VECTOR (79 downto 0);
                stream_out : out STD_LOGIC_VECTOR (output_bits-1 downto 0));
    end component;
    
    component FSM_k_IPM is
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
    end component;
    
    component MulModMersenne is
        Generic ( bits : INTEGER := 31);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : out UNSIGNED (bits-1 downto 0));
    end component;
    
    signal mps_plaintexts, mps_keys : STD_LOGIC_VECTOR (k*4*d*bits-1 downto 0);
    signal mps_ciphertexts : UNSIGNED (k*4*d*bits-1 downto 0);
    signal mps_rsts, mps_dones : STD_LOGIC_VECTOR (k-1 downto 0);
    signal trv_outs : STD_LOGIC_VECTOR (k*d*(d-1)*bits-1 downto 0);
    signal trv_rsts, trv_ens : STD_LOGIC_VECTOR (k-1 downto 0);
    
    signal fsm_ciphertexts : UNSIGNED (k*4*bits-1 downto 0);
    signal fsm_ciphertexts_comp : STD_LOGIC_VECTOR (k-2 downto 0);
    signal fsm_dones : STD_LOGIC_VECTOR (k-1 downto 0);
    
    signal keys : UNSIGNED (k*4*d*bits-1 downto 0);
    signal coicos : UNSIGNED ((k-1)*d*bits-1 downto 0);
    
    signal ciphertext_reg : STD_LOGIC_VECTOR (4*bits-1 downto 0);
    signal done_reg : STD_LOGIC;
    
begin

    RED: for i in 0 to k-1 generate
        MPSs: mid_pSquare_dSHARES_IPM Generic Map (bits, d) Port Map (clk, mps_rsts(i), UNSIGNED(coeffs((i+1)*d*bits-1 downto i*d*bits)), UNSIGNED(inv_coeffs((i*d+1)*bits-1 downto i*d*bits)), UNSIGNED(mps_plaintexts((i+1)*4*d*bits-1 downto i*4*d*bits)), UNSIGNED(mps_keys((i+1)*4*d*bits-1 downto i*4*d*bits)), UNSIGNED(trv_outs((i+1)*d*(d-1)*bits-1 downto i*d*(d-1)*bits)), mps_ciphertexts((i+1)*4*d*bits-1 downto i*4*d*bits), mps_dones(i));
        TRVs: Trivium Generic Map (d*(d-1)*bits) Port Map (clk, trv_rsts(i), trv_ens(i), trv_keys((i+1)*80-1 downto i*80), trv_ivs((i+1)*80-1 downto i*80), trv_outs((i+1)*d*(d-1)*bits-1 downto i*d*(d-1)*bits));
        FSMs: FSM_k_IPM Generic Map (bits, d, k) Port Map (clk, rst, UNSIGNED(coeffs((i+1)*d*bits-1 downto (i*d+1)*bits)), UNSIGNED(inv_coeffs((i*d+1)*bits-1 downto i*d*bits)), UNSIGNED(coeffs), plaintext, STD_LOGIC_VECTOR(keys((i+1)*4*d*bits-1 downto i*4*d*bits)), mps_ciphertexts, mps_dones, trv_outs((i*d+2)*(d-1)*bits-1 downto i*d*(d-1)*bits), mps_rsts(i), mps_plaintexts((i+1)*4*d*bits-1 downto i*4*d*bits), mps_keys((i+1)*4*d*bits-1 downto i*4*d*bits), trv_rsts(i), trv_ens(i), fsm_ciphertexts((i+1)*4*bits-1 downto i*4*bits), fsm_dones(i));
    end generate;
    
    -- Adapt key sharing to coefficients of redundancy domains
    COICOk: for i in 0 to k-2 generate
        COICOd: for j in 0 to d-1 generate
            Mul: MulModMersenne Generic Map (bits) Port Map (UNSIGNED(coeffs((j+1)*bits-1 downto j*bits)), UNSIGNED(inv_coeffs(((i+1)*d+j+1)*bits-1 downto ((i+1)*d+j)*bits)), coicos((i*d+j+1)*bits-1 downto (i*d+j)*bits));
        end generate;
    end generate;
    keys(4*d*bits-1 downto 0) <= UNSIGNED(key);
    KRCk: for r in 0 to k-2 generate
        KRCw: for i in 0 to 3 generate
            KRCs: for j in 0 to d-1 generate
                Mul: MulModMersenne Generic Map (bits) Port Map (keys((i*d+j+1)*bits-1 downto (i*d+j)*bits), coicos((r*d+j+1)*bits-1 downto (r*d+j)*bits), keys(((r+1)*4*d+i*d+j+1)*bits-1 downto ((r+1)*4*d+i*d+j)*bits));
            end generate;
        end generate;
    end generate;
    
    CMP: for i in 1 to k-1 generate
        fsm_ciphertexts_comp(i-1) <= '1' when (fsm_ciphertexts(4*bits-1 downto 0) = fsm_ciphertexts((i+1)*4*bits-1 downto i*4*bits)) else '0';
    end generate;
    
    DET: process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                ciphertext_reg          <= (others => '0');
                ciphertext              <= (others => '0');
                done_reg                <= '0';
                done                    <= '0';
            else
                ciphertext              <= ciphertext_reg;
                done                    <= done_reg;
                if (fsm_dones = (k-1 downto 0 => '1')) then
                    if (fsm_ciphertexts_comp = (k-2 downto 0 => '1')) then
                        ciphertext_reg  <= STD_LOGIC_VECTOR(fsm_ciphertexts(4*bits-1 downto 0));
                        done_reg        <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;
