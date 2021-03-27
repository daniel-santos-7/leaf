library IEEE;
use IEEE.std_logic_1164.all;

entity reg_file_tb is 
end reg_file_tb;

architecture reg_file_tb_arch of reg_file_tb is

    signal rd_reg0, rd_reg1, wr_reg: std_logic_vector(3 downto 0);
    signal wr_data: std_logic_vector(31 downto 0);
    signal clk, reg_wr: std_logic;
    signal rd_data0, rd_data1: std_logic_vector(31 downto 0);

begin
    
    uut: entity work.reg_file port map (clk, rd_reg0, rd_reg1, wr_reg, wr_data, reg_wr, rd_data0, rd_data1);

    process

        constant period: time := 10 ns;

        begin

            -- Test case 1

            rd_reg0 <= b"0001";
            rd_reg1 <= b"0010";
            wr_reg <= b"0001";
            wr_data <= x"105A_FA12";
            reg_wr <= '1';

            clk <= '0';
            wait for period/2;
            clk <= '1';
            wait for period/2;

            assert (rd_data0 = wr_data)
            report "test failure: it should write register #1" severity failure;

            -- Test case 2

            rd_reg0 <= b"0001";
            rd_reg1 <= b"0010";
            wr_reg <= b"0010";
            wr_data <= x"FFB1_9122";
            reg_wr <= '1';

            clk <= '0';
            wait for period/2;
            clk <= '1';
            wait for period/2;

            assert (rd_data1 = wr_data)
            report "test failure: it should write register #2" severity failure;

            -- Test case 3

            rd_reg0 <= b"0001";
            rd_reg1 <= b"0010";
            wr_reg <= b"0000";
            wr_data <= x"0000_0000";
            reg_wr <= '0';

            clk <= '0';
            wait for period/2;
            clk <= '1';
            wait for period/2;

            assert (rd_data0 = x"105A_FA12" and rd_data1 = x"FFB1_9122")
            report "test failure: it should read registers #1 and #2" severity failure;

            -- Test case 4

            rd_reg0 <= b"0000";
            rd_reg1 <= b"0010";
            wr_reg <= b"0000";
            wr_data <= x"FB5A_A112";
            reg_wr <= '1';

            clk <= '0';
            wait for period/2;
            clk <= '1';
            wait for period/2;

            assert (rd_data0 = x"0000_0000")
            report "test failure: it shouldn't write register #0" severity failure;
            
            wait;

    end process;
    
end architecture reg_file_tb_arch;