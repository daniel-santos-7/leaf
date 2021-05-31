library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;
use work.tbs_pkg.all;

entity id_ex_stage_tb is
end entity id_ex_stage_tb;

architecture id_ex_stage_tb_arch of id_ex_stage_tb is
    
    signal clk: std_logic;
    signal pc: std_logic_vector(31 downto 0);
    signal next_pc: std_logic_vector(31 downto 0);
    signal instr: std_logic_vector(31 downto 0) := x"00000000";
    signal no_op: std_logic;
    signal rd_mem_data: std_logic_vector(31 downto 0);
    signal rd_mem_en: std_logic;
    signal wr_mem_en: std_logic;
    signal rd_wr_mem_addr: std_logic_vector(31 downto 0);
    signal wr_mem_data: std_logic_vector(31 downto 0);
    signal branch, jmp, target_shift: std_logic;
    signal target: std_logic_vector(31 downto 0);
    signal wr_mem_byte_en: std_logic_vector(3 downto 0);

    procedure tick(signal clk: out std_logic) is

    begin
        
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;

    end procedure;
    
begin
    
    uut: id_ex_stage port map (
        clk,
        pc,
        next_pc,
        instr,
        no_op,
        rd_mem_data,
        rd_mem_en,
        wr_mem_en,
        rd_wr_mem_addr,
        wr_mem_data,
        wr_mem_byte_en,
        branch, 
        jmp, 
        target_shift,
        target
    );

    process

    begin

        pc <= x"00000000";
        next_pc <= x"00000004";
        instr <= i_instr(JALR_OPCODE, b"00001", b"000", b"00010", x"00000008");
        no_op <= '0';
        rd_mem_data <= x"00000000";

        tick(clk);

        assert rd_mem_en = '0';
        assert wr_mem_en = '0';
        assert rd_wr_mem_addr = x"00000000";
        assert wr_mem_data = x"00000000";
        assert branch = '0';
        assert jmp = '1';
        assert target_shift = '1';
        assert target = x"00000008";

        pc <= x"00000008";
        next_pc <= x"0000000c";
        instr <= i_instr(LOAD_OPCODE, b"00001", b"010", b"00000", x"00000004");
        no_op <= '0';
        rd_mem_data <= x"00000010";

        tick(clk);

        assert rd_mem_en = '1';
        assert wr_mem_en = '0';
        assert rd_wr_mem_addr = x"00000004";
        assert wr_mem_data = x"00000000";
        assert branch = '0';
        assert jmp = '0';
        assert target_shift = '0';
        assert target = x"00000004";

        pc <= x"0000000c";
        next_pc <= x"00000010";
        instr <= s_instr(STORE_OPCODE, b"010", b"00001", b"00001", x"00000008");
        no_op <= '0';
        rd_mem_data <= x"00000000";

        tick(clk);

        assert rd_mem_en = '0';
        assert wr_mem_en = '1';
        assert rd_wr_mem_addr = x"00000018";
        assert wr_mem_data = x"00000010";
        assert branch = '0';
        assert jmp = '0';
        assert target_shift = '0';
        assert target = x"00000018";

        pc <= x"00000010";
        next_pc <= x"00000014";
        instr <= b_instr(BRANCH_OPCODE, b"000", b"00000", b"00000", x"0000000c");
        no_op <= '0';
        rd_mem_data <= x"00000000";

        tick(clk);

        assert rd_mem_en = '0';
        assert wr_mem_en = '0';
        assert rd_wr_mem_addr = x"00000000";
        assert wr_mem_data = x"00000000";
        assert branch = '1';
        assert jmp = '0';
        assert target_shift = '0';
        assert target = x"0000001C";

        no_op <= '1';

        tick(clk);

        assert rd_mem_en = '0';
        assert wr_mem_en = '0';
        assert rd_wr_mem_addr = x"00000000";
        assert wr_mem_data = x"00000000";
        assert branch = '0';
        assert jmp = '0';
        assert target_shift = '0';

        wait;

    end process;
    
end architecture id_ex_stage_tb_arch;