library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity ex_block is
    port (
        opd0_src0: in  std_logic_vector(31 downto 0);
        opd0_src1: in  std_logic_vector(31 downto 0);
        opd1_src0: in  std_logic_vector(31 downto 0);
        opd1_src1: in  std_logic_vector(31 downto 0);
        ex_ctrl:   in  std_logic_vector(5  downto 0);     
        ex_func:   in  std_logic_vector(9  downto 0);
        res:       out std_logic_vector(31 downto 0)
    );
end entity ex_block;

architecture ex_block_arch of ex_block is
    
    signal op_en:        std_logic;
    signal func_type:    std_logic;
    signal opd0_src_sel: std_logic;
    signal opd1_src_sel: std_logic;
    signal opd0_pass:    std_logic;
    signal opd1_pass:    std_logic;

    signal func3: std_logic_vector(2 downto 0);
    signal func7: std_logic_vector(6 downto 0);

    signal opd0: std_logic_vector(31 downto 0);
    signal opd1: std_logic_vector(31 downto 0);
    
    signal gtd_opd0: std_logic_vector(31 downto 0);
    signal gtd_opd1: std_logic_vector(31 downto 0);
    
    signal op: std_logic_vector(5 downto 0);

begin

    op_en        <= ex_ctrl(0);
    func_type    <= ex_ctrl(1);
    opd0_pass    <= ex_ctrl(2);
    opd1_pass    <= ex_ctrl(3);
    opd0_src_sel <= ex_ctrl(4);
    opd1_src_sel <= ex_ctrl(5);

    func3 <= ex_func(2 downto 0);
    func7 <= ex_func(9 downto 3);

    opd0 <= opd0_src1 when opd0_src_sel = '1' else opd0_src0;
    opd1 <= opd1_src1 when opd1_src_sel = '1' else opd1_src0;

    gtd_opd0 <= opd0 and (31 downto 0 => opd0_pass);
    gtd_opd1 <= opd1 and (31 downto 0 => opd1_pass);

    ex_alu_ctrl: alu_ctrl port map (
        alu_op_en     => op_en,
        alu_func_type => func_type,
        func3         => func3,
        func7         => func7,
        alu_op        => op
    );

    ex_alu: alu port map (
        opd0 => gtd_opd0, 
        opd1 => gtd_opd1,
        op   => op,
        res  => res
    );
    
end architecture ex_block_arch;