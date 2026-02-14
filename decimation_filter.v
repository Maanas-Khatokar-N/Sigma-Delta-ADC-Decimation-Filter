//==============================================================================
// TEAM:          94
//
// FILE NAME:     decimation_filter.v
// MODULE:        decimation_filter (Top-Level Decimation Chain)
//
// DESCRIPTION:
// This is the top-level RTL module for the Digital Decimation Filter. It 
// integrates a multi-stage architecture (CIC + FIR + Halfband) to efficiently 
// downsample the Delta-Sigma Modulator output while filtering high-frequency 
// quantization noise.
//
// ARCHITECTURE & METHODOLOGY:
// 1. Stage 1: CIC Filter (R=16) - Efficiently performs coarse decimation 
//    without hardware multipliers.
// 2. Stage 2: FIR Compensation Filter (R=2) - Corrects the CIC droop and 
//    provides initial stopband attenuation.
// 3. Stage 3 & 4: Halfband Filters (R=2 each) - Efficiently decimates to the 
//    final Nyquist rate with reduced computational complexity.
//
// KEY FEATURES:
// - Total Decimation Factor: 128.
// - High Precision Datapath: Maintains 50-bit internal width to preserve 
//   Signal-to-Noise Ratio (SNR) and support the target ENOB.
//
// INPUT:         Modulator Bit-stream (Multi-bit signed)
// OUTPUT:        High-Resolution, Decimated PCM Data (50-bit signed)
//==============================================================================



module decimation_filter #(
    parameter INPUT_WIDTH = 5,
    parameter CIC_R = 16,
    parameter CIC_N = 15,
    parameter CIC_M = 1,
    parameter CIC_OUTPUT_WIDTH = INPUT_WIDTH + CIC_N * $clog2(CIC_R * CIC_M),
    parameter FIR_COEFF_WIDTH = 18,
    parameter FIR_NUM_TAPS = 26,
    parameter FIR_R = 2,
    parameter FIR_OUTPUT_WIDTH = 50,
    parameter HB_COEFF_WIDTH = 18,
    parameter HB_NUM_TAPS = 7,
    parameter HB_OUTPUT_WIDTH = 50
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          in_valid,
    input  wire signed [INPUT_WIDTH-1:0] in_data,
    output wire                          out_valid,
    output wire signed [HB_OUTPUT_WIDTH-1:0] out_data
);

    // Interconnect signals
    wire cic_out_valid;
    wire signed [CIC_OUTPUT_WIDTH-1:0] cic_out_data;
    
    wire fir_out_valid;
    wire signed [FIR_OUTPUT_WIDTH-1:0] fir_out_data;
    
    wire hb1_out_valid;
    wire signed [HB_OUTPUT_WIDTH-1:0] hb1_out_data;

    //--------------------------------------------------------------------------
    // CIC Decimation Filter Instance
    //--------------------------------------------------------------------------
    cic_filter #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .R(CIC_R),
        .N(CIC_N),
        .M(CIC_M),
        .INTERNAL_WIDTH(CIC_OUTPUT_WIDTH)
    ) u_cic (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .out_valid(cic_out_valid),
        .out_data(cic_out_data)
    );

    //--------------------------------------------------------------------------
    // FIR Compensation Filter Instance
    //--------------------------------------------------------------------------
    fir_filter #(
        .INPUT_WIDTH(CIC_OUTPUT_WIDTH),
        .COEFF_WIDTH(FIR_COEFF_WIDTH),
        .NUM_TAPS(FIR_NUM_TAPS),
        .R(FIR_R),
        .OUTPUT_WIDTH(FIR_OUTPUT_WIDTH)
    ) u_fir (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(cic_out_valid),
        .in_data(cic_out_data),
        .out_valid(fir_out_valid),
        .out_data(fir_out_data)
    );

    //--------------------------------------------------------------------------
    // First Halfband Filter Instance
    //--------------------------------------------------------------------------
    halfband_filter #(
        .INPUT_WIDTH(FIR_OUTPUT_WIDTH),
        .COEFF_WIDTH(HB_COEFF_WIDTH),
        .NUM_TAPS(HB_NUM_TAPS),
        .OUTPUT_WIDTH(HB_OUTPUT_WIDTH),
        .COEFF_FILE("hb1_coeffs.mem")
    ) u_hb1 (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(fir_out_valid),
        .in_data(fir_out_data),
        .out_valid(hb1_out_valid),
        .out_data(hb1_out_data)
    );

    //--------------------------------------------------------------------------
    // Second Halfband Filter Instance
    //--------------------------------------------------------------------------
    halfband_filter #(
        .INPUT_WIDTH(HB_OUTPUT_WIDTH),
        .COEFF_WIDTH(HB_COEFF_WIDTH),
        .NUM_TAPS(HB_NUM_TAPS),
        .OUTPUT_WIDTH(HB_OUTPUT_WIDTH),
        .COEFF_FILE("hb2_coeffs.mem")
    ) u_hb2 (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(hb1_out_valid),
        .in_data(hb1_out_data),
        .out_valid(out_valid),
        .out_data(out_data)
    );

endmodule