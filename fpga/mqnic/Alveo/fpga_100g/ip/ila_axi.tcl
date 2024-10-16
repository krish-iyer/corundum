create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_axi                                                                                                                                                                                            
set_property -dict [list \
			CONFIG.C_NUM_OF_PROBES {44} \
			CONFIG.Component_Name {ila_axi} \
			CONFIG.C_SLOT_0_AXI_ID_WIDTH {8} \
			CONFIG.C_SLOT_0_AXI_DATA_WIDTH {512} \
			CONFIG.C_SLOT_0_AXI_ADDR_WIDTH {34} \
			CONFIG.C_ENABLE_ILA_AXI_MON {true} \
			CONFIG.C_MONITOR_TYPE {AXI}
		   ] [get_ips ila_axi]
