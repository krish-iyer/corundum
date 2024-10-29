create_ip -name ila -vendor xilinx.com -library ip -module_name ila_reconstream
set_property -dict [list \
			CONFIG.C_PROBE1_WIDTH {64} \
			CONFIG.C_PROBE0_WIDTH {512} \
			CONFIG.C_PROBE5_WIDTH {32} \
			CONFIG.C_PROBE6_WIDTH {32} \
			CONFIG.C_NUM_OF_PROBES {7}
		   ] [get_ips ila_reconstream]
