########################################################################
# create_ndm.tcl
# -----------------------------------------------------------------------
# Purpose : Create a New Design Model (.ndm) library for the 45nm
#           NangateOpenCellLibrary (FreePDK45) to be used in ICC2.
#
# Tool    : Synopsys Library Manager  (icc2_lm_shell)
# Run     : cd ASIC/pnr/1_ndm/run
#           icc2_lm_shell -f ../script/create_ndm.tcl | tee icc2_lm_output.txt
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
set TECH_FILE "${PDK_ROOT}/tech/techfile/milkyway/FreePDK45_10m.tf"

# --- Timing Library (.db) — worst-case, same as used in synthesis
set WORST_DB  "${PDK_ROOT}/lib/Front_End/Liberty/NLDM/NangateOpenCellLibrary_ss0p95vn40c.db"

# --- Physical Library (LEF) — combined tech+macro LEF
#     This single file contains BOTH the technology layer definitions
#     AND all standard cell macro definitions for this PDK.
set COMBINED_LEF "${PDK_ROOT}/lib/Back_End/lef/NangateOpenCellLibrary.lef"

# --- NDM output directory (relative to the run/ folder where this is executed)
set NDM_LIB_NAME  "NangateOpenCellLibrary"
set NDM_OUT_DIR   "../output"

puts "INFO: PDK_ROOT     = $PDK_ROOT"
puts "INFO: TECH_FILE    = $TECH_FILE"
puts "INFO: WORST_DB     = $WORST_DB"
puts "INFO: COMBINED_LEF = $COMBINED_LEF"
puts "INFO: NDM output   = ${NDM_OUT_DIR}/${NDM_LIB_NAME}*.ndm"

# ======================================================================
# 2. Pre-flight Checks
# ======================================================================
foreach f [list $TECH_FILE $WORST_DB $COMBINED_LEF] {
    if {![file exists $f]} {
        puts "ERROR: File not found: $f"
        puts "ERROR: Please verify your PDK installation path."
        exit 1
    }
}
puts "INFO: All input files verified."

# ======================================================================
# 3. Create Library Manager Workspace
# ======================================================================
#    -flow exploration : Lightweight mode for library characterization.
#                        Analyzes source files and creates the NDM.
#    -technology       : Points to the process tech file.
#    The last argument is the workspace (library) name.
# ======================================================================
puts "INFO: Creating workspace..."
create_workspace -flow exploration \
                 -technology $TECH_FILE \
                 $NDM_LIB_NAME

# ======================================================================
# 4. Read Timing Library (.db)
# ======================================================================
#    read_db reads Synopsys .db format into the workspace.
#    This provides timing/power characterization data for every cell.
# ======================================================================
puts "INFO: Reading timing library (.db)..."
read_db $WORST_DB

# ======================================================================
# 5. Read Physical Library (LEF)
# ======================================================================
#    read_lef reads the LEF (Library Exchange Format) file.
#    For Nangate 45nm, the combined .lef includes:
#      - TECHNOLOGY section (layers, vias, sites)
#      - MACRO definitions (cell layouts, pin geometries, obstructions)
# ======================================================================
puts "INFO: Reading physical library (LEF)..."
read_lef $COMBINED_LEF

# ======================================================================
# 6. Set Workspace Options
# ======================================================================
#    These options ensure the NDM contains all the data ICC2 needs:
#    - keep_all_physical_cells : Retain filler cells, tap cells, etc.
#    - save_design_views      : Include abstract/design views.
#    - save_layout_views      : Include full layout views.
#    - enable_lib_cell_editing : Allow ICC2 to modify cells if needed.
# ======================================================================
puts "INFO: Setting workspace options..."
set_app_options -list {lib.workspace.keep_all_physical_cells true}
set_app_options -list {lib.workspace.save_design_views       true}
set_app_options -list {lib.workspace.save_layout_views        true}
set_app_options -list {design.enable_lib_cell_editing         mutable}

# ======================================================================
# 7. Analyze & Group Libraries
# ======================================================================
#    group_libs analyzes the logic (.db) and physical (.lef) sources
#    in exploration mode. It correlates the timing arcs with the
#    physical cell abstracts and groups them into a coherent library.
# ======================================================================
puts "INFO: Grouping and analyzing libraries..."
group_libs

# ======================================================================
# 8. Check & Commit Workspace → Write NDM
# ======================================================================
#    process_workspaces validates the workspace data and writes the
#    .ndm file(s) to the specified output directory.
#
#    -directory : Where to write the .ndm output
#    -output    : Base name for the .ndm library
#
#    The resulting .ndm will appear in:
#      ../output/NangateOpenCellLibrary_<N>.ndm
# ======================================================================
puts "INFO: Processing workspace and writing NDM..."
file mkdir $NDM_OUT_DIR
process_workspaces -directory $NDM_OUT_DIR \
                   -output $NDM_LIB_NAME

# ======================================================================
# 9. Report & Quit
# ======================================================================
puts "INFO: ============================================"
puts "INFO:  NDM Creation Complete!"
puts "INFO:  Output directory: $NDM_OUT_DIR"
puts "INFO:  Look for: ${NDM_OUT_DIR}/${NDM_LIB_NAME}*.ndm"
puts "INFO: ============================================"
puts "INFO: Please verify the .ndm file exists before proceeding."

quit
