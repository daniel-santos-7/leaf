----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: trap and interrupt control (EX time)
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity trap_ctrl is
    port (
        instr_err_i    : in  std_logic;
        fetch_fault_i  : in  std_logic;
        ecall_i        : in  std_logic;
        ebreak_i       : in  std_logic;
        mret_i         : in  std_logic;
        wfi_i          : in  std_logic;
        int_trap_i     : in  std_logic;
        retire_i       : in  std_logic;
        pipe_en_i      : in  std_logic;

        exi_taken_i    : in  std_logic;
        tmi_taken_i    : in  std_logic;
        swi_taken_i    : in  std_logic;

        imrd_malgn_i   : in  std_logic;
        dmld_malgn_i   : in  std_logic;
        dmld_fault_i   : in  std_logic;
        dmst_malgn_i   : in  std_logic;
        dmst_fault_i   : in  std_logic;

        exec_res_i     : in  std_logic_vector(XLEN-1 downto 0);
        pc_i           : in  std_logic_vector(XLEN-1 downto 0);
        pc_next_i      : in  std_logic_vector(XLEN-1 downto 2);

        regwr_en_i     : in  std_logic;
        csrwr_en_i     : in  std_logic;

        csrwr_mode_i   : in  std_logic_vector(2      downto 0);
        csrrd_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        regwr_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        immwr_data_i   : in  std_logic_vector(XLEN-1 downto 0);

        exc_taken_o    : out std_logic;
        taken_o        : out std_logic;
        mcause_exc_o   : out std_logic_vector(4 downto 0);
        mtval_o        : out std_logic_vector(XLEN-1 downto 0);
        mepc_o         : out std_logic_vector(XLEN-1 downto 2);
        regwr_en_o     : out std_logic;
        csrwr_en_o     : out std_logic;
        csrwr_data_o   : out std_logic_vector(XLEN-1 downto 0);
        retire_o       : out std_logic
    );
end entity trap_ctrl;

architecture rtl of trap_ctrl is

    signal exc_fault  : std_logic;
    signal exc_taken  : std_logic;
    signal mcause_exc : std_logic_vector(4 downto 0);
    signal mtval      : std_logic_vector(XLEN-1 downto 0);
    signal mepc       : std_logic_vector(XLEN-1 downto 2);
    signal csrwr_data : std_logic_vector(XLEN-1 downto 0);

begin

    exc_fault <= imrd_malgn_i or dmld_malgn_i or dmld_fault_i or
                 dmst_malgn_i or dmst_fault_i;

    -- The spec's trap priority, in one chain. An ecall is the only cause left
    -- once the eleven above it are ruled out, so it is the else.
    encode_trap: process(swi_taken_i, tmi_taken_i, exi_taken_i, imrd_malgn_i,
                         fetch_fault_i, instr_err_i, ebreak_i, dmld_malgn_i,
                         dmld_fault_i, dmst_malgn_i, dmst_fault_i,
                         exec_res_i, pc_i)
    begin
        if swi_taken_i = '1' then       -- machine software interrupt
            mcause_exc <= b"00011";
            mtval      <= (others => '0');
        elsif tmi_taken_i = '1' then    -- machine timer interrupt
            mcause_exc <= b"00111";
            mtval      <= (others => '0');
        elsif exi_taken_i = '1' then    -- machine external interrupt
            mcause_exc <= b"01011";
            mtval      <= (others => '0');
        elsif imrd_malgn_i = '1' then   -- instruction address misaligned
            mcause_exc <= b"00000";
            mtval      <= exec_res_i;
        elsif fetch_fault_i = '1' then  -- instruction access fault
            mcause_exc <= b"00001";
            mtval      <= pc_i;
        elsif instr_err_i = '1' then    -- illegal instruction
            mcause_exc <= b"00010";
            mtval      <= (others => '0');
        elsif ebreak_i = '1' then       -- breakpoint
            mcause_exc <= b"00011";
            mtval      <= pc_i;
        elsif dmld_malgn_i = '1' then   -- load address misaligned
            mcause_exc <= b"00100";
            mtval      <= exec_res_i;
        elsif dmld_fault_i = '1' then   -- load access fault
            mcause_exc <= b"00101";
            mtval      <= exec_res_i;
        elsif dmst_malgn_i = '1' then   -- store address misaligned
            mcause_exc <= b"00110";
            mtval      <= exec_res_i;
        elsif dmst_fault_i = '1' then   -- store access fault
            mcause_exc <= b"00111";
            mtval      <= exec_res_i;
        else                            -- environment call
            mcause_exc <= b"01011";
            mtval      <= (others => '0');
        end if;
    end process encode_trap;

    csrwr_mux: process(csrwr_mode_i, regwr_data_i, immwr_data_i, csrrd_data_i)
    begin
        case csrwr_mode_i is
            when b"001" => csrwr_data <= regwr_data_i;
            when b"010" => csrwr_data <= csrrd_data_i or regwr_data_i;
            when b"011" => csrwr_data <= csrrd_data_i and not regwr_data_i;
            when b"101" => csrwr_data <= immwr_data_i;
            when b"110" => csrwr_data <= csrrd_data_i or immwr_data_i;
            when b"111" => csrwr_data <= csrrd_data_i and not immwr_data_i;
            when others => csrwr_data <= (others => '0');
        end case;
    end process csrwr_mux;

    -- A wfi released by an interrupt stacks the word past itself, so the
    -- handler's mret does not fall back in and sleep again.
    mepc <= pc_next_i when wfi_i = '1' else
            pc_i(XLEN-1 downto 2);

    exc_taken <= instr_err_i or fetch_fault_i or ecall_i or ebreak_i or
                 int_trap_i or exc_fault;

    -- An mret redirects the fetch but commits nothing in csrs beyond the
    -- mstatus unstacking, so it joins the redirect and not exc_taken.
    taken_o     <= exc_taken or mret_i;

    exc_taken_o <= exc_taken;

    mcause_exc_o  <= mcause_exc;
    mtval_o       <= mtval;
    mepc_o        <= mepc;

    regwr_en_o  <= regwr_en_i and not exc_fault;
    csrwr_en_o  <= csrwr_en_i and not exc_fault;

    csrwr_data_o <= csrwr_data;

    -- retire_i is the raw "the ID slot held an instruction" bit. pipe_en is
    -- what keeps a parked wfi from counting the instruction ahead of it once
    -- per parked cycle. See verif/tests/wfi_timer.
    retire_o    <= retire_i and pipe_en_i and not exc_taken;

end architecture rtl;
