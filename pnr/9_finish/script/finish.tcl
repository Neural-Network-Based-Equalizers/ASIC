########################################################################
# finish.tcl
# -----------------------------------------------------------------------
# Purpose : ICC2 Finishing + Output Generation for neural_eq_top (45nm)
#           - Opens routed block from Step 7
#           - Inserts metal fill / filler cells (Nangate verified names)
#           - Final DRC + LVS checks
#           - Writes GDS (with Nangate layer map)
#           - Writes post-layout Verilog netlist (with PG)
#           - Writes SPEF parasitics
#           - Saves final block
#
# Tool    : Synopsys IC Compiler II  (icc2_shell)
# Run     : cd ASIC/pnr/9_finish/run
#           icc2_shell -f ../script/finish.tcl | tee ../log/finish.log
#
# Prereq  : Step 7 (routing.tcl) must be complete.
#           Block neural_eq_top_route must exist in the .dlib.
#
# ICC1 equiv file : pnr45.tcl  Section "7. Finishing" + "8. Outputs"
# Author  : Auto-generated for neural_eq_top PnR flow
########################################################################
set_host_options -max_cores 4

puts "INFO: ================================================"
puts "INFO:  ICC2 Finishing + Output — neural_eq_top (45nm)"
puts "INFO: ================================================"

# ======================================================================
# 1. Variables
# ======================================================================
set design          "neural_eq_top"
set design_lib_path "../../2_design_library/output"
set DLIB            "${design_lib_path}/${design}.dlib"

set PDK_ROOT  "/home/standard_cell_libraries/NangateOpenCellLibrary_PDKv1_3_v2010_12"
set GDS_MAP   "${PDK_ROOT}/tech/strmout/FreePDK45_10m_gdsout.map"

# ======================================================================
# 2. Open Routed Block
# ======================================================================
sh rm -f ${DLIB}/${design}_route/design.ndm.lock

# ICC1 equiv: open_mw_lib ./${design} ; open_mw_cel ${design}_6_routed
puts "INFO: Opening routed block..."
open_lib   $DLIB
open_block ${design}_route

copy_block -from_block ${design}_route -to_block ${design}_final
current_block ${design}_final
start_gui

# ======================================================================
# 2b. Post-Route Optimizations & Yield Enhancement
# ======================================================================
# This section runs the optimizations that were skipped during the
# main routing step to save time. 

puts "INFO: Running Post-route timing optimization and DRC cleanup..."
route_opt

puts "INFO: Inserting redundant vias for yield enhancement..."
add_redundant_vias

puts "INFO: Running final Incremental ECO routing (DRC cleanup)..."
# This single incremental pass will clean up any DRCs left over from
# the main route, the hold buffers, AND the redundant vias all at once!
route_detail -incremental true

# ======================================================================
# 3. Final DRC + LVS Pre-Check (Before Filling)
# ======================================================================
# Verify routing is clean before adding filler cells.
# Any routing DRC here must be fixed (go back to routing step).
#
# ICC1 equiv (pnr45.tcl line 550-552):
#   verify_zrt_route
#   verify_lvs -ignore_floating_port -ignore_floating_net ...
# ICC2 equiv from pnr90.tcl:
#   check_routes ; check_lvs
# ======================================================================
puts "INFO: Running pre-fill DRC + LVS checks..."
file mkdir ../report
check_routes           > ../report/finish_pre_fill_drc.rpt
check_lvs -max_error 0 > ../report/finish_pre_fill_lvs.rpt

# ======================================================================
# 4. Insert Standard Cell Filler Cells
# ======================================================================
# Filler cells fill empty spaces in standard cell rows to:
#   1. Complete the N-well and P-well implants (electrical continuity)
#   2. Satisfy manufacturing density rules
#   3. Prevent DRC errors from well discontinuities
#
# Filler cells are inserted from largest to smallest to minimize fragmentation.
# Verified cell names from LEF directory:
#   FILLCELL_X32, FILLCELL_X16, FILLCELL_X8, FILLCELL_X4, FILLCELL_X2, FILLCELL_X1
#
# ICC1 equiv (pnr45.tcl lines 532-533):
#   insert_stdcell_filler \
#     -cell_without_metal {FILLCELL_X32 FILLCELL_X16 FILLCELL_X8 FILLCELL_X4 FILLCELL_X2 FILLCELL_X1} \
#     -connect_to_power VDD -connect_to_ground VSS
#
# ICC2 equiv from pnr90.tcl:
#   create_stdcell_fillers -lib_cells $FillerCells
# ======================================================================
puts "INFO: Inserting filler cells..."
create_stdcell_fillers \
    -lib_cells {
        */FILLCELL_X32
        */FILLCELL_X16
        */FILLCELL_X8
        */FILLCELL_X4
        */FILLCELL_X2
        */FILLCELL_X1
    }

# Remove any filler cells that were placed where they cause DRC violations
# ICC2 equiv from pnr90.tcl: remove_stdcell_fillers_with_violation
remove_stdcell_fillers_with_violation

# ======================================================================
# 5. Final PG Reconnect After Filler Insertion
# ======================================================================
# Filler cells have VDD/VSS pins that must be connected.
#
# ICC1 equiv (pnr45.tcl lines 537-540):
#   derive_pg_connection -power_net VDD -ground_net VSS ...
# ICC2: connect_pg_net
# ======================================================================
puts "INFO: Reconnecting PG nets after filler insertion..."
connect_pg_net -net VDD [get_pins -hierarchical "*/VDD"]
connect_pg_net -net VSS [get_pins -hierarchical "*/VSS"]

# ======================================================================
# 6. Name Rules (for Verilog/GDSII compatibility)
# ======================================================================
# Ensures net and cell names are compatible with Verilog/GDSII standards.
# Removes case conflicts and illegal characters.
#
# ICC1 equiv (pnr45.tcl lines 567-571):
#   define_name_rules no_case -case_insensitive
#   change_names -rule no_case -hierarchy
#   change_names -rule verilog -hierarchy
#   set verilogout_no_tri  true
#   set verilogout_equation false
# ICC2: same commands, same syntax
# ======================================================================
puts "INFO: Applying name rules..."
define_name_rules no_case -case_insensitive
change_names -rule no_case  -hierarchy
change_names -rule verilog  -hierarchy

# ======================================================================
# 7. Final DRC + LVS (After Filler)
# ======================================================================
# ICC1 equiv (pnr45.tcl lines 550-552):
#   verify_zrt_route
#   verify_lvs -ignore_floating_port -ignore_floating_net \
#              -check_open_locator -check_short_locator
# ICC2 equiv from pnr90.tcl: check_routes + check_lvs
# ======================================================================
puts "INFO: Running final DRC + LVS checks..."
check_routes           > ../report/finish_final_drc.rpt
check_lvs -max_error 0 > ../report/finish_final_lvs.rpt
check_legality -verbose > ../report/finish_legality.rpt
check_pg_drc           > ../report/finish_pg_drc.rpt

# ======================================================================
# 8. Write GDS (Stream Out)
# ======================================================================
# Writes the physical layout in GDS format for mask tape-out.
# Uses the Nangate layer map: FreePDK45_10m_gdsout.map
#   metal1=11, metal2=13 ... metal10=29, via1=12 ... via9=42
#
# ICC1 equiv (pnr45.tcl lines 554-563):
#   set_write_stream_options \
#     -map_layer $sc_dir/tech/strmout/FreePDK45_10m_gdsout.map \
#     -output_filling fill \
#     -child_depth 20 \
#     -output_outdated_fill \
#     -output_pin {text geometry}
#   write_stream -lib $design -format gds -cells $design ./output/${design}.gds
#
# ICC2 equiv: write_gds command
# ======================================================================
puts "INFO: Writing GDS layout..."
file mkdir ../output
write_gds \
    -layer_map   $GDS_MAP \
    -long_names \
    ../output/${design}.gds

# ======================================================================
# 9. Write Post-Layout Verilog Netlist
# ======================================================================
# Writes the gate-level Verilog netlist including PG connections.
# Used for LVS and formal verification against the GDS.
#
# ICC1 equiv (pnr45.tcl lines 574-575):
#   write_verilog -pg -no_physical_only_cells ./output/${design}_icc.v
#   write_verilog -no_physical_only_cells ./output/${design}_icc_nopg.v
#
# ICC2 equiv from pnr90.tcl:
#   write_verilog -include {all} ../output/${design}.v
# ======================================================================
puts "INFO: Writing post-layout Verilog netlist..."

# Full netlist (with PG and physical-only cells like fillers)
write_verilog \
    -include {all} \
    ../output/${design}_final_pg.v

# Functional netlist only (no filler cells, no PG pins — for verification)
write_verilog \
    -exclude_cell_types {filler_cell tap_cell} \
    ../output/${design}_final_nopg.v

# ======================================================================
# 10. Write SPEF (Parasitics)
# ======================================================================
# Exports post-layout RC parasitics for static timing analysis
# in PrimeTime or other sign-off tools.
#
# ICC1 equiv (pnr45.tcl lines 577-578):
#   extract_rc
#   write_parasitics -output {./output/mips_16.spef}
# ICC2 equiv from pnr90.tcl:
#   write_parasitics -format spef -output ../output/${design}
# ======================================================================
puts "INFO: Writing SPEF parasitics..."
write_parasitics \
    -format spef \
    -output ../output/${design}

# ======================================================================
# 11. Write SDC (for STA handoff)
# ======================================================================
puts "INFO: Writing final SDC..."
write_sdc -output ../output/${design}_final.sdc

# ======================================================================
# 12. Write DEF (for record)
# ======================================================================
puts "INFO: Writing final DEF..."
write_def ../output/${design}_final.def

# ======================================================================
# 13. Final Reports
# ======================================================================
puts "INFO: Generating final design reports..."
report_area -include filler    > ../report/finish_area_with_fill.rpt
report_area -physical_only     > ../report/finish_area_physical.rpt
report_utilization             > ../report/finish_utilization.rpt
report_qor                     > ../report/finish_qor.rpt
report_design                  > ../report/finish_design.rpt
report_cell                    > ../report/finish_cells.rpt
report_timing -delay_type max -max_paths 20 -nosplit > ../report/finish_timing_setup.rpt
report_timing -delay_type min -max_paths 20 -nosplit > ../report/finish_timing_hold.rpt

# ======================================================================
# 14. Save Final Block
# ======================================================================
# ICC1 equiv (pnr45.tcl line 542):
#   save_mw_cel -as ${design}_7_finished
#   close_mw_cel
#   close_mw_lib
# ICC2: save_block ; close_lib
# ======================================================================
puts "INFO: Saving final block..."
save_block -as ${design}_final

puts "INFO: ================================================"
puts "INFO:  Finishing Complete!"
puts "INFO:  Final GDS : ../output/${design}.gds"
puts "INFO:  Final V   : ../output/${design}_final_pg.v"
puts "INFO:  Final SPEF: ../output/${design}.spef.gz"
puts "INFO:  Final SDC : ../output/${design}_final.sdc"
puts "INFO: ================================================"
puts "INFO:  Flow Complete — all PnR steps done!"
puts "INFO: ================================================"

