###############################################################################
# Created by write_sdc
# Wed Sep 30 06:32:41 2026
###############################################################################
current_design top
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name i_clk -period 100.0000 [get_ports {i_clk}]
set_clock_uncertainty 0.5000 i_clk
set_propagated_clock [get_clocks {i_clk}]
set_input_delay 20.0000 -clock [get_clocks {i_clk}] -add_delay [get_ports {i_rst_n}]
set_output_delay 20.0000 -clock [get_clocks {i_clk}] -add_delay [get_ports {o_cordic_done}]
set_output_delay 20.0000 -clock [get_clocks {i_clk}] -add_delay [get_ports {o_miso}]
set_false_path\
    -from [list [get_ports {i_mosi}]\
           [get_ports {i_sck}]\
           [get_ports {i_ss_n}]]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.0500 [get_ports {o_cordic_done}]
set_load -pin_load 0.0500 [get_ports {o_miso}]
###############################################################################
# Design Rules
###############################################################################
