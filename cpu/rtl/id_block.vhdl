----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: instruction decode block
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity id_block is
    port (
        flush     : in  std_logic;
        instr     : in  std_logic_vector(31 downto 0);
        instr_err : out std_logic;
        func3     : out std_logic_vector(2  downto 0);
        func7     : out std_logic_vector(6  downto 0);
        dmls_ctrl : out std_logic_vector(1  downto 0);
        istg_ctrl : out std_logic_vector(3  downto 0);
        exec_ctrl : out std_logic_vector(7  downto 0);
        csrs_addr : out std_logic_vector(11 downto 0);
        regs_addr : out std_logic_vector(14 downto 0);
        imm       : out std_logic_vector(31 downto 0)
    );
end entity id_block;

architecture id_block_arch of id_block is
    
    signal opcode   : std_logic_vector(6  downto 0);
    signal payload  : std_logic_vector(24 downto 0);
    signal rd_addr  : std_logic_vector(4  downto 0);
    signal rs1_addr : std_logic_vector(4  downto 0);
    signal rs2_addr : std_logic_vector(4  downto 0);
    signal imm_type : std_logic_vector(2  downto 0);

begin
    
    opcode   <= instr(6  downto  0);
    payload  <= instr(31 downto  7);
    rd_addr  <= instr(11 downto  7);
    rs1_addr <= instr(19 downto 15);
    rs2_addr <= instr(24 downto 20);

    id_imm_gen: imm_gen port map (
        payload => payload,
        itype   => imm_type,
        imm     => imm
    );

    id_main_ctrl: main_ctrl port map (
        flush     => flush,
        opcode    => opcode,
        instr_err => instr_err,
        imm_type  => imm_type,
        istg_ctrl => istg_ctrl,
        exec_ctrl => exec_ctrl, 
        dmls_ctrl => dmls_ctrl
    );

    func3 <= instr(14 downto 12);
    func7 <= instr(31 downto 25);

    regs_addr <= rs2_addr & rs1_addr & rd_addr;
    csrs_addr <= instr(31 downto 20);

end architecture id_block_arch;