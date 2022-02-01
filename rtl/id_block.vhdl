library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity id_block is
    port (
        instr         : in  std_logic_vector(31 downto 0);
        flush         : in  std_logic;
        regs_addr     : out std_logic_vector(14 downto 0);
        int_strg_ctrl : out std_logic_vector(2  downto 0);
        csrs_addr     : out std_logic_vector(11 downto 0);
        csrs_mode     : out std_logic_vector(2  downto 0);
        csrs_ctrl     : out std_logic;
        ex_func       : out std_logic_vector(9  downto 0);
        ex_ctrl       : out std_logic_vector(5  downto 0);
        dmls_dtype    : out std_logic_vector(2  downto 0);
        dmls_ctrl     : out std_logic_vector(1  downto 0);
        brde_mode     : out std_logic_vector(2  downto 0);
        brde_ctrl     : out std_logic_vector(1  downto 0);
        imm           : out std_logic_vector(31 downto 0)
    );
end entity id_block;

architecture id_block_arch of id_block is
    
    signal opcode   : std_logic_vector(6  downto 0);
    signal payload  : std_logic_vector(24 downto 0);
    signal rd_addr  : std_logic_vector(4  downto 0);
    signal rs1_addr : std_logic_vector(4  downto 0);
    signal rs2_addr : std_logic_vector(4  downto 0);
    signal func3    : std_logic_vector(2  downto 0);
    signal func7    : std_logic_vector(6  downto 0);
    signal itype    : std_logic_vector(2  downto 0);

begin
    
    opcode   <= instr(6  downto  0);
    payload  <= instr(31 downto  7);
    rd_addr  <= instr(11 downto  7);
    rs1_addr <= instr(19 downto 15);
    rs2_addr <= instr(24 downto 20);
    func3    <= instr(14 downto 12);
    func7    <= instr(31 downto 25);

    id_imm_gen: imm_gen port map (
        payload => payload,
        itype   => itype,
        imm     => imm
    );

    id_main_ctrl: main_ctrl port map (
        opcode          => opcode,
        flush           => flush,
        int_strg_ctrl   => int_strg_ctrl,
        ig_imm_type     => itype,
        alu_src0        => ex_ctrl(4), 
        alu_src1        => ex_ctrl(5), 
        alu_opd0_pass   => ex_ctrl(2),
        alu_opd1_pass   => ex_ctrl(3),
        alu_op_en       => ex_ctrl(0), 
        alu_func_type   => ex_ctrl(1),
        lsu_mode        => dmls_ctrl(1), 
        lsu_en          => dmls_ctrl(0),
        brd_en          => brde_ctrl(1),
        csrs_wr_en      => csrs_ctrl,
        if_jmp          => brde_ctrl(0)
    );

    regs_addr   <=  rs2_addr & rs1_addr & rd_addr;
    csrs_addr   <=  func7 & rs2_addr;
    ex_func     <=  func7 & func3;

    csrs_mode   <=  func3;
    brde_mode   <=  func3;
    dmls_dtype  <=  func3;

end architecture id_block_arch;