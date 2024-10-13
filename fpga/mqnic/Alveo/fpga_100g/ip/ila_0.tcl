create_ip -name ila -vendor xilinx.com -library ip -module_name ila_0
set_property -dict [list \
			CONFIG.C_PROBE3_WIDTH {2} \
			CONFIG.C_PROBE2_WIDTH {16} \
			CONFIG.C_PROBE1_WIDTH {16} \
			CONFIG.C_PROBE0_WIDTH {16} \
			CONFIG.C_NUM_OF_PROBES {10}
		   ] [get_ips ila_0]
