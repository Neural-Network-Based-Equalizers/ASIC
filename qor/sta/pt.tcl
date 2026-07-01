restore_session ./min/neural_eq_top_min.session
# 1. Restore the min (hold) or max (setup) session we just generated:
restore_session ./min/neural_eq_top_min.session

# 2. Do your manual analysis and fixes (exactly like your MIPS screenshot)
report_timing -delay_type min
fix_eco_timing -type hold -methods {size_cell insert_buffer} -buffer_list {BUF_X1 BUF_X2} -setup_margin 0.01

# 3. CRITICAL DIFFERENCE FOR ICC2: 
# When you write the changes, you MUST specify "-format icc2" and name it what eco.tcl expects!
write_changes -format icc2 -output ./min/hazem_fix_hold.tcl

# 4. Exit PrimeTime
exit

restore_session mips_16_min.session/
   # -> Change to: restore_session ./min/neural_eq_top_min.session/

report_timing -delay_type min

report_constraint -all_violators

report_global_timing

report_timing -delay_type min

insert_buffer U320/Z BUF_X1
   # -> Change U320/Z to whatever your actual failing pin is in neural_eq_top

report_timing -delay_type min

report_timing -delay_type min -to pc_current_reg_9_
   # -> Change pc_current_reg_9_ to your actual failing endpoint in neural_eq_top

9  fix_eco_timing -type min -methods size_cells

10 fix_eco_timing -type hold -methods size_cells

11 fix_eco_timing -type hold -methods size_cells

12 fix_eco_timing -type hold -methods { size_cell insert_buffer } -buffer_list { BUF_X1 BUF_X2 } -setup_margin 0.01
   # -> Note: Make sure BUF_X1/BUF_X2 match your Nangate 45nm buffer names. 
   # -> You might need to use { BUF_X2 BUF_X4 } depending on the Nangate library names.

13 report_global_timing

14 write_changes -output hamada.tcl 
   # -> CRITICAL Change to: write_changes -format icc2 -output ./min/hazem_fix_hold.tcl

15 history




# 1. First, fix the hold timing violations
fix_eco_timing -type hold -methods {insert_buffer} -buffer_list {BUF_X1 BUF_X2 BUF_X4}

# 2. Next, fix the Max Capacitance DRC violations (using the exact type from the man page)
fix_eco_drc -type max_capacitance -buffer_list {BUF_X2 BUF_X4 BUF_X8}

# 3. Finally, fix the Max Transition DRC violation
fix_eco_drc -type max_transition -buffer_list {BUF_X2 BUF_X4 BUF_X8}

# 4. Verify everything is clean
report_constraint -all_violators

# 5. Write out the changes for ICC2 ECO routing
write_changes -format icc2 -output ./min/hazem_fix_all.tcl
