set link_path  "/home/standard_cell_libraries/NangateOpenCellLibrary_PDKv1_3_v2010_12/lib/Front_End/Liberty/NLDM/NangateOpenCellLibrary_ff1p25v0c.db"

read_verilog "../../../pnr/9_finish/output/neural_eq_top_final_pg.v"

current_design neural_eq_top
link

source ../../../pnr/9_finish/output/neural_eq_top_final.sdc
read_parasitics ../../../pnr/9_finish/output/neural_eq_top.spef.gz

update_timing

save_session neural_eq_top_min.session

report_constraint -all_violators -significant_digits 4 > ./neural_eq_top.min_constr.rpt
report_timing -delay_type min -nworst 40 -significant_digits 4 > ./neural_eq_top.min_timing.rpt

# Note: You will apply ECO fixes interactively and write them out manually, e.g.:
# write_changes -format icc2 -output ./hazem_fix_hold.tcl

write_sdf ./neural_eq_top.min.sdf
exit



