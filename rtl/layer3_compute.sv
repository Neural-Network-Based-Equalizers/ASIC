// =============================================================================
// Module      : layer3_compute
// Project     : Neural Network Equalizer — ASIC PnR Hardened
// Author      : Hazem Yasser Mahmoud Mohamed
// Description : Layer 3 compute block. 2-neuron linear dual-bank MAC layer.
//               All weight and bias memories are accessed through black-box
//               ROM macro instances (defined in rom_macros.sv). No internal
//               $readmemh or simulation-only arrays exist in this file —
//               the module is 100% synthesisable.
//
//               Synchronous 1-cycle read latency:
//                 tick=1 : addr presented to ROM macros
//                 tick=2 : dout valid, accumulation begins
//                 tick=7 : final accumulate + clamp + output register + fire
//               Layer 3 uses linear activation (no ReLU).
// =============================================================================
`timescale 1ns / 1ps
import rom_data_pkg::*;

module layer3_compute (
    input  logic clk, rst_n,
    input  logic valid_in,
    input  logic signed [15:0] l2_out [0:31],
    output logic signed [15:0] l3_out [0:1],
    output logic valid_out
);
    
    logic [2:0] l3_tick;
    logic l3_busy;
    logic signed [15:0] l3_latched_in [0:31];
    logic signed [15:0] l3_out_reg    [0:1];

    // =========================================================================
    // FSM: tick=1 (ROM fetch) -> tick=2..7 (accumulate) -> fire on tick=7
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            l3_tick <= 0; l3_busy <= 0; valid_out <= 0;
        end else begin
            valid_out <= 0;
            if (valid_in && !l3_busy) begin
                l3_busy <= 1; l3_tick <= 1;
                for (int i = 0; i < 32; i++) l3_latched_in[i] <= l2_out[i];
            end else if (l3_busy) begin
                if (l3_tick == 7) begin
                    valid_out <= 1;
                    if (valid_in) begin
                        l3_tick <= 1;
                        for (int i = 0; i < 32; i++) l3_latched_in[i] <= l2_out[i];
                    end else begin
                        l3_busy <= 0;
                    end
                end else begin
                    l3_tick <= l3_tick + 1;
                end
            end
        end
    end

    // =========================================================================
    // Input mux: tick=2 presents group0 (tick=1 is ROM fetch — no accumulate).
    // =========================================================================
    logic signed [15:0] l3a_in1, l3a_in2, l3a_in3;
    logic signed [15:0] l3b_in1, l3b_in2, l3b_in3;
    always_comb begin
        if (l3_busy) begin
            case (l3_tick)
                2: begin {l3a_in1,l3a_in2,l3a_in3}={l3_latched_in[0], l3_latched_in[1], l3_latched_in[2]};  {l3b_in1,l3b_in2,l3b_in3}={l3_latched_in[16],l3_latched_in[17],l3_latched_in[18]}; end
                3: begin {l3a_in1,l3a_in2,l3a_in3}={l3_latched_in[3], l3_latched_in[4], l3_latched_in[5]};  {l3b_in1,l3b_in2,l3b_in3}={l3_latched_in[19],l3_latched_in[20],l3_latched_in[21]}; end
                4: begin {l3a_in1,l3a_in2,l3a_in3}={l3_latched_in[6], l3_latched_in[7], l3_latched_in[8]};  {l3b_in1,l3b_in2,l3b_in3}={l3_latched_in[22],l3_latched_in[23],l3_latched_in[24]}; end
                5: begin {l3a_in1,l3a_in2,l3a_in3}={l3_latched_in[9], l3_latched_in[10],l3_latched_in[11]}; {l3b_in1,l3b_in2,l3b_in3}={l3_latched_in[25],l3_latched_in[26],l3_latched_in[27]}; end
                6: begin {l3a_in1,l3a_in2,l3a_in3}={l3_latched_in[12],l3_latched_in[13],l3_latched_in[14]}; {l3b_in1,l3b_in2,l3b_in3}={l3_latched_in[28],l3_latched_in[29],l3_latched_in[30]}; end
                7: begin {l3a_in1,l3a_in2,l3a_in3}={l3_latched_in[15],16'd0,16'd0};                         {l3b_in1,l3b_in2,l3b_in3}={l3_latched_in[31],16'd0,16'd0};                    end
                default: begin {l3a_in1,l3a_in2,l3a_in3}=48'd0; {l3b_in1,l3b_in2,l3b_in3}=48'd0; end
            endcase
        end else begin
            {l3a_in1,l3a_in2,l3a_in3}=48'd0; {l3b_in1,l3b_in2,l3b_in3}=48'd0;
        end
    end

    // =========================================================================
    // Per-neuron generate: ROM macro instantiation + dual-bank MAC + clamp
    // =========================================================================
    genvar i;
    generate
        for (i = 0; i < 2; i++) begin : L3_MAC

            // -----------------------------------------------------------------
            // Weight address: local to this neuron's mini-ROM (0..5).
            // Each mini-ROM holds only neuron i's 6 weight words, so the
            // i*6 global offset is gone — addr is simply (tick - 1).
            // -----------------------------------------------------------------
            logic [2:0] w_addr;
            always_comb begin
                if (l3_busy && l3_tick >= 1 && l3_tick <= 6)
                    w_addr = 3'(l3_tick - 1);
                else
                    w_addr = 3'd0;
            end

            // Per-neuron weight mini-ROMs — 6 entries each, explicit case MUX
            logic [47:0] w_bus_a, w_bus_b;
            MINI_W_ROM_6x48 #(
                .ROM_DATA (L3A_W_FLAT[288*(1-i) +: 288])
            ) u_l3a_w_rom (
                .clk  (clk),
                .addr (w_addr),
                .dout (w_bus_a)
            );
            MINI_W_ROM_6x48 #(
                .ROM_DATA (L3B_W_FLAT[288*(1-i) +: 288])
            ) u_l3b_w_rom (
                .clk  (clk),
                .addr (w_addr),
                .dout (w_bus_b)
            );

            // Per-neuron bias mini-ROM — 1 entry, neuron i's bias baked as parameter
            // L3_b_DATA is 32-bit (2 × 16-bit); neuron 0 at MSB [31:16]
            logic signed [15:0] bias_val;
            MINI_b_ROM_1x16 #(
                .ROM_DATA (L3_b_DATA[16*(1-i) +: 16])
            ) u_l3_b_rom (
                .clk  (clk),
                .addr (1'b0),
                .dout (bias_val)
            );

            // Partial products
            logic signed [31:0] p1, p2, p3, p4, p5, p6;
            assign p1 = l3a_in1 * $signed(w_bus_a[47:32]);
            assign p2 = l3a_in2 * $signed(w_bus_a[31:16]);
            assign p3 = l3a_in3 * $signed(w_bus_a[15:0]);
            assign p4 = l3b_in1 * $signed(w_bus_b[47:32]);
            assign p5 = l3b_in2 * $signed(w_bus_b[31:16]);
            assign p6 = l3b_in3 * $signed(w_bus_b[15:0]);

            // Accumulate from tick=2 (tick=1 is the fetch cycle)
            logic signed [39:0] acc;
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    acc <= 0;
                else if (valid_in && !l3_busy)
                    acc <= 0;
                else if (l3_busy && l3_tick == 7 && valid_in)
                    acc <= 0; // Clear for back-to-back next transaction
                else if (l3_busy && l3_tick >= 2)
                    acc <= acc + (p1+p2) + (p3+p4) + (p5+p6);
            end

            // Fire at tick=7 — linear activation (no ReLU)
            logic signed [39:0] final_acc;
            logic signed [39:0] tmp;
            assign final_acc = acc + (p1+p2) + (p3+p4) + (p5+p6);
            assign tmp       = (final_acc >>> 14) + bias_val;

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    l3_out_reg[i] <= 0;
                else if (l3_busy && l3_tick == 7) begin
                    if      (tmp > 32767)  l3_out_reg[i] <= 32767;
                    else if (tmp < -32768) l3_out_reg[i] <= -32768;
                    else                   l3_out_reg[i] <= tmp[15:0];
                end
            end

        end
    endgenerate

    always_comb begin
        for (int o3 = 0; o3 < 2; o3++) l3_out[o3] = l3_out_reg[o3];
    end

endmodule
