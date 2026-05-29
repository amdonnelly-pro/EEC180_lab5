create_clock -name board_clock -period 20.000 [get_ports MAX10_CLK1_50]
derive_clock_uncertainty
