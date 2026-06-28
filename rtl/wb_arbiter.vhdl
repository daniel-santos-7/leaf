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

    type state_t is (INST_GRANT, DATA_GRANT);

    signal state : state_t;

begin

    fsm_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state <= INST_GRANT;
            else
                case state is
                    when INST_GRANT =>
                        if inst_cyc_i = '1' then
                            if ack_i = '1' or err_i = '1' then
                                if data_cyc_i = '1' then
                                    state <= DATA_GRANT;
                                end if;
                            end if;
                        else
                            if data_cyc_i = '1' then
                                state <= DATA_GRANT;
                            end if;
                        end if;
                    when DATA_GRANT =>
                        if data_cyc_i = '1' then
                            if ack_i = '1' or err_i = '1' then
                                if inst_cyc_i = '1' then
                                    state <= INST_GRANT;
                                end if;
                            end if;
                        else
                            if inst_cyc_i = '1' then
                                state <= INST_GRANT;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process fsm_proc;

    -- Combinatorial outputs --
    out_proc: process(state, inst_cyc_i, inst_stb_i, inst_adr_i,
                      data_cyc_i, data_stb_i, data_adr_i, data_sel_i,
                      data_we_i, data_dat_i)
    begin
        case state is
            when INST_GRANT =>
                cyc_o <= inst_cyc_i;
                stb_o <= inst_stb_i;
                adr_o <= inst_adr_i;
                sel_o <= (others => '1');
                we_o  <= '0';
                dat_o <= (others => '0');
            when DATA_GRANT =>
                cyc_o <= data_cyc_i;
                stb_o <= data_stb_i;
                adr_o <= data_adr_i;
                sel_o <= data_sel_i;
                we_o  <= data_we_i;
                dat_o <= data_dat_i;
        end case;
    end process out_proc;

    inst_ack_o <= ack_i when state = INST_GRANT else '0';
    inst_err_o <= err_i when state = INST_GRANT else '0';
    data_ack_o <= ack_i when state = DATA_GRANT else '0';
    data_err_o <= err_i when state = DATA_GRANT else '0';

    inst_dat_o <= dat_i when state = INST_GRANT else (others => '0');
    data_dat_o <= dat_i when state = DATA_GRANT else (others => '0');

end architecture rtl;