library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity skid_buffer is
    generic (
        DATA_WIDTH : positive
    );
    port (
        clk_i    : in  std_logic;
        reset_i  : in  std_logic;
        data_i   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        valid_i  : in  std_logic;
        ready_o  : out std_logic;
        data_o   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        valid_o  : out std_logic;
        ready_i  : in  std_logic
    );
end entity skid_buffer;

architecture rtl of skid_buffer is

    signal data_reg : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal valid_reg : std_logic;
    
    signal skid_reg : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal skid_valid_reg : std_logic;

begin

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                valid_reg <= '0';
                skid_valid_reg <= '0';
                data_reg <= (others => '0');
                skid_reg <= (others => '0');
            else
                if ready_i = '1' or valid_reg = '0' then
                    if skid_valid_reg = '1' then
                        data_reg <= skid_reg;
                        valid_reg <= '1';
                        if valid_i = '1' then
                            skid_reg <= data_i;
                            skid_valid_reg <= '1';
                        else
                            skid_valid_reg <= '0';
                        end if;
                    else
                        if valid_i = '1' then
                            data_reg <= data_i;
                            valid_reg <= '1';
                        else
                            valid_reg <= '0';
                        end if;
                        skid_valid_reg <= '0';
                    end if;
                else
                    if skid_valid_reg = '0' then
                        if valid_i = '1' then
                            skid_reg <= data_i;
                            skid_valid_reg <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    ready_o <= (not skid_valid_reg) or ready_i;
    valid_o <= valid_reg;
    data_o  <= data_reg;

end architecture rtl;
