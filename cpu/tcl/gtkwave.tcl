set display_list [ gtkwave::getDisplayedSignals ]
set display_list_length [ llength $display_list ]
if { $display_list_length > 0 } {
    set num_deleted [ gtkwave::deleteSignalsFromList $display_list ]
    puts "INFO: $num_deleted signals were deleted."
}

set leaf_core "top.leaf_tb.uut.leaf_core"
set rst_signal "$leaf_core.reset"
set clk_signal "$leaf_core.clk"
set flush_signal "$leaf_core.flush"
set pc_signal "$leaf_core.pc_reg"
set instr_signal "$leaf_core.instr_reg"

set reg_file "$leaf_core.core_id_ex_stage.stage_istg_block.istg_reg_file.regs"
set regs [list]
for {set i 0} {$i < 32} {incr i} {
    lappend regs "$reg_file\[$i\]"
}

set signals [list $rst_signal $clk_signal $flush_signal $pc_signal $instr_signal {*}$regs]

set num_added [ gtkwave::addSignalsFromList $signals ]
if { $num_added > 0 } {
    puts "INFO: $num_added signals were added."
}

set total_traces [ gtkwave::getTotalNumTraces ]

set fp [open "leaf_trace.csv" w]

set header [list "time"]
for {set i 0} {$i < $total_traces} {incr i} {
    set trace_name [ gtkwave::getTraceNameFromIndex $i ]
    lappend header $trace_name
}
puts $fp [join $header ","]

set start_time 0
foreach {time value} [gtkwave::signalChangeList $clk_signal -start_time $start_time] {
    if {$value == 1} {
        gtkwave::setMarker $time
        set row [list $time]
        for {set i 0} {$i < $total_traces} {incr i} {
            set trace_value [ gtkwave::getTraceValueAtMarkerFromIndex $i ]
            lappend row $trace_value
        }
        puts $fp [join $row ","]
    }
}
close $fp

# set num_highlighted [gtkwave::highlightSignalsFromList [list $clk_signal]]
# puts "INFO: $num_highlighted signals were highlighted."
# set prev_time_value -1
# set time_value 0
# while {$time_value != $prev_time_value} {
#     gtkwave::setMarker $time_value
#     puts "time_value = $time_value"
#
#     for {set i 0} {$i < [ gtkwave::getTotalNumTraces ]} {incr i} {
#         set trace_name [ gtkwave::getTraceNameFromIndex $i ]
#         set trace_value [ gtkwave::getTraceValueAtMarkerFromIndex $i ]
#         puts "$trace_name = $trace_value"
#     }
#
#     set prev_time_value $time_value
#     set time_value [ gtkwave::findNextEdge ]
# }
