library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity csrs_logic is
    port (
        csrwr_mode : in  std_logic_vector(2  downto 0);
        csrrd_data : in  std_logic_vector(31 downto 0);
        regwr_data : in  std_logic_vector(31 downto 0);
        immwr_data : in  std_logic_vector(31 downto 0);
        csrwr_data : out std_logic_vector(31 downto 0)
    );
end entity csrs_logic;

architecture rtl of csrs_logic is
begin
    
    main: process(csrwr_mode, regwr_data, immwr_data, csrrd_data)
    begin
        case csrwr_mode is
            when b"001" => csrwr_data <= regwr_data;
            when b"010" => csrwr_data <= csrrd_data or regwr_data;
            when b"011" => csrwr_data <= csrrd_data and not regwr_data;
            when b"101" => csrwr_data <= immwr_data;
            when b"110" => csrwr_data <= csrrd_data or immwr_data;
            when b"111" => csrwr_data <= csrrd_data and not immwr_data;
            when others => csrwr_data <= (others => '0');
        end case;
    end process main;
    
end architecture rtl;