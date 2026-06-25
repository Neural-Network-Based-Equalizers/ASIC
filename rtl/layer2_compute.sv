// =============================================================================
// Module      : layer2_compute
// Project     : Neural Network Equalizer — ASIC PnR Hardened
// Author      : Hazem Yasser Mahmoud Mohamed
// Description : Layer 2 compute block. 32-neuron ReLU dual-bank MAC layer.
//               All weight and bias memories are accessed through black-box
//               ROM macro instances (defined in rom_macros.sv). No internal
//               $readmemh or simulation-only arrays exist in this file —
//               the module is 100% synthesisable.
//
//               Synchronous 1-cycle read latency:
//                 tick=1 : addr presented to ROM macros
//                 tick=2 : dout valid, accumulation begins
//                 tick=7 : final accumulate + ReLU + output register + fire
// =============================================================================
`timescale 1ns / 1ps
import rom_data_pkg::*;

module layer2_compute (
    input  logic clk, rst_n,
    input  logic valid_in,
    input  logic signed [15:0] l1_out [0:31],
    output logic signed [15:0] l2_out [0:31],
    output logic valid_out
);
    
    logic [2:0] l2_tick;
    logic l2_busy;
    logic signed [15:0] l2_latched_in [0:31];
    logic signed [15:0] l2_out_reg    [0:31];

    // =========================================================================
    // FSM: tick=1 (ROM fetch) -> tick=2..7 (accumulate) -> fire on tick=7
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            l2_tick <= 0; l2_busy <= 0; valid_out <= 0;
        end else begin
            valid_out <= 0;
            if (valid_in && !l2_busy) begin
                l2_busy <= 1; l2_tick <= 1;
                for (int i = 0; i < 32; i++) l2_latched_in[i] <= l1_out[i];
            end else if (l2_busy) begin
                if (l2_tick == 7) begin
                    valid_out <= 1;
                    if (valid_in) begin
                        l2_tick <= 1;
                        for (int i = 0; i < 32; i++) l2_latched_in[i] <= l1_out[i];
                    end else begin
                        l2_busy <= 0;
                    end
                end else begin
                    l2_tick <= l2_tick + 1;
                end
            end
        end
    end

    // =========================================================================
    // Input mux: tick=2 presents group0 (tick=1 is ROM fetch — no accumulate).
    // =========================================================================
    logic signed [15:0] l2a_in1, l2a_in2, l2a_in3;
    logic signed [15:0] l2b_in1, l2b_in2, l2b_in3;
    always_comb begin
        if (l2_busy) begin
            case (l2_tick)
                2: begin {l2a_in1,l2a_in2,l2a_in3}={l2_latched_in[0], l2_latched_in[1], l2_latched_in[2]};  {l2b_in1,l2b_in2,l2b_in3}={l2_latched_in[16],l2_latched_in[17],l2_latched_in[18]}; end
                3: begin {l2a_in1,l2a_in2,l2a_in3}={l2_latched_in[3], l2_latched_in[4], l2_latched_in[5]};  {l2b_in1,l2b_in2,l2b_in3}={l2_latched_in[19],l2_latched_in[20],l2_latched_in[21]}; end
                4: begin {l2a_in1,l2a_in2,l2a_in3}={l2_latched_in[6], l2_latched_in[7], l2_latched_in[8]};  {l2b_in1,l2b_in2,l2b_in3}={l2_latched_in[22],l2_latched_in[23],l2_latched_in[24]}; end
                5: begin {l2a_in1,l2a_in2,l2a_in3}={l2_latched_in[9], l2_latched_in[10],l2_latched_in[11]}; {l2b_in1,l2b_in2,l2b_in3}={l2_latched_in[25],l2_latched_in[26],l2_latched_in[27]}; end
                6: begin {l2a_in1,l2a_in2,l2a_in3}={l2_latched_in[12],l2_latched_in[13],l2_latched_in[14]}; {l2b_in1,l2b_in2,l2b_in3}={l2_latched_in[28],l2_latched_in[29],l2_latched_in[30]}; end
                7: begin {l2a_in1,l2a_in2,l2a_in3}={l2_latched_in[15],16'd0,16'd0};                         {l2b_in1,l2b_in2,l2b_in3}={l2_latched_in[31],16'd0,16'd0};                    end
                default: begin {l2a_in1,l2a_in2,l2a_in3}=48'd0; {l2b_in1,l2b_in2,l2b_in3}=48'd0; end
            endcase
        end else begin
            {l2a_in1,l2a_in2,l2a_in3}=48'd0; {l2b_in1,l2b_in2,l2b_in3}=48'd0;
        end
    end

    // =========================================================================
    // Per-neuron generate: ROM macro instantiation + dual-bank MAC + ReLU
    // =========================================================================
    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : L2_MAC

            // -----------------------------------------------------------------
            // Weight address: local to this neuron's mini-ROM (0..5).
            // Each mini-ROM holds only neuron i's 6 weight words, so the
            // i*6 global offset is gone — addr is simply (tick - 1).
            // -----------------------------------------------------------------
            logic [2:0] w_addr;
            always_comb begin
                if (l2_busy && l2_tick >= 1 && l2_tick <= 6)
                    w_addr = 3'(l2_tick - 1);
                else
                    w_addr = 3'd0;
            end

            // Per-neuron weight mini-ROMs — 6 entries each, explicit case MUX
            logic [47:0] w_bus_a, w_bus_b;
            MINI_W_ROM_6x48 #(
                .ROM_DATA (L2A_W_FLAT[288*(31-i) +: 288])
            ) u_l2a_w_rom (
                .clk  (clk),
                .addr (w_addr),
                .dout (w_bus_a)
            );
            MINI_W_ROM_6x48 #(
                .ROM_DATA (L2B_W_FLAT[288*(31-i) +: 288])
            ) u_l2b_w_rom (
                .clk  (clk),
                .addr (w_addr),
                .dout (w_bus_b)
            );

            // Per-neuron bias mini-ROM — 1 entry, neuron i's bias baked as parameter
            logic signed [15:0] bias_val;
            MINI_b_ROM_1x16 #(
                .ROM_DATA (L2_b_DATA[16*(31-i) +: 16])
            ) u_l2_b_rom (
                .clk  (clk),
                .addr (1'b0),
                .dout (bias_val)
            );

            // Partial products
            logic signed [31:0] p1, p2, p3, p4, p5, p6;
            assign p1 = l2a_in1 * $signed(w_bus_a[47:32]);
            assign p2 = l2a_in2 * $signed(w_bus_a[31:16]);
            assign p3 = l2a_in3 * $signed(w_bus_a[15:0]);
            assign p4 = l2b_in1 * $signed(w_bus_b[47:32]);
            assign p5 = l2b_in2 * $signed(w_bus_b[31:16]);
            assign p6 = l2b_in3 * $signed(w_bus_b[15:0]);

            // Accumulate from tick=2 (tick=1 is the fetch cycle)
            logic signed [39:0] acc;
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    acc <= 0;
                else if (valid_in && !l2_busy)
                    acc <= 0;
                else if (l2_busy && l2_tick == 7 && valid_in)
                    acc <= 0; // Clear for back-to-back next transaction
                else if (l2_busy && l2_tick >= 2)
                    acc <= acc + (p1+p2) + (p3+p4) + (p5+p6);
            end

            // Fire at tick=7
            logic signed [39:0] final_acc;
            logic signed [39:0] tmp;
            logic signed [39:0] tmp_relu;
            assign final_acc = acc + (p1+p2) + (p3+p4) + (p5+p6);
            assign tmp       = (final_acc >>> 14) + bias_val;
            assign tmp_relu  = (tmp < 0) ? 40'sd0 : tmp;

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    l2_out_reg[i] <= 0;
                else if (l2_busy && l2_tick == 7) begin
                    if      (tmp_relu > 32767)  l2_out_reg[i] <= 32767;
                    else if (tmp_relu < -32768) l2_out_reg[i] <= -32768;
                    else                        l2_out_reg[i] <= tmp_relu[15:0];
                end
            end

        end
    endgenerate

    always_comb begin
        for (int o2 = 0; o2 < 32; o2++) l2_out[o2] = l2_out_reg[o2];
    end

endmodule
