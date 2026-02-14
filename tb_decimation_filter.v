//==============================================================================
// TEAM:          94
//
// FILE NAME:     tb_top_final.v
// MODULE:        tb_top_final (Testbench)
//
// DESCRIPTION:
// This testbench verifies the Register Transfer Level (RTL) implementation of 
// the Digital Decimation Filter chain designed for a Delta-Sigma ADC.
//
// KEY OBJECTIVES VERIFIED:
// 1. Decimation Strategy: Validates the multi-stage downsampling architecture 
//    (CIC + FIR + Halfband) required to convert high-speed modulated 
//    input into high-resolution output.
// 2. Resolution Support: Verifies data path widths (up to 50-bit) to support 
//    target ENOB and minimize quantization noise.
// 3. Sampling Rate: Confirms correct decimation factors to achieve the target 
//    Nyquist sampling rates (0.5 ksps - 2 ksps).
//
// INPUT:         Bit-stream from Delta-Sigma Modulator (input_stream5.txt)
// OUTPUT:        Decimated, filtered high-precision samples (output_filters.txt)
//==============================================================================


module tb_decimation_filter;

    parameter INPUT_WIDTH = 5;
    parameter FIR_OUTPUT_WIDTH = 50;
    parameter CLK_PERIOD = 10;

    reg                          clk;
    reg                          rst_n;
    reg                          in_valid;
    reg signed [INPUT_WIDTH-1:0] in_data;
    wire                         out_valid;
    wire signed [FIR_OUTPUT_WIDTH-1:0] out_data;

    integer input_file;
    integer output_file;
    integer scan_result;
    integer input_sample;
    integer sample_count;
    integer output_count;

    decimation_filter #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .CIC_R(16),
        .CIC_N(15),
        .CIC_M(1),
        .FIR_COEFF_WIDTH(18),
        .FIR_NUM_TAPS(26),
        .FIR_R(2),
        .FIR_OUTPUT_WIDTH(FIR_OUTPUT_WIDTH),
        .HB_COEFF_WIDTH(18),
        .HB_NUM_TAPS(7),
        .HB_OUTPUT_WIDTH(50)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .out_valid(out_valid),
        .out_data(out_data)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Output Capture
    always @(posedge clk) begin
        if (out_valid) begin
            $fwrite(output_file, "%d\n", out_data);
            output_count = output_count + 1;
        end
    end

    // Main Test
    initial begin
        rst_n = 0;
        in_valid = 0;
        in_data = 0;
        sample_count = 0;
        output_count = 0;

        input_file = $fopen("modulator_output1.txt", "r");
        if (input_file == 0) begin
            $display("ERROR: Could not open input txt file");
            $finish;
        end

        output_file = $fopen("output_filters.txt", "w");
        if (output_file == 0) begin
            $display("ERROR: Could not open output txt file");
            $fclose(input_file);
            $finish;
        end

        $display("========================================");
        $display("Started Simulation...");
        $display("========================================");

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        while (!$feof(input_file)) begin
            scan_result = $fscanf(input_file, "%d\n", input_sample);
            
            if (scan_result == 1) begin
                @(posedge clk);
                #1;
                in_valid = 1;
                in_data = input_sample;
                sample_count = sample_count + 1;
                
            end
        end

        @(posedge clk);
        #1;
        in_valid = 0;

        $display("========================================");
        $display("Waiting for pipeline to flush...");
        repeat(100) @(posedge clk);

        $fclose(input_file);
        $fclose(output_file);

        $display("========================================");
        $display("Test Complete!");
        $display("Total input samples: %0d", sample_count);
        $display("Total output samples: %0d", output_count);
        $display("Expected decimation: 128 (16*2*2*2)");
        $display("Actual decimation: %0f", sample_count / (output_count * 1.0));
        $display("Output written to: output_filters.txt");
        $display("========================================");

        $finish;
    end

    initial begin
        #(CLK_PERIOD * 1000000);
        $display("ERROR: Simulation timeout!");
        $finish;
    end

    initial begin
        $dumpfile("wave_decimation_filter.vcd");
        $dumpvars(0, tb_decimation_filter);
    end

endmodule