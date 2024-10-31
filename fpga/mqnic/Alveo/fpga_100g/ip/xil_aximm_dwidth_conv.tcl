create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -module_name xil_aximm_dwidth_conv
set_property -dict [list \
			CONFIG.SI_DATA_WIDTH {512} \
			CONFIG.MI_DATA_WIDTH {256} \
			CONFIG.MAX_SPLIT_BEATS {16}
		   ] [get_ips xil_aximm_dwidth_conv]
