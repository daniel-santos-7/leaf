----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: execution block
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity ex_block is
    port (
        trap_taken  : in  std_logic;
        trap_target : in  std_logic_vector(31 downto 0);
        func3       : in  std_logic_vector(2  downto 0);
        func7       : in  std_logic_vector(6  downto 0);
        reg0        : in  std_logic_vector(31 downto 0);
        reg1        : in  std_logic_vector(31 downto 0);
        pc          : in  std_logic_vector(31 downto 0);
        imm         : in  std_logic_vector(31 downto 0);
        exec_ctrl   : in  std_logic_vector(7  downto 0);
        imrd_malgn  : out std_logic;
        taken       : out std_logic;
        target      : out std_logic_vector(31 downto 0);
        res         : out std_logic_vector(31 downto 0)
    );
end entity ex_block;

architecture ex_block_arch of ex_block is

    signal jmp   : std_logic;
    signal br_en : std_logic;

    signal opd0_src_sel : std_logic;
    signal opd1_src_sel : std_logic;
    signal opd0_pass    : std_logic;
    signal opd1_pass    : std_logic;
    signal ftype        : std_logic;
    signal op_en        : std_logic;

    signal opd0     : std_logic_vector(31 downto 0);
    signal opd1     : std_logic_vector(31 downto 0);
    signal gtd_opd0 : std_logic_vector(31 downto 0);
    signal gtd_opd1 : std_logic_vector(31 downto 0);
    signal op       : std_logic_vector(5  downto 0);
    signal ires     : std_logic_vector(31 downto 0);
    signal branch   : std_logic;

begin
    
    jmp   <= exec_ctrl(7);
    br_en <= exec_ctrl(6);

    opd0_src_sel <= exec_ctrl(5);
    opd1_src_sel <= exec_ctrl(4);
    opd0_pass    <= exec_ctrl(3);
    opd1_pass    <= exec_ctrl(2);
    ftype        <= exec_ctrl(1);
    op_en        <= exec_ctrl(0);

    opd0 <= pc  when opd0_src_sel = '1' else reg0;
    opd1 <= imm when opd1_src_sel = '1' else reg1;

    gtd_opd0 <= opd0 and (31 downto 0 => opd0_pass);
    gtd_opd1 <= opd1 and (31 downto 0 => opd1_pass);

    exec_alu_ctrl: alu_ctrl port map (
        op_en => op_en,
        ftype => ftype,
        func3 => func3,
        func7 => func7,
        op    => op
    );

    exec_alu: alu port map (
        opd0 => gtd_opd0, 
        opd1 => gtd_opd1,
        op   => op,
        res  => ires
    );

    exec_br_detector: br_detector port map (
        reg0   => reg0,
        reg1   => reg1,
        mode   => func3,
        en     => br_en,
        branch => branch
    );

    imrd_malgn <= '0' when ires(1 downto 0) = b"00" else branch or jmp;

    taken  <= branch or jmp or trap_taken;
    target <= ires;
    res    <= ires;
    
end architecture ex_block_arch;