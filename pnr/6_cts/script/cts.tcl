########################################################################
# cts.tcl
# -----------------------------------------------------------------------
# Purpose : ICC2 Clock Tree Synthesis for neural_eq_top (45nm FreePDK45)
#           - Opens placed block from Step 5
#           - Sets clock input transitions
#           - Defines CTS cell library (CLKBUF cells only)
#           - Sets NDR (non-default routing rules) for clock nets
#           - Sets clock tree targets (skew, latency)
#           - Runs 3-step clock_opt: build → route → final_opto
#           - Reconnects PG nets after CTS buffer insertion
#           - Saves as neural_eq_top_cts block
#
# Tool    : Synopsys IC Compiler II  (icc2_shell)
# Run     : cd ASIC/pnr/6_cts/run
#           icc2_shell -f ../script/cts.tcl | tee ../log/cts.log
#
# Prereq  : Step 5 (placement.tcl) must be complete.
#           Block neural_eq_top_pl must exist in the .dlib.
#
# ICC1 equiv file : pnr45.tcl  Section "5. CTS"
# Author  : Auto-generated for neural_eq_top PnR flow
########################################################################

puts "INFO: ================================================"
puts "INFO:  ICC2 CTS — neural_eq_top (45nm)"
puts "INFO: ================================================"

# ======================================================================
# 1. Variables
# ======================================================================
set design          "neural_eq_top"
set design_lib_path "../../2_design_library/output"
set DLIB            "${design_lib_path}/${design}.dlib"

# ======================================================================
# 2. Remove lock file & Open Block
# ======================================================================
sh rm -f ${DLIB}/${design}_pl/design.ndm.lock

# ICC1 equiv: open_mw_lib ./${design} ; open_mw_cel ${design}_4_placed
puts "INFO: Opening placed block..."
open_lib  $DLIB
open_block ${design}_pl

copy_block -from_block ${design}_pl -to_block ${design}_cts
current_block ${design}_cts

# ======================================================================
# 3. Pre-CTS Checks
# ======================================================================
# Validates placement quality, checks for congestion + timing issues
# before running the clock tree. Important to fix violations now —
# CTS will propagate any existing problems.
#
# ICC1 equiv (pnr45.tcl line 335):
#   check_physical_design -stage pre_clock_opt
# ICC2 equiv from pnr90.tcl:
#   check_design -checks pre_clock_tree_stage
# ======================================================================
puts "INFO: Running pre-CTS checks..."
check_design -checks pre_clock_tree_stage

# Reset any stale clock tree options from prior runs
# ICC1 equiv: NOT in pnr45.tcl
# ICC2 equiv from pnr90.tcl:
remove_clock_tree_options -all -target_skew -target_latency

# ======================================================================
# 4. Restore Routing Layer Range for CTS
# ======================================================================
# CTS needs to route on metal3–metal9 for clock nets (see NDR section).
# Restore full routing access temporarily.
#
# ICC1 equiv (pnr45.tcl line 61):
#   remove_ignored_layers -all
# ======================================================================
set_ignored_layers -max_routing_layer metal9 -min_routing_layer metal1

# ======================================================================
# 5. Report Existing Clocks
# ======================================================================
# Verify that fun_clk is properly defined before CTS.
#
# ICC1 equiv (pnr45.tcl line 337-338):
#   check_clock_tree
#   report_clock_tree
# ICC2 equiv from pnr90.tcl:
#   report_clocks
#   report_clock_qor -type structure
# ======================================================================
puts "INFO: Reporting clock status..."
report_clocks > ../report/cts_clocks.rpt
report_clock_qor -type structure > ../report/cts_clock_qor_pre.rpt

# ======================================================================
# 6. Clock Input Transition
# ======================================================================
# Models the slew (transition time) at the clock port. This affects
# how the clock tree is built — a fast input edge leads to less
# insertion delay and better skew targets.
#
# ICC1 equiv (pnr45.tcl line 344):
#   set_driving_cell -lib_cell BUF_X16 -pin Z [get_ports clk]
# ICC2 equiv from pnr90.tcl:
#   set_input_transition -rise 0.3 {fun_clk}
#   set_input_transition -fall 0.2 {fun_clk}
# ======================================================================
puts "INFO: Setting clock input transitions..."
set_input_transition -rise 0.3 {fun_clk}
set_input_transition -fall 0.2 {fun_clk}

# ======================================================================
# 7. Restrict Which Cells CTS Can Use
# ======================================================================
# First exclude ALL cells from CTS, then selectively include only
# the CLKBUF cells (and optionally INV cells for inversion-based trees).
# This ensures CTS does not pick random BUF or logic cells.
#
# Verified CLKBUF cell names from LEF directory:
#   CLKBUF_X1, CLKBUF_X2, CLKBUF_X3
#
# ICC1 equiv (pnr45.tcl lines 369-371):
#   set_clock_tree_references -references [get_lib_cells */CLKBUF*]
# ICC2 equiv from pnr90.tcl:
#   set_lib_cell_purpose -exclude cts [get_lib_cells -of [get_cells *]]
#   set_lib_cell_purpose -include cts */CLKBUF_X1  ...
# ======================================================================
puts "INFO: Setting CTS cell library (CLKBUF_X1/X2/X3)..."

# Step 1: Exclude all cells currently in design from CTS consideration
set_lib_cell_purpose -exclude cts [get_lib_cells -of [get_cells *]]

# Step 2: Include only the designated clock buffer cells
set_lib_cell_purpose -include cts NangateOpenCellLibrary/CLKBUF_X1
set_lib_cell_purpose -include cts NangateOpenCellLibrary/CLKBUF_X2
set_lib_cell_purpose -include cts NangateOpenCellLibrary/CLKBUF_X3

# Optionally include INV cells (preferred in some CTS flows for
# better slew control due to pull-up vs pull-down resistance balance)
# ICC1 equiv (pnr45.tcl, commented): set_clock_tree_references -references [get_lib_cells */INV*]
# set_lib_cell_purpose -include cts NangateOpenCellLibrary/INV_X2
# set_lib_cell_purpose -include cts NangateOpenCellLibrary/INV_X4

# ======================================================================
# 8. Clock Tree Targets (Skew & Latency)
# ======================================================================
# -target_skew   : Maximum allowed difference in clock arrival time
#                  between any two flip-flop clock pins (0.5ns from pnr45.tcl)
# -target_latency: Target clock insertion delay from port to sinks (0.5ns)
#
# ICC1 equiv (pnr45.tcl lines 354-360):
#   set_clock_tree_options \
#     -clock_trees clk \
#     -target_early_delay 0.1 \
#     -target_skew 0.5 \
#     -max_capacitance 300 \
#     -max_fanout 10 \
#     -max_transition 0.3
# ICC2 equiv from pnr90.tcl:
#   set_clock_tree_options -target_skew 0.01
#   set_clock_tree_options -target_latency 0.5
#
# Note: ICC2 sets targets globally for all clocks (no -clock_trees needed
# unless you have multiple clocks with different targets).
# ======================================================================
puts "INFO: Setting clock tree targets..."
set_clock_tree_options -target_skew    0.5
set_clock_tree_options -target_latency 0.5

# Per-clock DRC limits (applied to the clock tree itself)
set_max_transition -clock_path 0.3 [get_clocks fun_clk]
set_app_options -name cts.common.max_fanout           -value 10
set_app_options -name cts.common.user_instance_name_prefix -value "CTS_"

# ======================================================================
# 9. Non-Default Routing Rules (NDR) for Clock Nets
# ======================================================================
# Clock nets use double-width, double-spacing routing to reduce
# crosstalk and improve signal integrity. This is called NDR.
#
# NDR values from pnr45.tcl (lines 381-390):
#   metal3: width 0.14µm spacing 0.14µm (2× the min 0.07µm)
#   metal4: width 0.28µm spacing 0.28µm (2× the min 0.14µm)
#   metal5: width 0.28µm spacing 0.28µm
#
# ICC1 equiv (pnr45.tcl lines 381-390):
#   define_routing_rule my_route_rule \
#     -widths   {metal3 0.14 metal4 0.28 metal5 0.28} \
#     -spacings {metal3 0.14 metal4 0.28 metal5 0.28}
#   set_clock_tree_options -clock_trees clk \
#     -routing_rule my_route_rule \
#     -layer_list "metal3 metal4 metal5"
#   set_clock_tree_options -use_default_routing_for_sinks 1
#
# ICC2 equiv from pnr90.tcl:
#   create_routing_rule clk_network_NDR -multiplier_spacing 2 -multiplier_width 2
#   set_clock_routing_rules -net_type root   -rules clk_network_NDR ...
#   set_clock_routing_rules -net_type internal ...
#   set_clock_routing_rules -net_type sink   -default_rule ...
# ======================================================================
puts "INFO: Creating NDR for clock nets..."

create_routing_rule clk_network_NDR \
    -multiplier_spacing 2 \
    -multiplier_width   2

# Root: from clock port to first buffer — use NDR on metal3-metal9
set_clock_routing_rules \
    -net_type         root \
    -rules            clk_network_NDR \
    -max_routing_layer metal9 \
    -min_routing_layer metal3

# Internal: between clock buffers — use NDR on metal3-metal9
set_clock_routing_rules \
    -net_type         internal \
    -rules            clk_network_NDR \
    -max_routing_layer metal9 \
    -min_routing_layer metal3

# Sink: last buffer to flip-flop clock pin — use DEFAULT rule (no NDR)
# This avoids DRC issues at the cell level where default rules apply.
# ICC1 equiv (pnr45.tcl line 390): set_clock_tree_options -use_default_routing_for_sinks 1
set_clock_routing_rules \
    -net_type         sink \
    -default_rule \
    -max_routing_layer metal9 \
    -min_routing_layer metal3

# Reduce OCV (On-Chip Variation) pessimism by sharing clock buffers
# ICC1 equiv: NOT in pnr45.tcl
set_app_options -name time.remove_clock_reconvergence_pessimism -value true

report_routing_rules  -verbose > ../report/cts_routing_rules.rpt
report_clock_routing_rules     > ../report/cts_clock_routing_rules.rpt
report_clock_settings          > ../report/cts_clock_settings.rpt

# ======================================================================
# 10. Clock Tree Synthesis — 3-Step Flow
# ======================================================================
# ICC2 clock_opt is broken into 3 phases for better control.
# Each phase can be run and analyzed independently.
#
# --- Phase 1: Build Clock Tree (CTS)
# Inserts clock buffers and builds the tree topology.
# No routing yet — just logical tree construction.
#
# ICC1 equiv (pnr45.tcl line 400):
#   clock_opt -only_cts -no_clock_route
# ICC2 equiv from pnr90.tcl:
#   clock_opt -from build_clock -to build_clock
# ======================================================================
puts "INFO: Phase 1 — Building clock tree..."
clock_opt -from build_clock -to build_clock

# Analyze CTS results
report_clock_qor -type structure > ../report/cts_post_build_qor.rpt
report_timing -nosplit           > ../report/cts_post_build_timing.rpt

# ======================================================================
# --- Phase 2: Route Clock Nets
# Routes all clock nets using the NDR rules defined above.
#
# ICC1 equiv (pnr45.tcl line 422):
#   route_group -all_clock_nets
# ICC2 equiv from pnr90.tcl:
#   clock_opt -from route_clock -to route_clock
# ======================================================================
puts "INFO: Phase 2 — Routing clock nets..."
clock_opt -from route_clock -to route_clock

# Verify clock route DRC
check_routes -drc true > ../report/cts_clock_route_drc.rpt

# ======================================================================
# --- Phase 3: Clock Tree Optimization (CTO)
# Post-route optimization: skew balancing, hold slack fixing,
# buffer sizing, and gate relocation.
# Also handles hold time fixing if set_fix_hold is set.
#
# ICC1 equiv (pnr45.tcl line 417):
#   clock_opt -only_psyn -no_clock_route
# ICC2 equiv from pnr90.tcl:
#   clock_opt -from route_clock -to final_opto
# ======================================================================
puts "INFO: Phase 3 — Clock tree optimization (CTO)..."

# Uncomment to enable hold time fixing during CTO:
# set_fix_hold [all_clocks]
# set_fix_hold_options -prioritize_tns

clock_opt -from route_clock -to final_opto

# ======================================================================
# 11. Reconnect PG Nets After CTS Insertions
# ======================================================================
# CTS inserted new clock buffers — their VDD/VSS pins must be connected.
#
# ICC1 equiv (pnr45.tcl lines 430-433):
#   derive_pg_connection -power_net VDD -ground_net VSS ...
# ICC2: connect_pg_net
# ======================================================================
puts "INFO: Reconnecting PG nets for CTS-inserted cells..."
puts "INFO:   CTS cells inserted: [sizeof_collection [get_cells CTS_*]]"
connect_pg_net -net VDD [get_pins -hierarchical "*/VDD"]
connect_pg_net -net VSS [get_pins -hierarchical "*/VSS"]
check_pg_drc > ../report/cts_pg_drc_final.rpt

# ======================================================================
# 12. Reports
# ======================================================================
# ICC1 equiv (pnr45.tcl lines 402-408):
#   report_design_physical -utilization
#   report_clock_tree -summary
#   report_clock_timing -type summary
#   report_timing
#   report_timing -delay_type min
#   report_constraints -all_violators
# ======================================================================
puts "INFO: Generating CTS reports..."
report_clock_tree_options           > ../report/cts_clock_tree_options.rpt
report_clock_settings               > ../report/cts_clk_setting_final.rpt
report_utilization -verbose         > ../report/cts_utilization.rpt
report_design                       > ../report/cts_design.rpt
report_cell                         > ../report/cts_cells.rpt
report_qor                          > ../report/cts_qor.rpt
check_routes -drc true              > ../report/cts_drc_final.rpt
report_timing -delay_type min -nosplit > ../report/cts_timing_min.rpt
report_timing -delay_type max -nosplit > ../report/cts_timing_max.rpt
report_ports -verbose [get_ports *clk*] > ../report/cts_clk_ports.rpt

# ======================================================================
# 13. Write Intermediate Outputs
# ======================================================================
puts "INFO: Writing CTS outputs..."
file mkdir ../output
write_def     ../output/${design}_cts.def
write_verilog -include {all} ../output/${design}_cts.v
write_sdc     -output ../output/${design}_cts.sdc

# ======================================================================
# 14. Save Block
# ======================================================================
# ICC1 equiv (pnr45.tcl line 435):
#   save_mw_cel -as ${design}_5_cts
# ======================================================================
puts "INFO: Saving block as ${design}_cts..."
save_block

puts "INFO: ================================================"
puts "INFO:  CTS Complete!"
puts "INFO:  Block saved: ${design}_cts"
puts "INFO:  Next step: Step 7 — Routing"
puts "INFO: ================================================"
