# Simulator Setup
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Paths relative to Cordic/sim/cocotb/
PDK_CELLS = $(PWD)/sky130

ifeq ($(GLS),1)
    # --- Gate-Level Simulation Mode (make GLS=1) ---
    COMPILE_ARGS += -DFUNCTIONAL -DUSE_POWER_PINS
    
    # SkyWater 130nm cell models from local sky130 folder + top_gl netlist from results/
    VERILOG_SOURCES += $(PDK_CELLS)/primitives.v
    VERILOG_SOURCES += $(PDK_CELLS)/sky130_fd_sc_hd.v
    VERILOG_SOURCES += $(PWD)/../../results/top_gl.v
else
    # --- Standard RTL Simulation Mode (make) ---
    VERILOG_SOURCES += $(PWD)/../../src/top.v
    VERILOG_SOURCES += $(PWD)/../../src/cordic_circular.v
    VERILOG_SOURCES += $(PWD)/../../src/spi_target.v
endif

TOPLEVEL = top
MODULE ?= test_corner_cases

COMPILE_ARGS += -g2005-sv

include $(shell cocotb-config --makefiles)/Makefile.sim

# Phony targets for individual modules and full suite
.PHONY: test_corner_cases test_spi_protocol test_random_sweep test_reset_and_timing test_full_regression

test_corner_cases:
	\((MAKE) clean &&\)(MAKE) MODULE=test_corner_cases

test_spi_protocol:
	\((MAKE) clean &&\)(MAKE) MODULE=test_spi_protocol

test_random_sweep:
	\((MAKE) clean &&\)(MAKE) MODULE=test_random_sweep

test_reset_and_timing:
	\((MAKE) clean &&\)(MAKE) MODULE=test_reset_and_timing

test_full_regression:
	\((MAKE) clean &&\)(MAKE) MODULE=test_full_regression
