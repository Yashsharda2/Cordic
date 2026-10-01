# cordic_spi_top constraints, 10 MHz
create_clock -name i_clk -period 100 [get_ports i_clk]
set_clock_uncertainty 0.5 [get_clocks i_clk]

# Reset is treated as synchronous to i_clk (held low for several clocks)
set_input_delay 20 -clock [get_clocks i_clk] [get_ports i_rst_n]

# SPI pins are asynchronous to i_clk: they only feed the 2-FF synchronizers
set_false_path -from [get_ports {i_sck i_ss_n i_mosi}]

# Outputs go to an external master that samples them on its own clock
set_output_delay 20 -clock [get_clocks i_clk] [get_ports {o_miso o_cordic_done}]
set_load 0.05 [all_outputs]
