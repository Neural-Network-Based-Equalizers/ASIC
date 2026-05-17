# ============================================================ #
# ============= Design Library (DLIB) Creation ============== #
# ============================================================ #
# Project  : Neural Network Equalizer
# Top Cell : neural_eq_top
# Tool     : IC Compiler II (icc2_shell)
# Process  : SAED 90nm
# Usage    : icc2_shell -f 2_design_library/create_dlib.tcl
#
# Run AFTER create_ndm.tcl has completed successfully.
# ============================================================ #

# ======================================================= #
# ==================== Path Variables =================== #
# ======================================================= #
set COMMON_PATH      "/home/ICer/Downloads/Lib"
set TECH_FILE_PATH   "$COMMON_PATH/process/astro/tech/astroTechFile.tf"
set TLU_PATH         "$COMMON_PATH/Technology_Kit/starrcxt"

# ======================================================= #
# =================== Design Variables ================== #
# ======================================================= #
set DESIGN_NAME      "neural_eq_top"
set DLIB_NAME        "neural_eq.dlib"

# --- NDM built in create_ndm.tcl
set REFERENCE_NDM    "./1_ndm/saed90nm_max.ndm"

# --- Synthesis outputs (from DC / Synopsys Synthesis)
set NETLIST_FILE     "../syn/output/${DESIGN_NAME}.v"
set SDC_FILE         "../syn/output/${DESIGN_NAME}.sdc"

# ======================================================= #
# ================ Create Design Library ================ #
# ======================================================= #
# Creates the ICC2 design library (.dlib) that holds all
# design blocks for neural_eq_top and its sub-modules:
#   input_window_ctrl  -> layer1_compute
#                      -> layer2_compute
#                      -> layer3_compute

create_lib \
    -technology $TECH_FILE_PATH \
    -ref_libs   $REFERENCE_NDM \
    $DLIB_NAME

# ======================================================= #
# ==================== Load Netlist ==================== #
# ======================================================= #
# Read the gate-level netlist produced by synthesis.
# The -top flag sets neural_eq_top as the design root so
# all four sub-modules are linked correctly.

read_verilog \
    -top  $DESIGN_NAME \
    $NETLIST_FILE

# Set the active design to the top-level
current_design $DESIGN_NAME

# ======================================================= #
# ==================== Read SDC ======================== #
# ======================================================= #
# Load the timing constraints exported from synthesis.
# Key constraints for this design:
#   - Clock : clk @ 10ns  (100 MHz), uncertainty 0.3ns
#   - Input delay  : 2.0ns
#   - Output delay : 2.0ns
#   - False path   : rst_n (async active-low reset)
#   - Max fanout   : 32 on rst_n

read_sdc $SDC_FILE

# ======================================================= #
# ================ TLU+ Parasitics Setup =============== #
# ======================================================= #
# Register both RC corners so ICC2 can perform concurrent
# setup and hold analysis during PnR of neural_eq_top.
#
# maxTLU -> worst-case RC  -> used for setup (late) timing
# minTLU -> best-case  RC  -> used for hold  (early) timing

read_parasitic_tech \
    -layermap  ${TLU_PATH}/tech2itf.map \
    -tlup      ${TLU_PATH}/tluplus/saed90nm_1p9m_1t_Cmax.tluplus \
    -name      maxTLU

read_parasitic_tech \
    -layermap  ${TLU_PATH}/tech2itf.map \
    -tlup      ${TLU_PATH}/tluplus/saed90nm_1p9m_1t_Cmin.tluplus \
    -name      minTLU

set_parasitic_parameters \
    -late_spec  maxTLU \
    -early_spec minTLU

# ======================================================= #
# ================ Design Checks ======================= #
# ======================================================= #
# Verify that the design is linked correctly and that all
# references (input_window_ctrl, layer1/2/3_compute) resolve.

check_design  -checks dp

# ======================================================= #
# =================== Save Block ======================= #
# ======================================================= #
# Save the initialised block as the baseline for PnR.
# All subsequent ICC2 steps (floorplan, place, cts, route)
# will open this saved block and iterate on top of it.

save_block \
    -as   ${DESIGN_NAME}_init \
    ${DLIB_NAME}:${DESIGN_NAME}.design

puts ""
puts "============================================================"
puts " Design Library created and initialised successfully."
puts ""
puts "   DLIB    : ${DLIB_NAME}"
puts "   Block   : ${DESIGN_NAME}_init"
puts "   NDM ref : ${REFERENCE_NDM}"
puts ""
puts " To open in ICC2 for floorplanning:"
puts "   open_lib  ${DLIB_NAME}"
puts "   open_block ${DESIGN_NAME}_init"
puts "============================================================"
puts ""

quit
