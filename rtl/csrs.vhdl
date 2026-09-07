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
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        ex_irq_i     : in  std_logic;
        sw_irq_i     : in  std_logic;
        tm_irq_i     : in  std_logic;
        -- The whole mcause code field, ranked in trap_ctrl. The interrupt and
        -- exception numberings collide (3, 7, 11), so it is stored as it arrives.
        mcause_exc_i : in  std_logic_vector(4 downto 0);
        mtval_i      : in  std_logic_vector(XLEN-1 downto 0);
        -- The PC to stack, not mepc_reg_o below -- that is mepc read back out.
        mepc_i       : in  std_logic_vector(XLEN-1 downto 2);
        mret_i       : in  std_logic;
        exc_taken_i  : in  std_logic;
        wr_en_i      : in  std_logic;
        id_valid_i   : in  std_logic;
        wr_addr_i    : in  std_logic_vector(11 downto 0);
        rw_addr_i    : in  std_logic_vector(11 downto 0);
        wr_data_i    : in  std_logic_vector(XLEN-1 downto 0);
        pipe_en_i    : in  std_logic;
        pc_i         : in  std_logic_vector(XLEN-1 downto 2);
        cycle_i      : in  std_logic_vector(63 downto 0);
        timer_i      : in  std_logic_vector(63 downto 0);
        instret_i    : in  std_logic_vector(63 downto 0);
        cop_dat_i    : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o    : out std_logic_vector(5 downto 0);
        cop_dat_o    : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o     : out std_logic;
        -- One armed interrupt per cause -- mie bit and mip bit, masked by
        -- mstatus.MIE -- registered onto ID/EX beside int_trap_o. trap_ctrl
        -- ranks these to name mcause, so they must be the same snapshot that
        -- armed the trap: from the live causes the code and the interrupt bit
        -- can disagree and mcause comes out as an unrelated exception.
        exi_trap_o   : out std_logic;
        tmi_trap_o   : out std_logic;
        swi_trap_o   : out std_logic;
        -- Their live OR: main_ctrl's decode squash and mcause's interrupt bit.
        int_taken_o  : out std_logic;
        -- The same OR without mstatus.MIE, for the wfi wake alone. The spec
        -- makes WFI unaffected by the global enable: a locally enabled
        -- interrupt must resume the hart even with MIE clear, and then simply
        -- takes no trap. Covered by verif/tests/wfi_mie0.
        int_pend_o   : out std_logic;
        -- The OR of the three registered arms above, so it reaches ex_block
        -- beside the instruction squashed for it -- whose pc is the mepc -- and
        -- cannot drift from the cause trap_ctrl ranks the way a fourth flop of
        -- its own could.
        int_trap_o   : out std_logic;
        -- The two redirect candidates, registered onto ID/EX. trap_ctrl picks
        -- between them with the same mret it drives taken_o from, so the whole
        -- redirect -- taken and target alike -- is decided there.
        mepc_reg_o   : out std_logic_vector(XLEN-1 downto 2);
        mtvec_reg_o  : out std_logic_vector(XLEN-1 downto 2);
        csrrd_data_o : out std_logic_vector(XLEN-1 downto 0);
        pc_o         : out std_logic_vector(XLEN-1 downto 0)
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
    signal exi_pend             : std_logic;
    signal tmi_pend             : std_logic;
    signal swi_pend             : std_logic;
    signal int_pend             : std_logic;
    signal int_taken            : std_logic;
    signal exi_trap             : std_logic;
    signal tmi_trap             : std_logic;
    signal swi_trap             : std_logic;

    signal mepc_reg       : std_logic_vector(XLEN-1 downto 2);
    signal mtvec_base_reg : std_logic_vector(XLEN-1 downto 2);
    signal csrrd_data_reg : std_logic_vector(XLEN-1 downto 0);
    signal pc_reg         : std_logic_vector(XLEN-1 downto 2);
    signal exi_trap_reg   : std_logic;
    signal tmi_trap_reg   : std_logic;
    signal swi_trap_reg   : std_logic;
    signal int_trap       : std_logic;

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

    -- The write is unconditional under exc_taken_i. mcause.INT comes from the
    -- registered arms, not the live int_taken: the two encodings collide at 3, 7
    -- and 11, so an interrupt going pending during an ecall's own commit cycle
    -- would otherwise flip that ecall's mcause to an interrupt code.
    write_mcause: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mcause_int <= '0';
                mcause_exc <= (others => '0');
            elsif exc_taken_i = '1' then
                mcause_int <= int_trap;
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
                exi_trap_reg   <= '0';
                tmi_trap_reg   <= '0';
                swi_trap_reg   <= '0';
            elsif pipe_en_i = '1' then
                mepc_reg       <= mepc_bypassed;
                mtvec_base_reg <= mtvec_base_bypassed;
                csrrd_data_reg <= rd_data_bypassed;
                pc_reg         <= pc_i;
                exi_trap_reg   <= exi_trap;
                tmi_trap_reg   <= tmi_trap;
                swi_trap_reg   <= swi_trap;
            end if;
        end if;
    end process pipeline_reg;

    mie_meie_bypassed    <= wr_data_i(11) when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MIE)     else mie_meie;
    mie_mtie_bypassed    <= wr_data_i(7)  when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MIE)     else mie_mtie;
    mie_msie_bypassed    <= wr_data_i(3)  when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MIE)     else mie_msie;
    mstatus_mie_bypassed <= wr_data_i(3)  when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MSTATUS) else mstatus_mie;
    mepc_bypassed        <= wr_data_i(XLEN-1 downto 2) when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MEPC)  else mepc;
    mtvec_base_bypassed  <= wr_data_i(XLEN-1 downto 2) when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MTVEC) else mtvec_base;

    -- mip needs no bypass: it is not writable. Each pending line carries its
    -- own mie bit and nothing else: mstatus.MIE is added where it belongs, to
    -- int_taken and to the arms below, and never to int_pend -- the wfi wake
    -- reads that one and must ignore the global enable.
    exi_pend  <= mie_meie_bypassed and mip_meip;
    tmi_pend  <= mie_mtie_bypassed and mip_mtip;
    swi_pend  <= mie_msie_bypassed and mip_msip;
    int_pend  <= exi_pend or tmi_pend or swi_pend;

    int_taken <= int_pend and mstatus_mie_bypassed;

    -- The armed trap, one cause per line, guarded three times: the global
    -- enable the pending lines leave out, plus the two below.
    --
    -- The one-shot: mstatus.MIE only clears at the edge exc_taken_i commits the
    -- trap, so the causes above are still up through that cycle and the trap
    -- would commit twice. id_valid_i covers this on its own today -- exc_taken
    -- reaches flush_i, which main_ctrl already subtracts -- so exc_taken_i here
    -- is redundant, kept as the local guard rather than a dependency on how far
    -- flush_i happens to reach. Covered by verif/tests/wfi_timer.
    --
    -- id_valid_i pins the trap to a real instruction. pc_reg tracks the ID slot
    -- whether or not it decoded, so arming on a stale or flushed slot stacks a
    -- wrong-path pc: an interrupt landing in an mret's shadow took the handler's
    -- own address as its mepc and the mret then returned into itself. Covered by
    -- verif/tests/int_mret_shadow.
    exi_trap  <= exi_pend and mstatus_mie_bypassed and not exc_taken_i and id_valid_i;
    tmi_trap  <= tmi_pend and mstatus_mie_bypassed and not exc_taken_i and id_valid_i;
    swi_trap  <= swi_pend and mstatus_mie_bypassed and not exc_taken_i and id_valid_i;

    -- EX-aligned, and derived from the three registers rather than a fourth
    -- flop of its own: mcause's interrupt bit and the cause trap_ctrl ranks
    -- then cannot come from different snapshots.
    int_trap  <= exi_trap_reg or tmi_trap_reg or swi_trap_reg;

    cop_we_o        <= wr_en_i and cop_sel_wr;
    cop_adr_o       <= wr_addr_i(5 downto 0) when (wr_en_i and cop_sel_wr) = '1' else rw_addr_i(5 downto 0);
    cop_dat_o       <= wr_data_i;
    exi_trap_o      <= exi_trap_reg;
    tmi_trap_o      <= tmi_trap_reg;
    swi_trap_o      <= swi_trap_reg;
    int_taken_o     <= int_taken;
    int_pend_o      <= int_pend;
    int_trap_o      <= int_trap;
    mepc_reg_o      <= mepc_reg;
    mtvec_reg_o     <= mtvec_base_reg;
    csrrd_data_o    <= csrrd_data_reg;
    pc_o            <= pc_reg & b"00";

end architecture rtl;