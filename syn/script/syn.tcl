# ################################## #
# ============= Setup ============== #
# ################################## #
set_host_options -max_cores 8

# --- Library (update path to your actual library)
set worst_case "NangateOpenCellLibrary_ss0p95vn40c.db"

lappend search_path "/home/standard_cell_libraries/NangateOpenCellLibrary_PDKv1_3_v2010_12/lib/Front_End/Liberty/NLDM"
set_app_var target_library [list $worst_case]
set_app_var link_library   "* $target_library"

# --- Work directory
sh rm -rf work
sh mkdir -p work
define_design_lib work -path ./work

# --- Top module
set design neural_eq_top
# --fixes all violations in the design ICC2
set compile_top_all_paths true
# --- Define Structured Verification Format (SVF) 
set_svf ${design}.svf 


# ################################## #
# ============ Translate =========== #
# ################################## #

analyze -format sverilog -lib work  ../../rtl/${design}.sv ; # Check Syntax Errors and generate intermediate files 
elaborate $design -lib work ; # Translate from RTL to getech netlist  and check {linting, design issues , not supported width mismatch} 
current_design  
check_design

# # Read all RTL files
# analyze -format sverilog -lib work ../rtl/input_window_ctrl.sv
# analyze -format sverilog -lib work ../rtl/layer1_compute.sv
# analyze -format sverilog -lib work ../rtl/layer2_compute.sv
# analyze -format sverilog -lib work ../rtl/layer3_compute.sv
# analyze -format sverilog -lib work ../rtl/neural_eq_top.sv

# elaborate $design -lib work
# current_design $design
# check_design

# ################################## #
# =========== Constraints ========== #
# ################################## #
source ../cons/cons.tcl  

# ################################## #
# ========== Optimization ========== #
# ################################## #
set_fix_multiple_port_nets -all -buffer_constants 
link
compile_ultra
#compile -map_effort high
report_timing -max_paths 20 > ../report/synth_timing_before_optimize.rpt 

compile -top  

report_timing -max_paths 20 > ../report/synth_timing_after_optimize.rpt 


# ################################## #
# ============ Reports ============= #
# ################################## #

# report_area    -nosplit            > ./report/synth_area.rpt
# report_power   -nosplit            > ./report/synth_power.rpt
# report_cell                        > ./report/synth_cells.rpt
# report_qor                         > ./report/synth_qor.rpt
# report_clock                       > ./report/clock.rpt
# report_constraint -all_violators   > ./report/violations.rpt
# report_timing -max_paths 20        > ./report/synth_timing.rpt
# report_resources                   > ./report/synth_resources.rpt

report_area  -nosplit  > ../report/synth_area.rpt
report_power -nosplit > ../report/synth_power.rpt
report_cell > ../report/synth_cells.rpt
report_qor  > ../report/synth_qor.rpt
report_clock > ../report/clock.rpt
report_constraint -all_violators -nosplit > ../report/Syn_violations.rpt
report_timing > ../report/critical_Path_timing.rpt
report_timing -max_paths 20 > ../report/synth_timing.rpt 
report_resources > ../report/synth_resources.rpt
report_logic_levels > ../report/logic_levels.rpt 

# ################################## #
# ============ Outputs ============= #
# ################################## #
define_name_rules no_case -case_insensitive
change_names -rule no_case -hierarchy
change_names -rule verilog -hierarchy
# extra from icc2
report_names -rules verilog
# extra from icc1 make sure they exist in icc2
set verilogout_no_tri	 true
set verilogout_equation  false

## only in icc2 el gammal flow
write_sdc ../output/${design}.sdc 
write_sdf ../output/${design}.sdf 


write -hierarchy -format verilog -output ../output/${design}.v 
write -f ddc -hierarchy -output ../output/${design}.ddc 

## what is this ?? it was turned off 
set_svf -off

exit
