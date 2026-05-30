----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: control and status registers
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;

entity csrs is
    generic (
        MHART_ID : std_logic_vector(XLEN-1 downto 0) := (others => '0')
    );
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        ex_irq_i     : in  std_logic;
        sw_irq_i     : in  std_logic;
        tm_irq_i     : in  std_logic;
        imrd_malgn_i : in  std_logic;
        imrd_fault_i : in  std_logic;
        instr_err_i  : in  std_logic;
        dmld_malgn_i : in  std_logic;
        dmld_fault_i : in  std_logic;
        dmst_malgn_i : in  std_logic;
        dmst_fault_i : in  std_logic;
        wr_en_i      : in  std_logic;
        wr_mode_i    : in  std_logic_vector(2  downto 0);
        rw_addr_i    : in  std_logic_vector(11 downto 0);
        wr_data_i    : in  std_logic_vector(XLEN-1 downto 0);
        exec_res_i   : in  std_logic_vector(XLEN-1 downto 0);
        pc_i         : in  std_logic_vector(XLEN-1 downto 0);
        next_pc_i    : in  std_logic_vector(XLEN-1 downto 0);
        cycle_i      : in  std_logic_vector(63 downto 0);
        timer_i      : in  std_logic_vector(63 downto 0);
        instret_i    : in  std_logic_vector(63 downto 0);
        cop_dat_i    : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o    : out std_logic_vector(5 downto 0);
        cop_dat_o    : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o     : out std_logic;
        pcwr_en_o    : out std_logic;
        trap_taken_o : out std_logic;
        trap_target_o: out std_logic_vector(XLEN-1 downto 0);
        rd_data_o    : out std_logic_vector(XLEN-1 downto 0)
    );
end entity csrs;

architecture rtl of csrs is

    -- registers --

    signal mstatus_mie  : std_logic;
    signal mstatus_mpie : std_logic;
    signal mie_meie     : std_logic;
    signal mie_mtie     : std_logic;
    signal mie_msie     : std_logic;
    signal mtvec_base   : std_logic_vector(XLEN-1 downto 2);
    signal mscratch     : std_logic_vector(XLEN-1 downto 0);
    signal mepc         : std_logic_vector(XLEN-1 downto 2);
    signal mcause_int   : std_logic;
    signal mcause_exc   : std_logic_vector(4 downto 0);
    signal mtval        : std_logic_vector(XLEN-1 downto 0);
    signal mip_meip     : std_logic;
    signal mip_mtip     : std_logic;
    signal mip_msip     : std_logic;

    -- system calls --

    signal env_exc : std_logic;
    signal ecall   : std_logic;
    signal ebreak  : std_logic;
    signal mret    : std_logic;
    signal wfi     : std_logic;

    -- interruptions taken signals --

    signal exi_taken : std_logic;
    signal swi_taken : std_logic;
    signal tmi_taken : std_logic;
    signal int_taken : std_logic;
    signal exc_taken : std_logic;
    signal cop_sel   : std_logic;

begin

    env_exc <= '1' when wr_en_i = '1' and wr_mode_i = b"000" else '0';
    ecall   <= '1' when env_exc = '1' and rw_addr_i = x"000" else '0';
    ebreak  <= '1' when env_exc = '1' and rw_addr_i = x"001" else '0';
    wfi     <= '1' when env_exc = '1' and rw_addr_i = x"105" else '0';
    mret    <= '1' when env_exc = '1' and rw_addr_i = x"302" else '0';

    exi_taken <= mie_meie and mip_meip;
    tmi_taken <= mie_mtie and mip_mtip;
    swi_taken <= mie_msie and mip_msip;

    int_taken <= (exi_taken or tmi_taken or swi_taken) and mstatus_mie;
    exc_taken <= imrd_malgn_i or imrd_fault_i or instr_err_i or ebreak or dmld_malgn_i or dmld_fault_i or dmst_malgn_i or dmst_fault_i or ecall or int_taken;
    cop_sel <= '1' when rw_addr_i(11 downto 6) = b"011111" else '0';

    read_csr: process(rw_addr_i, mstatus_mie, mstatus_mpie, mie_meie, mie_mtie, mie_msie, mtvec_base, mscratch, mepc, mcause_int, mcause_exc, mtval, mip_meip, mip_mtip, mip_msip, cycle_i, timer_i, instret_i, cop_sel, cop_dat_i)
    begin
        case rw_addr_i is
            when CSR_ADDR_MHARTID  => rd_data_o <= MHART_ID;
            when CSR_ADDR_MISA     => rd_data_o <= (30 => '1', 8 => '1', others => '0');
            when CSR_ADDR_MSTATUS  => rd_data_o <= (12 downto 11 => '1', 7 => mstatus_mpie, 3 => mstatus_mie, others => '0');
            when CSR_ADDR_MIE      => rd_data_o <= (11 => mie_meie, 7 => mie_mtie, 3 => mie_msie, others => '0');
            when CSR_ADDR_MTVEC    => rd_data_o <= mtvec_base & b"00";
            when CSR_ADDR_MSCRATCH => rd_data_o <= mscratch;
            when CSR_ADDR_MEPC     => rd_data_o <= mepc & b"00";
            when CSR_ADDR_MCAUSE   => rd_data_o <= mcause_int & (30 downto 5 => '0') & mcause_exc;
            when CSR_ADDR_MTVAL    => rd_data_o <= mtval;
            when CSR_ADDR_MIP      => rd_data_o <= (11 => mip_meip, 7 => mip_mtip, 3 => mip_msip, others => '0');
            when CSR_ADDR_CYCLE    => rd_data_o <= cycle_i(XLEN-1 downto 0);
            when CSR_ADDR_TIME     => rd_data_o <= timer_i(XLEN-1 downto 0);
            when CSR_ADDR_INSTRET  => rd_data_o <= instret_i(XLEN-1 downto 0);
            when CSR_ADDR_CYCLEH   => rd_data_o <= cycle_i(63 downto 32);
            when CSR_ADDR_TIMEH    => rd_data_o <= timer_i(63 downto 32);
            when CSR_ADDR_INSTRETH => rd_data_o <= instret_i(63 downto 32);
            when others            =>
                if cop_sel = '1' then
                    rd_data_o <= cop_dat_i;
                else
                    rd_data_o <= (others => '0');
                end if;
        end case;
    end process read_csr;

    write_mstatus: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mstatus_mie  <= '0';
                mstatus_mpie <= '1';
            elsif exc_taken = '1' then
                mstatus_mie  <= '0';
                mstatus_mpie <= mstatus_mie;
            elsif mret = '1' then
                mstatus_mie  <= mstatus_mpie;
                mstatus_mpie <= '1';
            elsif rw_addr_i = CSR_ADDR_MSTATUS and wr_en_i = '1' then
                mstatus_mie  <= wr_data_i(3);
                mstatus_mpie <= wr_data_i(7);
            end if;
        end if;
    end process write_mstatus;

    write_mie: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mie_meie <= '0';
                mie_mtie <= '0';
                mie_msie <= '0';
            elsif rw_addr_i = CSR_ADDR_MIE and wr_en_i = '1' then
                mie_meie <= wr_data_i(11);
                mie_mtie <= wr_data_i(7);
                mie_msie <= wr_data_i(3);
            end if;
        end if;
    end process write_mie;

    write_mtvec: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mtvec_base <= (others => '0');
            elsif rw_addr_i = CSR_ADDR_MTVEC and wr_en_i = '1' then
                mtvec_base <= wr_data_i(XLEN-1 downto 2);
            end if;
        end if;
    end process write_mtvec;

    write_mscratch: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mscratch <= (others => '0');
            elsif rw_addr_i = CSR_ADDR_MSCRATCH and wr_en_i = '1' then
                mscratch <= wr_data_i;
            end if;
        end if;
    end process write_mscratch;

    write_mepc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mepc <= (others => '0');
            elsif exc_taken = '1' then
                if wfi = '1' then
                    mepc <= next_pc_i(XLEN-1 downto 2);
                else
                    mepc <= pc_i(XLEN-1 downto 2);
                end if;
            elsif rw_addr_i = CSR_ADDR_MEPC and wr_en_i = '1' then
                mepc <= wr_data_i(XLEN-1 downto 2);
            end if;
        end if;
    end process write_mepc;

    write_mcause: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mcause_int <= '0';
                mcause_exc <= (others => '0');
            elsif exc_taken = '1' then
                mcause_int <= int_taken;
                if int_taken = '1' then
                    if swi_taken = '1' then
                        mcause_exc <= b"00011";
                    elsif tmi_taken = '1' then
                        mcause_exc <= b"00111";
                    elsif exi_taken = '1' then
                        mcause_exc <= b"01011";
                    end if;
                else
                    if imrd_malgn_i = '1' then
                        mcause_exc <= b"00000";
                    elsif imrd_fault_i = '1' then
                        mcause_exc <= b"00001";
                    elsif instr_err_i = '1' then
                        mcause_exc <= b"00010";
                    elsif ebreak = '1' then
                        mcause_exc <= b"00011";
                    elsif dmld_malgn_i = '1' then
                        mcause_exc <= b"00100";
                    elsif dmld_fault_i = '1' then
                        mcause_exc <= b"00101";
                    elsif dmst_malgn_i = '1' then
                        mcause_exc <= b"00110";
                    elsif dmst_fault_i = '1' then
                        mcause_exc <= b"00111";
                    elsif ecall = '1' then
                        mcause_exc <= b"01011";
                    end if;
                end if;
            elsif rw_addr_i = CSR_ADDR_MCAUSE and wr_en_i = '1' then
                mcause_int <= wr_data_i(XLEN-1);
                mcause_exc <= wr_data_i(4 downto 0);
            end if;
        end if;
    end process write_mcause;

    write_mtval: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mtval <= (others => '0');
            elsif exc_taken = '1' then
                if int_taken = '1' then
                    mtval <= (others => '0');
                elsif imrd_malgn_i = '1' then
                    mtval <= exec_res_i;
                elsif imrd_fault_i = '1' then
                    mtval <= pc_i;
                elsif instr_err_i = '1' then
                    mtval <= (others => '0');
                elsif ebreak = '1' then
                    mtval <= pc_i;
                elsif dmld_malgn_i = '1' or dmld_fault_i = '1' or dmst_malgn_i = '1' or dmst_fault_i = '1' then
                    mtval <= exec_res_i;
                else
                    mtval <= (others => '0');   -- ecall
                end if;
            elsif rw_addr_i = CSR_ADDR_MTVAL and wr_en_i = '1' then
                mtval <= wr_data_i;
            end if;
        end if;
    end process write_mtval;

    write_mip: process(reset_i, ex_irq_i, sw_irq_i, tm_irq_i)
    begin
        if reset_i = '1' then
            mip_meip <= '0';
            mip_msip <= '0';
            mip_mtip <= '0';
        else
            mip_meip <= ex_irq_i;
            mip_msip <= sw_irq_i;
            mip_mtip <= tm_irq_i;
        end if;
    end process write_mip;

    cop_adr_o <= rw_addr_i(5 downto 0);
    cop_dat_o <= wr_data_i;
    cop_we_o  <= wr_en_i and cop_sel;

    pcwr_en_o     <= exi_taken or tmi_taken or swi_taken or not wfi;
    trap_taken_o  <= exc_taken or mret;
    trap_target_o <= mepc & b"00" when mret = '1' else mtvec_base & b"00";

end architecture rtl;
