set link_path  "/home/standard_cell_libraries/NangateOpenCellLibrary_PDKv1_3_v2010_12/lib/Front_End/Liberty/NLDM/NangateOpenCellLibrary_ff1p25v0c.db"

read_verilog "../../../pnr/output/neural_eq_top_icc.v"

current_design neural_eq_top
link

source ../../../syn/cons/cons.tcl
read_parasitics ../../rcxt/cmin/neural_eq_top_cmin_t125.spef
#read_parasitics ../../../pnr/output/neural_eq_top.spef.min

update_timing

save_session neural_eq_top_min.session

report_constraint -all_violators -significant_digits 4 > ./neural_eq_top.min_constr.rpt
report_timing -delay_type min -nworst 40 -significant_digits 4 > ./neural_eq_top.min_timing.rpt

write_sdf ./neural_eq_top.min.sdf
exit



