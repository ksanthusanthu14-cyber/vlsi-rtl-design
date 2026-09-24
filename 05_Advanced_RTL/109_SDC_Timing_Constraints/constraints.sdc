# =========================================================
# PROJECT 109 - SDC TIMING CONSTRAINTS
# =========================================================

# Primary clock
create_clock -name CLK -period 10.0 [get_ports clk]

# Clock uncertainty
set_clock_uncertainty 0.5 [get_clocks CLK]

# Input delay
set_input_delay 2.0 -clock CLK [get_ports data_in]

# Output delay
set_output_delay 2.0 -clock CLK [get_ports data_out]

# Input transition
set_input_transition 0.2 [get_ports data_in]

# Output load
set_load 0.5 [get_ports data_out]