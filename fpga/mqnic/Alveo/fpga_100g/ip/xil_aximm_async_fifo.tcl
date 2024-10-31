create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name xil_aximm_async_fifo
set_property -dict [list \
			CONFIG.synchronization_stages_axi {3} \
			CONFIG.INTERFACE_TYPE {AXI_MEMORY_MAPPED} \
			CONFIG.Reset_Type {Asynchronous_Reset} \
			CONFIG.Clock_Type_AXI {Independent_Clock} \
			CONFIG.DATA_WIDTH {512} \
			CONFIG.FIFO_Implementation_wach {Independent_Clocks_Distributed_RAM} \
			CONFIG.Full_Threshold_Assert_Value_wach {15} \
			CONFIG.Empty_Threshold_Assert_Value_wach {13} \
			CONFIG.FIFO_Implementation_wdch {Independent_Clocks_Builtin_FIFO} \
			CONFIG.Empty_Threshold_Assert_Value_wdch {1018} \
			CONFIG.FIFO_Implementation_wrch {Independent_Clocks_Distributed_RAM} \
			CONFIG.Full_Threshold_Assert_Value_wrch {15} \
			CONFIG.Empty_Threshold_Assert_Value_wrch {13} \
			CONFIG.FIFO_Implementation_rach {Independent_Clocks_Distributed_RAM} \
			CONFIG.Full_Threshold_Assert_Value_rach {15} \
			CONFIG.Empty_Threshold_Assert_Value_rach {13} \
			CONFIG.FIFO_Implementation_rdch {Independent_Clocks_Builtin_FIFO} \
			CONFIG.Empty_Threshold_Assert_Value_rdch {1018} \
			CONFIG.FIFO_Implementation_axis {Independent_Clocks_Builtin_FIFO} \
			CONFIG.Empty_Threshold_Assert_Value_axis {1018}
		   ] [get_ips xil_aximm_async_fifo]
