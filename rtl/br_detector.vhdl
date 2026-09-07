----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: branch detector
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;

entity br_detector is
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        reg0_i       : in  std_logic_vector(XLEN-1 downto 0);
        reg1_i       : in  std_logic_vector(XLEN-1 downto 0);
        mode_i       : in  std_logic_vector(2           downto 0);
        en_i         : in  std_logic;
        jmp_i        : in  std_logic;
        arith_res_i    : in  std_logic_vector(XLEN-1 downto 0);
        trap_taken_i : in  std_logic;
        trap_target_i: in  std_logic_vector(XLEN-1 downto 0);
        redirect_ack_i : in  std_logic;
        taken_o      : out std_logic;
        target_o     : out std_logic_vector(XLEN-1 downto 0);
        imrd_malgn_o : out std_logic
    );
end entity br_detector;

architecture br_detector_arch of br_detector is

    signal equal:         std_logic;
    signal less:          std_logic;
    signal less_unsigned: std_logic;
    signal branch_i:      std_logic;

    signal taken_int  : std_logic;
    signal target_int : std_logic_vector(XLEN-1 downto 0);

    -- Redirect held until the fetch stage can accept it: the bus may defer
    -- acceptance for any number of cycles, so taken_o/target_o stay asserted
    -- until redirect_ack_i arrives.
    signal taken_reg  : std_logic;
    signal target_reg : std_logic_vector(XLEN-1 downto 0);

begin

    equal <= '1' when reg0_i = reg1_i else '0';

    less <= '1' when signed(reg0_i) < signed(reg1_i) else '0';

    less_unsigned <= '1' when unsigned(reg0_i) < unsigned(reg1_i) else '0';

    exec: process(mode_i, equal, less, less_unsigned)
    begin
        case mode_i is
            when EQ_BD_MODE  => branch_i <= equal;
            when NE_BD_MODE  => branch_i <= not(equal);
            when LT_BD_MODE  => branch_i <= less;
            when GE_BD_MODE  => branch_i <= not(less) or equal;
            when LTU_BD_MODE => branch_i <= less_unsigned;
            when GEU_BD_MODE => branch_i <= not(less_unsigned) or equal;
            when others      => branch_i <= '0';
        end case;
    end process exec;

    imrd_malgn_o <= arith_res_i(1) and ((branch_i and en_i) or jmp_i);

    taken_int   <= (branch_i and en_i) or jmp_i or trap_taken_i;
    target_int  <= trap_target_i when trap_taken_i = '1' else arith_res_i(XLEN-1 downto 1) & b"0";

    -- Clearing on the acknowledge takes priority over capturing: a redirect
    -- resolving in that same cycle still drives taken_o combinationally
    -- through taken_int, so nothing is lost.
    redirect_hold: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' or redirect_ack_i = '1' then
                taken_reg  <= '0';
                target_reg <= (others => '0');
            elsif taken_int = '1' then
                taken_reg  <= '1';
                target_reg <= target_int;
            end if;
        end if;
    end process redirect_hold;

    taken_o  <= taken_int or taken_reg;
    target_o <= target_int when taken_int = '1' else target_reg;

end architecture br_detector_arch;
