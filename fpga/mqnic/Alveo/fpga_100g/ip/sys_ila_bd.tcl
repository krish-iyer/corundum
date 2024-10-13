create_bd_design "sys_ila_bd"
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_0
endgroup
set_property location {1 66 -162} [get_bd_cells system_ila_0]
copy_bd_objs /  [get_bd_cells {system_ila_0}]
copy_bd_objs /  [get_bd_cells {system_ila_0}]
set_property -dict [list \
			CONFIG.C_SLOT_0_AXI_ID_WIDTH.VALUE_SRC PROPAGATED \
			CONFIG.C_SLOT_0_AXI_DATA_WIDTH.VALUE_SRC USER \
			CONFIG.C_SLOT_0_AXIS_TDATA_WIDTH.VALUE_SRC USER \
			CONFIG.C_SLOT_1_AXI_ID_WIDTH.VALUE_SRC PROPAGATED \
			CONFIG.C_SLOT_1_AXI_DATA_WIDTH.VALUE_SRC USER \
			CONFIG.C_SLOT_1_AXIS_TDATA_WIDTH.VALUE_SRC USER \
			CONFIG.C_SLOT_2_AXI_DATA_WIDTH.VALUE_SRC USER \
			CONFIG.C_SLOT_2_AXIS_TDATA_WIDTH.VALUE_SRC USER \
			CONFIG.C_SLOT_2_AXIS_TDEST_WIDTH.VALUE_SRC USER \
			CONFIG.C_SLOT_3_AXI_DATA_WIDTH.VALUE_SRC USER \
			CONFIG.C_SLOT_3_AXIS_TDATA_WIDTH.VALUE_SRC USER
		   ] [get_bd_cells system_ila_0]

set_property -dict [list \
			CONFIG.C_SLOT {3} \
			CONFIG.C_BRAM_CNT {57.5} \
			CONFIG.C_NUM_MONITOR_SLOTS {4} \
			CONFIG.C_SLOT_0_AXIS_TDATA_WIDTH {512} \
			CONFIG.C_SLOT_1_AXIS_TDATA_WIDTH {512} \
			CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
			CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
			CONFIG.C_SLOT_2_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
			CONFIG.C_SLOT_3_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
			CONFIG.C_SLOT_2_AXIS_TDATA_WIDTH {512} \
			CONFIG.C_SLOT_2_AXIS_TDEST_WIDTH {2} \
			CONFIG.C_SLOT_3_AXIS_TDATA_WIDTH {512}
		   ] [get_bd_cells system_ila_0]

set_property -dict [list \
			CONFIG.C_SLOT_0_AXI_DATA_WIDTH.VALUE_SRC USER \
			CONFIG.C_SLOT_0_AXI_ADDR_WIDTH.VALUE_SRC USER
		   ] [get_bd_cells system_ila_2]

set_property -dict [list \
			CONFIG.C_BRAM_CNT {34.5} \
			CONFIG.C_SLOT_0_AXI_DATA_WIDTH {512} \
			CONFIG.C_SLOT_0_AXI_ADDR_WIDTH {34}
		   ] [get_bd_cells system_ila_2]

set_property -dict [list \
			CONFIG.C_SLOT_0_AXI_DATA_WIDTH.VALUE_SRC USER \
			CONFIG.C_SLOT_0_AXI_ADDR_WIDTH.VALUE_SRC USER
		   ] [get_bd_cells system_ila_1]

set_property -dict [list \
			CONFIG.C_BRAM_CNT {34.5} \
			CONFIG.C_SLOT_0_AXI_DATA_WIDTH {512} \
			CONFIG.C_SLOT_0_AXI_ADDR_WIDTH {32}
		   ] [get_bd_cells system_ila_1]

create_bd_intf_port -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_async_dma_ddr
connect_bd_intf_net [get_bd_intf_ports m_axi_async_dma_ddr] [get_bd_intf_pins system_ila_1/SLOT_0_AXI]
create_bd_port -dir I -type clk -freq_hz 250000000 clk
connect_bd_net [get_bd_ports clk] [get_bd_pins system_ila_1/clk]
startgroup
create_bd_port -dir I -type rst rst
endgroup
connect_bd_net [get_bd_ports rst] [get_bd_pins system_ila_1/resetn]
create_bd_intf_port -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_ddr
create_bd_port -dir I -type clk -freq_hz 332000000 ddr_clk
startgroup
create_bd_port -dir I -type rst ddr_rst
endgroup
connect_bd_net [get_bd_ports ddr_rst] [get_bd_pins system_ila_2/resetn]
connect_bd_net [get_bd_ports ddr_clk] [get_bd_pins system_ila_2/clk]
connect_bd_intf_net [get_bd_intf_ports m_axi_ddr] [get_bd_intf_pins system_ila_2/SLOT_0_AXI]
create_bd_intf_port -mode Monitor -vlnv xilinx.com:interface:axis_rtl:1.0 recon_s_axis
create_bd_intf_port -mode Monitor -vlnv xilinx.com:interface:axis_rtl:1.0 icap_s_axis
create_bd_intf_port -mode Monitor -vlnv xilinx.com:interface:axis_rtl:1.0 rmt_s_axis
create_bd_intf_port -mode Monitor -vlnv xilinx.com:interface:axis_rtl:1.0 tap_s_axis
connect_bd_intf_net [get_bd_intf_ports tap_s_axis] [get_bd_intf_pins system_ila_0/SLOT_3_AXIS]
connect_bd_intf_net [get_bd_intf_ports rmt_s_axis] [get_bd_intf_pins system_ila_0/SLOT_2_AXIS]
connect_bd_intf_net [get_bd_intf_ports icap_s_axis] [get_bd_intf_pins system_ila_0/SLOT_1_AXIS]
connect_bd_intf_net [get_bd_intf_ports recon_s_axis] [get_bd_intf_pins system_ila_0/SLOT_0_AXIS]
connect_bd_net [get_bd_ports clk] [get_bd_pins system_ila_0/clk]
connect_bd_net [get_bd_ports rst] [get_bd_pins system_ila_0/resetn]
set_property -dict [list \
			CONFIG.CLK_DOMAIN {clk} \
			CONFIG.FREQ_HZ {250000000} \
			CONFIG.HAS_TLAST {1} \
			CONFIG.HAS_TKEEP {1} \
			CONFIG.TDEST_WIDTH {2} \
			CONFIG.TDATA_NUM_BYTES {64}
		   ] [get_bd_intf_ports rmt_s_axis]

set_property -dict [list \
			CONFIG.CLK_DOMAIN {clk} \
			CONFIG.FREQ_HZ {250000000} \
			CONFIG.HAS_TLAST {1} \
			CONFIG.HAS_TKEEP {1} \
			CONFIG.TDATA_NUM_BYTES {64}
		   ] [get_bd_intf_ports recon_s_axis]

set_property -dict [list \
			CONFIG.CLK_DOMAIN {clk} \
			CONFIG.FREQ_HZ {250000000} \
			CONFIG.HAS_TLAST {1} \
			CONFIG.HAS_TKEEP {1} \
			CONFIG.TDATA_NUM_BYTES {64}
		   ] [get_bd_intf_ports icap_s_axis]

set_property -dict [list \
			CONFIG.CLK_DOMAIN {clk} \
			CONFIG.FREQ_HZ {250000000} \
			CONFIG.HAS_TLAST {1} \
			CONFIG.HAS_TKEEP {1} \
			CONFIG.TDATA_NUM_BYTES {64}
		   ] [get_bd_intf_ports tap_s_axis]


set_property -dict [list \
			CONFIG.CLK_DOMAIN {ddr_clk} \
			CONFIG.ADDR_WIDTH {34} \
			CONFIG.FREQ_HZ {332000000} \
			CONFIG.DATA_WIDTH {512}
		   ] [get_bd_intf_ports m_axi_ddr]

set_property -dict [list \
			CONFIG.CLK_DOMAIN {clk} \
			CONFIG.FREQ_HZ {250000000} \
			CONFIG.DATA_WIDTH {512}
		   ] [get_bd_intf_ports m_axi_async_dma_ddr]

save_bd_design
