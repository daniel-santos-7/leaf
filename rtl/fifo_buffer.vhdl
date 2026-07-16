library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fifo_buffer is
    generic (
        DATA_WIDTH : natural := 32 -- Width of each data slot
    );
    port (
        clk_i : in  std_logic; -- System clock
        reset_i : in  std_logic; -- Synchronous reset (active high)

        -- Input Interface
        valid_i : in  std_logic; -- Input data is valid (push)
        ready_i : in  std_logic; -- Downstream is ready (pop enable)
        data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Data to be stored

        -- Output Interface
        valid_o : out std_logic; -- FIFO is not empty (data available)
        ready_o : out std_logic; -- FIFO is not full (ready to accept data)
        data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)  -- Data at current read pointer
    );
end entity fifo_buffer;

architecture rtl of fifo_buffer is

    constant FIFO_DEPTH : natural := 3;
    constant ADDR_WIDTH : natural := 2;

    type fifo_data_array is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    signal fifo_data_reg : fifo_data_array; -- Memory array

    signal wr_ptr_reg : unsigned(ADDR_WIDTH-1 downto 0); -- Write address pointer
    signal rd_ptr_reg : unsigned(ADDR_WIDTH-1 downto 0); -- Read address pointer

    signal wr_ptr_next : unsigned(ADDR_WIDTH-1 downto 0); -- Next write address
    signal rd_ptr_next : unsigned(ADDR_WIDTH-1 downto 0); -- Next read address

    signal empty_reg : std_logic; -- Registered empty flag
    signal full_reg  : std_logic; -- Registered full flag

    signal pushing : std_logic;
    signal popping : std_logic;

begin

    ----------------------- Internal Control Signals ---------------------

    pushing <= valid_i and not full_reg;
    popping <= ready_i and not empty_reg;

    wr_ptr_next <= (others => '0') when wr_ptr_reg = FIFO_DEPTH - 1 else wr_ptr_reg + 1;
    rd_ptr_next <= (others => '0') when rd_ptr_reg = FIFO_DEPTH - 1 else rd_ptr_reg + 1;

    ----------------------- Datapath Logic -----------------------------

    -- Process 1: Memory Write (Dedicated to RAM inference)
    memory_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if pushing = '1' then
                fifo_data_reg(to_integer(wr_ptr_reg)) <= data_i;
            end if;
        end if;
    end process memory_proc;

    -- Combinational data output
    data_o <= fifo_data_reg(to_integer(rd_ptr_reg));

    ----------------------- Control Logic ----------------------------

    -- Process 2: Write Pointer Management
    write_pointer_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                wr_ptr_reg <= (others => '0');
            elsif pushing = '1' then
                wr_ptr_reg <= wr_ptr_next;
            end if;
        end if;
    end process write_pointer_proc;

    -- Process 3: Read Pointer Management
    read_pointer_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                rd_ptr_reg <= (others => '0');
            elsif popping = '1' then
                rd_ptr_reg <= rd_ptr_next;
            end if;
        end if;
    end process read_pointer_proc;

    -- Process 4: Status Logic (Optimized, no counter)
    status_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                empty_reg    <= '1';
                full_reg     <= '0';
            else
                if pushing = '1' and popping = '0' then
                    empty_reg <= '0';
                    if wr_ptr_next = rd_ptr_reg then
                        full_reg <= '1';
                    end if;
                elsif popping = '1' and pushing = '0' then
                    full_reg <= '0';
                    if rd_ptr_next = wr_ptr_reg then
                        empty_reg <= '1';
                    end if;
                end if;
                -- Simultaneous push/pop: distance remains constant, no change to flags
            end if;
        end if;
    end process status_proc;

    ------------------------------ Outputs ------------------------------

    valid_o <= not empty_reg;
    ready_o <= not full_reg;

end architecture rtl;
