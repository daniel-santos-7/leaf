----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: control and status registers
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;

entity csrs is
    generic (
        MHART_ID : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        ex_irq      : in  std_logic;
        sw_irq      : in  std_logic;
        tm_irq      : in  std_logic;
        imrd_malgn  : in  std_logic;
        imrd_fault  : in  std_logic;
        instr_err   : in  std_logic;
        dmld_malgn  : in  std_logic;
        dmld_fault  : in  std_logic;
        dmst_malgn  : in  std_logic;
        dmst_fault  : in  std_logic;
        wr_en       : in  std_logic;
        wr_mode     : in  std_logic_vector(2  downto 0);
        rw_addr     : in  std_logic_vector(11 downto 0);
        wr_data     : in  std_logic_vector(31 downto 0);
        exec_res    : in  std_logic_vector(31 downto 0);
        pc          : in  std_logic_vector(31 downto 0);
        next_pc     : in  std_logic_vector(31 downto 0);
        cycle       : in  std_logic_vector(63 downto 0);
        timer       : in  std_logic_vector(63 downto 0);
        instret     : in  std_logic_vector(63 downto 0);
        pcwr_en     : out std_logic;
        trap_taken  : out std_logic;
        trap_target : out std_logic_vector(31 downto 0);
        rd_data     : out std_logic_vector(31 downto 0)
    );
end entity csrs;

architecture rtl of csrs is

    -- registers --

    signal mstatus_mie  : std_logic;
    signal mstatus_mpie : std_logic;
    signal mie_meie     : std_logic;
    signal mie_mtie     : std_logic;
    signal mie_msie     : std_logic;
    signal mtvec_base   : std_logic_vector(31 downto 2);
    signal mscratch     : std_logic_vector(31 downto 0);
    signal mepc         : std_logic_vector(31 downto 2);
    signal mcause_int   : std_logic;
    signal mcause_exc   : std_logic_vector(4 downto 0);
    signal mtval        : std_logic_vector(31 downto 0);
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

begin

    env_exc <= '1' when wr_en = '1' and wr_mode = b"000" else '0';
    ecall   <= '1' when env_exc = '1' and rw_addr = x"000" else '0';
    ebreak  <= '1' when env_exc = '1' and rw_addr = x"001" else '0';
    wfi     <= '1' when env_exc = '1' and rw_addr = x"105" else '0';
    mret    <= '1' when env_exc = '1' and rw_addr = x"302" else '0';

    exi_taken <= mie_meie and mip_meip;
    tmi_taken <= mie_mtie and mip_mtip;
    swi_taken <= mie_msie and mip_msip;

    int_taken <= (exi_taken or tmi_taken or swi_taken) and mstatus_mie;
    exc_taken <= imrd_malgn or imrd_fault or instr_err or ebreak or dmld_malgn or dmld_fault or dmst_malgn or dmst_fault or ecall or int_taken or mret;

    read_csr: process(rw_addr, mstatus_mie, mstatus_mpie, mie_meie, mie_mtie, mie_msie, mtvec_base, mscratch, mepc, mcause_int, mcause_exc, mtval, mip_meip, mip_mtip, mip_msip, cycle, timer, instret)
    begin
        case rw_addr is
            when CSR_ADDR_MHARTID  => rd_data <= MHART_ID;
            when CSR_ADDR_MISA     => rd_data <= (30 => '1', 8 => '1', others => '0');
            when CSR_ADDR_MSTATUS  => rd_data <= (12 downto 11 => '1', 7 => mstatus_mpie, 3 => mstatus_mie, others => '0');
            when CSR_ADDR_MIE      => rd_data <= (11 => mie_meie, 7 => mie_mtie, 3 => mie_msie, others => '0');
            when CSR_ADDR_MTVEC    => rd_data <= mtvec_base & b"00";
            when CSR_ADDR_MSCRATCH => rd_data <= mscratch;
            when CSR_ADDR_MEPC     => rd_data <= mepc & b"00";
            when CSR_ADDR_MCAUSE   => rd_data <= mcause_int & (30 downto 5 => '0') & mcause_exc;
            when CSR_ADDR_MTVAL    => rd_data <= mtval;
            when CSR_ADDR_MIP      => rd_data <= (11 => mip_meip, 7 => mip_mtip, 3 => mip_msip, others => '0');
            when CSR_ADDR_CYCLE    => rd_data <= cycle(31 downto  0);
            when CSR_ADDR_TIME     => rd_data <= timer(31 downto  0);
            when CSR_ADDR_INSTRET  => rd_data <= instret(31 downto  0);
            when CSR_ADDR_CYCLEH   => rd_data <= cycle(63 downto 32);
            when CSR_ADDR_TIMEH    => rd_data <= timer(63 downto 32);
            when CSR_ADDR_INSTRETH => rd_data <= instret(63 downto 32);
            when others            => rd_data <= (others => '0');
        end case;
    end process read_csr;

    write_mstatus: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mstatus_mie  <= '0';
                mstatus_mpie <= '1';
            elsif exc_taken = '1' then
                mstatus_mie  <= '0';
                mstatus_mpie <= mstatus_mie;
            elsif mret = '1' then
                mstatus_mie  <= mstatus_mpie;
                mstatus_mpie <= '1';
            elsif rw_addr = CSR_ADDR_MSTATUS and wr_en = '1' then
                mstatus_mie  <= wr_data(3);
                mstatus_mpie <= wr_data(7);
            end if;
        end if;
    end process write_mstatus;

    write_mie: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mie_meie <= '0';
                mie_mtie <= '0';
                mie_msie <= '0';
            elsif rw_addr = CSR_ADDR_MIE and wr_en = '1' then
                mie_meie <= wr_data(11);
                mie_mtie <= wr_data(7);
                mie_msie <= wr_data(3);
            end if;
        end if;
    end process write_mie;

    write_mtvec: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mtvec_base <= (others => '0');
            elsif rw_addr = CSR_ADDR_MTVEC and wr_en = '1' then
                mtvec_base <= wr_data(31 downto 2);
            end if;
        end if;
    end process write_mtvec;

    write_mscratch: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mscratch <= (others => '0');
            elsif rw_addr = CSR_ADDR_MSCRATCH and wr_en = '1' then
                mscratch <= wr_data;
            end if;
        end if;
    end process write_mscratch;

    write_mepc: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mepc <= (others => '0');
            elsif exc_taken = '1' then
                if wfi = '1' then
                    mepc <= next_pc(31 downto 2);
                else
                    mepc <= pc(31 downto 2);
                end if;
            elsif rw_addr = CSR_ADDR_MEPC and wr_en = '1' then
                mepc <= wr_data(31 downto 2);
            end if;
        end if;
    end process write_mepc;

    write_mcause: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mcause_int <= '0';
                mcause_exc <= (others => '0');
            elsif exc_taken = '1' then
                mcause_int <= int_taken;
                if int_taken = '1' then
                    if swi_taken = '1' then
                        mcause_exc <= b"00011";
                    elsif tmi_taken = '1' then
                        mcause_exc <= b"00111";
                    elsif exc_taken = '1' then
                        mcause_exc <= b"01011";
                    end if;
                else
                    if imrd_malgn = '1' then
                        mcause_exc <= b"00000";
                    elsif imrd_fault = '1' then
                        mcause_exc <= b"00001";
                    elsif instr_err = '1' then
                        mcause_exc <= b"00010";
                    elsif ebreak = '1' then
                        mcause_exc <= b"00011";
                    elsif dmld_malgn = '1' then
                        mcause_exc <= b"00100";
                    elsif dmld_fault = '1' then
                        mcause_exc <= b"00101";
                    elsif dmst_malgn = '1' then
                        mcause_exc <= b"00110";
                    elsif dmst_fault = '1' then
                        mcause_exc <= b"00111";
                    elsif ecall = '1' then
                        mcause_exc <= b"01011";
                    end if;
                end if;
            elsif rw_addr = CSR_ADDR_MCAUSE and wr_en = '1' then
                mcause_int <= wr_data(31);
                mcause_exc <= wr_data(4 downto 0);
            end if;
        end if;
    end process write_mcause;

    write_mtval: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mtval <= (others => '0');
            elsif exc_taken = '1' then
                if imrd_malgn = '1' or dmld_malgn = '1' or dmst_malgn = '1' then
                    mtval <= exec_res;
                elsif ebreak = '1' then
                    mtval <= pc;
                else
                    mtval <= (others => '0');
                end if;
            elsif rw_addr = CSR_ADDR_MTVAL and wr_en = '1' then
                mtval <= wr_data;
            end if;
        end if;
    end process write_mtval;

    write_mip: process(reset, ex_irq, sw_irq, tm_irq)
    begin
        if reset = '1' then
            mip_meip <= '0';
            mip_msip <= '0';
            mip_mtip <= '0';
        else
            mip_meip <= ex_irq;
            mip_msip <= sw_irq;
            mip_mtip <= tm_irq;
        end if;
    end process write_mip;

    pcwr_en     <= exi_taken or tmi_taken or swi_taken or not wfi;
    trap_taken  <= exc_taken;
    trap_target <= mepc & b"00" when mret = '1' else mtvec_base & b"00";

end architecture rtl;
