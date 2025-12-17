library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Cloneless is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           read : in STD_LOGIC;
           write : in STD_LOGIC;
           address : in STD_LOGIC_VECTOR (2 downto 0);
           data_in : in STD_LOGIC_VECTOR (3 downto 0);
           data_out : out STD_LOGIC_VECTOR (3 downto 0));
end Cloneless;

architecture Behavioral of Cloneless is

    component FF_srst is
        Generic ( bits : INTEGER := 4);
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               inpt : in STD_LOGIC_VECTOR ((bits-1) downto 0);
               outpt : out STD_LOGIC_VECTOR ((bits-1) downto 0));
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
    
    component mid_pSquare_dSHARES_IPM_kRED is
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
    end component;
    
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
    
    component controller is
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               core_done : in STD_LOGIC;
               ciphertext_register_parallel_enable : out STD_LOGIC;
               core_rst : out STD_LOGIC;
               core_en : out STD_LOGIC;
               done : out STD_LOGIC);
    end component;
    
    component mps_ipm_controller is
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
    end component;

    signal config0_enable, config1_enable, data_in_enable, seed_enable, data_out_enable, status_enable : STD_LOGIC;
    signal config0_out, config1_out, status_in, status_out, data_out_out : STD_LOGIC_VECTOR (3 downto 0);

    signal contr_en, contr_rst, ciphertext_register_parallel_enable, contr_done : STD_LOGIC;
    signal core_select : STD_LOGIC_VECTOR (1 downto 0);
    signal mps_ipm_trng_puf_active : STD_LOGIC_VECTOR (1 downto 0);

    signal plaintext, ciphertext : STD_LOGIC_VECTOR (123 downto 0);
    signal seed : STD_LOGIC_VECTOR (159 downto 0);

    signal mps_ipm_rst, cln_estrng_rst, cln_ropuf_rst : STD_LOGIC;
    signal cln_estrng_en, cln_ropuf_en : STD_LOGIC;
    signal mps_ipm_plaintext : STD_LOGIC_VECTOR (123 downto 0);
    signal mps_ipm_ciphertext : STD_LOGIC_VECTOR (123 downto 0);
    signal cln_estrng_ciphertext, cln_ropuf_ciphertext : STD_LOGIC_VECTOR (31 downto 0);
    signal mps_ipm_done, cln_estrng_done, cln_ropuf_done : STD_LOGIC;
    signal cln_estrng1_done, cln_estrng2_done, cln_estrng3_done, cln_estrng4_done : STD_LOGIC;
    signal cln_ropuf1_done, cln_ropuf2_done, cln_ropuf3_done, cln_ropuf4_done : STD_LOGIC;
    
    signal mps_ipm_trv_keys : STD_LOGIC_VECTOR (159 downto 0);
    constant mps_ipm_const_key : STD_LOGIC_VECTOR (247 downto 0) := x"E254279BFD731B0E3E46A19B88096E7BAFBAC9A3169A987296768DDAEF1762";
    constant mps_ipm_trv_ivs : STD_LOGIC_VECTOR (159 downto 0) := x"A57E40B2691F8F8BA820820AC703515E81A2B472";
    constant mps_ipm_coeffs : STD_LOGIC_VECTOR (123 downto 0) := x"132F3BD45F1B1A3BFB2FB535A22919C";
    constant mps_ipm_inv_coeffs : STD_LOGIC_VECTOR (123 downto 0) := x"FC388F747DE49D356D358BE5704C985";
    signal mps_ipm_key : STD_LOGIC_VECTOR (247 downto 0);

    signal mps_ipm_contr_rst, cln_estrng_contr_rst, cln_ropuf_contr_rst : STD_LOGIC;
    signal mps_ipm_contr_en, cln_estrng_contr_en, cln_ropuf_contr_en : STD_LOGIC;
    signal mps_ipm_ciphertext_register_parallel_enable, cln_estrng_ciphertext_register_parallel_enable, cln_ropuf_ciphertext_register_parallel_enable : STD_LOGIC;
    signal mps_ipm_contr_done, cln_estrng_contr_done, cln_ropuf_contr_done : STD_LOGIC;
    
begin

    -- Choose config/IO register by address
    config0_enable                      <= '1' when ((address = "000") AND (write = '1')) else '0';
    config1_enable                      <= '1' when ((address = "001") AND (write = '1')) else '0';
    data_in_enable                      <= '1' when ((address = "010") AND (write = '1')) else '0';
    seed_enable                         <= '1' when ((address = "011") AND (write = '1')) else '0';
    status_enable                       <= '1' when ((address = "100") AND (read = '1')) else '0';
    data_out_enable                     <= '1' when (((address = "101") AND (read = '1')) OR (ciphertext_register_parallel_enable = '1')) else '0';

    -- Config and IO registers
    config0_r: FF_srst Generic Map (4) Port Map (clk, rst, config0_enable, data_in, config0_out);
    config1_r: FF_srst Generic Map (4) Port Map (clk, rst, config1_enable, data_in, config1_out);
    data_in_r: FF_serpar_srst Generic Map (4, 124) Port Map (clk, rst, data_in_enable, '0', data_in, (others=>'0'), open, plaintext);
    seed_r: FF_serpar_srst Generic Map (4, 160) Port Map (clk, rst, seed_enable, '0', data_in, (others=>'0'), open, seed);
    status_r: FF_srst Generic Map (4) Port Map (clk, rst, status_enable, status_in, status_out);
    data_out_r: FF_serpar_srst Generic Map (4, 124) Port Map (clk, rst, data_out_enable, ciphertext_register_parallel_enable, (others=>'0'), ciphertext, data_out_out, open);
    contr_rst                           <= config0_out(3);
    contr_en                            <= config0_out(2);
    core_select                         <= config0_out(1 downto 0);
    mps_ipm_trng_puf_active             <= config1_out(3 downto 2);
    status_in                           <= contr_done & (2 downto 0 => '0');
    data_out                            <= status_out when (status_enable = '1') else data_out_out when (data_out_enable = '1') else (others => '0');

    -- Core <-> framework connection assignments
    mps_ipm_plaintext                   <= plaintext when (core_select = "00") else (others => '0');
    mps_ipm_contr_rst                   <= contr_rst;
    cln_estrng_contr_rst                <= contr_rst;
    cln_ropuf_contr_rst                 <= contr_rst;
    mps_ipm_contr_en                    <= contr_en when (core_select = "00") else '0';
    cln_estrng_contr_en                 <= contr_en when (core_select = "01") else '0';
    cln_ropuf_contr_en                  <= contr_en when (core_select = "10") else '0';
    ciphertext_register_parallel_enable <= mps_ipm_ciphertext_register_parallel_enable when (core_select = "00") else cln_estrng_ciphertext_register_parallel_enable when (core_select = "01") else cln_ropuf_ciphertext_register_parallel_enable;
    contr_done                          <= mps_ipm_contr_done when (core_select = "00") else cln_estrng_contr_done when (core_select = "01") else cln_ropuf_contr_done;
    ciphertext                          <= mps_ipm_ciphertext when (core_select = "00") else ((123 downto 32 => '0') & cln_estrng_ciphertext) when (core_select = "01") else ((123 downto 32 => '0') & cln_ropuf_ciphertext);

    -- Inner-product masked mid-pSquare block cipher with d shares and k redundancies
    MPS_d2_ipm_r2: mid_pSquare_dSHARES_IPM_kRED Generic Map (31, 2, 2) Port Map (clk, mps_ipm_rst, mps_ipm_coeffs, mps_ipm_inv_coeffs, mps_ipm_plaintext, mps_ipm_key, mps_ipm_trv_keys, mps_ipm_trv_ivs, mps_ipm_ciphertext, mps_ipm_done);
    MPS_d2_ipm_r2_controller: mps_ipm_controller Port Map (clk, mps_ipm_contr_rst, mps_ipm_contr_en, mps_ipm_done, mps_ipm_trng_puf_active, seed, mps_ipm_const_key, mps_ipm_trv_keys, mps_ipm_key, mps_ipm_ciphertext_register_parallel_enable, mps_ipm_rst, mps_ipm_contr_done);

    -- Edge-Sampling based True Random Number Generator (ES-TRNG)
    ESTRNG1: es_trng Generic Map (8, 23, 31, 1) Port Map (clk, cln_estrng_rst, cln_estrng_en, cln_estrng_ciphertext(7 downto 0), cln_estrng1_done);
    ESTRNG2: es_trng Generic Map (8, 23, 47, 1) Port Map (clk, cln_estrng_rst, cln_estrng_en, cln_estrng_ciphertext(15 downto 8), cln_estrng2_done);
    ESTRNG3: es_trng Generic Map (8, 31, 47, 1) Port Map (clk, cln_estrng_rst, cln_estrng_en, cln_estrng_ciphertext(23 downto 16), cln_estrng3_done);
    ESTRNG4: es_trng Generic Map (8, 31, 59, 1) Port Map (clk, cln_estrng_rst, cln_estrng_en, cln_estrng_ciphertext(31 downto 24), cln_estrng4_done);
    cln_estrng_done <= cln_estrng1_done AND cln_estrng2_done AND cln_estrng3_done AND cln_estrng4_done;
    ESTRNG_controller: controller Port Map (clk, cln_estrng_contr_rst, cln_estrng_contr_en, cln_estrng_done, cln_estrng_ciphertext_register_parallel_enable, cln_estrng_rst, cln_estrng_en, cln_estrng_contr_done);
    
    -- Ring Oscillator based Physically Unclonable Function (RO-PUF)
    ROPUF1: ro_puf Generic Map (8, 4, 23, 1023, 1) Port Map (clk, cln_ropuf_rst, cln_ropuf_en, cln_ropuf_ciphertext(7 downto 0), cln_ropuf1_done);
    ROPUF2: ro_puf Generic Map (8, 4, 31, 4095, 1) Port Map (clk, cln_ropuf_rst, cln_ropuf_en, cln_ropuf_ciphertext(15 downto 8), cln_ropuf2_done);
    ROPUF3: ro_puf Generic Map (8, 4, 47, 16383, 1) Port Map (clk, cln_ropuf_rst, cln_ropuf_en, cln_ropuf_ciphertext(23 downto 16), cln_ropuf3_done);
    ROPUF4: ro_puf Generic Map (8, 4, 59, 65535, 1) Port Map (clk, cln_ropuf_rst, cln_ropuf_en, cln_ropuf_ciphertext(31 downto 24), cln_ropuf4_done);
    cln_ropuf_done <= cln_ropuf1_done AND cln_ropuf2_done AND cln_ropuf3_done AND cln_ropuf4_done;
    ROPUF_controller: controller Port Map (clk, cln_ropuf_contr_rst, cln_ropuf_contr_en, cln_ropuf_done, cln_ropuf_ciphertext_register_parallel_enable, cln_ropuf_rst, cln_ropuf_en, cln_ropuf_contr_done);

end Behavioral;
