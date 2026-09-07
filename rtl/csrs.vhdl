----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: control and status registers
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity csrs is
    generic (
        MHART_ID : std_logic_vector(XLEN-1 downto 0) := (others => '0')
    );
    port (
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;
        ex_irq_i      : in  std_logic;
        sw_irq_i      : in  std_logic;
        tm_irq_i      : in  std_logic;
        -- The whole mcause code field, ranked in trap_ctrl. The interrupt and
        -- exception numberings collide (3, 7, 11), so it is stored as it arrives.
        mcause_exc_i  : in  std_logic_vector(4 downto 0);
        mtval_i       : in  std_logic_vector(XLEN-1 downto 0);
        -- mcause's interrupt bit, armed and registered in main_ctrl. The two
        -- numberings collide (3, 7, 11), so the bit and the code above must be
        -- the same snapshot: both arrive from the ID/EX boundary, neither is
        -- rebuilt here.
        int_trap_i    : in  std_logic;
        -- The PC to stack, not mepc_reg_o below -- that is mepc read back out.
        mepc_i        : in  std_logic_vector(XLEN-1 downto 2);
        mret_i        : in  std_logic;
        exc_taken_i   : in  std_logic;
        wr_en_i       : in  std_logic;
        wr_addr_i     : in  std_logic_vector(11 downto 0);
        rw_addr_i     : in  std_logic_vector(11 downto 0);
        wr_data_i     : in  std_logic_vector(XLEN-1 downto 0);
        pipe_en_i     : in  std_logic;
        pc_i          : in  std_logic_vector(XLEN-1 downto 2);
        cycle_i       : in  std_logic_vector(63 downto 0);
        timer_i       : in  std_logic_vector(63 downto 0);
        instret_i     : in  std_logic_vector(63 downto 0);
        cop_dat_i     : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o     : out std_logic_vector(5 downto 0);
        cop_dat_o     : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o      : out std_logic;
        -- The interrupt state itself, for main_ctrl to arm from: the enable
        -- and pending bit of each cause, plus the global enable. The mie and
        -- mstatus lines are the write-forwarded copies, so a csrrs that sets
        -- one arms the interrupt in the cycle it commits, not one later.
        mie_meie_o    : out std_logic;
        mie_mtie_o    : out std_logic;
        mie_msie_o    : out std_logic;
        mip_meip_o    : out std_logic;
        mip_mtip_o    : out std_logic;
        mip_msip_o    : out std_logic;
        mstatus_mie_o : out std_logic;
        -- The two redirect candidates, registered onto ID/EX. trap_ctrl picks
        -- between them with the same mret it drives taken_o from, so the whole
        -- redirect -- taken and target alike -- is decided there.
        mepc_reg_o    : out std_logic_vector(XLEN-1 downto 2);
        mtvec_reg_o   : out std_logic_vector(XLEN-1 downto 2);
        csrrd_data_o  : out std_logic_vector(XLEN-1 downto 0);
        pc_o          : out std_logic_vector(XLEN-1 downto 0)
    );
end entity csrs;

architecture rtl of csrs is

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

    signal cop_sel_rd          : std_logic;
    signal cop_sel_wr          : std_logic;
    signal rd_data_int         : std_logic_vector(XLEN-1 downto 0);
    signal rd_data_bypassed    : std_logic_vector(XLEN-1 downto 0);
    signal mepc_bypassed       : std_logic_vector(XLEN-1 downto 2);
    signal mtvec_base_bypassed : std_logic_vector(XLEN-1 downto 2);

    -- Same write-forwarding bypass as mepc/mtvec, so a csrrs that sets MIE arms
    -- the interrupt in the cycle it commits, not one cycle later.
    signal mie_meie_bypassed    : std_logic;
    signal mie_mtie_bypassed    : std_logic;
    signal mie_msie_bypassed    : std_logic;
    signal mstatus_mie_bypassed : std_logic;

    signal mepc_reg       : std_logic_vector(XLEN-1 downto 2);
    signal mtvec_base_reg : std_logic_vector(XLEN-1 downto 2);
    signal csrrd_data_reg : std_logic_vector(XLEN-1 downto 0);
    signal pc_reg         : std_logic_vector(XLEN-1 downto 2);

begin

    cop_sel_rd <= '1' when rw_addr_i(11 downto 6) = b"011111" else '0';
    cop_sel_wr <= '1' when wr_addr_i(11 downto 6) = b"011111" else '0';

    runit: rd_data_bypassed <= wr_data_i when (wr_en_i = '1' and wr_addr_i = rw_addr_i) else rd_data_int;

    read_csr: process(rw_addr_i, mstatus_mie, mstatus_mpie, mie_meie, mie_mtie, mie_msie, mtvec_base, mscratch, mepc, mcause_int, mcause_exc, mtval, mip_meip, mip_mtip, mip_msip, cycle_i, timer_i, instret_i, cop_sel_rd, cop_dat_i)
    begin
        case rw_addr_i is
            when CSR_ADDR_MHARTID  => rd_data_int <= MHART_ID;
            when CSR_ADDR_MISA     => rd_data_int <= (30 => '1', 8 => '1', others => '0');
            when CSR_ADDR_MSTATUS  => rd_data_int <= (12 downto 11 => '1', 7 => mstatus_mpie, 3 => mstatus_mie, others => '0');
            when CSR_ADDR_MIE      => rd_data_int <= (11 => mie_meie, 7 => mie_mtie, 3 => mie_msie, others => '0');
            when CSR_ADDR_MTVEC    => rd_data_int <= mtvec_base & b"00";
            when CSR_ADDR_MSCRATCH => rd_data_int <= mscratch;
            when CSR_ADDR_MEPC     => rd_data_int <= mepc & b"00";
            when CSR_ADDR_MCAUSE   => rd_data_int <= mcause_int & (30 downto 5 => '0') & mcause_exc;
            when CSR_ADDR_MTVAL    => rd_data_int <= mtval;
            when CSR_ADDR_MIP      => rd_data_int <= (11 => mip_meip, 7 => mip_mtip, 3 => mip_msip, others => '0');
            when CSR_ADDR_CYCLE    => rd_data_int <= cycle_i(XLEN-1 downto 0);
            when CSR_ADDR_TIME     => rd_data_int <= timer_i(XLEN-1 downto 0);
            when CSR_ADDR_INSTRET  => rd_data_int <= instret_i(XLEN-1 downto 0);
            when CSR_ADDR_CYCLEH   => rd_data_int <= cycle_i(63 downto 32);
            when CSR_ADDR_TIMEH    => rd_data_int <= timer_i(63 downto 32);
            when CSR_ADDR_INSTRETH => rd_data_int <= instret_i(63 downto 32);
            when others            =>
                if cop_sel_rd = '1' then
                    rd_data_int <= cop_dat_i;
                else
                    rd_data_int <= (others => '0');
                end if;
        end case;
    end process read_csr;

    write_mstatus: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mstatus_mie  <= '0';
                mstatus_mpie <= '1';
            elsif exc_taken_i = '1' then
                mstatus_mie  <= '0';
                mstatus_mpie <= mstatus_mie;
            elsif mret_i = '1' then
                mstatus_mie  <= mstatus_mpie;
                mstatus_mpie <= '1';
            elsif wr_addr_i = CSR_ADDR_MSTATUS and wr_en_i = '1' then
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
            elsif wr_addr_i = CSR_ADDR_MIE and wr_en_i = '1' then
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
            elsif wr_addr_i = CSR_ADDR_MTVEC and wr_en_i = '1' then
                mtvec_base <= wr_data_i(XLEN-1 downto 2);
            end if;
        end if;
    end process write_mtvec;

    write_mscratch: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mscratch <= (others => '0');
            elsif wr_addr_i = CSR_ADDR_MSCRATCH and wr_en_i = '1' then
                mscratch <= wr_data_i;
            end if;
        end if;
    end process write_mscratch;

    write_mepc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mepc <= (others => '0');
            elsif exc_taken_i = '1' then
                mepc <= mepc_i;
            elsif wr_addr_i = CSR_ADDR_MEPC and wr_en_i = '1' then
                mepc <= wr_data_i(XLEN-1 downto 2);
            end if;
        end if;
    end process write_mepc;

    -- The write is unconditional under exc_taken_i.
    write_mcause: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mcause_int <= '0';
                mcause_exc <= (others => '0');
            elsif exc_taken_i = '1' then
                mcause_int <= int_trap_i;
                mcause_exc <= mcause_exc_i;
            elsif wr_addr_i = CSR_ADDR_MCAUSE and wr_en_i = '1' then
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
            elsif exc_taken_i = '1' then
                mtval <= mtval_i;
            elsif wr_addr_i = CSR_ADDR_MTVAL and wr_en_i = '1' then
                mtval <= wr_data_i;
            end if;
        end if;
    end process write_mtval;

    write_mip: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mip_meip <= '0';
                mip_msip <= '0';
                mip_mtip <= '0';
            else
                mip_meip <= ex_irq_i;
                mip_msip <= sw_irq_i;
                mip_mtip <= tm_irq_i;
            end if;
        end if;
    end process write_mip;

    pipeline_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mepc_reg       <= (others => '0');
                mtvec_base_reg <= (others => '0');
                csrrd_data_reg <= (others => '0');
                pc_reg         <= (others => '0');
            elsif pipe_en_i = '1' then
                mepc_reg       <= mepc_bypassed;
                mtvec_base_reg <= mtvec_base_bypassed;
                csrrd_data_reg <= rd_data_bypassed;
                pc_reg         <= pc_i;
            end if;
        end if;
    end process pipeline_reg;

    mie_meie_bypassed    <= wr_data_i(11) when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MIE)     else mie_meie;
    mie_mtie_bypassed    <= wr_data_i(7)  when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MIE)     else mie_mtie;
    mie_msie_bypassed    <= wr_data_i(3)  when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MIE)     else mie_msie;
    mstatus_mie_bypassed <= wr_data_i(3)  when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MSTATUS) else mstatus_mie;
    mepc_bypassed        <= wr_data_i(XLEN-1 downto 2) when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MEPC)  else mepc;
    mtvec_base_bypassed  <= wr_data_i(XLEN-1 downto 2) when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MTVEC) else mtvec_base;

    cop_we_o        <= wr_en_i and cop_sel_wr;
    cop_adr_o       <= wr_addr_i(5 downto 0) when (wr_en_i and cop_sel_wr) = '1' else rw_addr_i(5 downto 0);
    cop_dat_o       <= wr_data_i;
    mie_meie_o      <= mie_meie_bypassed;
    mie_mtie_o      <= mie_mtie_bypassed;
    mie_msie_o      <= mie_msie_bypassed;
    mip_meip_o      <= mip_meip;
    mip_mtip_o      <= mip_mtip;
    mip_msip_o      <= mip_msip;
    mstatus_mie_o   <= mstatus_mie_bypassed;
    mepc_reg_o      <= mepc_reg;
    mtvec_reg_o     <= mtvec_base_reg;
    csrrd_data_o    <= csrrd_data_reg;
    pc_o            <= pc_reg & b"00";

end architecture rtl;