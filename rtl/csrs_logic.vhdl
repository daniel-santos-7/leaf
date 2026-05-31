----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: CSR write data mux
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;

entity csrs_logic is
    port (
        csrwr_mode_i : in  std_logic_vector(2           downto 0);
        csrrd_data_i : in  std_logic_vector(XLEN-1      downto 0);
        regwr_data_i : in  std_logic_vector(XLEN-1      downto 0);
        immwr_data_i : in  std_logic_vector(XLEN-1      downto 0);
        csrwr_data_o : out std_logic_vector(XLEN-1      downto 0)
    );
end entity csrs_logic;

architecture rtl of csrs_logic is
begin

    main: process(csrwr_mode_i, regwr_data_i, immwr_data_i, csrrd_data_i)
    begin
        case csrwr_mode_i is
            when b"001" => csrwr_data_o <= regwr_data_i;
            when b"010" => csrwr_data_o <= csrrd_data_i or regwr_data_i;
            when b"011" => csrwr_data_o <= csrrd_data_i and not regwr_data_i;
            when b"101" => csrwr_data_o <= immwr_data_i;
            when b"110" => csrwr_data_o <= csrrd_data_i or immwr_data_i;
            when b"111" => csrwr_data_o <= csrrd_data_i and not immwr_data_i;
            when others => csrwr_data_o <= (others => '0');
        end case;
    end process main;

end architecture rtl;