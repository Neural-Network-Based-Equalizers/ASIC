################################################################################
#
# Design name:  neural_eq_top_fp
#
# Created by icc2 write_sdc on Wed Apr 29 17:38:50 2026
#
################################################################################

set sdc_version 2.1
set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA

################################################################################
#
# Units
# time_unit               : 1e-09
# resistance_unit         : 1000000
# capacitive_load_unit    : 1e-15
# voltage_unit            : 1
# current_unit            : 1e-06
# power_unit              : 1e-12
################################################################################


# Mode: default
# Corner: default
# Scenario: default

# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 76
create_clock -name clk -period 10 -waveform {0 5} [get_ports {clk}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 82
set_false_path -from [get_ports {rst_n}]
set_load -pin_load 0.05 [get_ports {out_I[15]}]
set_load -pin_load 0.05 [get_ports {out_I[14]}]
set_load -pin_load 0.05 [get_ports {out_I[13]}]
set_load -pin_load 0.05 [get_ports {out_I[12]}]
set_load -pin_load 0.05 [get_ports {out_I[11]}]
set_load -pin_load 0.05 [get_ports {out_I[10]}]
set_load -pin_load 0.05 [get_ports {out_I[9]}]
set_load -pin_load 0.05 [get_ports {out_I[8]}]
set_load -pin_load 0.05 [get_ports {out_I[7]}]
set_load -pin_load 0.05 [get_ports {out_I[6]}]
set_load -pin_load 0.05 [get_ports {out_I[5]}]
set_load -pin_load 0.05 [get_ports {out_I[4]}]
set_load -pin_load 0.05 [get_ports {out_I[3]}]
set_load -pin_load 0.05 [get_ports {out_I[2]}]
set_load -pin_load 0.05 [get_ports {out_I[1]}]
set_load -pin_load 0.05 [get_ports {out_I[0]}]
set_load -pin_load 0.05 [get_ports {out_Q[15]}]
set_load -pin_load 0.05 [get_ports {out_Q[14]}]
set_load -pin_load 0.05 [get_ports {out_Q[13]}]
set_load -pin_load 0.05 [get_ports {out_Q[12]}]
set_load -pin_load 0.05 [get_ports {out_Q[11]}]
set_load -pin_load 0.05 [get_ports {out_Q[10]}]
set_load -pin_load 0.05 [get_ports {out_Q[9]}]
set_load -pin_load 0.05 [get_ports {out_Q[8]}]
set_load -pin_load 0.05 [get_ports {out_Q[7]}]
set_load -pin_load 0.05 [get_ports {out_Q[6]}]
set_load -pin_load 0.05 [get_ports {out_Q[5]}]
set_load -pin_load 0.05 [get_ports {out_Q[4]}]
set_load -pin_load 0.05 [get_ports {out_Q[3]}]
set_load -pin_load 0.05 [get_ports {out_Q[2]}]
set_load -pin_load 0.05 [get_ports {out_Q[1]}]
set_load -pin_load 0.05 [get_ports {out_Q[0]}]
set_load -pin_load 0.05 [get_ports {valid_out}]
set_clock_uncertainty 0.3 [get_clocks {clk}]
set_clock_transition 0.1 [get_clocks {clk}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 9
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {valid_in}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 10
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[15]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 11
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[14]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 12
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[13]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 13
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[12]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 14
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[11]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 15
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[10]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 16
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[9]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 17
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[8]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 18
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[7]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 19
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[6]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 20
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[5]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 21
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[4]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 22
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[3]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 23
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[2]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 24
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[1]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 25
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_I[0]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 26
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[15]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 27
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[14]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 28
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[13]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 29
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[12]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 30
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[11]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 31
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[10]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 32
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[9]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 33
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[8]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 34
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[7]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 35
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[6]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 36
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[5]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 37
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[4]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 38
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[3]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 39
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[2]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 40
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[1]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 41
set_driving_cell -lib_cell DFFX1 -pin Q [get_ports {in_Q[0]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 83; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 83
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {valid_in}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 84; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 84
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[15]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 85; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 85
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[14]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 86; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 86
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[13]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 87; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 87
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[12]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 88; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 88
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[11]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 89; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 89
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[10]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 90; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 90
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[9]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 91; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 91
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[8]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 92; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 92
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[7]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 93; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 93
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[6]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 94; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 94
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[5]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 95; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 95
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[4]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 96; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 96
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[3]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 97; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 97
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[2]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 98; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 98
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[1]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 99; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 99
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_I[0]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 100; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 100
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[15]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 101; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 101
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[14]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 102; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 102
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[13]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 103; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 103
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[12]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 104; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 104
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[11]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 105; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 105
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[10]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 106; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 106
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[9]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 107; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 107
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[8]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 108; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 108
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[7]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 109; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 109
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[6]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 110; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 110
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[5]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 111; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 111
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[4]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 112; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 112
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[3]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 113; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 113
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[2]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 114; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 114
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[1]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 115; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 115
set_input_delay -clock [get_clocks {clk}] -max 2 [get_ports {in_Q[0]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 116; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 116
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[15]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 117; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 117
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[14]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 118; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 118
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[13]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 119; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 119
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[12]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 120; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 120
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[11]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 121; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 121
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[10]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 122; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 122
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[9]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 123; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 123
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[8]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 124; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 124
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[7]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 125; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 125
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[6]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 126; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 126
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[5]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 127; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 127
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[4]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 128; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 128
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[3]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 129; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 129
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[2]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 130; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 130
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[1]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 131; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 131
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_I[0]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 132; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 132
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[15]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 133; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 133
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[14]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 134; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 134
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[13]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 135; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 135
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[12]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 136; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 136
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[11]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 137; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 137
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[10]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 138; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 138
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[9]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 139; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 139
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[8]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 140; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 140
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[7]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 141; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 141
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[6]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 142; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 142
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[5]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 143; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 143
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[4]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 144; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 144
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[3]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 145; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 145
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[2]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 146; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 146
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[1]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 147; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 147
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {out_Q[0]}]
# /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 148; \
#   /home/ICer/Desktop/Graduation_Project/syn/output/neural_eq_top.sdc, line 148
set_output_delay -clock [get_clocks {clk}] -max 2 [get_ports {valid_out}]
