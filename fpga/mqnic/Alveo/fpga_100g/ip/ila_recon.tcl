create_ip -name ila -vendor xilinx.com -library ip -module_name ila_recon
set_property -dict [list \
			CONFIG.C_PROBE12_WIDTH {34} \
			CONFIG.C_PROBE10_WIDTH {23} \
			CONFIG.C_PROBE8_WIDTH {34} \
			CONFIG.C_PROBE6_WIDTH {23} \
			CONFIG.C_PROBE5_WIDTH {34} \
			CONFIG.C_PROBE3_WIDTH {32} \
			CONFIG.C_PROBE2_WIDTH {8} \
			CONFIG.C_PROBE1_WIDTH {2} \
			CONFIG.C_PROBE0_WIDTH {3} \
			CONFIG.C_NUM_OF_PROBES {14}
		   ] [get_ips ila_recon]
