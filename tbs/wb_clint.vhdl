----------------------------------------------------------------------
-- Project: Leaf
-- Developed by: Daniel Santos
-- Module: CLINT model for the testbench.
-- Date: 2026
----------------------------------------------------------------------
--
-- Minimal core-local interruptor, laid out at the addresses Spike puts its
-- own CLINT at, so a test can arm an interrupt the same way on both models
-- and the register dump stays comparable:
--
--   0x02000000  msip       (bit 0 -> sw_irq_o)
--   0x02004000  mtimecmp   low word
--   0x02004004  mtimecmp   high word
--   0x0200BFF8  mtime      low word
--   0x0200BFFC  mtime      high word
--
-- tm_irq_o is mtime >= mtimecmp, as the privileged spec defines MTIP. Reset
-- leaves mtimecmp at zero, which matches Spike -- MTIP is therefore pending
-- out of reset, and a test that wants a timer interrupt at a chosen moment
-- has to park mtimecmp first. Until it does, mie.MTIE is what holds the
-- interrupt off, on both models alike.
--
-- mtime ticks once every RTC_DIV clocks rather than every clock: it is a
-- real-time counter, not a cycle counter, and the division widens the window
-- a wfi actually spends parked.
--
-- Reads answer one cycle after the request, matching wb_ram_dual, and sel_o
-- marks the cycle in which dat_o is ours -- the testbench uses it to pick
-- between the two read paths. Acknowledges are left to wb_ram_dual, which
-- acks every request regardless of address.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity wb_clint is
    generic (
        RTC_DIV : positive := 8
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;

        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        we_i  : in  std_logic;
        adr_i : in  std_logic_vector(31 downto 2);
        dat_i : in  std_logic_vector(31 downto 0);
        dat_o : out std_logic_vector(31 downto 0);
        sel_o : out std_logic;

        sw_irq_o : out std_logic;
        tm_irq_o : out std_logic
    );
end entity wb_clint;

architecture arch of wb_clint is

    -- Word addresses: the byte address shifted right by two, which is what
    -- the Wishbone address port carries.
    function word_adr (byte_adr : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(byte_adr / 4, 30));
    end function word_adr;

    constant ADR_MSIP        : std_logic_vector(31 downto 2) := word_adr(16#02000000#);
    constant ADR_MTIMECMP_LO : std_logic_vector(31 downto 2) := word_adr(16#02004000#);
    constant ADR_MTIMECMP_HI : std_logic_vector(31 downto 2) := word_adr(16#02004004#);
    constant ADR_MTIME_LO    : std_logic_vector(31 downto 2) := word_adr(16#0200BFF8#);
    constant ADR_MTIME_HI    : std_logic_vector(31 downto 2) := word_adr(16#0200BFFC#);

    signal mtime    : unsigned(63 downto 0);
    signal mtimecmp : unsigned(63 downto 0);
    signal msip     : std_logic;

    signal prescaler : natural range 0 to RTC_DIV-1;

    signal access_en : std_logic;

begin

    access_en <= cyc_i and stb_i;

    regs: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                mtime     <= (others => '0');
                mtimecmp  <= (others => '0');
                msip      <= '0';
                prescaler <= 0;
            else
                if prescaler = RTC_DIV-1 then
                    prescaler <= 0;
                    mtime     <= mtime + 1;
                else
                    prescaler <= prescaler + 1;
                end if;

                if access_en = '1' and we_i = '1' then
                    if adr_i = ADR_MSIP then
                        msip <= dat_i(0);
                    elsif adr_i = ADR_MTIMECMP_LO then
                        mtimecmp(31 downto 0) <= unsigned(dat_i);
                    elsif adr_i = ADR_MTIMECMP_HI then
                        mtimecmp(63 downto 32) <= unsigned(dat_i);
                    end if;
                end if;
            end if;
        end if;
    end process regs;

    read_port: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                dat_o <= (others => '0');
                sel_o <= '0';
            else
                dat_o <= (others => '0');
                sel_o <= '0';
                if access_en = '1' then
                    if adr_i = ADR_MSIP then
                        sel_o <= '1';
                        dat_o <= (0 => msip, others => '0');
                    elsif adr_i = ADR_MTIMECMP_LO then
                        sel_o <= '1';
                        dat_o <= std_logic_vector(mtimecmp(31 downto 0));
                    elsif adr_i = ADR_MTIMECMP_HI then
                        sel_o <= '1';
                        dat_o <= std_logic_vector(mtimecmp(63 downto 32));
                    elsif adr_i = ADR_MTIME_LO then
                        sel_o <= '1';
                        dat_o <= std_logic_vector(mtime(31 downto 0));
                    elsif adr_i = ADR_MTIME_HI then
                        sel_o <= '1';
                        dat_o <= std_logic_vector(mtime(63 downto 32));
                    end if;
                end if;
            end if;
        end if;
    end process read_port;

    sw_irq_o <= msip;
    tm_irq_o <= '1' when mtime >= mtimecmp else '0';

end architecture arch;
