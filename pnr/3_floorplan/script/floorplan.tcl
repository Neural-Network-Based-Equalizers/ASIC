########################################################################
# floorplan.tcl
# -----------------------------------------------------------------------
# Purpose : ICC2 Floorplan step for neural_eq_top (45nm FreePDK45)
#           - Opens design from Step 2 (design_setup)
#           - Sets routing layer directions & ignored layers
#           - Creates floorplan (core area, utilization, offsets)
#           - Places I/O pins
#           - Inserts tap cells
#           - Virtual flat placement (initial cell placement estimate)
#           - Saves as neural_eq_top_fp block
#
# Tool    : Synopsys IC Compiler II  (icc2_shell)
# Run     : cd ASIC/pnr/3_floorplan/run
#           icc2_shell -f ../script/floorplan.tcl | tee ../log/floorplan.log
#
# Prereq  : Step 2 (design_setup.tcl) must be complete.
#           Block neural_eq_top_setup must exist in:
#           ../../2_design_library/output/neural_eq_top.dlib
#
# ICC1 equiv file : pnr45.tcl  Section "2. Floorplan"
# Author  : Auto-generated for neural_eq_top PnR flow
########################################################################

puts "INFO: ================================================"
puts "INFO:  ICC2 Floorplan — neural_eq_top (45nm)"
puts "INFO: ================================================"

# ======================================================================
# 1. Variables
# ======================================================================
set design          "neural_eq_top"
set design_lib_path "../../2_design_library/output"
set DLIB            "${design_lib_path}/${design}.dlib"

# ======================================================================
# 2. Remove lock file if left from a previous crashed session
# ======================================================================
# ICC1 equiv: (no equivalent — ICC1 lock files managed differently)
sh rm -f ${DLIB}/${design}_setup/design.ndm.lock

# ======================================================================
# 3. Open Design Library & Copy Block
# ======================================================================
# ICC1 equiv:
#   open_mw_lib ./${design}
#   open_mw_cel ${design}

puts "INFO: Opening design library..."
open_lib $DLIB

# copy_block creates a new named snapshot from the setup block
# ICC1 equiv: copy_mw_cel -from ${design} -to ${design}_fp  (or just save_mw_cel -as)
copy_block -from_block ${design}_setup -to_block ${design}_fp
current_block ${design}_fp

# ======================================================================
# 4. Set Metal Layer Routing Directions
# ======================================================================
# ICC2 requires explicit direction attributes. In ICC1 these were defined
# in the technology file (.tf) and applied automatically.
#
# ICC1 equiv: NOT in pnr45.tcl — ICC1 read directions from the .tf file.
#             In ICC2 with NDM, directions must be set explicitly.
#
# Verified from NangateOpenCellLibrary.tech.lef:
#   metal1=H, metal2=V, metal3=H, metal4=V, metal5=H
#   metal6=V, metal7=H, metal8=V, metal9=H, metal10=V
# ======================================================================
puts "INFO: Setting metal layer routing directions..."
set_attribute [get_layers {metal1 metal3 metal5 metal7 metal9}]  routing_direction horizontal
set_attribute [get_layers {metal2 metal4 metal6 metal8 metal10}] routing_direction vertical

# ======================================================================
# 5. Set Ignored Layers (Signal Routing Limit)
# ======================================================================
# Reserves metal7–metal10 for the power grid (PG ring + mesh).
# Signal routes are confined to metal1–metal6.
#
# ICC1 equiv (pnr45.tcl line 61):
#   report_ignored_layers
#   remove_ignored_layers -all
#   set_ignored_layers -max_routing_layer metal6
#
# ICC2 syntax is the same command name, same options.
# ======================================================================
puts "INFO: Setting ignored layers (max signal layer = metal6)..."
report_ignored_layers
set_ignored_layers -max_routing_layer metal6

# ======================================================================
# 6. Set Site Definition (Standard Cell Placement Grid)
# ======================================================================
# Tells ICC2 which site template to use for cell placement rows.
# Verified from NangateOpenCellLibrary.tech.lef:
#   SITE FreePDK45_38x28_10R_NP_162NW_34O  SIZE 0.19 BY 1.4
#
# ICC1 equiv: NOT in pnr45.tcl — ICC1 picked the site automatically
#             from the Milkyway tech file.
# ======================================================================
set Name_unit [get_site_defs]
set_attribute [get_site_defs $Name_unit] is_default true
set_attribute [get_site_defs $Name_unit] symmetry {Y}

# ======================================================================
# 7. Initialize Floorplan (Core Area)
# ======================================================================
# Creates the chip boundary and core area.
#   -core_utilization : Cell area / total core area ratio.
#                       0.25 = 25% utilization (same as ICC1 script)
#   -core_offset      : Space between chip boundary and core boundary
#                       (I/O margins). 12.4µm matches pnr45.tcl values.
#   -shape R          : Rectangular floorplan
#   -flip_first_row   : First standard cell row is flipped
#
# ICC1 equiv (pnr45.tcl lines 51-53):
#   create_floorplan -core_utilization 0.25 \
#     -start_first_row -flip_first_row \
#     -left_io2core 12.4 -bottom_io2core 12.4 \
#     -right_io2core 12.4 -top_io2core 12.4
# ======================================================================
puts "INFO: Initializing floorplan (25% utilization, 12.4µm margins)..."
initialize_floorplan \
    -core_utilization 0.25 \
    -core_offset      {12.4 12.4 12.4 12.4} \
    -shape            R \
    -flip_first_row   false

# ======================================================================
# 8. Place I/O Pins
# ======================================================================
# Distributes I/O ports evenly around the chip boundary.
# For a proof-of-concept, automatic placement is sufficient.
# For a real design, you would use set_block_pin_constraints first
# to control which layers and sides each port group goes on.
#
# ICC1 equiv: NOT in pnr45.tcl — ICC1 used the GUI or
#             place_fp_port interactively.
# ICC2 equiv from pnr90.tcl:
#   place_pins -ports [get_ports *]
# ======================================================================
puts "INFO: Placing I/O pins..."
place_pins -ports [get_ports *]

# ======================================================================
# 9. Create Placement Blockages (Optional / Proof-of-Concept)
# ======================================================================
# Uncomment and adjust coordinates if you need to reserve regions
# (e.g., for macros or analog blocks).
#
# ICC1 equiv (pnr45.tcl lines 104-114, commented):
#   create_bounds -name "temp" -coordinate {55 0 270 270} datamem
# ICC2 equiv from pnr90.tcl:
#   create_placement_blockage -boundary {{x1 y1} {x2 y2}} -type hard
# ======================================================================
# create_placement_blockage -boundary {{50 50} {100 100}} -name BLK1 -type hard
# create_placement_blockage -boundary {{100 100} {150 150}} -name BLK2 -type soft

# ======================================================================
# 10. Insert Tap Cells
# ======================================================================
# Tap cells connect the well to the power rail, preventing latch-up.
# Must be placed periodically (every 25-30µm row distance).
#
# Verified cell name from TAP.lef: MACRO TAP (i.e. NangateOpenCellLibrary/TAP)
#
# ICC1 equiv (pnr45.tcl lines 220-222):
#   add_tap_cell_array -master TAP \
#     -distance 30 \
#     -pattern stagger_every_other_row
#
# ICC2 equiv: create_tap_cells (different command name, same concept)
# ======================================================================
puts "INFO: Inserting tap cells..."
create_tap_cells \
    -lib_cell NangateOpenCellLibrary/TAP \
    -distance 25 \
    -pattern  every_other_row

# ======================================================================
# 11. Initial Virtual Flat Placement
# ======================================================================
# Generates an approximate placement of cells for congestion/timing
# estimation at the floorplan stage. Not a final placement.
#
# ICC1 equiv (pnr45.tcl line 213):
#   create_fp_placement -incremental all
# ICC2 equiv from pnr90.tcl:
#   create_placement -effort high -timing_driven ...
# ======================================================================
puts "INFO: Running initial virtual placement for assessment..."
create_placement \
    -effort                      medium \
    -timing_driven \
    -buffering_aware_timing_driven \
    -congestion

# ======================================================================
# 12. Floorplan Assessment Reports
# ======================================================================
# ICC1 equiv (pnr45.tcl lines 83-96, commented as guidelines):
#   route_fp_proto -congestion_map_only
#   extract_rc
#   report_timing -nosplit
#   report_constraint -all_violators -nosplit
# ======================================================================
puts "INFO: Generating floorplan reports..."
file mkdir ../report
report_utilization       > ../report/fp_utilization.rpt
report_design            > ../report/fp_design.rpt
report_qor               > ../report/fp_qor.rpt
report_timing -max_paths 5 -nosplit > ../report/fp_timing.rpt
report_ignored_layers    > ../report/fp_ignored_layers.rpt

# ======================================================================
# 13. Write Intermediate Outputs
# ======================================================================
puts "INFO: Writing DEF and Verilog checkpoints..."
file mkdir ../output
write_def     ../output/${design}_fp.def
write_verilog -include {all} ../output/${design}_fp.v
write_sdc -output ../output/${design}_fp.sdc

# ======================================================================
# 14. Save Block
# ======================================================================
# Creates a named snapshot inside the .dlib for the next stage to open.
#
# ICC1 equiv (pnr45.tcl line 119):
#   save_mw_cel -as ${design}_2_fp
# ======================================================================
puts "INFO: Saving block as ${design}_fp..."
save_block

puts "INFO: ================================================"
puts "INFO:  Floorplan Complete!"
puts "INFO:  Block saved: ${design}_fp"
puts "INFO:  Next step: Step 4 — Power Plan"
puts "INFO: ================================================"
