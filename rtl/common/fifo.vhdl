----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: fifo
-- description: generic circular buffer
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fifo is
    generic (
        SIZE: natural := 32;
        BITS: natural := 8 
    );

    port (
        clk:   in std_logic;
        reset: in std_logic;

        wr:      in  std_logic;
        wr_en:   out std_logic;
        wr_data: in  std_logic_vector(7 downto 0);

        rd:       in  std_logic;
        rd_en:    out std_logic;
        rd_data:  out std_logic_vector(7 downto 0)
    );
end entity fifo;

architecture fifo_arch of fifo is
    
    ----------------------------- types ----------------------------------

    type fifo_data_array is array (0 range SIZE-1) of std_logic_vector(2^BITS-1 downto 0);
    
    type fifo_op_type is (READ_OP, WRITE_OP);

    ---------------------------- fifo data -------------------------------

    signal fifo_data: fifo_data_array;

    --------------------- fifo last op register --------------------------
    
    signal fifo_op: fifo_op_type;

    ------------------------- external flags -----------------------------

    signal wr_pointer: integer range 0 to SIZE-1;
    signal rd_pointer: integer range 0 to SIZE-1;

    ------------------------- internal flags -----------------------------

    signal empty: std_logic;
    signal full:  std_logic;

begin
    
    ---------------------- read data from fifo ---------------------------

    rd_data <= fifo_data(rd_pointer);

    read_data: process(clk, reset)
    begin
        
        if reset = '1' then
            
            rd_pointer <= 0;

        elsif rising_edge(clk) then

            if rd = '1' and empty = '0' then
                
                rd_pointer <= rd_pointer + 1;
                
            end if;
            
        end if;

    end process read_data;

    ------------------------ write data on fifo --------------------------

    write_data: process(clk, reset)
    begin
        
        if reset = '1' then
            
            fifo_data <= (others => (others => '0'));
            
            wr_pointer <= 0;

        elsif rising_edge(clk) then

            if wr = '1' and full = '0' then
                
                fifo_data(wr_pointer) <= wr_pointer;
                
                wr_pointer <= wr_pointer + 1;

            end if;

        end if;

    end process write_data;

    --------------------- last operation storage -------------------------

    save_last_op: process(clk, reset)
    begin
        
        if reset = '1' then
            
            last_op <= READ_OP;

        elsif rising_edge(clk) then

            if rd = '1' and wr = '0' then
                
                last_op <= READ_OP;

            elsif rd = '0' and wr = '1' then

                last_op <= WRITE_OP;

            end if;

        end if;

    end process save_last_op;

    ------------------------- internal flags -----------------------------

    empty <= '1' when wr_pointer = rd_pointer and last_op = READ_OP  else '0';
    full  <= '1' when wr_pointer = rd_pointer and last_op = WRITE_OP else '0';

    -------------------------- output flags -------------------------------

    rd_en <= not empty;
    wr_en <= not full;

end architecture fifo_arch;

