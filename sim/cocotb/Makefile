# Simulator Setup
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Paths to RTL relative to ASIC/sim/cocotb/
VERILOG_SOURCES += $(PWD)/../../src/top.v
VERILOG_SOURCES += $(PWD)/../../src/cordic_circular.v
VERILOG_SOURCES += $(PWD)/../../src/spi_target.v

TOPLEVEL = top

# Default test module if none specified on CLI
MODULE ?= test_corner_cases

COMPILE_ARGS += -g2005-sv

include $(shell cocotb-config --makefiles)/Makefile.sim

# Phony targets for individual modules and full suite
.PHONY: test_corner_cases test_spi_protocol test_random_sweep test_reset_and_timing test_full_regression test-all

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

