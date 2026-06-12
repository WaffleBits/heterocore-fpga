set output_dir build/vivado
file mkdir $output_dir

read_verilog -sv [glob rtl/*.sv]
read_xdc boards/arty_a7_35t.xdc

synth_design -top heterocore_fpga_top -part xc7a35ticsg324-1L
opt_design
place_design
route_design

report_utilization -file $output_dir/utilization.rpt
report_timing_summary -file $output_dir/timing_summary.rpt
write_checkpoint -force $output_dir/heterocore_fpga_top.dcp
write_bitstream -force $output_dir/heterocore_fpga_top.bit

