----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: arithmetic logic unit
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;

entity alu is
    port(
        pc_i           : in  std_logic_vector(XLEN-1 downto 0);
        reg0_i         : in  std_logic_vector(XLEN-1 downto 0);
        reg1_i         : in  std_logic_vector(XLEN-1 downto 0);
        immwr_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        opd0_src_sel_i : in  std_logic;
        opd1_src_sel_i : in  std_logic;
        opd0_pass_i    : in  std_logic;
        opd1_pass_i    : in  std_logic;
        op_i           : in  std_logic_vector(5        downto 0);
        res_o          : out std_logic_vector(XLEN-1 downto 0);
        arith_res_o    : out std_logic_vector(XLEN-1 downto 0)
    );
end entity alu;

architecture alu_arch of alu is

    signal arith_op   :   std_logic;
    signal arith_opd0 : std_logic_vector(XLEN-1 downto 0);
    signal arith_opd1 : std_logic_vector(XLEN-1 downto 0);
    signal arith_res  : std_logic_vector(XLEN-1 downto 0);

    signal comp_en     : std_logic;
    signal comp_op     : std_logic;
    signal comp_opd0   : std_logic;
    signal comp_opd1   : std_logic;
    signal comp_opd2   : std_logic;
    signal comp_bypass : std_logic_vector(XLEN-1 downto 0);
    signal comp_res    : std_logic_vector(XLEN-1 downto 0);

    signal logic_op     : std_logic_vector(1        downto 0);
    signal logic_opd0   : std_logic_vector(XLEN-1 downto 0);
    signal logic_opd1   : std_logic_vector(XLEN-1 downto 0);
    signal logic_bypass : std_logic_vector(XLEN-1 downto 0);
    signal logic_res    : std_logic_vector(XLEN-1 downto 0);

    signal shifter_op     : std_logic_vector(1        downto 0);
    signal shifter_opd    : std_logic_vector(XLEN-1 downto 0);
    signal shifter_shamt  : std_logic_vector(4        downto 0);
    signal shifter_bypass : std_logic_vector(XLEN-1 downto 0);
    signal shifter_res    : std_logic_vector(XLEN-1 downto 0);

    signal opd0      : std_logic_vector(XLEN-1 downto 0);
    signal opd1      : std_logic_vector(XLEN-1 downto 0);
    signal gtd_opd0  : std_logic_vector(XLEN-1 downto 0);
    signal gtd_opd1  : std_logic_vector(XLEN-1 downto 0);

begin

    opd0 <= pc_i when opd0_src_sel_i = '1' else reg0_i;
    opd1 <= immwr_data_i when opd1_src_sel_i = '1' else reg1_i;
    gtd_opd0 <= opd0 and (XLEN-1 downto 0 => opd0_pass_i);
    gtd_opd1 <= opd1 and (XLEN-1 downto 0 => opd1_pass_i);

    arith_op   <= op_i(4) or op_i(5);
    arith_opd0 <= gtd_opd0;
    arith_opd1 <= gtd_opd1;

    comp_en     <= op_i(5);
    comp_op     <= op_i(4);
    comp_opd0   <= gtd_opd0(XLEN-1);
    comp_opd1   <= gtd_opd1(XLEN-1);
    comp_opd2   <= arith_res(XLEN-1);
    comp_bypass <= arith_res;

    logic_op     <= op_i(3 downto 2);
    logic_opd0   <= gtd_opd0;
    logic_opd1   <= gtd_opd1;
    logic_bypass <= comp_res;

    shifter_op     <= op_i(1 downto 0);
    shifter_opd    <= gtd_opd0;
    shifter_shamt  <= gtd_opd1(4 downto 0);
    shifter_bypass <= logic_res;

    arith_unit: process(arith_op, arith_opd0, arith_opd1)
        variable a_opd0 : std_logic_vector(XLEN-1 downto 0);
        variable a_opd1 : std_logic_vector(XLEN-1 downto 0);
        variable cin    : std_logic_vector(0          downto 0);
    begin
        if arith_op = '1' then
            a_opd0 := arith_opd0;
            a_opd1 := not arith_opd1;
            cin(0) := '1';
        else
            a_opd0 := arith_opd0;
            a_opd1 := arith_opd1;
            cin(0) := '0';
        end if;
        arith_res <= std_logic_vector(unsigned(a_opd0) + unsigned(a_opd1) + unsigned(cin));
    end process arith_unit;

    comparator: process(comp_en, comp_op, comp_opd0, comp_opd1, comp_opd2, comp_bypass)
        variable comp_res_i : std_logic;
    begin
        if comp_opd0 = comp_opd1 then
            comp_res_i := comp_opd2;
        else
            if comp_op = '0' then
                comp_res_i := comp_opd0 and not comp_opd1;
            else
                comp_res_i := not comp_opd0 and comp_opd1;
            end if;
        end if;

        if comp_en = '1' then
            comp_res <= (0 => comp_res_i, others => '0');
        else
            comp_res <= comp_bypass;
        end if;
    end process comparator;

    logic_unit: process(logic_op, logic_opd0, logic_opd1, logic_bypass)
        constant LOGIC_XOR : std_logic_vector(1 downto 0) := b"00";
        constant LOGIC_OR  : std_logic_vector(1 downto 0) := b"01";
        constant LOGIC_AND : std_logic_vector(1 downto 0) := b"10";
    begin
        case logic_op is
            when LOGIC_XOR => logic_res <= logic_opd0 xor logic_opd1;
            when LOGIC_OR  => logic_res <= logic_opd0 or logic_opd1;
            when LOGIC_AND => logic_res <= logic_opd0 and logic_opd1;
            when others    => logic_res <= logic_bypass;
        end case;
    end process logic_unit;

    shifter: process(shifter_op, shifter_opd, shifter_shamt, shifter_bypass)
        variable shamt: integer range 0 to 31;

        constant SHIFTER_SLL: std_logic_vector(1 downto 0) := b"00";
        constant SHIFTER_SRL: std_logic_vector(1 downto 0) := b"01";
        constant SHIFTER_SRA: std_logic_vector(1 downto 0) := b"10";
    begin
        shamt := to_integer(unsigned(shifter_shamt));

        case shifter_op is
            when SHIFTER_SLL => shifter_res <= std_logic_vector(shift_left(unsigned(shifter_opd), shamt));
            when SHIFTER_SRL => shifter_res <= std_logic_vector(shift_right(unsigned(shifter_opd), shamt));
            when SHIFTER_SRA => shifter_res <= std_logic_vector(shift_right(signed(shifter_opd), shamt));
            when others      => shifter_res <= shifter_bypass;
        end case;
    end process shifter;

    res_o       <= shifter_res;
    arith_res_o <= arith_res;

end architecture alu_arch;
