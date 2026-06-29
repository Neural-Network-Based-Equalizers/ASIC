########################################################################
# powerplan.tcl
# -----------------------------------------------------------------------
# Purpose : ICC2 Power Planning for neural_eq_top (45nm FreePDK45)
#           - Opens floorplan block from Step 3
#           - Creates VDD/VSS nets and connects standard cell PG pins
#           - Creates power ring (metal9/metal10)
#           - Creates power mesh (metal7/metal8 + metal6/metal5)
#           - Creates standard cell rails (metal1)
#           - Runs DRC/connectivity checks on PG network
#           - Saves as neural_eq_top_pp block
#
# Tool    : Synopsys IC Compiler II  (icc2_shell)
# Run     : cd ASIC/pnr/4_powerplan/run
#           icc2_shell -f ../script/powerplan.tcl | tee ../log/powerplan.log
#
# Prereq  : Step 3 (floorplan.tcl) must be complete.
#           Block neural_eq_top_fp must exist in the .dlib.
#
# ICC1 equiv file : pnr45.tcl  Section "3. POWER NETWORK"
# Author  : Auto-generated for neural_eq_top PnR flow
########################################################################
set_host_options -max_cores 4
puts "INFO: ================================================"
puts "INFO:  ICC2 Power Plan — neural_eq_top (45nm)"
puts "INFO: ================================================"

# ======================================================================
# 1. Variables
# ======================================================================
set design          "neural_eq_top"
set design_lib_path "../../2_design_library/output"
set DLIB            "${design_lib_path}/${design}.dlib"

# PG network parameters (verified from pnr45.tcl + PDK)
set ring_width   5        ; # µm — on metal9/metal10 (wide PG metals)
set ring_spacing 0.8      ; # µm
set ring_offset  0.8      ; # µm from core boundary
set mesh_width   2.5      ; # µm — for metal7/metal8 mesh
set mesh_pitch   30       ; # µm — strap pitch

# ======================================================================
# 2. Remove lock file & Open Block
# ======================================================================
sh rm -f ${DLIB}/${design}_fp/design.ndm.lock

# ICC1 equiv: open_mw_lib ./${design} ; open_mw_cel ${design}_2_fp
puts "INFO: Opening floorplan block..."
open_lib  $DLIB
open_block ${design}_fp

# ICC1 equiv: copy_mw_cel -from ${design}_2_fp -to ${design}_3_power
copy_block -from_block ${design}_fp -to_block ${design}_pp
current_block ${design}_pp

# ======================================================================
# 3. Remove Ignored Layers Before PG Planning
# ======================================================================
# During PG planning we need access to ALL layers (metal7-10 for PG).
# We restricted them to metal6 in the floorplan step.
# Re-enable them now; they will be re-restricted after PG is done.
#
# ICC1 equiv (pnr45.tcl line 200):
#   set_preroute_drc_strategy -max_layer metal6
# ICC2 equiv from pnr90.tcl:
#   remove_ignored_layers -all
# ======================================================================
puts "INFO: Removing ignored layer restrictions for PG planning..."
remove_ignored_layers -all

# ======================================================================
# 4. Create VDD and VSS Power/Ground Nets
# ======================================================================
# Declares VDD as a power net and VSS as a ground net in the design.
# These are logical net objects that will be driven by the PG network.
#
# ICC1 equiv (pnr45.tcl lines 128-131):
#   derive_pg_connection \
#     -power_net  VDD -ground_net VSS \
#     -power_pin  VDD -ground_pin  VSS
#
# In ICC2 this is split into two steps:
#   1. create_net declares the net type
#   2. connect_pg_net physically connects cell pins to those nets
# ======================================================================
puts "INFO: Creating VDD/VSS power and ground nets..."
create_net -power  VDD
create_net -ground VSS

# Connect hierarchically — all VDD/VSS pins in every cell + submodule
# ICC1 equiv: -power_pin VDD -ground_pin VSS in derive_pg_connection
connect_pg_net -net VDD [get_pins -hierarchical */VDD]
connect_pg_net -net VSS [get_pins -hierarchical */VSS]

# Enable auto-connect for any newly inserted cells (buffers, fillers, etc.)
set_app_option -name plan.pgroute.auto_connect_pg_net -value true

# ======================================================================
# 5. Power Ring (metal9 horizontal + metal10 vertical)
# ======================================================================
# The power ring runs around the core boundary, carrying VDD and VSS
# from the virtual pads to the mesh. This is the highest-level PG tier.
#
# Layer choice: metal9 (H) + metal10 (V) — widest metals in FreePDK45,
# min spacing 0.8µm, native width 0.8µm pitch 1.6µm (from tech LEF).
# We use 5µm wide straps for low IR drop.
#
# ICC1 equiv (pnr45.tcl lines 136-142):
#   set_fp_rail_constraints -set_ring -nets {VDD VSS} \
#     -horizontal_ring_layer {metal7 metal9} \
#     -vertical_ring_layer   {metal8 metal10} \
#     -ring_spacing 0.8 -ring_width 5 -ring_offset 0.8 \
#     -extend_strap core_ring
#   synthesize_fp_rail  -nets {VDD VSS} -synthesize_power_plan ...
#   commit_fp_rail
#
# ICC2: replace set_fp_rail_constraints + synthesize + commit with
#       create_pg_ring_pattern + set_pg_strategy + compile_pg
# ======================================================================
puts "INFO: Creating power ring (metal9 H + metal10 V)..."

# Create a region that expands just outside the core boundary
create_pg_region power_ring_region -core \
    -expand_by_edge "{{side: 1} {offset: $ring_offset}} \
                     {{side: 2} {offset: $ring_offset}} \
                     {{side: 3} {offset: $ring_offset}} \
                     {{side: 4} {offset: $ring_offset}}"

# Define the ring pattern: layer, width, spacing
create_pg_ring_pattern ring_pattern \
    -horizontal_layer  metal9  \
    -vertical_layer    metal10 \
    -horizontal_width  $ring_width    \
    -vertical_width    $ring_width    \
    -horizontal_spacing $ring_spacing \
    -vertical_spacing   $ring_spacing

# Assign the pattern to VDD/VSS nets as a strategy
set_pg_strategy core_ring \
    -pg_regions { power_ring_region } \
    -pattern    {{ name: ring_pattern } { nets: "VDD VSS" }}

# Implement (compile) the ring
compile_pg -strategies core_ring

# Check ring
check_pg_drc         > ../report/pg_ring_drc.rpt
check_pg_connectivity > ../report/pg_ring_connectivity.rpt

# ======================================================================
# 6. Power Mesh — Upper Tier (metal7 H + metal8 V)
# ======================================================================
# The mesh distributes power from the ring across the core area.
# metal7 (H) + metal8 (V): 0.4µm native width, 0.8µm pitch.
# We use 2.5µm wide straps at 30µm pitch.
#
# ICC1 equiv (pnr45.tcl lines 146-150):
#   set_fp_rail_constraints -add_layer -layer metal8 -direction vertical   -max_strap 128 -min_strap 20 -min_width 2.5 -spacing minimum
#   set_fp_rail_constraints -add_layer -layer metal7 -direction horizontal -max_strap 128 -min_strap 20 -min_width 2.5 -spacing minimum
# ======================================================================
puts "INFO: Creating power mesh upper tier (metal7 H + metal8 V)..."

create_pg_mesh_pattern mesh_upper \
    -layers {
        { {horizontal_layer: metal7} {width: 2.5} {pitch: 30} {spacing: interleaving} {offset: 2} {trim: true} }
        { {vertical_layer:   metal8} {width: 2.5} {pitch: 30} {spacing: interleaving} {offset: 2} {trim: true} }
    }

set_pg_strategy mesh_upper_strategy \
    -core \
    -pattern   {{ pattern: mesh_upper } { nets: "VDD VSS" }} \
    -extension {{ stop: outermost_ring }}

compile_pg -strategies mesh_upper_strategy

check_pg_drc          > ../report/pg_mesh_upper_drc.rpt
check_pg_connectivity > ../report/pg_mesh_upper_conn.rpt

# ======================================================================
# 7. Power Mesh — Lower Tier (metal5 H + metal6 V)
# ======================================================================
# Second mesh tier on lower metals to improve local power delivery.
# metal5 (H) + metal6 (V): 0.14µm native width, 0.28µm pitch.
# We use 1.5µm straps for this tier.
# Note: metal6 is the max signal layer, so mesh straps here reduce
# routing tracks. Adjust density if congestion is an issue.
#
# ICC1 equiv (pnr45.tcl lines 150-156):
#   set_fp_rail_constraints -add_layer -layer metal6 -direction vertical   -min_width 2.5 ...
#   set_fp_rail_constraints -add_layer -layer metal5 -direction horizontal -min_width 2.5 ...
# ======================================================================
puts "INFO: Creating power mesh lower tier (metal5 H + metal6 V)..."

create_pg_mesh_pattern mesh_lower \
    -layers {
        { {horizontal_layer: metal5} {width: 1.5} {pitch: 30} {spacing: interleaving} {offset: 2} {trim: true} }
        { {vertical_layer:   metal6} {width: 1.5} {pitch: 30} {spacing: interleaving} {offset: 2} {trim: true} }
    }

set_pg_strategy mesh_lower_strategy \
    -core \
    -pattern   {{ pattern: mesh_lower } { nets: "VDD VSS" }} \
    -extension {{ stop: outermost_ring }}

compile_pg -strategies mesh_lower_strategy

check_pg_drc          > ../report/pg_mesh_lower_drc.rpt
check_pg_connectivity > ../report/pg_mesh_lower_conn.rpt

# ======================================================================
# 8. Standard Cell Power Rails (metal1 horizontal)
# ======================================================================
# metal1 rails run horizontally through every standard cell row,
# delivering VDD and VSS to the cell power pins directly.
# Rail width = 0.16µm matches the cell height / rail tracks in Nangate.
#
# ICC1 equiv (pnr45.tcl lines 201):
#   preroute_standard_cells -fill_empty_rows -remove_floating_pieces
#
# ICC2: This is now a pattern + strategy + compile_pg flow.
# ======================================================================
puts "INFO: Creating standard cell power rails (metal1)..."

create_pg_std_cell_conn_pattern std_cell_rail \
    -layers    metal1 \
    -rail_width 0.16

set_pg_strategy rails_M1 \
    -core \
    -pattern {{ name: std_cell_rail } { nets: "VDD VSS" }}

compile_pg -strategies rails_M1

# ======================================================================
# 9. Full PG Network DRC + Connectivity Checks
# ======================================================================
# ICC1 equiv (pnr45.tcl line 209):
#   analyze_fp_rail -nets {VDD VSS} -power_budget 500 -voltage_supply 1.1
# ICC2: use check_pg_drc + check_pg_connectivity (separate commands)
# ======================================================================
puts "INFO: Running final PG DRC and connectivity checks..."
check_pg_drc           > ../report/pg_drc_final.rpt
check_pg_connectivity  > ../report/pg_connectivity_final.rpt
check_pg_missing_vias  > ../report/pg_missing_vias.rpt
analyze_power_plan -report_track_utilization_only > ../report/pg_track_utilization.rpt

# ======================================================================
# 10. Update Placement After PG (incremental)
# ======================================================================
# After inserting PG straps, some placed cells may overlap.
# Refresh placement to account for obstructions from metal straps.
#
# ICC1 equiv (pnr45.tcl line 213):
#   create_fp_placement -incremental all
# ICC2: create_placement with -incremental flag
# ======================================================================
puts "INFO: Refreshing placement after PG network insertion..."
create_placement -effort medium -incremental

# ======================================================================
# 11. Reports
# ======================================================================
puts "INFO: Generating power plan reports..."
report_utilization    > ../report/pp_utilization.rpt
report_qor            > ../report/pp_qor.rpt
report_timing -max_paths 5 -nosplit > ../report/pp_timing.rpt

# ======================================================================
# 12. Write Intermediate Outputs
# ======================================================================
file mkdir ../output
write_def      ../output/${design}_pp.def
write_verilog  -include {all} ../output/${design}_pp.v
write_sdc      -output ../output/${design}_pp.sdc

# ======================================================================
# 13. Save Block
# ======================================================================
# ICC1 equiv (pnr45.tcl line 224):
#   save_mw_cel -as ${design}_3_power
# ======================================================================
puts "INFO: Saving block as ${design}_pp..."
save_block

puts "INFO: ================================================"
puts "INFO:  Power Plan Complete!"
puts "INFO:  Block saved: ${design}_pp"
puts "INFO:  Next step: Step 5 — Placement"
puts "INFO: ================================================"

exit


