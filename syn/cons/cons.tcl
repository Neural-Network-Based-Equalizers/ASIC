## both ICC & ICCII have same DC
#### MINA & MICHAEL
create_clock -name fun_clk -period 4 -waveform {0 2} [get_ports fun_clk]
set_input_delay -max 2 -clock [get_clocks fun_clk] [remove_from_collection [all_inputs] [get_ports fun_clk]]
set_output_delay -max 2 -clock [get_clocks fun_clk] [all_outputs]
set_clock_uncertainty 0.35 [get_clocks]
set_false_path -hold -from [remove_from_collection [all_inputs] [get_ports fun_clk]]
set_false_path -hold -to [all_outputs]

set_case_analysis 0 test_mode
set_dont_touch_network [get_clocks {fun_clk}]
set_dont_touch_network [get_ports  {fun_rst_n}]

set_max_transition 0.5 [current_design]
set_max_capacitance 2.0 [current_design]
# set_max_area 0.0 

# set_driving_cell -lib_cell NBUFFX2 -pin Z [remove_from_collection [all_inputs] [get_ports {fun_clk}]];
# set_load 1 [all_outputs]

# #### elgammal
# ##################################################
# 		# ----- Clock Definations -----  # 
# ##################################################

# # --- Budget Clock (Timing Definations)
# create_clock -name fun_clk  -period 5 -waveform {0 2.5}  [get_ports fun_clk ]
# # --- Clock uncertainty Berfore CTS  uncertainty = Jitter + Source Latency  + Network Latency 
# set_clock_uncertainty -setup 0.03  [get_clocks fun_clk]  ;  # Consider Skew + Jitter 
# set_clock_uncertainty -hold  0.02  [get_clocks fun_clk]  ;  # only Consider Skew   


# # --- Modeling outside for Timing 
# # -- Type of Path IN to Reg >> pesudo as [input_delay =  Tcq + Tpd ] 
# set_input_delay  -clock fun_clk -max 0.05  [remove_from_collection [all_inputs] [get_ports {fun_clk}]]
 
# # -- Type of Path Reg to Output >> pesudo as [output_delay = Tpd + Tsetup ] 
# set_output_delay -max 0.05 -clock fun_clk [all_outputs] 

# # --- Prevent Tool do any thing on network 
# set_dont_touch_network [get_clocks {fun_clk}]
# #set_dont_touch_network [get_ports  {reset}]
# # ---  grouping paths 
# group_path -name "comp_paths" -to {fun_clk}
# set_app_var compile_ultra_ungroup_dw false
# set_wire_load_model  -name ForQA
# set_case_analysis 0 test_mode
# ##################################################
# 	# ----- Optimization ---------  # 
# ##################################################
# # set_max_area 0.0 
# set_max_transition 0.5 [current_design]
# # set_max_transition 0.5 -data_path [get_clocks fun_clk]

# set_max_capacitance 2.0 [current_design]
# set_max_fanout 3 $design 
# set_max_delay 3 -group_path "comp_paths" -to [all_outputs]

# ##################################################
# 		# ----- Interaface  ---------  # 
# ##################################################
# #set_driving_cell -lib_cell NBUFFX2 -pin Z [remove_from_collection [all_inputs] [get_ports {fun_clk}]];
# set_load 1 [all_outputs]

# ##################################################
# 	# ----- don't use  ---------  # 
# ################################################## 
# # set_dont_use [get_lib_cells */*AND3*]
# # set_dont_use [get_lib_cells */*AND2X4] 
# # set_dont_use [get_lib_cells */*AND2X1]
# # set_dont_use [get_lib_cells */*AND2X*]
# # set_dont_use [get_lib_cells */*NAND2X0]
# # set_dont_use [get_lib_cells */*NAND2X1]
# # set_dont_use [get_lib_cells */*NAND2X2]
# # set_dont_use [get_lib_cells */*DELLN1*]
# # set_dont_use [get_lib_cells */*INVX0]
# # set_dont_use [get_lib_cells */*INVX1]
# # set_dont_use [get_lib_cells */*INVX2]
# # set_dont_use [get_lib_cells */*AO22*]
# # set_dont_use [get_lib_cells */*AOI22*]
# # set_dont_use [get_lib_cells */*AO*]
# # set_dont_use [get_lib_cells */*OA*]
# # set_dont_use [get_lib_cells */*X0]
# # set_dont_use [get_lib_cells */*DELLN2X*]
# # set_dont_use [get_lib_cells */*DELLN2*]
# # set_dont_use [get_lib_cells */*DELLN*]
# # set_dont_use [get_lib_cells */*NBU*]
# # set_dont_use [get_lib_cells */*NBUFFX4]
# # set_dont_use [get_lib_cells */*OR3X1]
# # set_dont_use [get_lib_cells */*NAND2X1]
# # set_dont_use [get_lib_cells */*IBUFFX2]
# # set_dont_use [get_lib_cells */*OR2X4]
# # set_dont_use [get_lib_cells */*OR2X4]








# # =========================================================
# # Constraints for: neural_eq_top
# # Architecture:
# #   input_window_ctrl  -> layer1_compute (4 ticks)
# #                      -> layer2_compute (6 ticks)
# #                      -> layer3_compute (6 ticks)
# #
# # The critical combinational path is inside the MAC units:
# #   16x16 multiply -> 40-bit accumulate -> shift -> clamp
# #
# # Start with 10ns (100 MHz). Tighten if timing is met cleanly.
# # =========================================================




# # --- Clock ---
# create_clock -name fun_clk -period 10 -waveform {0 5} [get_ports fun_clk]

# # --- Clock uncertainty (jitter + skew) ---
# set_clock_uncertainty 0.3 [get_clocks fun_clk]

# # --- Clock transition ---
# set_clock_transition 0.1 [get_clocks fun_clk]

# # --- Input delays (data arrives 2ns after clock edge) ---
# set_input_delay -max 2.0 -clock [get_clocks fun_clk] \
#     [remove_from_collection [all_inputs] [get_ports {fun_clk rst_n}]]

# # --- Output delays (data must be stable 2ns before next clock edge) ---
# set_output_delay -max 2.0 -clock [get_clocks fun_clk] [all_outputs]

# # --- Reset is async: no timing on rst_n ---
# set_false_path -from [get_ports rst_n]
# set_max_fanout 32 [get_ports rst_n]

# # --- Drive strength on inputs (16-drive standard cell) ---
# set_driving_cell -lib_cell DFFX1 -pin Q \
#     [remove_from_collection [all_inputs] [get_ports {fun_clk rst_n}]]

# # --- Output load ---
# set_load 0.05 [all_outputs]



# # =========================================================
# # NOTE ON CLOCK PERIOD:
# #   The 16x16 signed multiply in each MAC expands to ~32-bit
# #   product before being added into a 40-bit accumulator.
# #   With a typical standard-cell library at ss/cold this
# #   path typically closes at 8-12ns.
# #   If the tool reports negative slack, relax to 12ns first,
# #   then recheck after compile -map_effort high.
# # =========================================================



