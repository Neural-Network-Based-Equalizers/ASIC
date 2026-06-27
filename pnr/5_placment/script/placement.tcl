########################################################################
# placement.tcl
# -----------------------------------------------------------------------
# Purpose : ICC2 Placement step for neural_eq_top (45nm FreePDK45)
#           - Opens power plan block from Step 4
#           - Sets placement app options
#           - Adds spare cells + tie cells (Nangate 45nm verified names)
#           - Detailed placement (coarse + legalized)
#           - Optional placement optimization (place_opt)
#           - Reconnects PG nets after cell insertion
#           - Saves as neural_eq_top_pl block
#
# Tool    : Synopsys IC Compiler II  (icc2_shell)
# Run     : cd ASIC/pnr/5_placment/run
#           icc2_shell -f ../script/placement.tcl | tee ../log/placement.log
#
# Prereq  : Step 4 (powerplan.tcl) must be complete.
#           Block neural_eq_top_pp must exist in the .dlib.
#
# ICC1 equiv file : pnr45.tcl  Section "4. Placement"
# Author  : Auto-generated for neural_eq_top PnR flow
########################################################################

puts "INFO: ================================================"
puts "INFO:  ICC2 Placement — neural_eq_top (45nm)"
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
sh rm -f ${DLIB}/${design}_pp/design.ndm.lock

# ICC1 equiv: open_mw_lib ./${design} ; open_mw_cel ${design}_3_power
puts "INFO: Opening power plan block..."
open_lib  $DLIB
open_block ${design}_pp

# ICC1 equiv: save_mw_cel -as ${design}_4_placed (done at end)
# copy_mw_cel is implicit in ICC1 — ICC2 requires explicit copy_block
copy_block -from_block ${design}_pp -to_block ${design}_pl
current_block ${design}_pl

# ======================================================================
# 3. Pre-Placement Checks
# ======================================================================
# Verifies the design is in a valid state before placement starts.
# Checks connectivity, power connections, and design rule readiness.
#
# ICC1 equiv (pnr45.tcl lines 234-235):
#   check_physical_design -stage pre_place_opt
#   check_physical_constraints
# ======================================================================
puts "INFO: Running pre-placement checks..."
check_design -checks pre_placement_stage

# ======================================================================
# 4. Placement App Options
# ======================================================================
# Controls how the placer behaves: fanout limits, instance naming, etc.
#
# ICC1 equiv: NOT in pnr45.tcl — ICC1 used set_app_var for similar globals
# ICC2 equiv from pnr90.tcl:
#   set_app_options -name opt.common.user_instance_name_prefix ...
#   set_app_options -name opt.common.max_fanout ...
# ======================================================================
puts "INFO: Setting placement options..."
set_app_options -name opt.common.user_instance_name_prefix -value "PLACE_"
set_app_options -name opt.common.max_fanout   -value 16
set_app_options -name opt.tie_cell.max_fanout -value 4

report_app_options > ../report/placement_options.rpt

# ======================================================================
# 5. Spare Cells
# ======================================================================
# Spare cells are unused logic cells pre-placed in the design for
# post-silicon ECO (engineering change order) without re-spinning masks.
#
# Verified Nangate cell names from LEF directory: NAND2_X4, NOR2_X4
#
# ICC1 equiv (pnr45.tcl lines 444-450):
#   insert_spare_cells \
#     -lib_cell {NOR2_X4 NAND2_X4} \
#     -num_instances 20 \
#     -cell_name SPARE_PREFIX_NAME \
#     -tie
#   set_dont_touch [all_spare_cells] true
#   set_attribute [all_spare_cells] is_soft_fixed true
#
# ICC2 equiv from pnr90.tcl: add_spare_cells / spread_spare_cells
# ======================================================================
puts "INFO: Adding spare cells..."
add_spare_cells \
    -cell_name   "SpareCell" \
    -lib_cell    "NangateOpenCellLibrary/NAND2_X4 NangateOpenCellLibrary/NOR2_X4" \
    -num_instances 20

# Spread spare cells randomly for good coverage
spread_spare_cells \
    -cells [get_cells SpareCell*] \
    -random_distribution

# Legalize spare cell locations
place_eco_cells \
    -cells       [get_cells SpareCell*] \
    -legalize_only

# Lock spare cells so placement optimization does not move them
set spare_cells [get_cells SpareCell*]
set_dont_touch $spare_cells
set_fixed_objects $spare_cells

# ======================================================================
# 6. Tie Cells
# ======================================================================
# Tie cells drive constant 0 or 1 values to pins that require a
# fixed logic level (e.g., scan enable, power-down pins).
# Using tie cells instead of connecting to VDD/VSS directly prevents
# antenna violations during routing.
#
# Verified cell names from LEF directory: LOGIC0_X1, LOGIC1_X1
#
# ICC1 equiv (pnr45.tcl lines 307-318):
#   set tie_pins [get_pins -all -filter "constant_value == 0 ..."]
#   derive_pg_connection -tie
#   connect_tie_cells -objects $tie_pins \
#     -tie_low_lib_cell  */LOGIC0_X1 \
#     -tie_high_lib_cell */LOGIC1_X1
#
# ICC2 equiv from pnr90.tcl: add_tie_cells command
# ======================================================================
puts "INFO: Adding tie cells..."

# Enable tie cells for use (they are often excluded by default)
set_attribute [get_lib_cells NangateOpenCellLibrary/LOGIC1_X1] dont_use false
set_attribute [get_lib_cells NangateOpenCellLibrary/LOGIC1_X1] dont_touch false
set_lib_cell_purpose -include all {NangateOpenCellLibrary/LOGIC1_X1}

set_attribute [get_lib_cells NangateOpenCellLibrary/LOGIC0_X1] dont_use false
set_attribute [get_lib_cells NangateOpenCellLibrary/LOGIC0_X1] dont_touch false
set_lib_cell_purpose -include all {NangateOpenCellLibrary/LOGIC0_X1}

# Insert tie cells on the spare cells (or all constant-tied pins)
add_tie_cells \
    -objects          $spare_cells \
    -tie_low_lib_cells  NangateOpenCellLibrary/LOGIC0_X1 \
    -tie_high_lib_cells NangateOpenCellLibrary/LOGIC1_X1 \
    -legalize

# ======================================================================
# 7. Reconnect PG After New Cell Insertions
# ======================================================================
# After adding spare + tie cells, their PG pins must be connected
# to the VDD/VSS power network.
#
# ICC1 equiv (pnr45.tcl lines 301-311):
#   derive_pg_connection -power_net VDD -ground_net VSS -power_pin VDD -ground_pin VSS
# ICC2: connect_pg_net
# ======================================================================
puts "INFO: Reconnecting PG nets after cell insertions..."
connect_pg_net -net VDD [get_pins -hierarchical "*/VDD"]
connect_pg_net -net VSS [get_pins -hierarchical "*/VSS"]
check_pg_drc > ../report/drc_after_spare_cells.rpt

# ======================================================================
# 8. Detailed Placement
# ======================================================================
# Performs coarse placement (approximate cell locations) followed by
# legalization (resolving overlaps, snapping to rows).
#
# -timing_driven              : Minimize timing violations during placement
# -buffering_aware_timing_driven : Models future buffer insertions for
#                                  more realistic timing estimates
# -congestion                 : Considers routing congestion during placement
# -congestion_effort medium   : Medium effort (high increases runtime)
# -incremental                : Keep prior approximate placement as starting point
#
# ICC1 equiv (pnr45.tcl lines 263):
#   place_opt
#   psynopt
# ICC2 equiv from pnr90.tcl:
#   create_placement -effort high -timing_driven -buffering_aware_timing_driven -congestion -incremental
#   legalize_placement -incremental
# ======================================================================
puts "INFO: Running detailed placement..."
create_placement \
    -effort                        high \
    -timing_driven \
    -buffering_aware_timing_driven \
    -congestion \
    -congestion_effort             medium \
    -incremental

# Legalize: moves each cell to the nearest legal location (row-aligned, no overlap)
legalize_placement -incremental
check_pg_drc > ../report/drc_after_legalize.rpt

# ======================================================================
# 9. Placement Optimization (Optional — Pre-CTS)
# ======================================================================
# Performs incremental timing-driven optimization on the placement.
# Focuses on fixing DRC and timing violations before CTS.
# Uncomment if timing or congestion issues are found after placement.
#
# ICC1 equiv (pnr45.tcl lines 284):
#   psynopt
# ICC2 equiv:
#   place_opt  : Full placement optimization (initial_place, drc, opto, final)
#   refine_opt : Incremental post-placement optimization
# ======================================================================
# place_opt
# refine_opt

# ======================================================================
# 10. Placement Legality Check
# ======================================================================
# ICC1 equiv (pnr45.tcl line 294):
#   check_legality
# ICC2: same command name
# ======================================================================
puts "INFO: Checking placement legality..."
check_legality -verbose > ../report/legality.rpt

# ======================================================================
# 11. Reports
# ======================================================================
# ICC1 equiv (pnr45.tcl lines 295-298, commented):
#   report_design_physical -utilization
# ======================================================================
puts "INFO: Generating placement reports..."
report_utilization  > ../report/pl_utilization.rpt
check_routability   > ../report/pl_routeability.rpt
check_pg_drc        > ../report/pl_pg_drc_final.rpt
report_design       > ../report/pl_design.rpt
report_cell         > ../report/pl_cells.rpt
report_qor          > ../report/pl_qor.rpt
report_timing -max_paths 10 -nosplit > ../report/pl_timing.rpt
report_ports [all_inputs]  > ../report/input_ports.rpt
report_ports [all_outputs] > ../report/output_ports.rpt

# ======================================================================
# 12. Write Intermediate Outputs
# ======================================================================
puts "INFO: Writing placed design outputs..."
file mkdir ../output
write_def     ../output/${design}_pl.def
write_verilog -include {all} ../output/${design}_pl.v
write_sdc     -output ../output/${design}_pl.sdc

# ======================================================================
# 13. Save Block
# ======================================================================
# ICC1 equiv (pnr45.tcl line 325):
#   save_mw_cel -as ${design}_4_placed
# ======================================================================
puts "INFO: Saving block as ${design}_pl..."
save_block

puts "INFO: ================================================"
puts "INFO:  Placement Complete!"
puts "INFO:  Block saved: ${design}_pl"
puts "INFO:  Next step: Step 6 — CTS"
puts "INFO: ================================================"
