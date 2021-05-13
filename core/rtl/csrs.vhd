-- # Machine trap setup:
-- CSRA_MSTATUS    = 0x300
-- CSRA_MIE        = 0x304
-- CSRA_MTVEC      = 0x305
-- CSRA_MSTATUSH   = 0x310

-- # Machine trap handling:
-- CSRA_MSCRATCH   = 0x340
-- CSRA_MEPC       = 0x341
-- CSRA_MCAUSE     = 0x342
-- CSRA_MTVAL      = 0x343
-- CSRA_MIP        = 0x344
-- CSRA_MTINST     = 0x34A
-- CSRA_MTVAL2     = 0x34B

-- # Machine counters:
-- CSRA_MCYCLE           = 0xB00
-- CSRA_MINSTRET         = 0xB02

-- # Machine counter setup:
-- CSRA_MCOUNTINHIBIT    = 0x320

library IEEE;
use IEEE.std_logic_1164.all;

entity csrs is

    generic (
        MHART_ID: std_logic_vector(31 downto 0)
    );

    port (
        clk: std_logic;
        rd_csr_addr: std_logic_vector(11 downto 0);
        rd_csr_data: std_logic_vector(31 downto 0)
    );

end entity csrs;

architecture csrs_arch of csrs is

    constant CSR_ADDR_MVENDORID := x"F11";
    constant CSR_ADDR_MARCHID := x"F12";
    constant CSR_ADDR_MIMPID := x"F13";
    constant CSR_ADDR_MHARTID := x"F14"
    constant CSR_ADDR_MISA := x"301";
    
begin
    
    read_csr: process(clk)
    
    begin
    
        if rising_edge(clk) then
            
            case rd_csr_addr is
                
                when CSR_ADDR_MVENDORID => rd_csr_data <= (others => '0');

                when CSR_ADDR_MARCHID => rd_csr_data <= (others => '0');

                when CSR_ADDR_MIMPID => rd_csr_data <= (others => '0');

                when CSR_ADDR_MHARTID => rd_csr_data <= MHART_ID;

                when CSR_ADDR_MISA => rd_csr_data <= (30 => '1', 8 => '1', others => '0'); -- RV32I

                when others => rd_csr_data <= (others => '0');
            
            end case;

        end if;

    end process read_csr;
    
end architecture csrs_arch;