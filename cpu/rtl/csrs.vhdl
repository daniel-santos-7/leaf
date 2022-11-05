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
use work.core_pkg.all;

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
        dmrd_malgn  : in  std_logic;
        dmrd_fault  : in  std_logic;
        dmwr_malgn  : in  std_logic;
        dmwr_fault  : in  std_logic;
        wr_en       : in  std_logic;
        cycle       : in  std_logic_vector(63 downto 0);
        timer       : in  std_logic_vector(63 downto 0);
        instret     : in  std_logic_vector(63 downto 0);
        pc          : in  std_logic_vector(31 downto 0);
        next_pc     : in  std_logic_vector(31 downto 0);
        wr_mode     : in  std_logic_vector(2  downto 0);
        rd_wr_addr  : in  std_logic_vector(11 downto 0);
        wr_reg_data : in  std_logic_vector(31 downto 0);
        wr_imm_data : in  std_logic_vector(31 downto 0);
        rd_data     : out std_logic_vector(31 downto 0)
    );
end entity csrs;

architecture csrs_arch of csrs is

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

    signal env_exc   : std_logic;
    signal ecall     : std_logic;
    signal ebreak    : std_logic;
    signal exi_taken : std_logic;
    signal swi_taken : std_logic;
    signal tmi_taken : std_logic;
    signal int_taken : std_logic;
    signal exc_taken : std_logic;

    signal wr_data_i : std_logic_vector(31 downto 0);
    signal rd_data_i : std_logic_vector(31 downto 0);

begin
    
    env_exc <= '1' when wr_en = '1' and wr_mode = b"000";
    ecall   <= '1' when env_exc = '1' and rd_wr_addr = x"000";
    ebreak  <= '1' when env_exc = '1' and rd_wr_addr = x"001";

    exi_taken <= mie_meie and mip_meip;
    tmi_taken <= mip_mtip and mie_mtie;
    swi_taken <= mip_msip and mie_msie;

    int_taken <= (exi_taken or tmi_taken or swi_taken) and mstatus_mie;
    exc_taken <= imrd_malgn or imrd_fault or instr_err or ebreak or dmrd_malgn or dmrd_fault or dmwr_malgn or dmwr_fault or ecall or int_taken;

    read_csr: process(rd_wr_addr, mstatus_mie, mstatus_mpie, mie_meie, mie_mtie, mie_msie, mtvec_base, mscratch, mepc, mcause_int, mcause_exc, mtval, mip_meip, mip_mtip, mip_msip, cycle, timer, instret)
    begin
        case rd_wr_addr is
            when CSR_ADDR_MHARTID  => rd_data_i <= MHART_ID;
            when CSR_ADDR_MISA     => rd_data_i <= (30 => '1', 8 => '1', others => '0');
            when CSR_ADDR_MSTATUS  => rd_data_i <= (7 => mstatus_mpie, 3 => mstatus_mie, others => '0');
            when CSR_ADDR_MIE      => rd_data_i <= (11 => mie_meie, 7 => mie_mtie, 3 => mie_msie, others => '0');
            when CSR_ADDR_MTVEC    => rd_data_i <= mtvec_base & b"00";
            when CSR_ADDR_MSCRATCH => rd_data_i <= mscratch;
            when CSR_ADDR_MEPC     => rd_data_i <= mepc & b"00";
            when CSR_ADDR_MCAUSE   => rd_data_i <= mcause_int & (30 downto 5 => '0') & mcause_exc;
            when CSR_ADDR_MTVAL    => rd_data_i <= mtval;
            when CSR_ADDR_MIP      => rd_data_i <= (11 => mip_meip, 7 => mip_mtip, 3 => mip_msip, others => '0');
            when CSR_ADDR_CYCLE    => rd_data_i <= cycle(31 downto  0);
            when CSR_ADDR_TIME     => rd_data_i <= timer(31 downto  0);
            when CSR_ADDR_INSTRET  => rd_data_i <= instret(31 downto  0);
            when CSR_ADDR_CYCLEH   => rd_data_i <= cycle(63 downto 32);
            when CSR_ADDR_TIMEH    => rd_data_i <= timer(63 downto 32);
            when CSR_ADDR_INSTRETH => rd_data_i <= instret(63 downto 32);
            when others            => rd_data_i <= (others => '0');
        end case;
    end process read_csr;

    wr_csr: process(wr_mode, wr_reg_data, wr_imm_data, rd_data_i)
    begin
        case wr_mode is
            when b"001" => wr_data_i <= wr_reg_data;
            when b"010" => wr_data_i <= rd_data_i or wr_reg_data;
            when b"011" => wr_data_i <= rd_data_i and not (wr_reg_data);
            when b"101" => wr_data_i <= wr_imm_data;
            when b"110" => wr_data_i <= rd_data_i or wr_imm_data;
            when b"111" => wr_data_i <= rd_data_i and not (wr_imm_data);
            when others => wr_data_i <= (others => '0');
        end case;
    end process wr_csr;

    write_mstatus: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mstatus_mie  <= '0';
                mstatus_mpie <= '1';
            elsif exc_taken = '1' then
                mstatus_mie  <= '0';
                mstatus_mpie <= mstatus_mie;
            elsif rd_wr_addr = CSR_ADDR_MSTATUS and wr_en = '1' then
                mstatus_mie  <= wr_data_i(3);
                mstatus_mpie <= wr_data_i(7);
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
            elsif rd_wr_addr = CSR_ADDR_MIE and wr_en = '1' then
                mie_meie <= wr_data_i(11);
                mie_mtie <= wr_data_i(7);
                mie_msie <= wr_data_i(3);
            end if;
        end if;
    end process write_mie;

    write_mtvec: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mtvec_base <= (others => '0');
            elsif rd_wr_addr = CSR_ADDR_MTVEC and wr_en = '1' then
                mtvec_base <= wr_data_i(31 downto 2);
            end if;
        end if;
    end process write_mtvec;

    write_mscratch: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mscratch <= (others => '0');
            elsif rd_wr_addr = CSR_ADDR_MSCRATCH and wr_en = '1' then
                mscratch <= wr_data_i;
            end if;
        end if;
    end process write_mscratch;

    write_mepc: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mepc <= (others => '0');
            elsif exc_taken = '1' then
                mepc <= pc(31 downto 2);
            elsif rd_wr_addr = CSR_ADDR_MEPC and wr_en = '1' then
                mepc <= wr_data_i(31 downto 2);
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
                    elsif dmrd_malgn = '1' then
                        mcause_exc <= b"00100";
                    elsif dmrd_fault = '1' then
                        mcause_exc <= b"00101";
                    elsif dmwr_malgn = '1' then
                        mcause_exc <= b"00110";
                    elsif dmwr_fault = '1' then
                        mcause_exc <= b"00111";
                    elsif ecall = '1' then
                        mcause_exc <= b"01011";
                    end if;
                end if;
            elsif rd_wr_addr = CSR_ADDR_MCAUSE and wr_en = '1' then
                mcause_int <= wr_data_i(31);
                mcause_exc <= wr_data_i(4 downto 0);
            end if;
        end if;
    end process write_mcause;

    write_mtval: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mtval <= (others => '0');
            elsif exc_taken = '1' then
                if imrd_malgn = '1' then
                    mtval <= next_pc;
                else
                    mtval <= (others => '0');
                end if;
            elsif rd_wr_addr = CSR_ADDR_MTVAL and wr_en = '1' then
                mtval <= wr_data_i;
            end if;
        end if;
    end process write_mtval;

    write_mip: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mip_meip <= '0';
                mip_msip <= '0';
                mip_mtip <= '0';
            else
                mip_meip <= ex_irq;
                mip_msip <= sw_irq;
                mip_mtip <= tm_irq;
            end if;
        end if;
    end process write_mip;
    
    rd_data <= rd_data_i;

end architecture csrs_arch;