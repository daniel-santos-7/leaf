library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity ex_block is
    port (
        opd0_src0 : in  std_logic_vector(31 downto 0);
        opd0_src1 : in  std_logic_vector(31 downto 0);
        opd1_src0 : in  std_logic_vector(31 downto 0);
        opd1_src1 : in  std_logic_vector(31 downto 0);
        ex_ctrl   : in  ex_ctrl_type;     
        ex_func   : in  ex_func_type;
        res       : out std_logic_vector(31 downto 0)
    );
end entity ex_block;

architecture ex_block_arch of ex_block is

    signal opd0     : std_logic_vector(31 downto 0);
    signal opd1     : std_logic_vector(31 downto 0);
    signal gtd_opd0 : std_logic_vector(31 downto 0);
    signal gtd_opd1 : std_logic_vector(31 downto 0);
    signal op       : std_logic_vector(5  downto 0);

begin
    
    opd0 <= opd0_src1 when ex_ctrl.opd0_src_sel = '1' else opd0_src0;
    opd1 <= opd1_src1 when ex_ctrl.opd1_src_sel = '1' else opd1_src0;

    gtd_opd0 <= opd0 and (31 downto 0 => ex_ctrl.opd0_pass);
    gtd_opd1 <= opd1 and (31 downto 0 => ex_ctrl.opd1_pass);

    ex_alu_ctrl: alu_ctrl port map (
        op_en => ex_ctrl.op_en,
        ftype => ex_ctrl.ftype,
        func3 => ex_func.func3,
        func7 => ex_func.func7,
        op    => op
    );

    ex_alu: alu port map (
        opd0 => gtd_opd0, 
        opd1 => gtd_opd1,
        op   => op,
        res  => res
    );
    
end architecture ex_block_arch;