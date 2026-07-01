# Neural Network Equalizer — ASIC Implementation

This repository contains the complete, automated RTL-to-GDSII physical design and verification flow for the **Neural Network Equalizer (`neural_eq_top`)**, an Application-Specific Integrated Circuit (ASIC) designed for complex baseband signal processing. 

The implementation targets the **Nangate FreePDK 45nm** process node and was executed using an industry-standard Synopsys EDA toolchain: Design Compiler (Synthesis), IC Compiler II (PnR), PrimeTime (STA), and StarRC (Extraction).

## Design Architecture & Optimizations

The `neural_eq_top` module is a 16-bit fixed-point feed-forward Multi-Layer Perceptron (MLP). It processes incoming I/Q symbols through a 4-stage pipeline:
1. `input_window_ctrl`: A 5-sample sliding window shift register.
2. `layer1_compute`: 32-neuron ReLU MAC array (7-tick pipeline).
3. `layer2_compute`: 32-neuron ReLU MAC array (9-tick pipeline).
4. `layer3_compute`: 2-neuron linear MAC array (9-tick pipeline).

To achieve the strict **200 MHz (5.0 ns)** timing target while minimizing silicon footprint, three major RTL-level hardware optimizations were utilized prior to physical synthesis:
* **Per-Neuron Mini-ROMs:** Instead of relying on standard SRAM macros, weights are "baked" into per-neuron synthesized Mini-ROMs using explicit `case` statements. The synthesis engine maps these to shallow combinational MUX trees, cutting the critical path depth by 66%.
* **Critical Path Pipelining:** Explicit pipeline registers separate the multiply and accumulate stages, isolating the 32-bit product generation from the 40-bit accumulation.
* **FSM Time-Multiplexing:** A tick-based finite state machine sequences the datapath, reusing 96 multipliers across consecutive clock cycles rather than instantiating 320 parallel multipliers. This yields a ~3x area reduction.

## Implementation Metrics & Final Results

The design successfully passed all physical and timing signoff checks with the following tape-out ready metrics:

| Metric | Achieved Value |
| :--- | :--- |
| **Process Technology** | Nangate FreePDK 45nm (1P10M) |
| **Target Clock** | 200 MHz (5.0 ns) |
| **Die Area** | 3.43 mm² (1.854 mm × 1.854 mm) |
| **Cell Utilization** | 24% (265,384 functional standard cells) |
| **Total Flip-Flops** | 14,745 |
| **Routed Wirelength** | 10.21 km |
| **Total Vias** | 2,171,630 (95.93% redundant via coverage) |
| **Clock Skew** | 0.20 ns |
| **Setup / Hold Slack** | +0.25 ns / +0.16 ns (PrimeTime Signoff) |
| **DRC / LVS Violations** | 0 / 0 |

## Directory Structure & Flow

The flow is strictly sequential and divided into the following environments:
* **`rtl/`**: Golden SystemVerilog source code.
* **`syn/`**: Logic Synthesis (Synopsys Design Compiler).
* **`pnr/`**: Physical Design (Synopsys IC Compiler II). Subdivided into 10 numbered stages: `1_ndm`, `2_design_library`, `3_floorplan`, `4_powerplan`, `5_placement`, `6_cts`, `7_routing`, `8_timing_analysis`, `9_finish`, and `10_eco`.
* **`qor/`**: Quality of Results. Contains Parasitic Extraction (`rcxt` / StarRC) and Static Timing Analysis (`sta` / PrimeTime).
* **`dft/` & `formality/`**: Design for Test and Logic Equivalence Checking.
* **`standard_cell_libraries/`**: Nangate 45nm PDK and Liberty timing databases.

### The ECO Signoff Cycle
During final signoff, an Engineering Change Order (ECO) loop is utilized to surgically repair localized hold-time and DRC violations without perturbing the global routing legality. The cycle loops from Extraction (StarRC) → STA & Fix Calculation (PrimeTime) → Back-Annotation & Legalization (ICC2).

![ASIC ECO Cycle](ASIC_ECO_Cycle_Textbook.svg)

## Note on Version Control (.gitignore)

Due to the massive size of EDA tool databases (NDMs), layouts (GDSII, DEF), extraction parasitics (SPEF), and run logs, this repository relies on an aggressive `.gitignore`. Only the driving Tcl scripts, RTL, constraints (SDC), and essential documentation are tracked. To reproduce the results, the flow must be executed locally on a machine with the appropriate Synopsys licenses and Nangate 45nm PDK.
