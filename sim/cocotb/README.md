Here is the complete, professional `README.md` for your CORDIC verification suite, structured using your project's exact file paths, target modules, and actual test results.

---

# CORDIC — Cocotb Verification Suite

## Setup

```bash
# Navigate to the cocotb test directory
cd CORDIC/sim/cocotb

# Activate Python virtual environment
source ../../.venv/bin/activate

```

---

## Running Tests

### Standard Behavioral RTL Simulation

```bash
# Run a single test module
make clean && make MODULE=test_corner_cases

# Run all test modules in series
for m in test_corner_cases test_spi_protocol test_random_sweep test_reset_and_timing; do
    echo "=== Running \(m ===" && make clean && make MODULE=\)m 2>&1 | tail -5
done

```

### Gate-Level Simulation (GLS)

```bash
# Run a single test module against the synthesized netlist
make clean && make GLS=1 MODULE=test_corner_cases

# Run the full test suite against the synthesized netlist
make clean && make GLS=1 MODULE=test_corner_cases,test_spi_protocol,test_random_sweep,test_reset_and_timing

```

---

## Verification Flows

| Flow | Command | What it uses | Catches |
| --- | --- | --- | --- |
| **RTL Behavioural** | `make MODULE=` | Icarus Verilog (`iverilog`) | Functional logic bugs, fixed-point math precision errors, SPI state machine mismatches |
| **Gate-Level (GLS)** | `make GLS=1 MODULE=` | Icarus Verilog + Sky130 PDK models + Synthesized Netlist | Synthesis translation bugs, unreset flip-flops, structural netlist gate-level timing / X-propagation |

* **RTL Sources Target**: `src/top.v`, `src/cordic_circular.v`, `src/spi_target.v`

* **GLS Netlist Target**: `results/top_gl.v`

* **PDK Cell Library**: `sim/cocotb/sky130/` (`primitives.v`, `sky130_fd_sc_hd.v`)

---

## Test Suite Overview

### Core Functionality & Protocol Suites

| Test | Module File | Description | Status |
| --- | --- | --- | --- |
| **Corner Cases** | `test_corner_cases.py` | Validates cardinal angles ($0^\circ, \pm 90^\circ, \pm 180^\circ$) and boundary bit precision limits ($\pm 1$ LSB). | ✅ PASS |
| **SPI Protocol & Timing** | `test_spi_protocol.py` | Tests mid-word $\text{CS\_N}$ abort recovery, back-to-back frames, and $f_{\text{SCK}} = f_{\text{CLK}} / 40$ timing boundary limits. | ✅ PASS |
| **Randomized Sweep** | `test_random_sweep.py` | Executes 1,000 randomized input angles, validating fixed-point output against floating-point math ($< 0.002$ max error tolerance). | ✅ PASS |
| **Reset & Recovery** | `test_reset_and_timing.py` | Asserts synchronous reset mid-calculation during active 15-iteration CORDIC execution and verifies clean recovery. | ✅ PASS |
| **Full Regression** | `test_full_regression.py` | Continuous multi-frame streaming transaction regression without idle cycles between SPI transfers. | ✅ PASS |

---

## Test Architecture

```text
┌──────────────────────────┐                   ┌────────────────────────────────────────┐
│       Python cocotb      │     SPI Bus       │                 top.v                  │
│   test_*.py / utils.py   │   (i_ss_n,        │             (Verilog DUT)              │
│                          │    i_sck,         │                                        │
│ • Fixed-Point Conversion │    i_mosi,        │  ┌──────────────────────────────────┐  │
│                          │    o_miso)        │  │           spi_target.v           │  │
│ • SPI Master BFM         │◄─────────────────►│  └────────────────┬─────────────────┘  │
│                          │                   │                   │                    │
│ • Error Tolerance Checks │   System Signals  │                   │ w_rx_data          │
│                          │  (i_clk, i_rst_n) │                   ▼                    │
│                          │──────────────────►│  ┌──────────────────────────────────┐  │
│                          │                   │  │         cordic_circular.v        │  │
│                          │                   │  └──────────────────────────────────┘  │
└──────────────────────────┘                   └────────────────────────────────────────┘
             │                                                      │
             ▼                                                      ▼
      Icarus Verilog                                         RTL / GLS Simulation
      (VPI Interface)                                        (0 Errors ASIC Flow)

```

---

## CORDIC Interface & Frame Quick Reference

### Interface Signals

| Signal Name | Direction | Type | Description |
| --- | --- | --- | --- |
| `i_clk` | Input | Wire | Primary system clock (10 MHz nominal) |
| `i_rst_n` | Input | Wire | Active-low synchronous reset |
| `i_ss_n` | Input | Wire | SPI Slave Select (Active Low) |
| `i_sck` | Input | Wire | Asynchronous SPI Serial Clock ($f_{\text{SCK}} \le f_{\text{CLK}} / 40$) |
| `i_mosi` | Input | Wire | SPI Master-Out Slave-In |
| `o_miso` | Output | Wire | SPI Master-In Slave-Out |
| `o_cordic_done` | Output | Wire | 1-cycle flag pulse indicating calculation completion |

### 2-Word SPI Frame Protocol

```text
i_ss_n : \____________________________________________________________________/
         |                Word 0               |                Word 1          |
MOSI   : [ Target Input Angle (Signed 16-bit) ] [   Dummy Data (16-bit 0x0000) ]
MISO   : [ COS Output (From PREVIOUS Frame)   ] [ SIN Output (CURRENT Angle)  ]

```

* **Angle Input Format**: Signed 16-bit integer mapping $[-32768, +32767]$ to $[-180^\circ, +180^\circ]$.
* **Output Format**: Q1.15 signed fixed-point mapping $[-32768, +32767]$ to $[-1.0, +0.999969]$.
