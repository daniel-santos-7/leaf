----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: Wishbone bus arbiter
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity wb_arbiter is
    port (
        clk_i    : in  std_logic;
        rst_i    : in  std_logic;

        inst_cyc_i : in  std_logic;
        inst_stb_i : in  std_logic;
        inst_adr_i : in  std_logic_vector(XLEN-1 downto 2);
        inst_ack_o : out std_logic;
        inst_err_o : out std_logic;

        data_cyc_i : in  std_logic;
        data_stb_i : in  std_logic;
        data_adr_i : in  std_logic_vector(XLEN-1 downto 2);
        data_sel_i : in  std_logic_vector(3 downto 0);
        data_we_i  : in  std_logic;
        data_dat_i : in  std_logic_vector(XLEN-1 downto 0);
        data_ack_o : out std_logic;
        data_err_o : out std_logic;

        cyc_o   : out std_logic;
        stb_o   : out std_logic;
        adr_o   : out std_logic_vector(XLEN-1 downto 2);
        sel_o   : out std_logic_vector(3 downto 0);
        we_o    : out std_logic;
        dat_o   : out std_logic_vector(XLEN-1 downto 0);
        ack_i   : in  std_logic;
        err_i   : in  std_logic;
        dat_i   : in  std_logic_vector(XLEN-1 downto 0);
        inst_dat_o : out std_logic_vector(XLEN-1 downto 0);
        data_dat_o : out std_logic_vector(XLEN-1 downto 0)
    );
end entity wb_arbiter;

architecture rtl of wb_arbiter is

    type state_t is (IDLE, INST_GNT, DATA_GNT);

    signal state : state_t;

begin

    fsm_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state <= IDLE;
                cyc_o <= '0';
                stb_o <= '0';
                adr_o <= (others => '0');
                sel_o <= (others => '0');
                we_o  <= '0';
                dat_o <= (others => '0');
            else
                case state is
                    when IDLE =>
                        if data_cyc_i = '1' then
                            state <= DATA_GNT;
                            cyc_o <= data_cyc_i;
                            stb_o <= data_stb_i;
                            adr_o <= data_adr_i;
                            sel_o <= data_sel_i;
                            we_o  <= data_we_i;
                            dat_o <= data_dat_i;
                        elsif inst_cyc_i = '1' then
                            state <= INST_GNT;
                            cyc_o <= inst_cyc_i;
                            stb_o <= inst_stb_i;
                            adr_o <= inst_adr_i;
                            sel_o <= (others => '1');
                            we_o  <= '0';
                            dat_o <= (others => '0');
                        end if;
                    when DATA_GNT =>
                        if ack_i = '1' or err_i = '1' then
                            state <= IDLE;
                            cyc_o <= '0';
                            stb_o <= '0';
                            adr_o <= (others => '0');
                            sel_o <= (others => '0');
                            we_o  <= '0';
                            dat_o <= (others => '0');
                        end if;
                    when INST_GNT =>
                        if ack_i = '1' or err_i = '1' then
                            state <= IDLE;
                            cyc_o <= '0';
                            stb_o <= '0';
                            adr_o <= (others => '0');
                            sel_o <= (others => '0');
                            we_o  <= '0';
                            dat_o <= (others => '0');
                        end if;
                end case;
            end if;
        end if;
    end process fsm_proc;

    inst_ack_o <= ack_i when state = INST_GNT else '0';
    inst_err_o <= err_i when state = INST_GNT else '0';
    data_ack_o <= ack_i when state = DATA_GNT else '0';
    data_err_o <= err_i when state = DATA_GNT else '0';

    inst_dat_o <= dat_i when state = INST_GNT else (others => '0');
    data_dat_o <= dat_i when state = DATA_GNT else (others => '0');

end architecture rtl;