library IEEE;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity ex_block is
    port (
        opd0_src0:    in  std_logic_vector(31 downto 0);
        opd0_src1:    in  std_logic_vector(31 downto 0);
        opd1_src0:    in  std_logic_vector(31 downto 0);
        opd1_src1:    in  std_logic_vector(31 downto 0);
        opd0_src_sel: in  std_logic;
        opd1_src_sel: in  std_logic;
        opd0_pass:    in  std_logic;
        opd1_pass:    in  std_logic;
        func_type:    in  std_logic;
        op_en:        in  std_logic;
        func3:        in  std_logic_vector(2  downto 0);
        func7:        in  std_logic_vector(6  downto 0);
        res:          out std_logic_vector(31 downto 0)
    );
end entity ex_block;

architecture ex_block_arch of ex_block is
    
    signal opd0:     std_logic_vector(31 downto 0);
    signal opd1:     std_logic_vector(31 downto 0);
    signal gtd_opd0: std_logic_vector(31 downto 0);
    signal gtd_opd1: std_logic_vector(31 downto 0);
    signal op:       std_logic_vector(5  downto 0);

begin

    opd0 <= opd0_src1 when opd0_src_sel = '1' else opd0_src0;
    opd1 <= opd1_src1 when opd1_src_sel = '1' else opd1_src0;

    gtd_opd0 <= opd0 when opd0_pass = '1' else (others => '0');
    gtd_opd1 <= opd1 when opd1_pass = '1' else (others => '0');
    
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