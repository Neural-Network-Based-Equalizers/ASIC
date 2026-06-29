set link_path  "/home/standard_cell_libraries/NangateOpenCellLibrary_PDKv1_3_v2010_12/lib/Front_End/Liberty/NLDM/NangateOpenCellLibrary_ss0p95vn40c.db"

read_verilog "../../../pnr/output/neural_eq_top_icc.v"

current_design neural_eq_top
link

source ../../../syn/cons/cons.tcl
read_parasitics ../../rcxt/cmax/neural_eq_top_cmax_tm40.spef
#read_parasitics ../../../pnr/output/neural_eq_top.spef.max

update_timing

save_session neural_eq_top_max.session

report_constraint -all_violators -significant_digits 4 > ./neural_eq_top.max_constr.rpt
report_timing -delay_type max -nworst 40 -significant_digits 4 > ./neural_eq_top.max_timing.rpt

write_sdf ./neural_eq_top.max.sdf

exit


