########################################################################
# routing.tcl
# -----------------------------------------------------------------------
# Purpose : ICC2 Routing step for neural_eq_top (45nm FreePDK45)
#           - Opens CTS block from Step 6
#           - Runs global route → track assign → detail route
#           - Hold time fixing
#           - Incremental ECO routing (DRC cleanup)
#           - Redundant via insertion
#           - Filler cell insertion (post-route)
#           - Full DRC + LVS checks
#           - Saves as neural_eq_top_route block
#
# Tool    : Synopsys IC Compiler II  (icc2_shell)
# Run     : cd ASIC/pnr/7_routing/run
#           icc2_shell -f ../script/routing.tcl | tee ../log/routing.log
#
# Prereq  : Step 6 (cts.tcl) must be complete.
#           Block neural_eq_top_cts must exist in the .dlib.
#
# ICC1 equiv file : pnr45.tcl  Section "6. Routing" + "7. Finishing"
# Author  : Auto-generated for neural_eq_top PnR flow
########################################################################

puts "INFO: ================================================"
puts "INFO:  ICC2 Routing — neural_eq_top (45nm)"
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
sh rm -f ${DLIB}/${design}_cts/design.ndm.lock

# ICC1 equiv: open_mw_lib ./${design} ; open_mw_cel ${design}_5_cts
puts "INFO: Opening CTS block..."
open_lib  $DLIB
open_block ${design}_cts

copy_block -from_block ${design}_cts -to_block ${design}_route
current_block ${design}_route

# ======================================================================
# 3. Pre-Route Checks
# ======================================================================
# Checks that the design is ready for routing: no unplaced cells,
# no missing PG connections, no major congestion hotspots.
#
# ICC1 equiv (pnr45.tcl lines 456-459):
#   check_physical_design -stage pre_route_opt
#   all_ideal_nets
#   all_high_fanout -nets -threshold 100
#   check_routeability
# ICC2 equiv from pnr90.tcl:
#   check_design -checks routability
# ======================================================================
puts "INFO: Running pre-route checks..."
check_design -checks routability > ../report/pre_route_check.rpt

# ======================================================================
# 4. Set Routing Layer Range
# ======================================================================
# Signal routes are on metal1–metal6.
# metal7–metal10 are reserved for the PG network.
#
# ICC1 equiv (pnr45.tcl line 61):
#   set_ignored_layers -max_routing_layer metal6
# ICC2:
#   set_ignored_layer -max M9 -min M1  (from pnr90.tcl for SAED)
#   We adapt for FreePDK45 layer names:
# ======================================================================
puts "INFO: Setting signal routing layer range (metal1-metal6)..."
set_ignored_layers -max_routing_layer metal6 -min_routing_layer metal1

# ======================================================================
# 5. Hold Time Fix Setup
# ======================================================================
# Adds buffers on short paths to meet hold time constraints.
# Must be set BEFORE routing so the router accounts for hold buffers.
# -prioritize_tns : Fix total negative slack first, then individual paths
# -preferred_buffer: Use low-drive buffers (BUF_X1/X2) for hold fixing
#
# ICC1 equiv (pnr45.tcl lines 495-497):
#   set_fix_hold [all_clocks]
#   set_prefer -min [get_lib_cells "*/BUF_X2 */BUF_X1"]
#   set_fix_hold_options -preferred_buffer
# ICC2: same commands — set_fix_hold syntax is unchanged
# ======================================================================
puts "INFO: Setting up hold time fix..."
set_fix_hold [all_clocks]
set_fix_hold_options -prioritize_tns
set_fix_hold_options -preferred_buffer

# ======================================================================
# 6. Routing App Options (SI + DRC)
# ======================================================================
# Configures the router for timing-driven and SI-aware routing.
#
# ICC1 equiv (pnr45.tcl lines 472-481):
#   set_route_options -groute_timing_driven true \
#                     -groute_incremental true \
#                     -track_assign_timing_driven true \
#                     -same_net_notch check_and_fix
#   set_si_options -route_xtalk_prevention true \
#                  -delta_delay true -min_delta_delay true \
#                  -static_noise true -timing_window true
# ICC2: uses set_app_options for routing configuration
# ======================================================================
puts "INFO: Setting routing options..."
set_app_options -name route.global.timing_driven        -value true
set_app_options -name route.track.timing_driven         -value true
set_app_options -name route.detail.timing_driven        -value true
set_app_options -name route.common.connect_within_pins_only -value true

# SI (Signal Integrity) options
set_app_options -name route.detail.xtalk_reduction      -value true
set_app_options -name si.enable_delay                   -value true
set_app_options -name si.enable_static_noise            -value true

# ======================================================================
# 7. Global Route
# ======================================================================
# Determines approximate paths for all nets through the routing grid.
# Assigns nets to routing regions (gcells) without detailed wire shapes.
# Very fast — used to identify congestion hotspots early.
#
# ICC1 equiv (pnr45.tcl line 500):
#   route_opt  (this ran all 3 stages at once)
# ICC2 equiv from pnr90.tcl: three separate commands
#   route_global → route_track → route_detail
# ======================================================================
puts "INFO: Step 7a — Global Route..."
route_global
check_routes > ../report/route_global_drc.rpt

# ======================================================================
# 8. Track Assignment
# ======================================================================
# Maps the global routes to specific metal tracks on each layer.
# Still no detailed wire shapes, but routing tracks are reserved.
# Timing-driven: prioritizes critical paths for better layer assignment.
#
# ICC1 equiv: part of route_opt
# ICC2 equiv from pnr90.tcl: route_track (separate command)
# ======================================================================
puts "INFO: Step 7b — Track Assignment..."
route_track
check_routes > ../report/route_track_drc.rpt

# ======================================================================
# 9. Detail Route
# ======================================================================
# Creates actual wire geometries on each metal layer.
# Resolves all remaining DRC violations (spacing, width, enclosure).
# This is the most time-consuming routing step.
#
# ICC1 equiv: part of route_opt + route_zrt_detail
# ICC2 equiv from pnr90.tcl: route_detail
# ======================================================================
puts "INFO: Step 7c — Detail Route..."
route_detail
check_routes > ../report/route_detail_drc_pass1.rpt

# ======================================================================
# 10. Incremental ECO Routing (DRC Cleanup)
# ======================================================================
# Fixes any remaining DRC violations from detail routing
# without disturbing already-clean nets.
#
# ICC1 equiv (pnr45.tcl lines 502-509):
#   route_zrt_eco -open_net_driven true
#   route_zrt_detail -incremental true -initial_drc_from_input true
#   insert_zrt_redundant_vias
#   verify_zrt_route
#   route_zrt_detail -incremental true -initial_drc_from_input true
# ICC2 equiv from pnr90.tcl:
#   route_detail -incremental true
# ======================================================================
puts "INFO: Step 7d — Incremental ECO routing (DRC cleanup)..."
route_detail -incremental true
check_routes > ../report/route_detail_drc_pass2.rpt

# ======================================================================
# 11. Post-Route Optimization (Hold Fix)
# ======================================================================
# After routing, fix any remaining hold violations with inserted buffers.
# The router then re-routes the buffer connections (ECO route).
#
# ICC1 equiv (pnr45.tcl line 501):
#   psynopt -only_hold_time -congestion
# ICC2 equiv: refine_opt -hold (or clock_opt hold sub-step)
# ======================================================================
puts "INFO: Step 7e — Post-route hold optimization..."
refine_opt -hold

# ECO route after hold buffer insertions
route_detail -incremental true
check_routes > ../report/route_hold_fix_drc.rpt

# ======================================================================
# 12. Redundant Via Insertion
# ======================================================================
# Inserts additional vias on single-cut via connections to improve
# manufacturing yield (yield enhancement for multi-patterning).
#
# ICC1 equiv (pnr45.tcl line 507):
#   insert_zrt_redundant_vias
#   verify_zrt_route
#   route_zrt_detail -incremental true -initial_drc_from_input true
# ICC2 equiv from pnr90.tcl: add_redundant_vias
# ======================================================================
puts "INFO: Inserting redundant vias..."
add_redundant_vias

# Final DRC check after via insertion
route_detail -incremental true
check_routes > ../report/route_redundant_via_drc.rpt

# ======================================================================
# 13. Reconnect PG Nets After Routing
# ======================================================================
# ICC1 equiv (pnr45.tcl lines 511-514):
#   derive_pg_connection -power_net VDD -ground_net VSS ...
# ICC2: connect_pg_net
# ======================================================================
puts "INFO: Reconnecting PG nets..."
connect_pg_net -net VDD [get_pins -hierarchical "*/VDD"]
connect_pg_net -net VSS [get_pins -hierarchical "*/VSS"]

# ======================================================================
# 14. Reports
# ======================================================================
# ICC1 equiv (pnr45.tcl, various report commands):
#   verify_zrt_route
#   verify_lvs
#   report_timing
# ======================================================================
puts "INFO: Generating routing reports..."
file mkdir ../report
check_routes           > ../report/route_drc_final.rpt
check_lvs -max_error 0 > ../report/route_lvs_final.rpt
check_legality -verbose > ../report/route_legality.rpt
check_clock_trees       > ../report/route_clock_trees.rpt
report_congestion -nosplit > ../report/route_congestion.rpt
report_utilization      > ../report/route_utilization.rpt
report_qor              > ../report/route_qor.rpt
report_timing -delay_type max -max_paths 20 -nosplit > ../report/route_timing_setup.rpt
report_timing -delay_type min -max_paths 20 -nosplit > ../report/route_timing_hold.rpt

# ======================================================================
# 15. Write Routing Outputs
# ======================================================================
puts "INFO: Writing routing outputs..."
file mkdir ../output
write_def              ../output/${design}_route.def
write_verilog -include {all} ../output/${design}_route.v
write_parasitics -format spef -output ../output/${design}_route

# ======================================================================
# 16. Save Block
# ======================================================================
# ICC1 equiv (pnr45.tcl line 523):
#   save_mw_cel -as ${design}_6_routed
# ======================================================================
puts "INFO: Saving block as ${design}_route..."
save_block

puts "INFO: ================================================"
puts "INFO:  Routing Complete!"
puts "INFO:  Block saved: ${design}_route"
puts "INFO:  Next step: Step 8 — Timing Analysis"
puts "INFO:         and Step 9 — Finishing"
puts "INFO: ================================================"
