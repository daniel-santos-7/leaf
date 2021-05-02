library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;
use work.tbs_pkg.all;

entity core_tb is
end entity core_tb;

architecture core_tb_arch of core_tb is
    
    signal clk: std_logic := '0';
    signal rd_instr_mem_data: std_logic_vector(31 downto 0);
    signal rd_instr_mem_addr: std_logic_vector(31 downto 0);
    signal rd_mem_data: std_logic_vector(31 downto 0);
    signal rd_mem_en: std_logic;
    signal wr_mem_data: std_logic_vector(31 downto 0);
    signal wr_mem_en: std_logic;
    signal rd_wr_mem_addr: std_logic_vector(31 downto 0);

begin
    
    uut: core port map (
        clk,
        rd_instr_mem_data,
        rd_instr_mem_addr,
        rd_mem_data,
        rd_mem_en,
        wr_mem_data,
        wr_mem_en,
        rd_wr_mem_addr
    );

    rom: process(rd_instr_mem_addr)
    
    begin
        
        case rd_instr_mem_addr is
            
            when x"00000000" => rd_instr_mem_data <= addi_instr(b"00001", b"00000", x"00000000");
            when x"00000004" => rd_instr_mem_data <= addi_instr(b"00010", b"00000", x"00000001");
            when x"00000008" => rd_instr_mem_data <= addi_instr(b"00011", b"00000", x"0000000a");
            when x"0000000C" => rd_instr_mem_data <= addi_instr(b"00100", b"00000", x"00000001");
            when x"00000010" => rd_instr_mem_data <= addi_instr(b"00100", b"00100", x"00000001");
            when x"00000014" => rd_instr_mem_data <= add_instr(b"00101", b"00000", b"00001");
            when x"00000018" => rd_instr_mem_data <= add_instr(b"00001", b"00000", b"00010");
            when x"0000001C" => rd_instr_mem_data <= add_instr(b"00010", b"00010", b"00101");
            when x"00000020" => rd_instr_mem_data <= blt_instr(b"00100", b"00011", x"FFFFFFF0");
            when x"00000024" => rd_instr_mem_data <= sw_instr(b"00000", b"00010", x"00000000");
            when others      => rd_instr_mem_data <= addi_instr(b"00000", b"00000", x"00000000");

        end case;

    end process rom;

    clk <= not clk after 5 ns when rd_instr_mem_addr <= x"00000028";

end architecture core_tb_arch;