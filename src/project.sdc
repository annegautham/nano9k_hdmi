// This tells the tool the serial clock is 126MHz
create_generated_clock -name ser_clk -source [get_nets {u_clkdiv/HCLKIN}] -divide_by 4 [get_pins {u_clkdiv/CLKOUT}]