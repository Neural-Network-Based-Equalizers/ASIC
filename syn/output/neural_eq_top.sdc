###################################################################

# Created by write_sdc on Sat Jun 27 09:07:43 2026

###################################################################
set sdc_version 2.1

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current mA
set_case_analysis 0 [get_ports test_mode]
create_clock [get_ports fun_clk]  -period 5  -waveform {0 2.5}
set_clock_uncertainty 0.35  [get_clocks fun_clk]
group_path -name comp_paths  -to [list [get_ports {out_I[15]}] [get_ports {out_I[14]}] [get_ports          \
{out_I[13]}] [get_ports {out_I[12]}] [get_ports {out_I[11]}] [get_ports        \
{out_I[10]}] [get_ports {out_I[9]}] [get_ports {out_I[8]}] [get_ports          \
{out_I[7]}] [get_ports {out_I[6]}] [get_ports {out_I[5]}] [get_ports           \
{out_I[4]}] [get_ports {out_I[3]}] [get_ports {out_I[2]}] [get_ports           \
{out_I[1]}] [get_ports {out_I[0]}] [get_ports {out_Q[15]}] [get_ports          \
{out_Q[14]}] [get_ports {out_Q[13]}] [get_ports {out_Q[12]}] [get_ports        \
{out_Q[11]}] [get_ports {out_Q[10]}] [get_ports {out_Q[9]}] [get_ports         \
{out_Q[8]}] [get_ports {out_Q[7]}] [get_ports {out_Q[6]}] [get_ports           \
{out_Q[5]}] [get_ports {out_Q[4]}] [get_ports {out_Q[3]}] [get_ports           \
{out_Q[2]}] [get_ports {out_Q[1]}] [get_ports {out_Q[0]}] [get_ports           \
valid_out] [get_clocks fun_clk]]
set_false_path -hold   -to [list [get_ports {out_I[15]}] [get_ports {out_I[14]}] [get_ports          \
{out_I[13]}] [get_ports {out_I[12]}] [get_ports {out_I[11]}] [get_ports        \
{out_I[10]}] [get_ports {out_I[9]}] [get_ports {out_I[8]}] [get_ports          \
{out_I[7]}] [get_ports {out_I[6]}] [get_ports {out_I[5]}] [get_ports           \
{out_I[4]}] [get_ports {out_I[3]}] [get_ports {out_I[2]}] [get_ports           \
{out_I[1]}] [get_ports {out_I[0]}] [get_ports {out_Q[15]}] [get_ports          \
{out_Q[14]}] [get_ports {out_Q[13]}] [get_ports {out_Q[12]}] [get_ports        \
{out_Q[11]}] [get_ports {out_Q[10]}] [get_ports {out_Q[9]}] [get_ports         \
{out_Q[8]}] [get_ports {out_Q[7]}] [get_ports {out_Q[6]}] [get_ports           \
{out_Q[5]}] [get_ports {out_Q[4]}] [get_ports {out_Q[3]}] [get_ports           \
{out_Q[2]}] [get_ports {out_Q[1]}] [get_ports {out_Q[0]}] [get_ports           \
valid_out]]
set_false_path -hold   -from [list [get_ports fun_rst_n] [get_ports scan_clk] [get_ports scan_rst_n] \
[get_ports test_mode] [get_ports valid_in] [get_ports {in_I[15]}] [get_ports   \
{in_I[14]}] [get_ports {in_I[13]}] [get_ports {in_I[12]}] [get_ports           \
{in_I[11]}] [get_ports {in_I[10]}] [get_ports {in_I[9]}] [get_ports {in_I[8]}] \
[get_ports {in_I[7]}] [get_ports {in_I[6]}] [get_ports {in_I[5]}] [get_ports   \
{in_I[4]}] [get_ports {in_I[3]}] [get_ports {in_I[2]}] [get_ports {in_I[1]}]   \
[get_ports {in_I[0]}] [get_ports {in_Q[15]}] [get_ports {in_Q[14]}] [get_ports \
{in_Q[13]}] [get_ports {in_Q[12]}] [get_ports {in_Q[11]}] [get_ports           \
{in_Q[10]}] [get_ports {in_Q[9]}] [get_ports {in_Q[8]}] [get_ports {in_Q[7]}]  \
[get_ports {in_Q[6]}] [get_ports {in_Q[5]}] [get_ports {in_Q[4]}] [get_ports   \
{in_Q[3]}] [get_ports {in_Q[2]}] [get_ports {in_Q[1]}] [get_ports {in_Q[0]}]]
set_max_delay 3  -to [get_ports {out_I[15]}]
set_max_delay 3  -to [get_ports {out_I[14]}]
set_max_delay 3  -to [get_ports {out_I[13]}]
set_max_delay 3  -to [get_ports {out_I[12]}]
set_max_delay 3  -to [get_ports {out_I[11]}]
set_max_delay 3  -to [get_ports {out_I[10]}]
set_max_delay 3  -to [get_ports {out_I[9]}]
set_max_delay 3  -to [get_ports {out_I[8]}]
set_max_delay 3  -to [get_ports {out_I[7]}]
set_max_delay 3  -to [get_ports {out_I[6]}]
set_max_delay 3  -to [get_ports {out_I[5]}]
set_max_delay 3  -to [get_ports {out_I[4]}]
set_max_delay 3  -to [get_ports {out_I[3]}]
set_max_delay 3  -to [get_ports {out_I[2]}]
set_max_delay 3  -to [get_ports {out_I[1]}]
set_max_delay 3  -to [get_ports {out_I[0]}]
set_max_delay 3  -to [get_ports {out_Q[15]}]
set_max_delay 3  -to [get_ports {out_Q[14]}]
set_max_delay 3  -to [get_ports {out_Q[13]}]
set_max_delay 3  -to [get_ports {out_Q[12]}]
set_max_delay 3  -to [get_ports {out_Q[11]}]
set_max_delay 3  -to [get_ports {out_Q[10]}]
set_max_delay 3  -to [get_ports {out_Q[9]}]
set_max_delay 3  -to [get_ports {out_Q[8]}]
set_max_delay 3  -to [get_ports {out_Q[7]}]
set_max_delay 3  -to [get_ports {out_Q[6]}]
set_max_delay 3  -to [get_ports {out_Q[5]}]
set_max_delay 3  -to [get_ports {out_Q[4]}]
set_max_delay 3  -to [get_ports {out_Q[3]}]
set_max_delay 3  -to [get_ports {out_Q[2]}]
set_max_delay 3  -to [get_ports {out_Q[1]}]
set_max_delay 3  -to [get_ports {out_Q[0]}]
set_max_delay 3  -to [get_ports valid_out]
set_input_delay -clock fun_clk  -max 2  [get_ports fun_rst_n]
set_input_delay -clock fun_clk  -max 2  [get_ports scan_clk]
set_input_delay -clock fun_clk  -max 2  [get_ports scan_rst_n]
set_input_delay -clock fun_clk  -max 2  [get_ports test_mode]
set_input_delay -clock fun_clk  -max 2  [get_ports valid_in]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[15]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[14]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[13]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[12]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[11]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[10]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[9]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[8]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[7]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[6]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[5]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[4]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[3]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[2]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[1]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_I[0]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[15]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[14]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[13]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[12]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[11]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[10]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[9]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[8]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[7]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[6]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[5]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[4]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[3]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[2]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[1]}]
set_input_delay -clock fun_clk  -max 2  [get_ports {in_Q[0]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[15]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[14]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[13]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[12]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[11]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[10]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[9]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[8]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[7]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[6]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[5]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[4]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[3]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[2]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[1]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_I[0]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[15]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[14]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[13]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[12]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[11]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[10]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[9]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[8]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[7]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[6]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[5]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[4]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[3]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[2]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[1]}]
set_output_delay -clock fun_clk  -max 2  [get_ports {out_Q[0]}]
set_output_delay -clock fun_clk  -max 2  [get_ports valid_out]
