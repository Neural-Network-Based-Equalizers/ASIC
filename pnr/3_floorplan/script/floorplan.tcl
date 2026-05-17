# ============================================================ #
# ================== Floorplan Script ======================== #
# ============================================================ #
# Project  : Neural Network Equalizer
# Top Cell : neural_eq_top
# Tool     : IC Compiler II (icc2_shell)
# Process  : SAED 90nm
# Usage    : icc2_shell -f ./3_floorplan/script/floorplan.tcl
#
# Design hierarchy:
#   neural_eq_top
#     |- u_input_window  (input_window_ctrl)   small ctrl logic
#     |- u_layer1        (layer1_compute)       32 MACs, ROM 128x48b
#     |- u_layer2        (layer2_compute)       32 MACs, ROM 2x192x48b  <- heaviest
#     |- u_layer3        (layer3_compute)        2 MACs, ROM 2x12x48b   small
#
# Ports:
#   Inputs  : clk, rst_n, valid_in, in_I[15:0], in_Q[15:0]    (37 bits)
#   Outputs : out_I[15:0], out_Q[15:0], valid_out               (33 bits)
#
# Clock : 10 ns (100 MHz)   critical path = 16x16 MAC chain
# ============================================================ #

# ============================================================ #
# ==================== Variables ============================= #
# ============================================================ #
set DESIGN_NAME    "neural_eq_top"
set DLIB_NAME      "./2_design_library/neural_eq.dlib"
set IN_BLOCK       "${DESIGN_NAME}_init"
set OUT_BLOCK      "${DESIGN_NAME}_fp"

set REPORT_DIR     "./3_floorplan/report"
set OUTPUT_DIR     "./3_floorplan/output"

file mkdir $REPORT_DIR
file mkdir $OUTPUT_DIR

# ============================================================ #
# ==================== Open Design =========================== #
# ============================================================ #
# Remove any stale lock from a previous interrupted session
set lock_file "${DLIB_NAME}/${IN_BLOCK}/design.ndm.lock"
if {[file exists $lock_file]} {
    sh rm -f $lock_file
    puts "INFO: Removed stale lock file."
}

open_lib  $DLIB_NAME
open_block ${IN_BLOCK}.design

# Copy into a fresh floorplan block so the init block is preserved
copy_block \
    -from_block ${DLIB_NAME}:${IN_BLOCK}.design \
    -to_block   $OUT_BLOCK

current_block ${OUT_BLOCK}.design

# ============================================================ #
# =================== Routing Layer Setup ==================== #
# ============================================================ #
# SAED 90nm 1P9M stack:
#   Vertical   : M1 M3 M5 M7 M9
#   Horizontal : M2 M4 M6 M8
# Cap M8 as the max routing layer — keep M9 for power straps only.

set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction vertical
set_attribute [get_layers {M2 M4 M6 M8}]    routing_direction horizontal

# Track offsets (SAED 90nm minimum pitch discipline)
set_attribute [get_layers M1] track_offset 0.03
set_attribute [get_layers M2] track_offset 0.04

# Ignore M9 for signal routing; use only M1-M8
set_ignored_layers -max_routing_layer M8

# ============================================================ #
# =================== Site Definition ======================= #
# ============================================================ #
set site_name [get_site_defs]
set_attribute [get_site_defs $site_name] is_default true
set_attribute [get_site_defs $site_name] symmetry {Y}

# ============================================================ #
# =================== Initialize Floorplan ================== #
# ============================================================ #
# neural_eq_top is a compute-heavy NN datapath.
# Layer2 alone has 32 dual-path MACs with 2 x 192-entry ROMs,
# so we need enough area to avoid congestion.
#
# Utilization 0.55 gives comfortable room for:
#   - 32+32+2 MAC accumulators (40-bit registers)
#   - ROM arrays mapped to standard cells or SRAM macros
#   - Clock tree buffers for a tight 10ns path
#
# Core offset 60um on all sides for power rings + IO buffer space.
# Aspect ratio 1:1 (square) — balanced routing for the
# I->L1->L2->L3 pipeline which has similar X and Y data flow.

initialize_floorplan \
    -core_utilization  0.55 \
    -shape             R    \
    -orientation       N    \
    -core_offset       {60 60 60 60} \
    -flip_first_row    false \
    -side_ratio        {1 1}

# ============================================================ #
# ==================== Pin Placement ========================= #
# ============================================================ #
# Pin assignment rationale:
#   LEFT  side (side 1)  : all inputs except clock/reset
#                          in_I[15:0], in_Q[15:0], valid_in
#   RIGHT side (side 3)  : all outputs
#                          out_I[15:0], out_Q[15:0], valid_out
#   BOTTOM side (side 2) : clk  (nearest to clock entry point)
#   TOP    side (side 4) : rst_n (false-path, less critical)
#
# Use M3 (vertical) for data ports (wider pitch, better SI).
# Use M4 (horizontal) for clk/rst to match H-tree spine direction.

# --- Data Inputs on LEFT (M3, side 1)
set_block_pin_constraints \
    -allowed_layers    {M3} \
    -sides             {1}
place_pins -ports [get_ports {in_I in_Q valid_in}]

# --- Data Outputs on RIGHT (M3, side 3)
set_block_pin_constraints \
    -allowed_layers    {M3} \
    -sides             {3}
place_pins -ports [get_ports {out_I out_Q valid_out}]

# --- Clock on BOTTOM (M4, side 2) — feeds CTS spine
set_block_pin_constraints \
    -allowed_layers    {M4} \
    -sides             {2}  \
    -corner_keepout_num_tracks 2
place_pins -ports [get_ports {clk}]

# --- Reset on TOP (M4, side 4) — false path, any convenient side
set_block_pin_constraints \
    -allowed_layers    {M4} \
    -sides             {4}  \
    -corner_keepout_num_tracks 2
place_pins -ports [get_ports {rst_n}]

# ============================================================ #
# =================== Placement Blockages ==================== #
# ============================================================ #
# Clear any auto-generated blockages first
remove_placement_blockages -all

# Hard blockages in corners for tap cell rings and corner cells
# (adjust coordinates after you see the actual die size from the
#  initialize_floorplan output or the GUI)
# Get die dimensions first
set bbox [get_attribute [current_block] bbox]
puts "Die bbox = $bbox"

set DIE_LLX [lindex [lindex $bbox 0] 0]
set DIE_LLY [lindex [lindex $bbox 0] 1]
set DIE_URX [lindex [lindex $bbox 1] 0]
set DIE_URY [lindex [lindex $bbox 1] 1]
puts "URX = $DIE_URX   URY = $DIE_URY"
set CORNER  15
set BR_X1   [expr {$DIE_URX - $CORNER}]
set TL_Y1   [expr {$DIE_URY - $CORNER}]

# Bottom-Left
create_placement_blockage -name corner_BL -type hard \
    -boundary [list [list 0 0] [list $CORNER $CORNER]]

# Bottom-Right
create_placement_blockage -name corner_BR -type hard \
    -boundary [list [list $BR_X1 0] [list $DIE_URX $CORNER]]

# Top-Left
create_placement_blockage -name corner_TL -type hard \
    -boundary [list [list 0 $TL_Y1] [list $CORNER $DIE_URY]]

# Top-Right
create_placement_blockage -name corner_TR -type hard \
    -boundary [list [list $BR_X1 $TL_Y1] [list $DIE_URX $DIE_URY]]



####################
set LEFT_X2  20
set RIGHT_X1 [expr {$DIE_URX - 20}]
set SIDE_Y1  $CORNER
set SIDE_Y2  [expr {$DIE_URY - $CORNER}]

# Left IO buffer zone
create_placement_blockage \
    -name               left_io_buf \
    -type               partial \
    -blocked_percentage 60 \
    -boundary [list [list 0 $SIDE_Y1] [list $LEFT_X2 $SIDE_Y2]]

# Right IO buffer zone
create_placement_blockage \
    -name               right_io_buf \
    -type               partial \
    -blocked_percentage 60 \
    -boundary [list [list $RIGHT_X1 $SIDE_Y1] [list $DIE_URX $SIDE_Y2]]

# ============================================================ #
# =================== Tap / Decap Cells ====================== #
# ============================================================ #
# SAED 90nm library: use DCAP as decap/tap cell.
# Pattern: every_other_row at 10um distance — good balance
# between leakage isolation and cell area overhead for a
# purely digital datapath design like neural_eq_top.

# Insert tap/decap cells
create_tap_cells \
    -lib_cell saed90nm_max/DCAP \
    -pattern  every_other_row  \
    -distance 10

# ============================================================ #
# ====================== Reports ============================= #
# ============================================================ #
report_ports  [all_inputs]  > ${REPORT_DIR}/fp_input_ports.rpt
report_ports  [all_outputs] > ${REPORT_DIR}/fp_output_ports.rpt
report_cell                 > ${REPORT_DIR}/fp_cells.rpt
report_nets                 > ${REPORT_DIR}/fp_nets.rpt
report_qor                  > ${REPORT_DIR}/fp_qor.rpt
report_utilization          > ${REPORT_DIR}/fp_utilization.rpt
get_placement_blockages     > ${REPORT_DIR}/fp_blockages.rpt

# ============================================================ #
# ==================== Write Outputs ========================= #
# ============================================================ #
write_def    ${OUTPUT_DIR}/${DESIGN_NAME}_fp.def
write_verilog -include {all} ${OUTPUT_DIR}/${DESIGN_NAME}_fp.v
write_sdc    -output ${OUTPUT_DIR}/${DESIGN_NAME}_fp.sdc

# ============================================================ #
# ===================== Save Block =========================== #
# ============================================================ #
save_block

puts ""
puts "============================================================"
puts " Floorplan complete. Block saved as: ${OUT_BLOCK}"
puts " Next step: Power Planning (power rings + stripes)"
puts "============================================================"
puts ""
