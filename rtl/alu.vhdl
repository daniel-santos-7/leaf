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
        -- One bit per operand: bit 0 selects/gates opd0, bit 1 opd1.
        opd_src_sel_i  : in  std_logic_vector(1        downto 0);
        opd_pass_i     : in  std_logic_vector(1        downto 0);
        op_i           : in  std_logic_vector(4        downto 0);
        res_o          : out std_logic_vector(XLEN-1 downto 0);
        arith_res_o    : out std_logic_vector(XLEN-1 downto 0);
        -- pc+4: the JAL/JALR link address and the mepc a wfi trap stacks. For
        -- those very instructions the one adder is busy computing the jump
        -- target, so this gets its own narrow incrementer.
        pc_next_o      : out std_logic_vector(XLEN-1 downto 0)
    );
end entity alu;

architecture rtl of alu is

    signal arith_op   : std_logic;
    signal arith_res  : std_logic_vector(XLEN-1 downto 0);

    signal comp_op   : std_logic;
    signal comp_bit  : std_logic;
    signal comp_res  : std_logic_vector(XLEN-1 downto 0);

    signal logic_op   : std_logic_vector(1      downto 0);
    signal logic_res  : std_logic_vector(XLEN-1 downto 0);

    signal shifter_op    : std_logic_vector(1      downto 0);
    signal shifter_src   : std_logic_vector(XLEN-1 downto 0);
    signal shifter_fill  : std_logic;
    signal shifter_shr   : std_logic_vector(XLEN   downto 0);
    signal shifter_res   : std_logic_vector(XLEN-1 downto 0);

    signal opd0     : std_logic_vector(XLEN-1 downto 0);
    signal opd1     : std_logic_vector(XLEN-1 downto 0);
    signal gtd_opd0 : std_logic_vector(XLEN-1 downto 0);
    signal gtd_opd1 : std_logic_vector(XLEN-1 downto 0);

    signal res_sel  : std_logic_vector(1      downto 0);
    signal res      : std_logic_vector(XLEN-1 downto 0);

begin

    opd0     <= pc_i         when opd_src_sel_i(0) = '1' else reg0_i;
    opd1     <= immwr_data_i when opd_src_sel_i(1) = '1' else reg1_i;
    gtd_opd0 <= opd0 and (XLEN-1 downto 0 => opd_pass_i(0));
    gtd_opd1 <= opd1 and (XLEN-1 downto 0 => opd_pass_i(1));

    -- The low two bits are shared: only the unit res_sel names reads them.
    res_sel    <= op_i(4 downto 3);
    arith_op   <= op_i(2);
    comp_op    <= op_i(0);
    logic_op   <= op_i(1 downto 0);
    shifter_op <= op_i(1 downto 0);

    arith_unit: process(arith_op, gtd_opd0, gtd_opd1)
        variable neg : std_logic_vector(XLEN-1 downto 0);
        variable cin : unsigned(0        downto 0);
    begin
        -- sub is the ones' complement plus a carry-in of one
        neg := gtd_opd1 xor (XLEN-1 downto 0 => arith_op);
        cin := (0 => arith_op);

        arith_res <= std_logic_vector(unsigned(gtd_opd0) + unsigned(neg) + cin);
    end process arith_unit;

    comparator: process(comp_op, gtd_opd0, gtd_opd1, arith_res)
    begin
        if gtd_opd0(XLEN-1) = gtd_opd1(XLEN-1) then
            -- equal signs cannot overflow the subtraction, so its sign answers
            comp_bit <= arith_res(XLEN-1);
        else
            -- signs differ: opd0's sign is the signed answer, its inverse
            -- the unsigned one
            comp_bit <= gtd_opd0(XLEN-1) xor comp_op;
        end if;
    end process comparator;

    comp_res <= (0 => comp_bit, others => '0');

    logic_unit: process(logic_op, gtd_opd0, gtd_opd1)
    begin
        case logic_op is
            when ALU_LOGIC_XOR => logic_res <= gtd_opd0 xor gtd_opd1;
            when ALU_LOGIC_OR  => logic_res <= gtd_opd0 or  gtd_opd1;
            when ALU_LOGIC_AND => logic_res <= gtd_opd0 and gtd_opd1;
            -- the encoding never produces b"11"
            when others        => logic_res <= (others => '0');
        end case;
    end process logic_unit;

    -- One right shifter serves the three: sll reverses operand and result, sra
    -- fills from the sign bit. A shift_left beside it costs a second barrel.
    shifter_shr <= std_logic_vector(shift_right(signed(shifter_fill & shifter_src),
                                                to_integer(unsigned(gtd_opd1(4 downto 0)))));

    shifter: process(shifter_op, gtd_opd0, shifter_shr)
    begin
        case shifter_op is
            when ALU_SHIFT_SLL =>
                for i in 0 to XLEN-1 loop
                    shifter_src(i) <= gtd_opd0(XLEN-1 - i);
                    shifter_res(i) <= shifter_shr(XLEN-1 - i);
                end loop;
                shifter_fill <= '0';
            when ALU_SHIFT_SRA =>
                shifter_src  <= gtd_opd0;
                shifter_fill <= gtd_opd0(XLEN-1);
                shifter_res  <= shifter_shr(XLEN-1 downto 0);
            when others =>
                shifter_src  <= gtd_opd0;
                shifter_fill <= '0';
                shifter_res  <= shifter_shr(XLEN-1 downto 0);
        end case;
    end process shifter;

    result_mux: process(res_sel, comp_res, shifter_res, logic_res, arith_res)
    begin
        case res_sel is
            when ALU_RES_COMP  => res <= comp_res;
            when ALU_RES_SHIFT => res <= shifter_res;
            when ALU_RES_LOGIC => res <= logic_res;
            when others        => res <= arith_res;
        end case;
    end process result_mux;

    res_o       <= res;
    arith_res_o <= arith_res;
    -- pc_i is word-aligned, so +4 is an increment of the word address
    pc_next_o   <= std_logic_vector(unsigned(pc_i(XLEN-1 downto 2)) + 1) & b"00";

end architecture rtl;
