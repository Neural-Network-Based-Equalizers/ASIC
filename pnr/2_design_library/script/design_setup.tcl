########################################################################
# design_setup.tcl
# -----------------------------------------------------------------------
# Purpose : ICC2 Design Setup for neural_eq_top (45nm FreePDK45)
#           - Creates the design library (.dlib) referencing the NDM
#           - Reads the synthesized netlist and constraints
#           - Loads TLU+ parasitic models
#           - Saves the initial design block
#
# Tool    : Synopsys IC Compiler II  (icc2_shell)
# Run     : cd ASIC/pnr/2_design_library/run
#           icc2_shell -f ../script/design_setup.tcl | tee icc2_output.txt
#
# Prereq  : Step 1 (NDM) must be completed first.
#           The .ndm file must exist in: ../1_ndm/output/
#
# Author  : Auto-generated for neural_eq_top PnR flow
# Date    : 2026-06-25
########################################################################

puts "INFO: ============================================"
puts "INFO:  ICC2 Design Setup — neural_eq_top (45nm)"
puts "INFO: ============================================"

# ======================================================================
# 1. Design & Path Variables
# ======================================================================
set design         "neural_eq_top"
set PDK_ROOT       "/home/standard_cell_libraries/NangateOpenCellLibrary_PDKv1_3_v2010_12"

# --- Technology File (Using the patched version from Step 1)
set TECH_FILE      "../../1_ndm/output/FreePDK45_10m_fixed.tf"

# --- Reference NDM libraries (output from Step 1)
# Note: exploration flow creates TWO NDM files (one for timing, one for physical-only cells like TAP/FILL)
set NDM_REF_LIB_TIMING   "../../1_ndm/output/NangateOpenCellLibrary_ss0p95vn40c.ndm"
set NDM_REF_LIB_PHYSICAL "../../1_ndm/output/NangateOpenCellLibrary_physical_only.ndm"
puts "INFO: Using NDM TIMING: $NDM_REF_LIB_TIMING"
puts "INFO: Using NDM PHYSICAL: $NDM_REF_LIB_PHYSICAL"

# --- Synthesis outputs (relative to pnr/2_design_library/run/)
set SYN_DIR        "../../../syn/output"
set NETLIST        "${SYN_DIR}/${design}.v"
set SDC_FILE       "${SYN_DIR}/${design}.sdc"

# --- TLU+ parasitic extraction files
set TLUP_MAX       "${PDK_ROOT}/tech/rcxt/FreePDK45_10m_Cmax.tlup"
set TLUP_MIN       "${PDK_ROOT}/tech/rcxt/FreePDK45_10m_Cmin.tlup"
set TLUP_MAP       "${PDK_ROOT}/tech/rcxt/FreePDK45_10m.map"

# --- Design library output
set DLIB_DIR       "../output"
set DLIB_NAME      "${design}.dlib"
set DLIB           "${DLIB_DIR}/${DLIB_NAME}"

puts "INFO: Design        = $design"
puts "INFO: TECH_FILE     = $TECH_FILE"
puts "INFO: NETLIST        = $NETLIST"
puts "INFO: SDC_FILE       = $SDC_FILE"
puts "INFO: DLIB output    = $DLIB"

# ======================================================================
# 2. Check File Existence
# ======================================================================
foreach f [list $TECH_FILE $NDM_REF_LIB_TIMING $NDM_REF_LIB_PHYSICAL $NETLIST $SDC_FILE $TLUP_MAX $TLUP_MIN $TLUP_MAP] {
    if {![file exists $f]} {
        puts "ERROR: File not found: $f"
        exit 1
    }
}
puts "INFO: All input files verified."

# ======================================================================
# 3. Create Design Library (.dlib)
# ======================================================================
# Equivalent to ICC1's create_mw_lib.
# -technology : Must be a Milkyway .tf file or an NDM technology library.
# -ref_libs   : The reference libraries (NDM format).
# ======================================================================
puts "INFO: Creating design library $DLIB..."
file mkdir $DLIB_DIR
create_lib $DLIB \
    -technology $TECH_FILE \
    -ref_libs   [list $NDM_REF_LIB_TIMING $NDM_REF_LIB_PHYSICAL]

# ======================================================================
# 4. Read Synthesized Netlist
# ======================================================================
#    read_verilog reads the gate-level netlist from synthesis.
#    -top specifies the top-level module name.
#
#    ICC1 equivalent: import_designs -format verilog -top -cel
# ======================================================================
puts "INFO: Reading synthesized netlist..."
read_verilog -top $design $NETLIST

# ======================================================================
# 5. Link the Design
# ======================================================================
#    link_block resolves all cell references against the NDM library.
#    This is the ICC2 equivalent of "link" in Design Compiler.
#    If cells are unresolved, check that the NDM was created correctly.
# ======================================================================
puts "INFO: Linking design..."
link_block

# --- Verify link was successful
set unresolved [get_cells -quiet -filter "is_unbound == true" -hierarchical]
if {[sizeof_collection $unresolved] > 0} {
    puts "WARNING: Unresolved cells found after link_block:"
    report_ref_libs
    puts "WARNING: Check your NDM library. Proceeding anyway..."
} else {
    puts "INFO: All cells resolved successfully."
}

# ======================================================================
# 6. Read Timing Constraints (SDC)
# ======================================================================
#    read_sdc loads the Synopsys Design Constraints file.
#    This includes clock definitions, I/O delays, false paths, etc.
#
#    ICC1 equivalent: source cons.tcl (or read_sdc)
# ======================================================================
puts "INFO: Reading SDC constraints..."
read_sdc $SDC_FILE

# --- Set clock as propagated for PnR (real delays, not ideal)
#     Clock name "fun_clk" confirmed from cons.tcl
set_propagated_clock [get_clocks fun_clk]

# ======================================================================
# 7. Read Parasitic Technology (TLU+)
# ======================================================================
#    read_parasitic_tech loads the TLU+ models for RC extraction.
#    We read both max (worst-case) and min (best-case) for
#    setup and hold analysis respectively.
#
#    ICC1 equivalent: set_tlu_plus_files -max_tluplus -min_tluplus -tech2itf_map
# ======================================================================
puts "INFO: Reading TLU+ parasitic models..."

read_parasitic_tech -layermap $TLUP_MAP \
                    -tlup $TLUP_MAX \
                    -name maxTLU

read_parasitic_tech -layermap $TLUP_MAP \
                    -tlup $TLUP_MIN \
                    -name minTLU

# --- Assign parasitic corners for timing analysis
set_parasitic_parameters -late_spec maxTLU -early_spec minTLU

# ======================================================================
# 8. Initial Reports
# ======================================================================
puts "INFO: Generating initial reports..."

report_ref_libs            > ../report/ref_libs.rpt
report_design              > ../report/design.rpt
report_clocks              > ../report/clocks.rpt
report_timing -max_paths 5 > ../report/timing_initial.rpt
report_constraints -all_violators -nosplit > ../report/violations_initial.rpt

# ======================================================================
# 9. Save Initial Block
# ======================================================================
#    save_block saves the current design state to the .dlib.
#    The -as option creates a named snapshot.
#
#    ICC1 equivalent: save_mw_cel -as
# ======================================================================
puts "INFO: Saving design block..."
save_block -as ${design}_setup

puts "INFO: ============================================"
puts "INFO:  Design Setup Complete!"
puts "INFO:  Design library: ${DLIB_DIR}/${DLIB_NAME}"
puts "INFO:  Block saved as: ${design}_setup"
puts "INFO: ============================================"
puts "INFO: Proceed to Step 3 (Floorplan) next."
puts "INFO: You can close this session or continue interactively."

# --- Do NOT quit here — user may want to inspect the design in GUI
# --- Uncomment the line below to auto-exit:
# quit

