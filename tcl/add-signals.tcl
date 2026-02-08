set display_list [ gtkwave::getDisplayedSignals ]
set display_list_length [ llength $display_list ]

if { $display_list_length > 0 } {
    set num_deleted [ gtkwave::deleteSignalsFromList $display_list ]
    puts "INFO: $num_deleted signals were deleted."
}

set leaf_core "top.leaf_tb.uut.leaf_core"
set rst_signal "$leaf_core.reset"
set clk_signal "$leaf_core.clk"
set flush_signal "$leaf_core.flush_reg"
set pc_signal "$leaf_core.pc_reg"
set instr_signal "$leaf_core.instr_reg"
set dmrd_en "$leaf_core.dmrd_en"
set dmwr_en "$leaf_core.dmwr_en"
set dmwr_be "$leaf_core.dmwr_be"
set dmrw_addr "$leaf_core.dmrw_addr"
set dmrd_data "$leaf_core.dmrd_data"
set dmwr_data "$leaf_core.dmwr_data"

set reg_file "$leaf_core.core_id_ex_stage.stage_id_block.stage_istg_block.istg_reg_file.regs"
set regs [list]

for {set i 0} {$i < 32} {incr i} {
    lappend regs "$reg_file\[$i\]"
}

set signals [list $rst_signal $clk_signal $flush_signal $pc_signal $instr_signal $dmrd_en $dmwr_en $dmwr_be $dmrw_addr $dmrd_data $dmwr_data {*}$regs]

set num_added [ gtkwave::addSignalsFromList $signals ]

if { $num_added > 0 } {
    puts "INFO: $num_added signals were added."
}
