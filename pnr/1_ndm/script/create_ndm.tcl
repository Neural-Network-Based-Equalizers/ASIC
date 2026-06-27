########################################################################
# create_ndm.tcl
# -----------------------------------------------------------------------
# Purpose : Create a New Design Model (.ndm) library for the 45nm
#           NangateOpenCellLibrary (FreePDK45) to be used in ICC2.
#
# Tool    : Synopsys Library Manager  (icc2_lm_shell)
# Run     : cd ASIC/pnr/1_ndm/run
#           icc2_lm_shell -f ../script/create_ndm.tcl | tee ../log/ndm.log
#
# FIX NOTE (2026-06-27):
#   The FreePDK45_10m.tf file is a Milkyway-format file with broken
#   contact code definitions for via5/via6/metal6 layers that make
#   ICC2 Library Manager reject it (TECH-041 / TECH-039 / LIB-007).
#   Solution: do NOT pass -technology to create_workspace.
#   ICC2 reads ALL technology information it needs directly from the
#   LEF file (TECHNOLOGY + LAYER sections). The .tf is ICC1/Milkyway only.
#
# Author  : Auto-generated for neural_eq_top PnR flow
# Date    : 2026-06-25
########################################################################

puts "INFO: ============================================"
puts "INFO:  NDM Creation for NangateOpenCellLibrary 45nm"
puts "INFO: ============================================"

# ======================================================================
# 1. Define Paths  (VM paths — /home/standard_cell_libraries/)
# ======================================================================
set PDK_ROOT "/home/standard_cell_libraries/NangateOpenCellLibrary_PDKv1_3_v2010_12"

# --- Technology File (Milkyway-format .tf — compatible with ICC2)
#     We use the .tf file, but it has a known bug (missing brace) which we will patch.
set ORIGINAL_TECH_FILE "${PDK_ROOT}/tech/techfile/milkyway/FreePDK45_10m.tf"
set PATCHED_TECH_FILE  "../output/FreePDK45_10m_fixed.tf"

# --- Macro LEF: contains all MACRO definitions (cell pin geometries, obs)
set MACRO_LEF "${PDK_ROOT}/lib/Back_End/lef/NangateOpenCellLibrary.macro.lef"

# --- Timing Library (.db) — worst-case corner, same as used in synthesis
set WORST_DB  "${PDK_ROOT}/lib/Front_End/Liberty/NLDM/NangateOpenCellLibrary_ss0p95vn40c.db"

# --- NDM output directory (relative to run/ folder where this is executed)
set NDM_LIB_NAME  "NangateOpenCellLibrary"
set NDM_OUT_DIR   "../output"

puts "INFO: PDK_ROOT     = $PDK_ROOT"
puts "INFO: ORIG_TECH_TF = $ORIGINAL_TECH_FILE"
puts "INFO: MACRO_LEF    = $MACRO_LEF"
puts "INFO: WORST_DB     = $WORST_DB"
puts "INFO: NDM output   = ${NDM_OUT_DIR}/${NDM_LIB_NAME}*.ndm"

# ======================================================================
# 2. Pre-flight Checks
# ======================================================================
foreach f [list $ORIGINAL_TECH_FILE $MACRO_LEF $WORST_DB] {
    if {![file exists $f]} {
        puts "ERROR: File not found: $f"
        puts "ERROR: Please verify your PDK installation path."
        exit 1
    }
}
puts "INFO: All input files verified."

# ======================================================================
# 2b. Patch the Broken Tech File (.tf)
# ======================================================================
#    The FreePDK45_10m.tf has a syntax error: the via5 layer is missing
#    its closing brace '}'. We patch it dynamically before creating
#    the workspace so we don't have to modify the read-only PDK.
# ======================================================================
puts "INFO: Patching broken FreePDK45_10m.tf to fix missing via5 closing brace..."
file mkdir ../output
set in_file [open $ORIGINAL_TECH_FILE r]
set out_file [open $PATCHED_TECH_FILE w]

while {[gets $in_file line] >= 0} {
    # If we are about to start the metal6 block, close the via5 block first!
    if {[string match {Layer		"metal6" \{} $line]} {
        puts $out_file "\}"
    }
    puts $out_file $line
}
close $in_file
close $out_file
puts "INFO: Patched tech file saved to $PATCHED_TECH_FILE"

# ======================================================================
# 3. Create Library Manager Workspace
# ======================================================================
#    -flow exploration : Lightweight mode — analyzes inputs, creates NDM.
#    -technology       : We pass the PATCHED Milkyway .tf file here!
# ======================================================================
puts "INFO: Creating workspace using patched TF as technology..."
create_workspace -flow exploration \
                 -technology $PATCHED_TECH_FILE \
                 $NDM_LIB_NAME

# ======================================================================
# 4. Read Macro LEF (standard cell physical abstracts)
# ======================================================================
#    The macro LEF contains MACRO blocks for every standard cell:
#      - Pin geometries (metal1 shapes for VDD/VSS/data pins)
#      - Obstruction layers (OBS sections)
#      - Cell sizes and origins
#    All 135+ cells in the Nangate library are defined here.
# ======================================================================
puts "INFO: Reading macro LEF (standard cell abstracts)..."
read_lef $MACRO_LEF

# ======================================================================
# 6. Read Timing Library (.db)
# ======================================================================
#    The .db file provides timing and power characterization for every
#    cell — setup/hold arcs, drive strengths, output capacitance, etc.
#    Worst-case (ss, 0.95V, -40°C) matches the synthesis library.
# ======================================================================
puts "INFO: Reading timing library (.db)..."
read_db $WORST_DB

# ======================================================================
# 7. Set Workspace Options
# ======================================================================
#    keep_all_physical_cells : Retain filler, tap, tie, antenna cells
#                              so ICC2 PnR can insert them later.
#    save_design_views       : Include abstract views in NDM.
#    save_layout_views       : Include layout views in NDM.
# ======================================================================
puts "INFO: Setting workspace options..."
set_app_options -list {lib.workspace.keep_all_physical_cells true}
set_app_options -list {lib.workspace.save_design_views       true}
set_app_options -list {lib.workspace.save_layout_views       true}

# ======================================================================
# 8. Group Libraries
# ======================================================================
#    group_libs correlates the timing data (.db) with the physical data
#    (LEF macros) and groups them into a single coherent library object.
# ======================================================================
puts "INFO: Grouping and correlating libraries..."
group_libs

# ======================================================================
# 9. Write NDM
# ======================================================================
#    process_workspaces validates and writes the .ndm file(s).
#    The output will appear in ../output/ as:
#      NangateOpenCellLibrary_1.ndm  (or similar numbered suffix)
# ======================================================================
puts "INFO: Processing workspace and writing NDM..."
file mkdir $NDM_OUT_DIR
process_workspaces -directory $NDM_OUT_DIR \
                   -output    $NDM_LIB_NAME

# ======================================================================
# 10. Report & Quit
# ======================================================================
puts "INFO: ============================================"
puts "INFO:  NDM Creation Complete!"
puts "INFO:  Output directory : $NDM_OUT_DIR"
puts "INFO:  Look for         : ${NDM_OUT_DIR}/${NDM_LIB_NAME}*.ndm"
puts "INFO: ============================================"
puts "INFO: Before running Step 2, verify the .ndm file exists with:"
puts "INFO:   ls -lh ../output/*.ndm"

quit
