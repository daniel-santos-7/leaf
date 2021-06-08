library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity id_ex_stage is
    
    port (
        clk:   in std_logic;
        reset: in std_logic;
        
        pc:         in std_logic_vector(31 downto 0);
        next_pc:    in std_logic_vector(31 downto 0);
        instr:      in std_logic_vector(31 downto 0);
        flush:      in std_logic;
        
        rd_mem_data:    in  std_logic_vector(31 downto 0);
        wr_mem_data:    out std_logic_vector(31 downto 0);
        rd_mem_en:      out std_logic;
        wr_mem_en:      out std_logic;
        rd_wr_mem_addr: out std_logic_vector(31 downto 0);
        wr_mem_byte_en: out std_logic_vector(3 downto 0);

        ex_irq: in std_logic;
        sw_irq: in std_logic;
        tm_irq: in std_logic;
        
        branch:  out std_logic; 
        jmp:     out std_logic; 
        trap:    out std_logic;
        
        target: out std_logic_vector(31 downto 0)
    );

end entity id_ex_stage;

architecture id_ex_stage_arch of id_ex_stage is
    
    signal opcode: std_logic_vector(6 downto 0);

    signal ig_payload:  std_logic_vector(24 downto 0);
    signal ig_imm_type: std_logic_vector(2  downto 0);
    signal ig_imm:      std_logic_vector(31 downto 0);

    signal rf_wr_reg_src:   std_logic_vector(1 downto 0);
    signal rf_rd_reg_addr0: std_logic_vector(4 downto 0);
    signal rf_rd_reg_addr1: std_logic_vector(4 downto 0);
    signal rf_wr_reg_addr:  std_logic_vector(4 downto 0);
    signal rf_wr_reg_en:    std_logic;
    signal rf_wr_reg_data:  std_logic_vector(31 downto 0);
    signal rf_rd_reg_data0: std_logic_vector(31 downto 0);
    signal rf_rd_reg_data1: std_logic_vector(31 downto 0);

    signal brd_reg0:   std_logic_vector(31 downto 0);
    signal brd_reg1:   std_logic_vector(31 downto 0);
    signal brd_mode:   std_logic_vector(2  downto 0);
    signal brd_en:     std_logic;
    signal brd_branch: std_logic;

    signal csrs_wr_mode:     std_logic_vector(2  downto 0);
    signal csrs_wr_en:       std_logic;
    signal csrs_rd_wr_addr:  std_logic_vector(11 downto 0);
    signal csrs_wr_reg_data: std_logic_vector(31 downto 0);
    signal csrs_wr_imm_data: std_logic_vector(31 downto 0);
    signal csrs_rd_data:     std_logic_vector(31 downto 0);

    signal alu_src0:      std_logic;
    signal alu_src1:      std_logic;
    signal alu_opd0_pass: std_logic;
    signal alu_opd1_pass: std_logic;
    
    signal alu_std_op: std_logic;
    signal alu_imm_op: std_logic;
    signal alu_func:   std_logic_vector(9 downto 0);
    
    signal alu_op:   std_logic_vector(3  downto 0);
    signal alu_opd0: std_logic_vector(31 downto 0);
    signal alu_opd1: std_logic_vector(31 downto 0);
    signal alu_res:  std_logic_vector(31 downto 0);

    signal lsu_rd_wr_addr: std_logic_vector(31 downto 0);
    signal lsu_wr_data:    std_logic_vector(31 downto 0);
    signal lsu_data_type:  std_logic_vector(2  downto 0);
    signal lsu_mode:       std_logic; 
    signal lsu_en:         std_logic;
    signal lsu_rd_data:    std_logic_vector(31 downto 0);

begin

    opcode <= instr(6 downto 0);

    ig_payload <= instr(31 downto 7);

    rf_rd_reg_addr0 <= instr(19 downto 15);
    rf_rd_reg_addr1 <= instr(24 downto 20);
    rf_wr_reg_addr  <= instr(11 downto  7);

    brd_reg0 <= rf_rd_reg_data0;
    brd_reg1 <= rf_rd_reg_data1;
    brd_mode <= instr(14 downto 12);
    
    csrs_wr_mode     <= instr(14 downto 12);
    csrs_rd_wr_addr  <= instr(31 downto 20);
    csrs_wr_reg_data <= rf_rd_reg_data0;
    csrs_wr_imm_data <= ig_imm;

    alu_func <= instr(31 downto 25) & instr(14 downto 12);

    lsu_rd_wr_addr <= alu_res;
    lsu_wr_data    <= rf_rd_reg_data1;
    lsu_data_type  <= instr(14 downto 12);

    rf_wr_reg_mux: process(rf_wr_reg_src, alu_res, lsu_rd_data, next_pc, csrs_rd_data)
    
    begin
        
        case rf_wr_reg_src is
            
            when b"00" =>
                
                rf_wr_reg_data <= alu_res;

            when b"01" =>
        
                rf_wr_reg_data <= lsu_rd_data;

            when b"10" =>

                rf_wr_reg_data <= next_pc;

            when b"11" =>

                rf_wr_reg_data <= csrs_rd_data;

            when others =>
                
                rf_wr_reg_data <= (others => '0');
        
        end case;

    end process rf_wr_reg_mux;

    alu_opd0_mux: process(alu_opd0_pass, alu_src0, pc, rf_rd_reg_data0)
    
    begin
    
        if alu_opd0_pass = '1' then
        
            if alu_src0 = '1' then
                
                alu_opd0 <= pc;

            else

                alu_opd0 <= rf_rd_reg_data0;

            end if;

        else
        
            alu_opd0 <= (others => '0');

        end if;

    end process alu_opd0_mux;

    alu_opd1_mux: process(alu_opd1_pass, alu_src1, ig_imm, rf_rd_reg_data1)
    
    begin
    
        if alu_opd1_pass = '1' then
            
            if alu_src1 = '1' then
            
                alu_opd1 <= ig_imm;
    
            else
    
                alu_opd1 <= rf_rd_reg_data1;
    
            end if;

        else

            alu_opd1 <= (others => '0');

        end if;
        
    end process alu_opd1_mux;

    stage_mc: main_ctrl port map (
        opcode          => opcode,
        flush           => flush,
        rf_wr_reg_src   => rf_wr_reg_src,
        rf_wr_reg_en    => rf_wr_reg_en,
        ig_imm_type     => ig_imm_type,
        alu_src0        => alu_src0, 
        alu_src1        => alu_src1, 
        alu_opd0_pass   => alu_opd0_pass,
        alu_opd1_pass   => alu_opd1_pass,
        alu_std_op      => alu_std_op, 
        alu_imm_op      => alu_imm_op,
        lsu_mode        => lsu_mode, 
        lsu_en          => lsu_en,
        brd_en          => brd_en,
        csrs_wr_en      => csrs_wr_en,
        if_jmp          => jmp
    );

    stage_ig: imm_gen port map (
        payload  => ig_payload,
        imm_type => ig_imm_type,
        imm      => ig_imm
    );

    stage_rf: reg_file port map (
        clk          => clk,
        rd_reg_addr0 => rf_rd_reg_addr0,
        rd_reg_addr1 => rf_rd_reg_addr1,
        wr_reg_addr  => rf_wr_reg_addr,
        wr_reg_data  => rf_wr_reg_data,
        wr_reg_en    => rf_wr_reg_en,
        rd_reg_data0 => rf_rd_reg_data0, 
        rd_reg_data1 => rf_rd_reg_data1
    );

    stage_br_detector: br_detector port map (
        reg0   => brd_reg0, 
        reg1   => brd_reg1,
        mode   => brd_mode,
        en     => brd_en,
        branch => brd_branch
    );

    stage_csrs: csrs port map (
        clk         => clk,
        reset       => reset,
        ex_irq      => ex_irq,
        sw_irq      => sw_irq,
        tm_irq      => tm_irq,
        wr_mode     => csrs_wr_mode,
        wr_en       => csrs_wr_en,
        rd_wr_addr  => csrs_rd_wr_addr,
        wr_reg_data => csrs_wr_reg_data,
        wr_imm_data => csrs_wr_imm_data,
        rd_data     => csrs_rd_data
    );

    stage_alu_ctrl: alu_ctrl port map (
        std_op => alu_std_op,
        imm_op => alu_imm_op,
        func   => alu_func,
        alu_op => alu_op
    );

    stage_alu: alu port map (
        opd0 => alu_opd0, 
        opd1 => alu_opd1,
        op   => alu_op,
        res  => alu_res
    );

    stage_lsu: lsu port map (
        rd_data        => lsu_rd_data,
        wr_data        => lsu_wr_data,
        rd_wr_addr     => lsu_rd_wr_addr,
        data_type      => lsu_data_type,
        mode           => lsu_mode, 
        en             => lsu_en,
        rd_mem_data    => rd_mem_data,
        wr_mem_data    => wr_mem_data,
        rd_mem_en      => rd_mem_en, 
        wr_mem_en      => wr_mem_en,
        rd_wr_mem_addr => rd_wr_mem_addr,
        wr_mem_byte_en => wr_mem_byte_en
    );

    branch <= brd_branch;
    target <= alu_res;

end architecture id_ex_stage_arch;