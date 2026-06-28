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
        reg0_i       : in  std_logic_vector(XLEN-1 downto 0);
        reg1_i       : in  std_logic_vector(XLEN-1 downto 0);
        mode_i       : in  std_logic_vector(2           downto 0);
        en_i         : in  std_logic;
        jmp_i        : in  std_logic;
        alu_res_i    : in  std_logic_vector(XLEN-1 downto 0);
        trap_taken_i : in  std_logic;
        trap_target_i: in  std_logic_vector(XLEN-1 downto 0);
        branch_o     : out std_logic;
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

    imrd_malgn_o <= alu_res_i(1) and ((branch_i and en_i) or jmp_i);

    taken_int   <= (branch_i and en_i) or jmp_i or trap_taken_i;
    target_int  <= trap_target_i when trap_taken_i = '1' else alu_res_i(XLEN-1 downto 1) & b"0";

    branch_o <= branch_i and en_i;
    taken_o  <= taken_int;
    target_o <= target_int;

end architecture br_detector_arch;
