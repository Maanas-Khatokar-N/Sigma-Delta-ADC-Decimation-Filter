# Digital Decimation Filter for Sigma-Delta ADC

A multi-stage Digital Decimation Filter implementation for high resolution Delta-Sigma ADC applications, achieving a total decimation factor of 128 through a three-stage topology.

## 📋 Project Overview

This project implements a high-performance decimation filter that processes high-speed, low-resolution modulator bit-streams to produce high-resolution, low-speed PCM output. The architecture uses:

**CIC (R = 16) → FIR (R = 2) → Halfband (2 × 2 = 4)**

Total decimation factor: **Rtotal = 128**

## 📁 Project Structure

### RTL & Testbench Files
- `decimation_filter.v` - Top-level module integrating all filter stages
- `cic_filter.v` - Stage 1: Cascaded Integrator-Comb filter for coarse decimation
- `fir_filter.v` - Stage 2: FIR filter for droop compensation
- `halfband_filter.v` - Stages 3 & 4: Halfband decimation filters
- `tb_decimation_filter.v` - Testbench with clock generation, file I/O, and verification

### Coefficient Files (Memory)
- `fir_coeffs.mem` - Hexadecimal coefficients for Stage 2 FIR filter
- `hb1_coeffs.mem` - Hexadecimal coefficients for Stage 3 Halfband filter
- `hb2_coeffs.mem` - Hexadecimal coefficients for Stage 4 Halfband filter

### Input/Output Simulation Files
- `modulator_output1.txt` - Primary input bitstream from Delta-Sigma Modulator
- `modulator_output2.txt` - Alternative input dataset for testing
- `modulator_output3.txt` - Third input dataset option
- `output_filters.txt` - Filtered PCM output (corresponds to modulator_output1.txt)

### Generated Simulation Files
- `filters.out` - Compiled executable from Icarus Verilog
- `wave_decimation_filter.vcd` - Value Change Dump file for waveform analysis

> **Note:** Generated files correspond to `modulator_output1.txt` input

## 🏗️ Module Hierarchy
```
tb_decimation_filter.v (Testbench)
└── decimation_filter.v (Top-level)
    ├── cic_filter.v (Stage 1)
    ├── fir_filter.v (Stage 2)
    └── halfband_filter.v (Stages 3 & 4)
        ├── u_hb1 (Instance 1)
        └── u_hb2 (Instance 2)
```

## 🔧 Architecture and Data Flow

### Stage 1: CIC Filter (`cic_filter.v`)
**Cascaded Integrator-Comb filter for coarse decimation**
- **Decimation Factor:** R = 16
- **Order:** N = 15
- **Differential Delay:** M = 1
- **Data Flow:** 5-bit Input → 65-bit Output
- **Design:** Multiplier-free architecture with internal width of 65 bits to prevent overflow
- **Width Calculation:** `Width = Input + N × log₂(R × M) = 65 bits`

### Stage 2: FIR Compensation Filter (`fir_filter.v`)
**Corrects CIC droop and provides additional decimation**
- **Decimation Factor:** R = 2
- **Taps:** 26
- **Data Flow:** 65-bit Input → 50-bit Output (Truncated)
- **Architecture:** Parallel Multiply-Accumulate (MAC)

### Stages 3 & 4: Halfband Filters (`halfband_filter.v`)
**Two identical instances for final Nyquist rate decimation**
- **Decimation Factor:** R = 2 (each stage)
- **Taps:** 7
- **Data Flow:** 50-bit Input → 50-bit Output
- **Design:** FSM-based serial operations for area optimization

## 🚀 Simulation Instructions

### Prerequisites
- Icarus Verilog v12.0 or later
- GTKWave Analyzer v3.3.100 or later
- Visual Studio Code (optional)

### Input File Configuration

The testbench defaults to `modulator_output1.txt`. To use alternate inputs:

1. Open `tb_decimation_filter.v`
2. Locate the file read command (around line 88)
3. Update the filename:
```verilog
// Example change:
input_file = $fopen("modulator_output2.txt", "r");
```


### Compilation and Simulation

**1. Compile the design:**
```bash
iverilog -o filters.out *.v
```
Compiles all Verilog source files into `filters.out` executable

**2. Run simulation:**
```bash
vvp ./filters.out
```
Executes the simulation and displays progress, sample counts, and results

**3. View waveforms:**
```bash
gtkwave ./wave_decimation_filter.vcd
```
Opens GTKWave GUI for signal visualization

## 📊 GTKWave Waveform Analysis

### Setup Steps

1. **Navigate Hierarchy:**
   - In the SST panel: `tb_decimation_filter` → `dut`

2. **Add Signals to Viewer:**
   - **Input signals:** `clk`, `in_valid`, `in_data`
   - **Stage 1 output:** `dut.cic_out_valid` (observe 16× rate drop)
   - **Stage 2 output:** `dut.fir_out_valid` (observe 2× rate drop)
   - **Final output:** `out_valid`, `out_data`

3. **Verification:**
   - Confirm `out_valid` asserts once for every 128 `in_valid` pulses
   - Verify decimation behavior at each stage


## 📈 Performance Characteristics

- **Total Decimation Ratio:** 128
- **Input:** 1-bit Delta-Sigma modulator stream
- **Output:** High-resolution PCM samples
- **Throughput:** One output sample per 128 input samples
- **Precision:** 50-bit output data path

