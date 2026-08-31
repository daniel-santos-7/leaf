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
        -- Decided in trap_ctrl, out of the four signals exported below. It
        -- comes back because two writes here need it: the interrupt bit of
        -- mcause, and the guard that keeps write_mtval from decoding an
        -- interrupt code as an exception one.
        int_taken_i  : in  std_logic;
        -- The whole mcause code field, prioritised in trap_ctrl: the interrupt
        -- code while int_taken is up, the exception code otherwise. The two
        -- numberings collide -- 3, 7 and 11 name something in each -- so
        -- anything decoding this has to rule out an interrupt first, the way
        -- write_mtval does. The three *_taken_o below feed the interrupt half.
        mcause_exc_i : in  std_logic_vector(4 downto 0);
        -- Picked in trap_ctrl by select_mtval, off the same cause chain that
        -- names mcause_exc_i: the spec pairs an mtval with each cause.
        mtval_i      : in  std_logic_vector(XLEN-1 downto 0);
        mret_i       : in  std_logic;
        wfi_i        : in  std_logic;
        exc_taken_i  : in  std_logic;
        wr_en_i      : in  std_logic;
        wr_addr_i    : in  std_logic_vector(11 downto 0);
        rw_addr_i    : in  std_logic_vector(11 downto 0);
        wr_data_i    : in  std_logic_vector(XLEN-1 downto 0);
        pipe_en_i    : in  std_logic;
        pc_i         : in  std_logic_vector(XLEN-1 downto 2);
        -- pc + 4 out of ex_block's incrementer. It pairs with pc_o, not with
        -- pc_i: ex_block is fed by pc_o, so this is the EX-aligned pc_reg plus
        -- one word, which is exactly the mepc a wfi trap has to stack.
        pc_next_i    : in  std_logic_vector(XLEN-1 downto 2);
        cycle_i      : in  std_logic_vector(63 downto 0);
        timer_i      : in  std_logic_vector(63 downto 0);
        instret_i    : in  std_logic_vector(63 downto 0);
        cop_dat_i    : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o    : out std_logic_vector(5 downto 0);
        cop_dat_o    : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o     : out std_logic;
        -- The four operands of the interrupt decision, which trap_ctrl makes.
        -- mie, mip and mstatus are registers owned here, so their read is here;
        -- ORing the three and masking them with MIE is a trap decision and
        -- happens over there. All four carry the write bypass.
        exi_taken_o   : out std_logic;
        tmi_taken_o   : out std_logic;
        swi_taken_o   : out std_logic;
        mstatus_mie_o : out std_logic;
        mepc_o       : out std_logic_vector(XLEN-1 downto 2);
        mtvec_base_o : out std_logic_vector(XLEN-1 downto 2);
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

    signal pc_full : std_logic_vector(XLEN-1 downto 0);

    signal cop_sel_rd          : std_logic;
    signal cop_sel_wr          : std_logic;
    signal rd_data_int         : std_logic_vector(XLEN-1 downto 0);
    signal rd_data_bypassed    : std_logic_vector(XLEN-1 downto 0);
    signal mepc_bypassed       : std_logic_vector(XLEN-1 downto 2);
    signal mtvec_base_bypassed : std_logic_vector(XLEN-1 downto 2);

    -- mie/mstatus go through the same write-forwarding bypass as mepc/mtvec, so
    -- a csrrs that sets MIE arms the interrupt in the cycle it commits rather
    -- than one cycle later. The four results leave for trap_ctrl, which makes
    -- the decision out of them.
    signal mie_meie_bypassed    : std_logic;
    signal mie_mtie_bypassed    : std_logic;
    signal mie_msie_bypassed    : std_logic;
    signal mstatus_mie_bypassed : std_logic;
    signal exi_taken            : std_logic;
    signal tmi_taken            : std_logic;
    signal swi_taken            : std_logic;

    signal mepc_reg       : std_logic_vector(XLEN-1 downto 2);
    signal mtvec_base_reg : std_logic_vector(XLEN-1 downto 2);
    signal csrrd_data_reg : std_logic_vector(XLEN-1 downto 0);
    signal pc_reg         : std_logic_vector(XLEN-1 downto 0);

begin

    pc_full <= pc_i & b"00";

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
                -- Every cause reaching here is EX-aligned, so pc_reg is the
                -- trapping instruction's PC whichever stage produced it.
                if wfi_i = '1' then
                    -- mepc must point past the WFI, so the handler's mret does
                    -- not fall back into it and sleep again. pc_next_i is that
                    -- word, already incremented in ex_block for JAL/JALR.
                    mepc <= pc_next_i;
                else
                    mepc <= pc_reg(XLEN-1 downto 2);
                end if;
            elsif wr_addr_i = CSR_ADDR_MEPC and wr_en_i = '1' then
                mepc <= wr_data_i(XLEN-1 downto 2);
            end if;
        end if;
    end process write_mepc;

    -- The write is unconditional under exc_taken_i, where the old form held
    -- the previous mcause whenever no cause matched. The only way to reach it
    -- is int_taken_i dropping between the cycle trap_ctrl arms the trap and the
    -- cycle it commits, and a held stale cause is no better an answer there.
    write_mcause: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mcause_int <= '0';
                mcause_exc <= (others => '0');
            elsif exc_taken_i = '1' then
                mcause_int <= int_taken_i;
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
                pc_reg         <= pc_full;
            end if;
        end if;
    end process pipeline_reg;

    mie_meie_bypassed    <= wr_data_i(11) when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MIE)     else mie_meie;
    mie_mtie_bypassed    <= wr_data_i(7)  when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MIE)     else mie_mtie;
    mie_msie_bypassed    <= wr_data_i(3)  when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MIE)     else mie_msie;
    mstatus_mie_bypassed <= wr_data_i(3)  when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MSTATUS) else mstatus_mie;
    mepc_bypassed        <= wr_data_i(XLEN-1 downto 2) when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MEPC)  else mepc;
    mtvec_base_bypassed  <= wr_data_i(XLEN-1 downto 2) when (wr_en_i = '1' and wr_addr_i = CSR_ADDR_MTVEC) else mtvec_base;

    -- mip needs no bypass: it is not writable, it just samples the irq inputs.
    exi_taken <= mie_meie_bypassed and mip_meip;
    tmi_taken <= mie_mtie_bypassed and mip_mtip;
    swi_taken <= mie_msie_bypassed and mip_msip;

    cop_we_o        <= wr_en_i and cop_sel_wr;
    cop_adr_o       <= wr_addr_i(5 downto 0) when (wr_en_i and cop_sel_wr) = '1' else rw_addr_i(5 downto 0);
    cop_dat_o       <= wr_data_i;
    exi_taken_o     <= exi_taken;
    tmi_taken_o     <= tmi_taken;
    swi_taken_o     <= swi_taken;
    mstatus_mie_o   <= mstatus_mie_bypassed;
    mepc_o          <= mepc_reg;
    mtvec_base_o    <= mtvec_base_reg;
    csrrd_data_o    <= csrrd_data_reg;
    pc_o            <= pc_reg;

end architecture rtl;