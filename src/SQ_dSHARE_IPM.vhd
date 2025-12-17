library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SQ_dSHARE_IPM is
    Generic (bits : INTEGER := 31;
             d : INTEGER := 2);
    Port ( clk : in STD_LOGIC;
           en : in STD_LOGIC;
           a : in UNSIGNED (d*bits-1 downto 0);
           c : in UNSIGNED (d*bits-1 downto 0);
           r : in UNSIGNED (d*(d-1)*bits-1 downto 0);
           b : out UNSIGNED (d*bits-1 downto 0));
end SQ_dSHARE_IPM;

architecture Behavioral of SQ_dSHARE_IPM is

    component AddModMersenne is
        Generic ( bits : INTEGER := 7);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : out UNSIGNED (bits-1 downto 0));
    end component;
    
    component SubModMersenne is
        Generic ( bits : INTEGER := 7);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : out UNSIGNED (bits-1 downto 0));
    end component;
                   
    component SquModMersenne is
        Generic (bits : INTEGER := 7);
        Port ( a : in UNSIGNED (bits-1 downto 0);
              b : out UNSIGNED (bits-1 downto 0));
    end component;
    
    component MulModMersenne is
        Generic ( bits : INTEGER := 7);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : out UNSIGNED (bits-1 downto 0));
    end component;
    
    component MulAddModMersenne is
        Generic ( bits : INTEGER := 7);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : in UNSIGNED (bits-1 downto 0);
               d : out UNSIGNED (bits-1 downto 0));
    end component;
    
    component SubMulModMersenne is
        Generic ( bits : INTEGER := 7);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : in UNSIGNED (bits-1 downto 0);
               d : out UNSIGNED (bits-1 downto 0));
    end component;
    
    component MulAddMulModMersenne is
        Generic ( bits : INTEGER := 7);
        Port ( a : in UNSIGNED (bits-1 downto 0);
               b : in UNSIGNED (bits-1 downto 0);
               c : in UNSIGNED (bits-1 downto 0);
               d : in UNSIGNED (bits-1 downto 0);
               e : out UNSIGNED (bits-1 downto 0));
    end component;

    component FF is
        Generic ( bits : INTEGER := 7);
        Port ( clk : in STD_LOGIC;
               en : in STD_LOGIC;
               inpt : in UNSIGNED ((bits-1) downto 0);
               outpt : out UNSIGNED ((bits-1) downto 0));
    end component;
    
    signal a_r, times2 : UNSIGNED ((d-1)*bits-1 downto 0);
    signal r_r, r_rr : UNSIGNED (d*(d-1)*bits-1 downto 0);
    signal alpha, alpha_r, beta, beta_r : UNSIGNED (((d*(d-1))/2)*bits-1 downto 0);
    signal gamma, gamma_mul, gamma_mul_rr, gamma_mul_beta : UNSIGNED (((d*(d+1))/2)*bits-1 downto 0);
    signal gamma_mul_r : UNSIGNED (d*bits-1 downto 0);
    
begin
    
    OuterLoop: for i in 0 to (d-1) generate
        Times2Cond: if (i > 0) generate
            times2(i*bits-1 downto (i-1)*bits) <= a((i+1)*bits-2 downto i*bits) & a((i+1)*bits-1);
        end generate;
        gamma_coeff_mul: MulModMersenne Generic Map (bits) Port Map (c((i+1)*bits-1 downto i*bits), a((i+1)*bits-1 downto i*bits), gamma((i+1)*bits-1 downto i*bits));
        gamma_mul_beta((d-i)*bits-1 downto (d-1-i)*bits) <= gamma_mul_rr(((d*(d+1))/2-(i*(i+1))/2)*bits-1 downto ((d*(d+1))/2-(i*(i+1))/2-1)*bits);
        b((d-i)*bits-1 downto (d-1-i)*bits) <= gamma_mul_beta(((d*(d+1))/2-(i*(i+1))/2)*bits-1 downto ((d*(d+1))/2-(i*(i+1))/2-1)*bits);
        InnerLoop: for j in i+1 to (d-1) generate
            alpha_coeff_muladd: MulAddModMersenne Generic Map (bits) Port Map (times2(j*bits-1 downto (j-1)*bits), c((j+1)*bits-1 downto j*bits), r(((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i+1)*bits-1 downto ((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i)*bits), alpha(((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i+1)*bits-1 downto ((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i)*bits));
            beta_coeff_muladd: MulAddMulModMersenne Generic Map (bits) Port Map (alpha_r(((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i+1)*bits-1 downto ((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i)*bits), a_r((i+1)*bits-1 downto i*bits), c((j+1)*bits-1 downto j*bits), r_r((d*(d-1)-((d-(j-i))*(d-(j-i)+1))/2+i+1)*bits-1 downto (d*(d-1)-((d-(j-i))*(d-(j-i)+1))/2+i)*bits), beta(((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i+1)*bits-1 downto ((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i)*bits));
            gamma_sub: SubModMersenne Generic Map (bits) Port Map (gamma(((d*(d+1))/2-((d+1-(j-i))*(d+2-(j-i)))/2+i+1)*bits-1 downto ((d*(d+1))/2-((d+1-(j-i))*(d+2-(j-i)))/2+i)*bits), r(((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i+1)*bits-1 downto ((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i)*bits), gamma(((d*(d+1))/2-((d-(j-i))*(d-(j-i)+1))/2+i+1)*bits-1 downto ((d*(d+1))/2-((d-(j-i))*(d-(j-i)+1))/2+i)*bits));
            gamma_mul_add: AddModMersenne Generic Map (bits) Port Map (gamma_mul_rr(((d*(d+1))/2-((d+1-(j-i))*(d+2-(j-i)))/2+i+1)*bits-1 downto ((d*(d+1))/2-((d+1-(j-i))*(d+2-(j-i)))/2+i)*bits), beta_r(((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i+1)*bits-1 downto ((d*(d-1))/2-((d-(j-i))*(d-(j-i)+1))/2+i)*bits), gamma_mul(((d*(d+1))/2-((d-(j-i))*(d-(j-i)+1))/2+i+1)*bits-1 downto ((d*(d+1))/2-((d-(j-i))*(d-(j-i)+1))/2+i)*bits));
            gamma_coeff_mul_beta_sub: SubMulModMersenne Generic Map (bits) Port Map (gamma_mul_beta(((d*(d+1))/2-((d+1-(j-i))*(d+2-(j-i)))/2+i+1)*bits-1 downto ((d*(d+1))/2-((d+1-(j-i))*(d+2-(j-i)))/2+i)*bits), c((j-i)*bits-1 downto (j-i-1)*bits), r_rr((d*(d-1)-(j*(j-1))/2-i)*bits-1 downto (d*(d-1)-(j*(j-1))/2-i-1)*bits), gamma_mul_beta(((d*(d+1))/2-((d-(j-i))*(d-(j-i)+1))/2+i+1)*bits-1 downto ((d*(d+1))/2-((d-(j-i))*(d-(j-i)+1))/2+i)*bits));
        end generate;
        gamma_mul_mul: MulModMersenne Generic Map (bits) Port Map (a((i+1)*bits-1 downto i*bits), gamma(((d*(d+1))/2-(i*(i+1))/2)*bits-1 downto ((d*(d+1))/2-(i*(i+1))/2-1)*bits), gamma_mul((i+1)*bits-1 downto i*bits));
    end generate;
    
    -- Fully pipelined
    a_reg: FF Generic Map ((d-1)*bits) Port Map (clk, en, a((d-1)*bits-1 downto 0), a_r);
    r_reg1: FF Generic Map (d*(d-1)*bits) Port Map (clk, en, r, r_r);
    r_reg2: FF Generic Map (d*(d-1)*bits) Port Map (clk, en, r_r, r_rr);
    alpha_reg: FF Generic Map (((d*(d-1))/2)*bits) Port Map (clk, en, alpha, alpha_r);
    beta_reg: FF Generic Map (((d*(d-1))/2)*bits) Port Map (clk, en, beta, beta_r);
    gamma_reg1: FF Generic Map (d*bits) Port Map (clk, en, gamma_mul(d*bits-1 downto 0), gamma_mul_r);
    gamma_reg2: FF Generic Map (d*bits) Port Map (clk, en, gamma_mul_r, gamma_mul_rr(d*bits-1 downto 0));
    gamma_mul_rr(((d*(d+1))/2)*bits-1 downto d*bits) <= gamma_mul(((d*(d+1))/2)*bits-1 downto d*bits);
    
end Behavioral;