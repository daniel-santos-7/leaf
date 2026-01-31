set total_traces [ gtkwave::getTotalNumTraces ]
set fp [open "trace.csv" w]

set header [list "time"]
for {set i 0} {$i < $total_traces} {incr i} {
    set trace_name [ gtkwave::getTraceNameFromIndex $i ]
    lappend header $trace_name
}
puts $fp [join $header ","]

set start_time 0
foreach {time value} [gtkwave::signalChangeList $clk_signal -start_time $start_time] {
    gtkwave::setMarker $time
    set row [list $time]
    for {set i 0} {$i < $total_traces} {incr i} {
        set trace_value [ gtkwave::getTraceValueAtMarkerFromIndex $i ]
        lappend row $trace_value
    }
    puts $fp [join $row ","]
}
close $fp