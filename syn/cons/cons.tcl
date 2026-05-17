# =========================================================
# Constraints for: neural_eq_top
# Architecture:
#   input_window_ctrl  -> layer1_compute (4 ticks)
#                      -> layer2_compute (6 ticks)
#                      -> layer3_compute (6 ticks)
#
# The critical combinational path is inside the MAC units:
#   16x16 multiply -> 40-bit accumulate -> shift -> clamp
#
# Start with 10ns (100 MHz). Tighten if timing is met cleanly.
# =========================================================

# --- Clock ---
create_clock -name clk -period 10 -waveform {0 5} [get_ports clk]

# --- Clock uncertainty (jitter + skew) ---
set_clock_uncertainty 0.3 [get_clocks clk]

# --- Clock transition ---
set_clock_transition 0.1 [get_clocks clk]

# --- Input delays (data arrives 2ns after clock edge) ---
set_input_delay -max 2.0 -clock [get_clocks clk] \
    [remove_from_collection [all_inputs] [get_ports {clk rst_n}]]

# --- Output delays (data must be stable 2ns before next clock edge) ---
set_output_delay -max 2.0 -clock [get_clocks clk] [all_outputs]

# --- Reset is async: no timing on rst_n ---
set_false_path -from [get_ports rst_n]
set_max_fanout 32 [get_ports rst_n]

# --- Drive strength on inputs (16-drive standard cell) ---
set_driving_cell -lib_cell DFFX1 -pin Q \
    [remove_from_collection [all_inputs] [get_ports {clk rst_n}]]

# --- Output load ---
set_load 0.05 [all_outputs]

# =========================================================
# NOTE ON CLOCK PERIOD:
#   The 16x16 signed multiply in each MAC expands to ~32-bit
#   product before being added into a 40-bit accumulator.
#   With a typical standard-cell library at ss/cold this
#   path typically closes at 8-12ns.
#   If the tool reports negative slack, relax to 12ns first,
#   then recheck after compile -map_effort high.
# =========================================================
