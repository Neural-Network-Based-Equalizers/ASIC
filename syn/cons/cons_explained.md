# Design Compiler Constraint Reference

This note explains the constraint commands used in the ASIC flow and the related commands copied from the MIPS and ref-flow examples.

The current ASIC file is the active one here:

- [ASIC/syn/cons/cons.tcl](ASIC/syn/cons/cons.tcl)

It is sourced by the synthesis driver here:

- [ASIC/syn/script/syn.tcl](ASIC/syn/script/syn.tcl)

The relevant call order is:

1. `syn.tcl` sets up libraries and the top design name.
1. `syn.tcl` runs `analyze` and `elaborate` on the RTL top.
1. `syn.tcl` calls `source ../cons/cons.tcl`.
1. DC applies the constraints before `compile` and reporting.

The two reference styles are:

- [mips_90___ICCII/syn/cons/cons.tcl](mips_90___ICCII/syn/cons/cons.tcl)
- [mips_90___ICCII/syn/cons/cons_2.tcl](mips_90___ICCII/syn/cons/cons_2.tcl)
- [ref_flow_45___ICC/syn/cons/cons.tcl](ref_flow_45___ICC/syn/cons/cons.tcl)

## 1. What the active ASIC file is doing

The active ASIC constraints are intentionally simple:

- define one functional clock
- model external input and output timing
- freeze the test-mode pin so DC optimizes only the functional mode
- protect the clock and reset networks from optimization
- apply basic physical design rule limits like transition and capacitance

That means this file is mainly telling DC how to view the top-level environment, not changing the RTL logic itself.

## 2. Command by command

| Command | What it does in DC | Why it is used here |
| --- | --- | --- |
| `create_clock -name fun_clk -period 4 -waveform {0 2} [get_ports fun_clk]` | Creates a primary clock on the `fun_clk` port. `-period 4` means a 4 ns cycle, and `-waveform {0 2}` sets a 50% duty cycle with rising edge at 0 ns and falling edge at 2 ns. | This is the main timing reference for the ASIC top module. All synchronous paths are timed relative to it. |
| `set_input_delay -max 2 -clock [get_clocks fun_clk] [remove_from_collection [all_inputs] [get_ports fun_clk]]` | Tells DC that primary input data can arrive up to 2 ns after the active edge of `fun_clk`. The clock port itself is excluded so it is not treated as data. | Models the delay of the external environment feeding your design. |
| `set_output_delay -max 2 -clock [get_clocks fun_clk] [all_outputs]` | Tells DC that outputs must be valid 2 ns before the next sampling edge of `fun_clk`. | Models the external capture requirement on the receiving block. |
| `set_clock_uncertainty 0.35 [get_clocks]` | Adds 0.35 ns of timing margin on all clocks. DC subtracts this from available setup time and uses it in hold analysis. | Gives margin for jitter, skew, and modeling error. |
| `set_false_path -hold -from [remove_from_collection [all_inputs] [get_ports fun_clk]]` | Removes hold checks from data input ports toward internal logic. | Used when the external launch timing is not meant to be hold-checked against the internal clock. |
| `set_false_path -hold -to [all_outputs]` | Removes hold checks from internal logic to the primary outputs. | Prevents DC from trying to enforce output hold timing that is owned by the next block or board-level interface. |
| `set_case_analysis 0 test_mode` | Forces `test_mode` to logic 0 during synthesis. DC then optimizes the functional path as if scan mode is inactive. | This is important because the top module uses muxes for functional vs scan clock/reset selection. |
| `set_dont_touch_network [get_clocks {fun_clk}]` | Prevents DC from buffering, rewriting, or otherwise optimizing the clock network. | Keeps the clock net stable before CTS or explicit clock-tree work. |
| `set_dont_touch_network [get_ports {fun_rst_n}]` | Prevents optimization on the reset pin network. | Useful when you want the reset connection preserved exactly as a top-level control input. |
| `set_max_transition 0.5 [current_design]` | Limits net slew across the design to 0.5 ns. | Keeps signal edges within a manufacturable and timing-friendly range. |
| `set_max_capacitance 2.0 [current_design]` | Limits the load capacitance seen by nets in the design. | Helps DC avoid weakly driven or overly loaded nets. |

## 3. Commands from the reference flows

These are not active in the current ASIC file, but they show up in the MIPS examples and are commonly used in DC flows.

| Command | What it does in DC | Typical reason to use it |
| --- | --- | --- |
| `set_clock_uncertainty -setup X [get_clocks fun_clk]` | Adds only setup uncertainty. | Useful when you want different setup and hold margins instead of one shared value. |
| `set_clock_uncertainty -hold X [get_clocks fun_clk]` | Adds only hold uncertainty. | Lets you tune hold protection separately from setup protection. |
| `set_max_area 0.0` | Sets a maximum area constraint. In many teaching flows, `0.0` is used as a placeholder or area-minimization style target, so check your lab convention. | Used when the flow wants DC to favor area reduction or to treat area as a controlled constraint. |
| `set_max_fanout 3 $design` | Limits the fanout per driver. | Forces DC to buffer or replicate logic instead of letting a net drive too many loads. |
| `set_input_delay -clock fun_clk -max 0.05 [remove_from_collection [all_inputs] [get_ports {fun_clk scan_clk}]]` | Models a very small external input delay and excludes both clock ports from the data set. | Used in small lab flows where the environment is idealized. |
| `set_output_delay -max 0.05 -clock fun_clk [all_outputs]` | Models a very small output delay budget. | Same idea: a simplified external interface model. |
| `set_driving_cell -lib_cell NBUFFX2 -pin Z [remove_from_collection [all_inputs] [get_ports {fun_clk scan_clk}]]` | Tells DC what cell is driving the inputs, so it can estimate input slew more realistically. | Used when the upstream logic is not ideal and you want better arrival-time modeling. |
| `set_load 1 [all_outputs]` | Adds a capacitive load to outputs. | Makes DC optimize output drivers against a more realistic sink. |
| `set_app_var compile_ultra_ungroup_dw false` | Prevents DC from ungrouping DesignWare blocks during compile. | Keeps DesignWare hierarchy visible and sometimes improves debug or naming. |
| `set_wire_load_model -name ForQA` | Applies a wire-load model for pre-layout estimation. | Useful when there is no physical floorplan yet and DC still needs wire-delay estimates. |
| `set_dont_use [get_lib_cells ...]` | Blocks specific library cells from being used by DC. | Used to avoid weak, undesirable, or non-preferred cells in synthesis. |
| `group_path -name "comp_paths" -to {fun_clk}` | Creates a named timing group for reporting and optimization. | Helps prioritize or report the path group that matters most. |
| `set_max_delay 3 -group_path "comp_paths" -to [all_outputs]` | Places an explicit maximum delay target on the grouped output paths. | Gives DC a direct timing goal for the output cone. |

## 4. Practical meaning for your ASIC top

For your `neural_eq_top` design, the important idea is that DC is being told to treat `fun_clk` as the real functional clock and `test_mode` as always low.

That means:

- the scan clock path is structurally present, but timing is not being optimized for scan mode
- the functional reset is preserved as a top-level control network
- the MAC and pipeline logic is timed against the 4 ns clock budget
- the physical-style limits on transition and capacitance are there to keep the netlist clean for downstream PnR

## 5. Quick interpretation guide

If you are deciding whether a command belongs in your ASIC flow, ask these questions:

- Is it defining the real clock and interface timing? Keep it.
- Is it forcing a mode pin like `test_mode` to one value? Keep it if you only care about functional synthesis.
- Is it a library preference or optimization knob? Keep it only if it matches your target library and flow.
- Is it a lab-only placeholder from a different example? Review it before copying it verbatim.

## 6. Notes

- The current ASIC `cons.tcl` is closer to the simple MIPS-style flow than the more aggressive ref-flow version.
- If you are tracing the flow from the script folder, start with [ASIC/syn/script/syn.tcl](ASIC/syn/script/syn.tcl) and follow the `source ../cons/cons.tcl` line.
- If you want, the next step can be a line-by-line comment version of [ASIC/syn/cons/cons.tcl](ASIC/syn/cons/cons.tcl) itself so each constraint is explained directly in the file.