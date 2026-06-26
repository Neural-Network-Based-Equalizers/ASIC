// =============================================================================
// File        : rom_macros.sv
// Project     : Neural Network Equalizer — ASIC Synthesized Logic ROM
// Author      : Hazem Yasser Mahmoud Mohamed
// Description : Synthesizable Mini-ROM primitives for all weight and bias
//               memories in the neural network compute pipeline.
//
//               Architecture: Per-neuron mini-ROMs.
//               Each neuron in the generate loop receives its own dedicated
//               mini-ROM instance whose ROM_DATA parameter is baked at
//               elaboration time from rom_data_pkg.sv. This produces the
//               smallest possible MUX tree and guarantees no block-RAM
//               inference in any synthesis tool (Synopsys DC, Cadence Genus,
//               AMD/Xilinx Vivado).
//
//               CRITICAL SYNTHESIS PROPERTY:
//               Every module uses an explicit case(addr) inside always_ff.
//               The synthesis tool sees a decoded MUX select per address arm,
//               never a dynamically-indexed array access. This prevents all
//               BRAM / SRAM macro inference for these small ROMs.
//
//               Primitives defined here:
//                 MINI_W_ROM_4x48 : 4-entry × 48-bit  (Layer 1 weights)
//                 MINI_W_ROM_6x48 : 6-entry × 48-bit  (Layers 2 & 3 weights)
//                 MINI_b_ROM_1x16 : 1-entry × 16-bit  (all layer biases)
//
//               Interface (all modules):
//                 1-cycle synchronous read:
//                   addr presented at clock T → dout valid at clock T+1
// =============================================================================


// -----------------------------------------------------------------------------
// MINI_W_ROM_4x48
// 4-entry × 48-bit weight ROM — used by Layer 1 (4 MAC cycles per neuron).
//
// ROM_DATA packing (MSB = word 0 = first word fetched):
//   ROM_DATA[191:144] = word 0   (tick=1 fetch → tick=2 accumulate)
//   ROM_DATA[143:96]  = word 1
//   ROM_DATA[95:48]   = word 2
//   ROM_DATA[47:0]    = word 3
// -----------------------------------------------------------------------------
module MINI_W_ROM_4x48 #(
    parameter logic [191:0] ROM_DATA = '0
)(
    input  logic        clk,
    input  logic [1:0]  addr,   // 0 .. 3
    output logic [47:0] dout
);
    always_ff @(posedge clk) begin
        case (addr)
            2'd0: dout <= ROM_DATA[191:144];
            2'd1: dout <= ROM_DATA[143:96];
            2'd2: dout <= ROM_DATA[95:48];
            2'd3: dout <= ROM_DATA[47:0];
            default: dout <= 48'h0;
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// MINI_W_ROM_6x48
// 6-entry × 48-bit weight ROM — used by Layers 2 & 3 (6 MAC cycles per neuron).
//
// ROM_DATA packing (MSB = word 0 = first word fetched):
//   ROM_DATA[287:240] = word 0
//   ROM_DATA[239:192] = word 1
//   ROM_DATA[191:144] = word 2
//   ROM_DATA[143:96]  = word 3
//   ROM_DATA[95:48]   = word 4
//   ROM_DATA[47:0]    = word 5
// -----------------------------------------------------------------------------
module MINI_W_ROM_6x48 #(
    parameter logic [287:0] ROM_DATA = '0
)(
    input  logic        clk,
    input  logic [2:0]  addr,   // 0 .. 5
    output logic [47:0] dout
);
    always_ff @(posedge clk) begin
        case (addr)
            3'd0: dout <= ROM_DATA[287:240];
            3'd1: dout <= ROM_DATA[239:192];
            3'd2: dout <= ROM_DATA[191:144];
            3'd3: dout <= ROM_DATA[143:96];
            3'd4: dout <= ROM_DATA[95:48];
            3'd5: dout <= ROM_DATA[47:0];
            default: dout <= 48'h0;
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// MINI_b_ROM_1x16
// 1-entry × 16-bit bias ROM — one instance per neuron, addr always 0.
// The single entry collapses to a constant register in synthesis.
// Kept as a proper module for structural uniformity with the weight ROMs.
// -----------------------------------------------------------------------------
module MINI_b_ROM_1x16 #(
    parameter logic [15:0] ROM_DATA = '0
)(
    input  logic            clk,
    input  logic [0:0]      addr,   // always 0
    output logic signed [15:0] dout
);
    always_ff @(posedge clk) begin
        case (addr)
            1'd0:    dout <= $signed(ROM_DATA);
            default: dout <= 16'sh0;
        endcase
    end
endmodule
