# Run with vivado -mode batch -source scripts/build_vivado.tcl.
set root [file normalize [file join [file dirname [info script]] ..]]
set build [file join $root build vivado]
create_project -force lab6 $build -part xc7a100tfgg676-2L

set manifest [open [file join $root scripts rtl.f]]
set sources {}
foreach line [split [read $manifest] "\n"] {
    if {[string trim $line] ne ""} {
        lappend sources [file join $root [string trim $line]]
    }
}
close $manifest
add_files -norecurse $sources

set reference [file join $root reference lab5]
add_files -fileset constrs_1 -norecurse [file join $reference constraints thinpad_top.xdc]
import_ip -files [file join $reference ip pll_example.xci]
generate_target all [get_ips pll_example]
set_property top thinpad_top [get_filesets sources_1]
update_compile_order -fileset sources_1

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
set status [get_property STATUS [get_runs impl_1]]
if {![string match "*Complete*" $status]} {
    error "Implementation failed: $status"
}
open_run impl_1
report_timing_summary -file [file join $build timing.rpt]
report_utilization -file [file join $build utilization.rpt]
report_drc -file [file join $build drc.rpt]
foreach delay_type {max min} {
    set worst_path [lindex [get_timing_paths -delay_type $delay_type -max_paths 1] 0]
    if {$worst_path eq "" || [get_property SLACK $worst_path] < 0} {
        error "Missing or failing timing paths for delay type $delay_type"
    }
}
puts "LAB6 BITSTREAM [file join $build lab6.runs impl_1 thinpad_top.bit]"
