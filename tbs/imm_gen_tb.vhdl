library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;
use work.tbs_pkg.all;

entity imm_gen_tb is 
end imm_gen_tb;

architecture imm_gen_tb_arch of imm_gen_tb is

    signal instr_payload: std_logic_vector(24 downto 0);
    signal imm_type: std_logic_vector(2 downto 0);
    signal imm: std_logic_vector(31 downto 0);
   
    function get_payload(instr: in std_logic_vector(31 downto 0)) return std_logic_vector is

    begin

        return instr(31 downto 7);

    end function get_payload;

begin
    
    uut: imm_gen port map (instr_payload, imm_type, imm);

    process

        constant period: time := 5 ns;

        begin

            instr_payload <= get_payload(i_instr(b"0010011", b"00001", b"000", b"00010", x"000000fa"));
            imm_type <= IMM_I_TYPE;

            wait for period;
            assert imm = x"000000fa" report "i instr imm decode failure" severity failure;

            instr_payload <= get_payload(s_instr(b"0100011", b"010", b"00001", b"00010", x"000001c5"));
            imm_type <= IMM_S_TYPE;

            wait for period;
            assert imm = x"000001c5" report "s instr imm decode failure" severity failure;

            instr_payload <= get_payload(b_instr(b"1100011", b"000", b"00001", b"00010", x"00000028"));
            imm_type <= IMM_B_TYPE;

            wait for period;
            assert imm = x"00000028" report "b instr imm decode failure" severity failure;

            instr_payload <= get_payload(u_instr(b"0110111", b"00001", x"0000a000"));
            imm_type <= IMM_U_TYPE;

            wait for period;
            assert imm = x"0000a000" report "u instr imm decode failure" severity failure;

            instr_payload <= get_payload(j_instr(b"1101111", b"00001", x"0001f000"));
            imm_type <= IMM_J_TYPE;

            wait for period;
            assert imm = x"0001f000" report "j instr imm decode failure" severity failure;

            wait;

    end process;
    
end architecture imm_gen_tb_arch;