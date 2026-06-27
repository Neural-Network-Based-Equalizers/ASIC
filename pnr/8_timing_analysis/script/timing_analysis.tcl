########################################################################
# timing_analysis.tcl
# -----------------------------------------------------------------------
# Purpose : ICC2 Post-Route Timing Analysis for neural_eq_top (45nm)
#           - Opens routed block from Step 7
#           - Runs comprehensive setup + hold timing reports
#           - Reports QoR, constraints, congestion, utilization
#           - Identifies critical paths and violating endpoints
#           - No modifications to the design — read-only analysis
#
# Tool    : Synopsys IC Compiler II  (icc2_shell)
# Run     : cd ASIC/pnr/8_timing_analysis/run
#           icc2_shell -f ../script/timing_analysis.tcl | tee ../log/timing.log
#
# Prereq  : Step 7 (routing.tcl) must be complete.
#           Block neural_eq_top_route must exist in the .dlib.
#
# ICC1 equiv file : pnr45.tcl — timing reports are scattered throughout.
#                  This step consolidates them all post-route.
# Author  : Auto-generated for neural_eq_top PnR flow
########################################################################

puts "INFO: ================================================"
puts "INFO:  ICC2 Timing Analysis — neural_eq_top (45nm)"
puts "INFO: ================================================"

# ======================================================================
# 1. Variables
# ======================================================================
set design          "neural_eq_top"
set design_lib_path "../../2_design_library/output"
set DLIB            "${design_lib_path}/${design}.dlib"

# ======================================================================
# 2. Open Routed Block (Read-Only Analysis)
# ======================================================================
# ICC1 equiv: open_mw_lib ./${design} ; open_mw_cel ${design}_6_routed
# No copy_block needed — this is a read-only analysis step.
# ======================================================================
sh rm -f ${DLIB}/${design}_route/design.ndm.lock

puts "INFO: Opening routed block for analysis..."
open_lib   $DLIB
open_block ${design}_route

# ======================================================================
# 3. Extract RC Parasitics
# ======================================================================
# Extracts resistance/capacitance from the routed metal geometries.
# This gives the most accurate timing picture after routing.
# Uses the TLU+ models loaded during design setup.
#
# ICC1 equiv (pnr45.tcl line 577):
#   extract_rc
# ICC2: extract_parasitics (if needed — usually done automatically)
# ======================================================================
puts "INFO: Extracting RC parasitics for accurate timing..."
extract_parasitics -effort high

# ======================================================================
# 4. Setup Timing Reports (max delay / setup check)
# ======================================================================
# Reports the worst setup slack paths. Positive slack = timing met.
# Negative slack = timing violation (setup failure).
#
# ICC1 equiv (pnr45.tcl comments, lines 91-95):
#   report_timing -nosplit
#   report_constraint -all_violators -nosplit -max_delay
# ======================================================================
puts "INFO: Generating setup timing reports..."
file mkdir ../report

report_timing \
    -delay_type max \
    -max_paths  20 \
    -path_type  full \
    -nosplit > ../report/timing_setup_top20.rpt

report_timing \
    -delay_type max \
    -max_paths  50 \
    -nosplit > ../report/timing_setup_top50.rpt

report_timing \
    -delay_type max \
    -path_type  full_clock_expanded \
    -max_paths  5 \
    -nosplit > ../report/timing_setup_full_clock.rpt

# ======================================================================
# 5. Hold Timing Reports (min delay / hold check)
# ======================================================================
# Reports the worst hold slack paths. Negative hold slack = hold violation.
# Hold violations cause double-clocking (functional failure).
#
# ICC1 equiv (pnr45.tcl line 407):
#   report_timing -delay_type min
#   report_constraint -all_violators -nosplit -min_delay
# ======================================================================
puts "INFO: Generating hold timing reports..."

report_timing \
    -delay_type min \
    -max_paths  20 \
    -path_type  full \
    -nosplit > ../report/timing_hold_top20.rpt

report_timing \
    -delay_type min \
    -max_paths  50 \
    -nosplit > ../report/timing_hold_top50.rpt

# ======================================================================
# 6. Constraint Violations Report
# ======================================================================
# Lists all paths that violate timing constraints (both setup and hold).
# If this is empty, timing is clean.
#
# ICC1 equiv (pnr45.tcl):
#   report_constraint -all_violators -nosplit
# ICC2: report_constraints (same concept)
# ======================================================================
puts "INFO: Reporting all constraint violations..."
report_constraints -all_violators -nosplit > ../report/timing_violations.rpt

# ======================================================================
# 7. QoR (Quality of Results) Report
# ======================================================================
# The QoR summary is the single best indicator of overall design quality.
# Shows WNS (Worst Negative Slack), TNS (Total Negative Slack),
# area, power, and DRC counts.
#
# ICC1 equiv: report_qor (same command)
# ======================================================================
puts "INFO: Generating QoR report..."
report_qor > ../report/timing_qor.rpt

# ======================================================================
# 8. Clock Reports
# ======================================================================
# ICC1 equiv (pnr45.tcl lines 403-408):
#   report_clock_tree -summary
#   report_clock_timing -type summary
# ======================================================================
puts "INFO: Generating clock reports..."
report_clocks                              > ../report/timing_clocks.rpt
report_clock_qor -type summary             > ../report/timing_clock_qor.rpt
report_clock_qor -type structure           > ../report/timing_clock_structure.rpt

# ======================================================================
# 9. Design Physical Reports
# ======================================================================
puts "INFO: Generating design physical reports..."
report_utilization                         > ../report/timing_utilization.rpt
report_design                              > ../report/timing_design.rpt
report_cell                                > ../report/timing_cells.rpt

# ======================================================================
# 10. Congestion Report
# ======================================================================
puts "INFO: Generating congestion report..."
report_congestion -nosplit                 > ../report/timing_congestion.rpt

# ======================================================================
# 11. Route DRC Summary
# ======================================================================
# Confirms the routed design is DRC-clean before finishing.
# ICC1 equiv: verify_zrt_route (at end of routing section)
# ======================================================================
puts "INFO: Running route DRC check..."
check_routes                               > ../report/timing_route_drc.rpt
check_lvs -max_error 0                     > ../report/timing_lvs.rpt

# ======================================================================
# 12. Summary to Screen
# ======================================================================
puts "INFO: ================================================"
puts "INFO: === TIMING SUMMARY ==="
report_qor -summary
puts "INFO: ================================================"
puts "INFO:  Timing Analysis Complete!"
puts "INFO:  All reports in: ../report/"
puts "INFO:  Next step: Step 9 — Finishing + GDS Output"
puts "INFO: ================================================"
