// =============================================================================
// Module      : layer1_compute
// Project     : Neural Network Equalizer — ASIC PnR Hardened
// Author      : Hazem Yasser Mahmoud Mohamed
// Description : Layer 1 compute block. 32-neuron ReLU MAC layer.
//               All weight and bias memories are accessed through black-box
//               ROM macro instances (defined in rom_macros.sv). No internal
//               $readmemh or simulation-only arrays exist in this file —
//               the module is 100% synthesisable.
//
//               Synchronous 1-cycle read latency:
//                 tick=1 : addr presented to ROM macro
//                 tick=2 : dout valid, accumulation begins
//                 tick=5 : final accumulate + ReLU + output register + fire
// =============================================================================

import rom_data_pkg::*;

module layer1_compute (
    input  logic clk, rst_n,
    input  logic valid_in,
    input  logic signed [15:0] win_I [0:4],
    input  logic signed [15:0] win_Q [0:4],
    output logic signed [15:0] l1_out [0:31],
    output logic valid_out
);
    
    logic signed [15:0] l1_latched_I [0:4];
    logic signed [15:0] l1_latched_Q [0:4];
    logic [2:0] l1_tick;
    logic l1_busy;

    // =========================================================================
    // FSM: tick=1 (ROM fetch) -> tick=2 (multiply) -> tick=3..6 (accumulate) -> fire on tick=7
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            l1_tick <= 0; l1_busy <= 0; valid_out <= 0;
        end else begin
            valid_out <= 0;
            if (valid_in && !l1_busy) begin
                l1_busy <= 1; l1_tick <= 1;
                for (int i = 0; i < 5; i++) begin
                    l1_latched_I[i] <= win_I[i];
                    l1_latched_Q[i] <= win_Q[i];
                end
            end else if (l1_busy) begin
                if (l1_tick == 7) begin
                    l1_busy <= 0; valid_out <= 1;
                end else begin
                    l1_tick <= l1_tick + 1;
                end
            end
        end
    end

    // =========================================================================
    // Input mux: tick=2 presents group0 (tick=1 is ROM fetch — no accumulate).
    // =========================================================================
    logic signed [15:0] l1_in1, l1_in2, l1_in3;
    always_comb begin
        case (l1_tick)
            2: {l1_in1, l1_in2, l1_in3} = {l1_latched_I[0], l1_latched_I[1], l1_latched_I[2]};
            3: {l1_in1, l1_in2, l1_in3} = {l1_latched_I[3], l1_latched_I[4], l1_latched_Q[0]};
            4: {l1_in1, l1_in2, l1_in3} = {l1_latched_Q[1], l1_latched_Q[2], l1_latched_Q[3]};
            5: {l1_in1, l1_in2, l1_in3} = {l1_latched_Q[4], 16'sd0, 16'sd0};
            default: {l1_in1, l1_in2, l1_in3} = 48'd0;
        endcase
    end

    // =========================================================================
    // Per-neuron generate: ROM macro instantiation + MAC + ReLU output
    // =========================================================================
    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : L1_MAC

            // -----------------------------------------------------------------
            // Weight address: local to this neuron's mini-ROM (0..3).
            // Each mini-ROM holds only neuron i's 4 weight words, so the
            // i*4 global offset is gone — addr is simply (tick - 1).
            // -----------------------------------------------------------------
            logic [1:0] w_addr;
            always_comb begin
                if (l1_busy && l1_tick >= 1 && l1_tick <= 4)
                    w_addr = 2'(l1_tick - 1);
                else
                    w_addr = 2'd0;
            end

            // Per-neuron weight mini-ROM — 4 entries, explicit case MUX, no BRAM
            logic [47:0] w_bus_sync;
            MINI_W_ROM_4x48 #(
                .ROM_DATA (L1_W_FLAT[192*(31-i) +: 192])
            ) u_l1_w_rom (
                .clk  (clk),
                .addr (w_addr),
                .dout (w_bus_sync)
            );

            // Per-neuron bias mini-ROM — 1 entry, neuron i's bias baked as parameter
            logic signed [15:0] bias_val;
            MINI_b_ROM_1x16 #(
                .ROM_DATA (L1_b_DATA[16*(31-i) +: 16])
            ) u_l1_b_rom (
                .clk  (clk),
                .addr (1'b0),
                .dout (bias_val)
            );

            // Partial products (weight packing: [47:32]=w0, [31:16]=w1, [15:0]=w2)
            logic signed [31:0] p1, p2, p3;
            assign p1 = l1_in1 * $signed(w_bus_sync[47:32]);
            assign p2 = l1_in2 * $signed(w_bus_sync[31:16]);
            assign p3 = l1_in3 * $signed(w_bus_sync[15:0]);

            // Register partial products to break critical path
            logic signed [31:0] p1_reg, p2_reg, p3_reg;
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    p1_reg <= 0; p2_reg <= 0; p3_reg <= 0;
                end else if (l1_busy) begin
                    p1_reg <= p1; p2_reg <= p2; p3_reg <= p3;
                end
            end

            // Accumulate from tick=3 (tick=1 fetch, tick=2 multiply, tick=3 accumulate)
            logic signed [39:0] acc;
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    acc <= 0;
                else if (valid_in && !l1_busy)
                    acc <= 0;
                else if (l1_busy && l1_tick >= 3 && l1_tick <= 6)
                    acc <= (p1_reg + p2_reg) + (p3_reg + acc);
            end

            // Fire at tick=7: acc holds groups 0..3 sum
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    l1_out[i] <= 0;
                end else if (l1_busy && l1_tick == 7) begin
                    logic signed [39:0] tmp;
                    tmp = (acc >>> 14) + bias_val;
                    if (tmp < 0) tmp = 0; // ReLU
                    if      (tmp > 32767)  l1_out[i] <= 32767;
                    else if (tmp < -32768) l1_out[i] <= -32768;
                    else                   l1_out[i] <= tmp[15:0];
                end
            end

        end
    endgenerate

endmodule
