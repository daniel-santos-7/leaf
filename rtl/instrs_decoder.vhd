library library IEEE;
use IEEE.std_logic_1164.all;

entity instrs_decoder is

    port(
        instr: in std_logic_vector(31 downto 0);
        rd_reg0, rd_reg1, wr_reg: out std_logic_vector(3 downto 0)
    );

end entity instrs_decoder;

architecture instrs_decoder_arch of instrs_decoder is
    
begin
    
    rd_reg0 <= instr(19 downto 15);

    rd_reg1 <= instr(24 downto 20);

    wr_reg <= instr(11 downto 7);
    
end architecture instrs_decoder_arch;