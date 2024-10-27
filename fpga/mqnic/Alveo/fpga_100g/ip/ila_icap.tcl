create_ip -name ila -vendor xilinx.com -library ip -module_name ila_icap
set_property -dict [list \
			CONFIG.C_PROBE1_WIDTH {64} \
			CONFIG.C_PROBE0_WIDTH {512} \
			CONFIG.C_NUM_OF_PROBES {5}
		   ] [get_ips ila_icap]
