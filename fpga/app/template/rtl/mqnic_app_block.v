// SPDX-License-Identifier: BSD-2-Clause-Views
/*
 * Copyright (c) 2021-2023 The Regents of the University of California
 */

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Application block
 */
module mqnic_app_block #
(
    // Structural configuration
    parameter IF_COUNT = 1,
    parameter PORTS_PER_IF = 1,
    parameter SCHED_PER_IF = PORTS_PER_IF,

    parameter PORT_COUNT = IF_COUNT*PORTS_PER_IF,

    // Clock configuration
    parameter CLK_PERIOD_NS_NUM = 4,
    parameter CLK_PERIOD_NS_DENOM = 1,

    // PTP configuration
    parameter PTP_CLK_PERIOD_NS_NUM = 4,
    parameter PTP_CLK_PERIOD_NS_DENOM = 1,
    parameter PTP_TS_WIDTH = 96,
    parameter PTP_PORT_CDC_PIPELINE = 0,
    parameter PTP_PEROUT_ENABLE = 0,
    parameter PTP_PEROUT_COUNT = 1,

    // Interface configuration
    parameter PTP_TS_ENABLE = 1,
    parameter TX_TAG_WIDTH = 16,
    parameter MAX_TX_SIZE = 9214,
    parameter MAX_RX_SIZE = 9214,

    // RAM configuration
    parameter DDR_CH = 1,
    parameter DDR_ENABLE = 1,
    parameter DDR_GROUP_SIZE = 1,
    parameter AXI_DDR_DATA_WIDTH = 512,
    parameter AXI_DDR_ADDR_WIDTH = 34,
    parameter AXI_DDR_STRB_WIDTH = (AXI_DDR_DATA_WIDTH/8),
    parameter AXI_DDR_ID_WIDTH = 8,
    parameter AXI_DDR_AWUSER_ENABLE = 0,
    parameter AXI_DDR_AWUSER_WIDTH = 1,
    parameter AXI_DDR_WUSER_ENABLE = 0,
    parameter AXI_DDR_WUSER_WIDTH = 1,
    parameter AXI_DDR_BUSER_ENABLE = 0,
    parameter AXI_DDR_BUSER_WIDTH = 1,
    parameter AXI_DDR_ARUSER_ENABLE = 0,
    parameter AXI_DDR_ARUSER_WIDTH = 1,
    parameter AXI_DDR_RUSER_ENABLE = 0,
    parameter AXI_DDR_RUSER_WIDTH = 1,
    parameter AXI_DDR_MAX_BURST_LEN = 256,
    parameter AXI_DDR_NARROW_BURST = 0,
    parameter AXI_DDR_FIXED_BURST = 0,
    parameter AXI_DDR_WRAP_BURST = 0,
    parameter HBM_CH = 1,
    parameter HBM_ENABLE = 0,
    parameter HBM_GROUP_SIZE = 1,
    parameter AXI_HBM_DATA_WIDTH = 256,
    parameter AXI_HBM_ADDR_WIDTH = 32,
    parameter AXI_HBM_STRB_WIDTH = (AXI_HBM_DATA_WIDTH/8),
    parameter AXI_HBM_ID_WIDTH = 8,
    parameter AXI_HBM_AWUSER_ENABLE = 0,
    parameter AXI_HBM_AWUSER_WIDTH = 1,
    parameter AXI_HBM_WUSER_ENABLE = 0,
    parameter AXI_HBM_WUSER_WIDTH = 1,
    parameter AXI_HBM_BUSER_ENABLE = 0,
    parameter AXI_HBM_BUSER_WIDTH = 1,
    parameter AXI_HBM_ARUSER_ENABLE = 0,
    parameter AXI_HBM_ARUSER_WIDTH = 1,
    parameter AXI_HBM_RUSER_ENABLE = 0,
    parameter AXI_HBM_RUSER_WIDTH = 1,
    parameter AXI_HBM_MAX_BURST_LEN = 256,
    parameter AXI_HBM_NARROW_BURST = 0,
    parameter AXI_HBM_FIXED_BURST = 0,
    parameter AXI_HBM_WRAP_BURST = 0,

    // Application configuration
    parameter APP_ID = 32'h12340001,
    parameter APP_CTRL_ENABLE = 1,
    parameter APP_DMA_ENABLE = 1,
    parameter APP_AXIS_DIRECT_ENABLE = 1,
    parameter APP_AXIS_SYNC_ENABLE = 1,
    parameter APP_AXIS_IF_ENABLE = 1,
    parameter APP_STAT_ENABLE = 1,
    parameter APP_GPIO_IN_WIDTH = 32,
    parameter APP_GPIO_OUT_WIDTH = 32,

    // DMA interface configuration
    parameter DMA_ADDR_WIDTH = 64,
    parameter DMA_IMM_ENABLE = 0,
    parameter DMA_IMM_WIDTH = 32,
    parameter DMA_LEN_WIDTH = 16,
    parameter DMA_TAG_WIDTH = 16,
    parameter RAM_SEL_WIDTH = 4,
    parameter RAM_ADDR_WIDTH = 16,
    parameter RAM_SEG_COUNT = 2,
    parameter RAM_SEG_DATA_WIDTH = 256*2/RAM_SEG_COUNT,
    parameter RAM_SEG_BE_WIDTH = RAM_SEG_DATA_WIDTH/8,
    parameter RAM_SEG_ADDR_WIDTH = RAM_ADDR_WIDTH-$clog2(RAM_SEG_COUNT*RAM_SEG_BE_WIDTH),
    parameter RAM_PIPELINE = 2,

    // AXI lite interface (application control from host)
    parameter AXIL_APP_CTRL_DATA_WIDTH = 32,
    parameter AXIL_APP_CTRL_ADDR_WIDTH = 16,
    parameter AXIL_APP_CTRL_STRB_WIDTH = (AXIL_APP_CTRL_DATA_WIDTH/8),

    // AXI lite interface (control to NIC)
    parameter AXIL_CTRL_DATA_WIDTH = 32,
    parameter AXIL_CTRL_ADDR_WIDTH = 16,
    parameter AXIL_CTRL_STRB_WIDTH = (AXIL_CTRL_DATA_WIDTH/8),

    // Ethernet interface configuration (direct, async)
    parameter AXIS_DATA_WIDTH = 512,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_TX_USER_WIDTH = TX_TAG_WIDTH + 1,
    parameter AXIS_RX_USER_WIDTH = (PTP_TS_ENABLE ? PTP_TS_WIDTH : 0) + 1,
    parameter AXIS_RX_USE_READY = 0,

    // Ethernet interface configuration (direct, sync)
    parameter AXIS_SYNC_DATA_WIDTH = AXIS_DATA_WIDTH,
    parameter AXIS_SYNC_KEEP_WIDTH = AXIS_SYNC_DATA_WIDTH/8,
    parameter AXIS_SYNC_TX_USER_WIDTH = AXIS_TX_USER_WIDTH,
    parameter AXIS_SYNC_RX_USER_WIDTH = AXIS_RX_USER_WIDTH,

    // Ethernet interface configuration (interface)
    parameter AXIS_IF_DATA_WIDTH = AXIS_SYNC_DATA_WIDTH*2**$clog2(PORTS_PER_IF),
    parameter AXIS_IF_KEEP_WIDTH = AXIS_IF_DATA_WIDTH/8,
    parameter AXIS_IF_TX_ID_WIDTH = 12,
    parameter AXIS_IF_RX_ID_WIDTH = PORTS_PER_IF > 1 ? $clog2(PORTS_PER_IF) : 1,
    parameter AXIS_IF_TX_DEST_WIDTH = $clog2(PORTS_PER_IF)+4,
    parameter AXIS_IF_RX_DEST_WIDTH = 8,
    parameter AXIS_IF_TX_USER_WIDTH = AXIS_SYNC_TX_USER_WIDTH,
    parameter AXIS_IF_RX_USER_WIDTH = AXIS_SYNC_RX_USER_WIDTH,

    // Statistics counter subsystem
    parameter STAT_ENABLE = 1,
    parameter STAT_INC_WIDTH = 24,
    parameter STAT_ID_WIDTH = 12,

    parameter UART_DATA_WIDTH = 512
)
(
    input  wire                                           clk,
    input  wire                                           rst,

    /*
     * AXI-Lite slave interface (control from host)
     */
    input  wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]            s_axil_app_ctrl_awaddr,
    input  wire [2:0]                                     s_axil_app_ctrl_awprot,
    input  wire                                           s_axil_app_ctrl_awvalid,
    output wire                                           s_axil_app_ctrl_awready,
    input  wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]            s_axil_app_ctrl_wdata,
    input  wire [AXIL_APP_CTRL_STRB_WIDTH-1:0]            s_axil_app_ctrl_wstrb,
    input  wire                                           s_axil_app_ctrl_wvalid,
    output wire                                           s_axil_app_ctrl_wready,
    output wire [1:0]                                     s_axil_app_ctrl_bresp,
    output wire                                           s_axil_app_ctrl_bvalid,
    input  wire                                           s_axil_app_ctrl_bready,
    input  wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]            s_axil_app_ctrl_araddr,
    input  wire [2:0]                                     s_axil_app_ctrl_arprot,
    input  wire                                           s_axil_app_ctrl_arvalid,
    output wire                                           s_axil_app_ctrl_arready,
    output wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]            s_axil_app_ctrl_rdata,
    output wire [1:0]                                     s_axil_app_ctrl_rresp,
    output wire                                           s_axil_app_ctrl_rvalid,
    input  wire                                           s_axil_app_ctrl_rready,

    /*
     * AXI-Lite master interface (control to NIC)
     */
    output wire [AXIL_CTRL_ADDR_WIDTH-1:0]                m_axil_ctrl_awaddr,
    output wire [2:0]                                     m_axil_ctrl_awprot,
    output wire                                           m_axil_ctrl_awvalid,
    input  wire                                           m_axil_ctrl_awready,
    output wire [AXIL_CTRL_DATA_WIDTH-1:0]                m_axil_ctrl_wdata,
    output wire [AXIL_CTRL_STRB_WIDTH-1:0]                m_axil_ctrl_wstrb,
    output wire                                           m_axil_ctrl_wvalid,
    input  wire                                           m_axil_ctrl_wready,
    input  wire [1:0]                                     m_axil_ctrl_bresp,
    input  wire                                           m_axil_ctrl_bvalid,
    output wire                                           m_axil_ctrl_bready,
    output wire [AXIL_CTRL_ADDR_WIDTH-1:0]                m_axil_ctrl_araddr,
    output wire [2:0]                                     m_axil_ctrl_arprot,
    output wire                                           m_axil_ctrl_arvalid,
    input  wire                                           m_axil_ctrl_arready,
    input  wire [AXIL_CTRL_DATA_WIDTH-1:0]                m_axil_ctrl_rdata,
    input  wire [1:0]                                     m_axil_ctrl_rresp,
    input  wire                                           m_axil_ctrl_rvalid,
    output wire                                           m_axil_ctrl_rready,

    /*
     * DMA read descriptor output (control)
     */
    output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_read_desc_dma_addr,
    output wire [RAM_SEL_WIDTH-1:0]                       m_axis_ctrl_dma_read_desc_ram_sel,
    output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_read_desc_ram_addr,
    output wire [DMA_LEN_WIDTH-1:0]                       m_axis_ctrl_dma_read_desc_len,
    output wire [DMA_TAG_WIDTH-1:0]                       m_axis_ctrl_dma_read_desc_tag,
    output wire                                           m_axis_ctrl_dma_read_desc_valid,
    input  wire                                           m_axis_ctrl_dma_read_desc_ready,

    /*
     * DMA read descriptor status input (control)
     */
    input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_ctrl_dma_read_desc_status_tag,
    input  wire [3:0]                                     s_axis_ctrl_dma_read_desc_status_error,
    input  wire                                           s_axis_ctrl_dma_read_desc_status_valid,

    /*
     * DMA write descriptor output (control)
     */
    output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_write_desc_dma_addr,
    output wire [RAM_SEL_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_ram_sel,
    output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_write_desc_ram_addr,
    output wire [DMA_IMM_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_imm,
    output wire                                           m_axis_ctrl_dma_write_desc_imm_en,
    output wire [DMA_LEN_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_len,
    output wire [DMA_TAG_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_tag,
    output wire                                           m_axis_ctrl_dma_write_desc_valid,
    input  wire                                           m_axis_ctrl_dma_write_desc_ready,

    /*
     * DMA write descriptor status input (control)
     */
    input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_ctrl_dma_write_desc_status_tag,
    input  wire [3:0]                                     s_axis_ctrl_dma_write_desc_status_error,
    input  wire                                           s_axis_ctrl_dma_write_desc_status_valid,

    /*
     * DMA read descriptor output (data)
     */
    output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_data_dma_read_desc_dma_addr,
    output wire [RAM_SEL_WIDTH-1:0]                       m_axis_data_dma_read_desc_ram_sel,
    output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_data_dma_read_desc_ram_addr,
    output wire [DMA_LEN_WIDTH-1:0]                       m_axis_data_dma_read_desc_len,
    output wire [DMA_TAG_WIDTH-1:0]                       m_axis_data_dma_read_desc_tag,
    output wire                                           m_axis_data_dma_read_desc_valid,
    input  wire                                           m_axis_data_dma_read_desc_ready,

    /*
     * DMA read descriptor status input (data)
     */
    input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_data_dma_read_desc_status_tag,
    input  wire [3:0]                                     s_axis_data_dma_read_desc_status_error,
    input  wire                                           s_axis_data_dma_read_desc_status_valid,

    /*
     * DMA write descriptor output (data)
     */
    output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_data_dma_write_desc_dma_addr,
    output wire [RAM_SEL_WIDTH-1:0]                       m_axis_data_dma_write_desc_ram_sel,
    output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_data_dma_write_desc_ram_addr,
    output wire [DMA_IMM_WIDTH-1:0]                       m_axis_data_dma_write_desc_imm,
    output wire                                           m_axis_data_dma_write_desc_imm_en,
    output wire [DMA_LEN_WIDTH-1:0]                       m_axis_data_dma_write_desc_len,
    output wire [DMA_TAG_WIDTH-1:0]                       m_axis_data_dma_write_desc_tag,
    output wire                                           m_axis_data_dma_write_desc_valid,
    input  wire                                           m_axis_data_dma_write_desc_ready,

    /*
     * DMA write descriptor status input (data)
     */
    input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_data_dma_write_desc_status_tag,
    input  wire [3:0]                                     s_axis_data_dma_write_desc_status_error,
    input  wire                                           s_axis_data_dma_write_desc_status_valid,

    /*
     * DMA RAM interface (control)
     */
    input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         ctrl_dma_ram_wr_cmd_sel,
    input  wire [RAM_SEG_COUNT*RAM_SEG_BE_WIDTH-1:0]      ctrl_dma_ram_wr_cmd_be,
    input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    ctrl_dma_ram_wr_cmd_addr,
    input  wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    ctrl_dma_ram_wr_cmd_data,
    input  wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_wr_cmd_valid,
    output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_wr_cmd_ready,
    output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_wr_done,
    input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         ctrl_dma_ram_rd_cmd_sel,
    input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    ctrl_dma_ram_rd_cmd_addr,
    input  wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_cmd_valid,
    output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_cmd_ready,
    output wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    ctrl_dma_ram_rd_resp_data,
    output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_resp_valid,
    input  wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_resp_ready,

    /*
     * DMA RAM interface (data)
     */
    input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         data_dma_ram_wr_cmd_sel,
    input  wire [RAM_SEG_COUNT*RAM_SEG_BE_WIDTH-1:0]      data_dma_ram_wr_cmd_be,
    input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    data_dma_ram_wr_cmd_addr,
    input  wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    data_dma_ram_wr_cmd_data,
    input  wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_wr_cmd_valid,
    output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_wr_cmd_ready,
    output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_wr_done,
    input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         data_dma_ram_rd_cmd_sel,
    input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    data_dma_ram_rd_cmd_addr,
    input  wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_cmd_valid,
    output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_cmd_ready,
    output wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    data_dma_ram_rd_resp_data,
    output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_resp_valid,
    input  wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_resp_ready,

    /*
     * PTP clock
     */
    input  wire                                           ptp_clk,
    input  wire                                           ptp_rst,
    input  wire                                           ptp_sample_clk,
    input  wire                                           ptp_td_sd,
    input  wire                                           ptp_pps,
    input  wire                                           ptp_pps_str,
    input  wire                                           ptp_sync_locked,
    input  wire [PTP_TS_WIDTH-1:0]                        ptp_sync_ts_rel,
    input  wire                                           ptp_sync_ts_rel_step,
    input  wire [PTP_TS_WIDTH-1:0]                        ptp_sync_ts_tod,
    input  wire                                           ptp_sync_ts_tod_step,
    input  wire                                           ptp_sync_pps,
    input  wire                                           ptp_sync_pps_str,
    input  wire [PTP_PEROUT_COUNT-1:0]                    ptp_perout_locked,
    input  wire [PTP_PEROUT_COUNT-1:0]                    ptp_perout_error,
    input  wire [PTP_PEROUT_COUNT-1:0]                    ptp_perout_pulse,

    /*
     * Ethernet (direct MAC interface - lowest latency raw traffic)
     */
    input  wire [PORT_COUNT-1:0]                          direct_tx_clk,
    input  wire [PORT_COUNT-1:0]                          direct_tx_rst,

    input  wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          s_axis_direct_tx_tdata,
    input  wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          s_axis_direct_tx_tkeep,
    input  wire [PORT_COUNT-1:0]                          s_axis_direct_tx_tvalid,
    output wire [PORT_COUNT-1:0]                          s_axis_direct_tx_tready,
    input  wire [PORT_COUNT-1:0]                          s_axis_direct_tx_tlast,
    input  wire [PORT_COUNT*AXIS_TX_USER_WIDTH-1:0]       s_axis_direct_tx_tuser,

    output wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          m_axis_direct_tx_tdata,
    output wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          m_axis_direct_tx_tkeep,
    output wire [PORT_COUNT-1:0]                          m_axis_direct_tx_tvalid,
    input  wire [PORT_COUNT-1:0]                          m_axis_direct_tx_tready,
    output wire [PORT_COUNT-1:0]                          m_axis_direct_tx_tlast,
    output wire [PORT_COUNT*AXIS_TX_USER_WIDTH-1:0]       m_axis_direct_tx_tuser,

    input  wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             s_axis_direct_tx_cpl_ts,
    input  wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             s_axis_direct_tx_cpl_tag,
    input  wire [PORT_COUNT-1:0]                          s_axis_direct_tx_cpl_valid,
    output wire [PORT_COUNT-1:0]                          s_axis_direct_tx_cpl_ready,

    output wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             m_axis_direct_tx_cpl_ts,
    output wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             m_axis_direct_tx_cpl_tag,
    output wire [PORT_COUNT-1:0]                          m_axis_direct_tx_cpl_valid,
    input  wire [PORT_COUNT-1:0]                          m_axis_direct_tx_cpl_ready,

    input  wire [PORT_COUNT-1:0]                          direct_rx_clk,
    input  wire [PORT_COUNT-1:0]                          direct_rx_rst,

    input  wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          s_axis_direct_rx_tdata,
    input  wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          s_axis_direct_rx_tkeep,
    input  wire [PORT_COUNT-1:0]                          s_axis_direct_rx_tvalid,
    output wire [PORT_COUNT-1:0]                          s_axis_direct_rx_tready,
    input  wire [PORT_COUNT-1:0]                          s_axis_direct_rx_tlast,
    input  wire [PORT_COUNT*AXIS_RX_USER_WIDTH-1:0]       s_axis_direct_rx_tuser,

    output wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          m_axis_direct_rx_tdata,
    output wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          m_axis_direct_rx_tkeep,
    output wire [PORT_COUNT-1:0]                          m_axis_direct_rx_tvalid,
    input  wire [PORT_COUNT-1:0]                          m_axis_direct_rx_tready,
    output wire [PORT_COUNT-1:0]                          m_axis_direct_rx_tlast,
    output wire [PORT_COUNT*AXIS_RX_USER_WIDTH-1:0]       m_axis_direct_rx_tuser,

    /*
     * Ethernet (synchronous MAC interface - low latency raw traffic)
     */
    input  wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     s_axis_sync_tx_tdata,
    input  wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     s_axis_sync_tx_tkeep,
    input  wire [PORT_COUNT-1:0]                          s_axis_sync_tx_tvalid,
    output wire [PORT_COUNT-1:0]                          s_axis_sync_tx_tready,
    input  wire [PORT_COUNT-1:0]                          s_axis_sync_tx_tlast,
    input  wire [PORT_COUNT*AXIS_SYNC_TX_USER_WIDTH-1:0]  s_axis_sync_tx_tuser,

    output wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     m_axis_sync_tx_tdata,
    output wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     m_axis_sync_tx_tkeep,
    output wire [PORT_COUNT-1:0]                          m_axis_sync_tx_tvalid,
    input  wire [PORT_COUNT-1:0]                          m_axis_sync_tx_tready,
    output wire [PORT_COUNT-1:0]                          m_axis_sync_tx_tlast,
    output wire [PORT_COUNT*AXIS_SYNC_TX_USER_WIDTH-1:0]  m_axis_sync_tx_tuser,

    input  wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             s_axis_sync_tx_cpl_ts,
    input  wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             s_axis_sync_tx_cpl_tag,
    input  wire [PORT_COUNT-1:0]                          s_axis_sync_tx_cpl_valid,
    output wire [PORT_COUNT-1:0]                          s_axis_sync_tx_cpl_ready,

    output wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             m_axis_sync_tx_cpl_ts,
    output wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             m_axis_sync_tx_cpl_tag,
    output wire [PORT_COUNT-1:0]                          m_axis_sync_tx_cpl_valid,
    input  wire [PORT_COUNT-1:0]                          m_axis_sync_tx_cpl_ready,

    input  wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     s_axis_sync_rx_tdata,
    input  wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     s_axis_sync_rx_tkeep,
    input  wire [PORT_COUNT-1:0]                          s_axis_sync_rx_tvalid,
    output wire [PORT_COUNT-1:0]                          s_axis_sync_rx_tready,
    input  wire [PORT_COUNT-1:0]                          s_axis_sync_rx_tlast,
    input  wire [PORT_COUNT*AXIS_SYNC_RX_USER_WIDTH-1:0]  s_axis_sync_rx_tuser,

    output wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     m_axis_sync_rx_tdata,
    output wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     m_axis_sync_rx_tkeep,
    output wire [PORT_COUNT-1:0]                          m_axis_sync_rx_tvalid,
    input  wire [PORT_COUNT-1:0]                          m_axis_sync_rx_tready,
    output wire [PORT_COUNT-1:0]                          m_axis_sync_rx_tlast,
    output wire [PORT_COUNT*AXIS_SYNC_RX_USER_WIDTH-1:0]  m_axis_sync_rx_tuser,

    /*
     * Ethernet (internal at interface module)
     */
    input  wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         s_axis_if_tx_tdata,
    input  wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         s_axis_if_tx_tkeep,
    input  wire [IF_COUNT-1:0]                            s_axis_if_tx_tvalid,
    output wire [IF_COUNT-1:0]                            s_axis_if_tx_tready,
    input  wire [IF_COUNT-1:0]                            s_axis_if_tx_tlast,
    input  wire [IF_COUNT*AXIS_IF_TX_ID_WIDTH-1:0]        s_axis_if_tx_tid,
    input  wire [IF_COUNT*AXIS_IF_TX_DEST_WIDTH-1:0]      s_axis_if_tx_tdest,
    input  wire [IF_COUNT*AXIS_IF_TX_USER_WIDTH-1:0]      s_axis_if_tx_tuser,

    output wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         m_axis_if_tx_tdata,
    output wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         m_axis_if_tx_tkeep,
    output wire [IF_COUNT-1:0]                            m_axis_if_tx_tvalid,
    input  wire [IF_COUNT-1:0]                            m_axis_if_tx_tready,
    output wire [IF_COUNT-1:0]                            m_axis_if_tx_tlast,
    output wire [IF_COUNT*AXIS_IF_TX_ID_WIDTH-1:0]        m_axis_if_tx_tid,
    output wire [IF_COUNT*AXIS_IF_TX_DEST_WIDTH-1:0]      m_axis_if_tx_tdest,
    output wire [IF_COUNT*AXIS_IF_TX_USER_WIDTH-1:0]      m_axis_if_tx_tuser,

    input  wire [IF_COUNT*PTP_TS_WIDTH-1:0]               s_axis_if_tx_cpl_ts,
    input  wire [IF_COUNT*TX_TAG_WIDTH-1:0]               s_axis_if_tx_cpl_tag,
    input  wire [IF_COUNT-1:0]                            s_axis_if_tx_cpl_valid,
    output wire [IF_COUNT-1:0]                            s_axis_if_tx_cpl_ready,

    output wire [IF_COUNT*PTP_TS_WIDTH-1:0]               m_axis_if_tx_cpl_ts,
    output wire [IF_COUNT*TX_TAG_WIDTH-1:0]               m_axis_if_tx_cpl_tag,
    output wire [IF_COUNT-1:0]                            m_axis_if_tx_cpl_valid,
    input  wire [IF_COUNT-1:0]                            m_axis_if_tx_cpl_ready,

    input  wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         s_axis_if_rx_tdata,
    input  wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         s_axis_if_rx_tkeep,
    input  wire [IF_COUNT-1:0]                            s_axis_if_rx_tvalid,
    output wire [IF_COUNT-1:0]                            s_axis_if_rx_tready,
    input  wire [IF_COUNT-1:0]                            s_axis_if_rx_tlast,
    input  wire [IF_COUNT*AXIS_IF_RX_ID_WIDTH-1:0]        s_axis_if_rx_tid,
    input  wire [IF_COUNT*AXIS_IF_RX_DEST_WIDTH-1:0]      s_axis_if_rx_tdest,
    input  wire [IF_COUNT*AXIS_IF_RX_USER_WIDTH-1:0]      s_axis_if_rx_tuser,

    output wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         m_axis_if_rx_tdata,
    output wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         m_axis_if_rx_tkeep,
    output wire [IF_COUNT-1:0]                            m_axis_if_rx_tvalid,
    input  wire [IF_COUNT-1:0]                            m_axis_if_rx_tready,
    output wire [IF_COUNT-1:0]                            m_axis_if_rx_tlast,
    output wire [IF_COUNT*AXIS_IF_RX_ID_WIDTH-1:0]        m_axis_if_rx_tid,
    output wire [IF_COUNT*AXIS_IF_RX_DEST_WIDTH-1:0]      m_axis_if_rx_tdest,
    output wire [IF_COUNT*AXIS_IF_RX_USER_WIDTH-1:0]      m_axis_if_rx_tuser,

    /*
     * DDR
     */
    input  wire [DDR_CH-1:0]                              ddr_clk,
    input  wire [DDR_CH-1:0]                              ddr_rst,

    output wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_awid,
    output wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0]           m_axi_ddr_awaddr,
    output wire [DDR_CH*8-1:0]                            m_axi_ddr_awlen,
    output wire [DDR_CH*3-1:0]                            m_axi_ddr_awsize,
    output wire [DDR_CH*2-1:0]                            m_axi_ddr_awburst,
    output wire [DDR_CH-1:0]                              m_axi_ddr_awlock,
    output wire [DDR_CH*4-1:0]                            m_axi_ddr_awcache,
    output wire [DDR_CH*3-1:0]                            m_axi_ddr_awprot,
    output wire [DDR_CH*4-1:0]                            m_axi_ddr_awqos,
    output wire [DDR_CH*AXI_DDR_AWUSER_WIDTH-1:0]         m_axi_ddr_awuser,
    output wire [DDR_CH-1:0]                              m_axi_ddr_awvalid,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_awready,
    output wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0]           m_axi_ddr_wdata,
    output wire [DDR_CH*AXI_DDR_STRB_WIDTH-1:0]           m_axi_ddr_wstrb,
    output wire [DDR_CH-1:0]                              m_axi_ddr_wlast,
    output wire [DDR_CH*AXI_DDR_WUSER_WIDTH-1:0]          m_axi_ddr_wuser,
    output wire [DDR_CH-1:0]                              m_axi_ddr_wvalid,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_wready,
    input  wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_bid,
    input  wire [DDR_CH*2-1:0]                            m_axi_ddr_bresp,
    input  wire [DDR_CH*AXI_DDR_BUSER_WIDTH-1:0]          m_axi_ddr_buser,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_bvalid,
    output wire [DDR_CH-1:0]                              m_axi_ddr_bready,
    output wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_arid,
    output wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0]           m_axi_ddr_araddr,
    output wire [DDR_CH*8-1:0]                            m_axi_ddr_arlen,
    output wire [DDR_CH*3-1:0]                            m_axi_ddr_arsize,
    output wire [DDR_CH*2-1:0]                            m_axi_ddr_arburst,
    output wire [DDR_CH-1:0]                              m_axi_ddr_arlock,
    output wire [DDR_CH*4-1:0]                            m_axi_ddr_arcache,
    output wire [DDR_CH*3-1:0]                            m_axi_ddr_arprot,
    output wire [DDR_CH*4-1:0]                            m_axi_ddr_arqos,
    output wire [DDR_CH*AXI_DDR_ARUSER_WIDTH-1:0]         m_axi_ddr_aruser,
    output wire [DDR_CH-1:0]                              m_axi_ddr_arvalid,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_arready,
    input  wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_rid,
    input  wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0]           m_axi_ddr_rdata,
    input  wire [DDR_CH*2-1:0]                            m_axi_ddr_rresp,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_rlast,
    input  wire [DDR_CH*AXI_DDR_RUSER_WIDTH-1:0]          m_axi_ddr_ruser,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_rvalid,
    output wire [DDR_CH-1:0]                              m_axi_ddr_rready,

    input  wire [DDR_CH-1:0]                              ddr_status,

    /*
     * HBM
     */
    input  wire [HBM_CH-1:0]                              hbm_clk,
    input  wire [HBM_CH-1:0]                              hbm_rst,

    output wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_awid,
    output wire [HBM_CH*AXI_HBM_ADDR_WIDTH-1:0]           m_axi_hbm_awaddr,
    output wire [HBM_CH*8-1:0]                            m_axi_hbm_awlen,
    output wire [HBM_CH*3-1:0]                            m_axi_hbm_awsize,
    output wire [HBM_CH*2-1:0]                            m_axi_hbm_awburst,
    output wire [HBM_CH-1:0]                              m_axi_hbm_awlock,
    output wire [HBM_CH*4-1:0]                            m_axi_hbm_awcache,
    output wire [HBM_CH*3-1:0]                            m_axi_hbm_awprot,
    output wire [HBM_CH*4-1:0]                            m_axi_hbm_awqos,
    output wire [HBM_CH*AXI_HBM_AWUSER_WIDTH-1:0]         m_axi_hbm_awuser,
    output wire [HBM_CH-1:0]                              m_axi_hbm_awvalid,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_awready,
    output wire [HBM_CH*AXI_HBM_DATA_WIDTH-1:0]           m_axi_hbm_wdata,
    output wire [HBM_CH*AXI_HBM_STRB_WIDTH-1:0]           m_axi_hbm_wstrb,
    output wire [HBM_CH-1:0]                              m_axi_hbm_wlast,
    output wire [HBM_CH*AXI_HBM_WUSER_WIDTH-1:0]          m_axi_hbm_wuser,
    output wire [HBM_CH-1:0]                              m_axi_hbm_wvalid,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_wready,
    input  wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_bid,
    input  wire [HBM_CH*2-1:0]                            m_axi_hbm_bresp,
    input  wire [HBM_CH*AXI_HBM_BUSER_WIDTH-1:0]          m_axi_hbm_buser,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_bvalid,
    output wire [HBM_CH-1:0]                              m_axi_hbm_bready,
    output wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_arid,
    output wire [HBM_CH*AXI_HBM_ADDR_WIDTH-1:0]           m_axi_hbm_araddr,
    output wire [HBM_CH*8-1:0]                            m_axi_hbm_arlen,
    output wire [HBM_CH*3-1:0]                            m_axi_hbm_arsize,
    output wire [HBM_CH*2-1:0]                            m_axi_hbm_arburst,
    output wire [HBM_CH-1:0]                              m_axi_hbm_arlock,
    output wire [HBM_CH*4-1:0]                            m_axi_hbm_arcache,
    output wire [HBM_CH*3-1:0]                            m_axi_hbm_arprot,
    output wire [HBM_CH*4-1:0]                            m_axi_hbm_arqos,
    output wire [HBM_CH*AXI_HBM_ARUSER_WIDTH-1:0]         m_axi_hbm_aruser,
    output wire [HBM_CH-1:0]                              m_axi_hbm_arvalid,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_arready,
    input  wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_rid,
    input  wire [HBM_CH*AXI_HBM_DATA_WIDTH-1:0]           m_axi_hbm_rdata,
    input  wire [HBM_CH*2-1:0]                            m_axi_hbm_rresp,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_rlast,
    input  wire [HBM_CH*AXI_HBM_RUSER_WIDTH-1:0]          m_axi_hbm_ruser,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_rvalid,
    output wire [HBM_CH-1:0]                              m_axi_hbm_rready,

    input  wire [HBM_CH-1:0]                              hbm_status,

    /*
     * Statistics increment output
     */
    output wire [STAT_INC_WIDTH-1:0]                      m_axis_stat_tdata,
    output wire [STAT_ID_WIDTH-1:0]                       m_axis_stat_tid,
    output wire                                           m_axis_stat_tvalid,
    input  wire                                           m_axis_stat_tready,

    /*
     * GPIO
     */
    input  wire [APP_GPIO_IN_WIDTH-1:0]                   gpio_in,
    output wire [APP_GPIO_OUT_WIDTH-1:0]                  gpio_out,

    /*
     * JTAG
     */
    input  wire                                           jtag_tdi,
    output wire                                           jtag_tdo,
    input  wire                                           jtag_tms,
    input  wire                                           jtag_tck,

    /*
     * UART
     */
    input wire						 uart_clk,
    input wire						 uart_rst,
    output wire [UART_DATA_WIDTH-1:0]			 uart_tx_axis_tdata,
    output wire						 uart_tx_axis_tvalid,
    input wire						 uart_tx_axis_tready,

    input wire [UART_DATA_WIDTH-1:0]			 uart_rx_axis_tdata,
    input wire						 uart_rx_axis_tvalid,
    output wire						 uart_rx_axis_tready
);

// check configuration
initial begin
    if (APP_ID != 32'h12340001) begin
        $error("Error: Invalid APP_ID (expected 32'h12340001, got 32'h%x) (instance %m)", APP_ID);
        $finish;
    end
end

/*
 * AXI-Lite slave interface (control from host)
 */

axil_ram #(
    .DATA_WIDTH(AXIL_APP_CTRL_DATA_WIDTH),
    .ADDR_WIDTH(12),
    .STRB_WIDTH(AXIL_APP_CTRL_STRB_WIDTH),
    .PIPELINE_OUTPUT(1)
)
ram_inst (
    .clk(clk),
    .rst(rst),

    .s_axil_awaddr(s_axil_app_ctrl_awaddr),
    .s_axil_awprot(s_axil_app_ctrl_awprot),
    .s_axil_awvalid(s_axil_app_ctrl_awvalid),
    .s_axil_awready(s_axil_app_ctrl_awready),
    .s_axil_wdata(s_axil_app_ctrl_wdata),
    .s_axil_wstrb(s_axil_app_ctrl_wstrb),
    .s_axil_wvalid(s_axil_app_ctrl_wvalid),
    .s_axil_wready(s_axil_app_ctrl_wready),
    .s_axil_bresp(s_axil_app_ctrl_bresp),
    .s_axil_bvalid(s_axil_app_ctrl_bvalid),
    .s_axil_bready(s_axil_app_ctrl_bready),
    .s_axil_araddr(s_axil_app_ctrl_araddr),
    .s_axil_arprot(s_axil_app_ctrl_arprot),
    .s_axil_arvalid(s_axil_app_ctrl_arvalid),
    .s_axil_arready(s_axil_app_ctrl_arready),
    .s_axil_rdata(s_axil_app_ctrl_rdata),
    .s_axil_rresp(s_axil_app_ctrl_rresp),
    .s_axil_rvalid(s_axil_app_ctrl_rvalid),
    .s_axil_rready(s_axil_app_ctrl_rready)
);


/*
 * AXI-Lite master interface (control to NIC)
 */
assign m_axil_ctrl_awaddr = 0;
assign m_axil_ctrl_awprot = 0;
assign m_axil_ctrl_awvalid = 1'b0;
assign m_axil_ctrl_wdata = 0;
assign m_axil_ctrl_wstrb = 0;
assign m_axil_ctrl_wvalid = 1'b0;
assign m_axil_ctrl_bready = 1'b1;
assign m_axil_ctrl_araddr = 0;
assign m_axil_ctrl_arprot = 0;
assign m_axil_ctrl_arvalid = 1'b0;
assign m_axil_ctrl_rready = 1'b1;

/*
 * DMA interface (control)
 */
assign m_axis_ctrl_dma_read_desc_dma_addr = 0;
assign m_axis_ctrl_dma_read_desc_ram_sel = 0;
assign m_axis_ctrl_dma_read_desc_ram_addr = 0;
assign m_axis_ctrl_dma_read_desc_len = 0;
assign m_axis_ctrl_dma_read_desc_tag = 0;
assign m_axis_ctrl_dma_read_desc_valid = 1'b0;
assign m_axis_ctrl_dma_write_desc_dma_addr = 0;
assign m_axis_ctrl_dma_write_desc_ram_sel = 0;
assign m_axis_ctrl_dma_write_desc_ram_addr = 0;
assign m_axis_ctrl_dma_write_desc_imm = 0;
assign m_axis_ctrl_dma_write_desc_imm_en = 0;
assign m_axis_ctrl_dma_write_desc_len = 0;
assign m_axis_ctrl_dma_write_desc_tag = 0;
assign m_axis_ctrl_dma_write_desc_valid = 1'b0;

assign ctrl_dma_ram_wr_cmd_ready = 1'b1;
assign ctrl_dma_ram_wr_done = ctrl_dma_ram_wr_cmd_valid;
assign ctrl_dma_ram_rd_cmd_ready = ctrl_dma_ram_rd_resp_ready;
assign ctrl_dma_ram_rd_resp_data = 0;
assign ctrl_dma_ram_rd_resp_valid = ctrl_dma_ram_rd_cmd_valid;

/*
 * DMA interface (data)
 */
assign m_axis_data_dma_read_desc_dma_addr = 0;
assign m_axis_data_dma_read_desc_ram_sel = 0;
assign m_axis_data_dma_read_desc_ram_addr = 0;
assign m_axis_data_dma_read_desc_len = 0;
assign m_axis_data_dma_read_desc_tag = 0;
assign m_axis_data_dma_read_desc_valid = 1'b0;
assign m_axis_data_dma_write_desc_dma_addr = 0;
assign m_axis_data_dma_write_desc_ram_sel = 0;
assign m_axis_data_dma_write_desc_ram_addr = 0;
assign m_axis_data_dma_write_desc_imm = 0;
assign m_axis_data_dma_write_desc_imm_en = 0;
assign m_axis_data_dma_write_desc_len = 0;
assign m_axis_data_dma_write_desc_tag = 0;
assign m_axis_data_dma_write_desc_valid = 1'b0;

assign data_dma_ram_wr_cmd_ready = 1'b1;
assign data_dma_ram_wr_done = data_dma_ram_wr_cmd_valid;
assign data_dma_ram_rd_cmd_ready = data_dma_ram_rd_resp_ready;
assign data_dma_ram_rd_resp_data = 0;
assign data_dma_ram_rd_resp_valid = data_dma_ram_rd_cmd_valid;

/*
 * Ethernet (direct MAC interface - lowest latency raw traffic)
 */
assign m_axis_direct_tx_tdata = s_axis_direct_tx_tdata;
assign m_axis_direct_tx_tkeep = s_axis_direct_tx_tkeep;
assign m_axis_direct_tx_tvalid = s_axis_direct_tx_tvalid;
assign s_axis_direct_tx_tready = m_axis_direct_tx_tready;
assign m_axis_direct_tx_tlast = s_axis_direct_tx_tlast;
assign m_axis_direct_tx_tuser = s_axis_direct_tx_tuser;

assign m_axis_direct_tx_cpl_ts = s_axis_direct_tx_cpl_ts;
assign m_axis_direct_tx_cpl_tag = s_axis_direct_tx_cpl_tag;
assign m_axis_direct_tx_cpl_valid = s_axis_direct_tx_cpl_valid;
assign s_axis_direct_tx_cpl_ready = m_axis_direct_tx_cpl_ready;

assign m_axis_direct_rx_tdata = s_axis_direct_rx_tdata;
assign m_axis_direct_rx_tkeep = s_axis_direct_rx_tkeep;
assign m_axis_direct_rx_tvalid = s_axis_direct_rx_tvalid;
assign s_axis_direct_rx_tready = m_axis_direct_rx_tready;
assign m_axis_direct_rx_tlast = s_axis_direct_rx_tlast;
assign m_axis_direct_rx_tuser = s_axis_direct_rx_tuser;

/*
 * Ethernet (synchronous MAC interface - low latency raw traffic)
 */
assign m_axis_sync_tx_tdata = s_axis_sync_tx_tdata;
assign m_axis_sync_tx_tkeep = s_axis_sync_tx_tkeep;
assign m_axis_sync_tx_tvalid = s_axis_sync_tx_tvalid;
assign s_axis_sync_tx_tready = m_axis_sync_tx_tready;
assign m_axis_sync_tx_tlast = s_axis_sync_tx_tlast;
assign m_axis_sync_tx_tuser = s_axis_sync_tx_tuser;

assign m_axis_sync_tx_cpl_ts = s_axis_sync_tx_cpl_ts;
assign m_axis_sync_tx_cpl_tag = s_axis_sync_tx_cpl_tag;
assign m_axis_sync_tx_cpl_valid = s_axis_sync_tx_cpl_valid;
assign s_axis_sync_tx_cpl_ready = m_axis_sync_tx_cpl_ready;

assign m_axis_sync_rx_tdata = s_axis_sync_rx_tdata;
assign m_axis_sync_rx_tkeep = s_axis_sync_rx_tkeep;
assign m_axis_sync_rx_tvalid = s_axis_sync_rx_tvalid;
assign s_axis_sync_rx_tready = m_axis_sync_rx_tready;
assign m_axis_sync_rx_tlast = s_axis_sync_rx_tlast;
assign m_axis_sync_rx_tuser = s_axis_sync_rx_tuser;

/*
 * Ethernet (internal at interface module)
 */
assign m_axis_if_tx_tdata = s_axis_if_tx_tdata;
assign m_axis_if_tx_tkeep = s_axis_if_tx_tkeep;
assign m_axis_if_tx_tvalid = s_axis_if_tx_tvalid;
assign s_axis_if_tx_tready = m_axis_if_tx_tready;
assign m_axis_if_tx_tlast = s_axis_if_tx_tlast;
assign m_axis_if_tx_tid = s_axis_if_tx_tid;
assign m_axis_if_tx_tdest = s_axis_if_tx_tdest;
assign m_axis_if_tx_tuser = s_axis_if_tx_tuser;

assign m_axis_if_tx_cpl_ts = s_axis_if_tx_cpl_ts;
assign m_axis_if_tx_cpl_tag = s_axis_if_tx_cpl_tag;
assign m_axis_if_tx_cpl_valid = s_axis_if_tx_cpl_valid;
assign s_axis_if_tx_cpl_ready = m_axis_if_tx_cpl_ready;

assign m_axis_if_rx_tdata = s_axis_if_rx_tdata;
assign m_axis_if_rx_tkeep = s_axis_if_rx_tkeep;
assign m_axis_if_rx_tvalid = s_axis_if_rx_tvalid;
assign s_axis_if_rx_tready = m_axis_if_rx_tready;
assign m_axis_if_rx_tlast = s_axis_if_rx_tlast;
assign m_axis_if_rx_tid = s_axis_if_rx_tid;
assign m_axis_if_rx_tdest = s_axis_if_rx_tdest;
assign m_axis_if_rx_tuser = s_axis_if_rx_tuser;

/*
 * DDR
 */
// assign m_axi_ddr_awid = 0;
// assign m_axi_ddr_awaddr = 0;
// assign m_axi_ddr_awlen = 0;
// assign m_axi_ddr_awsize = 0;
// assign m_axi_ddr_awburst = 0;
// assign m_axi_ddr_awlock = 0;
// assign m_axi_ddr_awcache = 0;
// assign m_axi_ddr_awprot = 0;
// assign m_axi_ddr_awqos = 0;
// assign m_axi_ddr_awuser = 0;
// assign m_axi_ddr_awvalid = 0;
// assign m_axi_ddr_wdata = 0;
// assign m_axi_ddr_wstrb = 0;
// assign m_axi_ddr_wlast = 0;
// assign m_axi_ddr_wuser = 0;
// assign m_axi_ddr_wvalid = 0;
// assign m_axi_ddr_bready = 0;
// assign m_axi_ddr_arid = 0;
// assign m_axi_ddr_araddr = 0;
// assign m_axi_ddr_arlen = 0;
// assign m_axi_ddr_arsize = 0;
// assign m_axi_ddr_arburst = 0;
// assign m_axi_ddr_arlock = 0;
// assign m_axi_ddr_arcache = 0;
// assign m_axi_ddr_arprot = 0;
// assign m_axi_ddr_arqos = 0;
// assign m_axi_ddr_aruser = 0;
// assign m_axi_ddr_arvalid = 0;
// assign m_axi_ddr_rready = 0;

/*
 * HBM
 */
assign m_axi_hbm_awid = 0;
assign m_axi_hbm_awaddr = 0;
assign m_axi_hbm_awlen = 0;
assign m_axi_hbm_awsize = 0;
assign m_axi_hbm_awburst = 0;
assign m_axi_hbm_awlock = 0;
assign m_axi_hbm_awcache = 0;
assign m_axi_hbm_awprot = 0;
assign m_axi_hbm_awqos = 0;
assign m_axi_hbm_awuser = 0;
assign m_axi_hbm_awvalid = 0;
assign m_axi_hbm_wdata = 0;
assign m_axi_hbm_wstrb = 0;
assign m_axi_hbm_wlast = 0;
assign m_axi_hbm_wuser = 0;
assign m_axi_hbm_wvalid = 0;
assign m_axi_hbm_bready = 0;
assign m_axi_hbm_arid = 0;
assign m_axi_hbm_araddr = 0;
assign m_axi_hbm_arlen = 0;
assign m_axi_hbm_arsize = 0;
assign m_axi_hbm_arburst = 0;
assign m_axi_hbm_arlock = 0;
assign m_axi_hbm_arcache = 0;
assign m_axi_hbm_arprot = 0;
assign m_axi_hbm_arqos = 0;
assign m_axi_hbm_aruser = 0;
assign m_axi_hbm_arvalid = 0;
assign m_axi_hbm_rready = 0;

/*
 * Statistics increment output
 */
assign m_axis_stat_tdata = 0;
assign m_axis_stat_tid = 0;
assign m_axis_stat_tvalid = 1'b0;

/*
 * GPIO
 */
assign gpio_out = 0;

/*
 * JTAG
 */
assign jtag_tdo = jtag_tdi;

parameter S_COUNT = 4;
parameter M_COUNT = 4;
parameter DATA_WIDTH = AXIS_SYNC_DATA_WIDTH;
parameter KEEP_ENABLE = (DATA_WIDTH>8);
parameter KEEP_WIDTH = (DATA_WIDTH/8);
parameter ID_ENABLE = 0;
parameter M_DEST_WIDTH = $clog2(M_COUNT+1);
parameter USER_ENABLE = 1;
parameter USER_WIDTH = AXIS_SYNC_TX_USER_WIDTH;
parameter ARB_TYPE_ROUND_ROBIN = 1;
parameter ARB_LSB_HIGH_PRIORITY = 1;
parameter AXIS_AXI_FIFO_DEPTH = 32;

wire [AXIS_SYNC_DATA_WIDTH-1:0] rmt_s_axis_tdata;
wire [AXIS_SYNC_KEEP_WIDTH-1:0] rmt_s_axis_tkeep;
wire				rmt_s_axis_tlast;
wire				rmt_s_axis_tvalid;
wire				rmt_s_axis_tready;
wire [AXIS_SYNC_TX_USER_WIDTH-1:0] rmt_s_axis_tuser;
wire [1:0]			   rmt_s_axis_tdest;

wire [AXIS_SYNC_DATA_WIDTH-1:0] recon_s_axis_tdata;
wire [AXIS_SYNC_KEEP_WIDTH-1:0] recon_s_axis_tkeep;
wire				recon_s_axis_tlast;
wire				recon_s_axis_tvalid;
wire				recon_s_axis_tready;

wire [AXIS_SYNC_DATA_WIDTH-1:0] tap_s_axis_sync_tx_tdata;
wire [AXIS_SYNC_KEEP_WIDTH-1:0] tap_s_axis_sync_tx_tkeep;
wire				tap_s_axis_sync_tx_tvalid;
wire				tap_s_axis_sync_tx_tready;
wire				tap_s_axis_sync_tx_tlast;
wire [AXIS_SYNC_TX_USER_WIDTH-1:0] tap_s_axis_sync_tx_tuser;

localparam				      DDR_ICAP_DMA_LEN_WIDTH = 24;
localparam				      DDR_ICAP_DMA_TAG_WIDTH = 8;
localparam				      DDR_ICAP_DMA_DEST_WIDTH = 8;
localparam				      DDR_ICAP_DMA_USER_WIDTH = 1;
localparam				      AXIS_ICAP_DATA_WIDTH = 512;
localparam				      AXIS_ICAP_KEEP_WIDTH = 64;

wire [AXI_DDR_ADDR_WIDTH-1:0]		      s_axis_read_desc_addr;
wire [DDR_ICAP_DMA_LEN_WIDTH-1:0]	      s_axis_read_desc_len;
wire [DDR_ICAP_DMA_TAG_WIDTH-1:0]	      s_axis_read_desc_tag;
wire [AXI_DDR_ID_WIDTH-1:0]		      s_axis_read_desc_id;
wire [DDR_ICAP_DMA_DEST_WIDTH-1:0]	      s_axis_read_desc_dest;
wire [DDR_ICAP_DMA_USER_WIDTH-1:0]	      s_axis_read_desc_user;
wire					      s_axis_read_desc_valid;
wire					      s_axis_read_desc_ready;

wire [AXIS_ICAP_DATA_WIDTH-1:0]		      icap_s_axis_tdata;
wire [AXIS_ICAP_KEEP_WIDTH-1:0]		      icap_s_axis_tkeep;
wire					      icap_s_axis_tlast;
wire					      icap_s_axis_tvalid;
reg					      icap_s_axis_tready = 1'b1;


wire [AXI_DDR_ID_WIDTH-1:0]		      m_axi_async_dma_ddr_arid;
wire [AXI_DDR_ADDR_WIDTH-1:0]		      m_axi_async_dma_ddr_araddr;
wire [7:0]				      m_axi_async_dma_ddr_arlen;
wire [2:0]				      m_axi_async_dma_ddr_arsize;
wire [1:0]				      m_axi_async_dma_ddr_arburst;
wire					      m_axi_async_dma_ddr_arlock;
wire [3:0]				      m_axi_async_dma_ddr_arcache;
wire [2:0]				      m_axi_async_dma_ddr_arprot;
wire [3:0]				      m_axi_async_dma_ddr_arqos;
wire [AXI_DDR_ARUSER_WIDTH-1:0]		      m_axi_async_dma_ddr_aruser;
wire					      m_axi_async_dma_ddr_arvalid;
wire					      m_axi_async_dma_ddr_arready;
wire [AXI_DDR_ID_WIDTH-1:0]		      m_axi_async_dma_ddr_rid;
wire [AXI_DDR_DATA_WIDTH-1:0]		      m_axi_async_dma_ddr_rdata;
wire [1:0]				      m_axi_async_dma_ddr_rresp;
wire					      m_axi_async_dma_ddr_rlast;
wire [AXI_DDR_RUSER_WIDTH-1:0]		      m_axi_async_dma_ddr_ruser;
wire					      m_axi_async_dma_ddr_rvalid;
wire					      m_axi_async_dma_ddr_rready;

axis_tap #(
    .DATA_WIDTH(DATA_WIDTH)
    )
axis_tap_inst (
    .clk(clk),
    .rst(rst),
    .tap_axis_tdata(s_axis_sync_tx_tdata),
    .tap_axis_tkeep(s_axis_sync_tx_tkeep),
    .tap_axis_tvalid(s_axis_sync_tx_tvalid),
    .tap_axis_tready(s_axis_sync_tx_tready),
    .tap_axis_tlast(s_axis_sync_tx_tlast),
    .tap_axis_tid(),
    .tap_axis_tdest(),
    .tap_axis_tuser(s_axis_sync_tx_tuser),

    .m_axis_tdata(tap_s_axis_sync_tx_tdata),
    .m_axis_tkeep(tap_s_axis_sync_tx_tkeep),
    .m_axis_tvalid(tap_s_axis_sync_tx_tvalid),
    .m_axis_tready(tap_s_axis_sync_tx_tready),
    .m_axis_tlast(tap_s_axis_sync_tx_tlast),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser(tap_s_axis_sync_tx_tuser)
    );


rmt #(
    .DATA_WIDTH(DATA_WIDTH)
)
rmt_inst (
    .clk(clk),
    .rst(rst),

    .s_axis_tdata(tap_s_axis_sync_tx_tdata),
    .s_axis_tkeep(tap_s_axis_sync_tx_tkeep),
    .s_axis_tvalid(tap_s_axis_sync_tx_tvalid),
    .s_axis_tready(tap_s_axis_sync_tx_tready),
    .s_axis_tlast(tap_s_axis_sync_tx_tlast),

    .m_axis_tdata(rmt_s_axis_tdata),
    .m_axis_tkeep(rmt_s_axis_tkeep),
    .m_axis_tvalid(rmt_s_axis_tvalid),
    .m_axis_tready(rmt_s_axis_tready),
    .m_axis_tlast(rmt_s_axis_tlast),
    .m_axis_tdest(rmt_s_axis_tdest)

);

assign recon_s_axis_tready = 1'b1;
   
axis_ram_switch_4x4 #(
    .S_DATA_WIDTH(DATA_WIDTH),
    .M_DATA_WIDTH(DATA_WIDTH),
    .M_DEST_WIDTH(M_DEST_WIDTH),
    .ID_ENABLE(ID_ENABLE),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH),
    .ARB_TYPE_ROUND_ROBIN(ARB_TYPE_ROUND_ROBIN),
    .ARB_LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
    )
axis_switch_inst (
    .clk(clk),
    .rst(rst),

    // rx
    .s00_axis_tdata(rmt_s_axis_tdata),
    .s00_axis_tkeep(rmt_s_axis_tkeep),
    .s00_axis_tvalid(rmt_s_axis_tvalid),
    .s00_axis_tready(rmt_s_axis_tready),
    .s00_axis_tlast(rmt_s_axis_tlast),
    .s00_axis_tid(),
    .s00_axis_tdest(rmt_s_axis_tdest),
    .s00_axis_tuser(rmt_s_axis_tuser),

    .s01_axis_tdata(),
    .s01_axis_tkeep(),
    .s01_axis_tvalid(),
    .s01_axis_tready(),
    .s01_axis_tlast(),
    .s01_axis_tid(),
    .s01_axis_tdest(),
    .s01_axis_tuser(),

    .s02_axis_tdata(),
    .s02_axis_tkeep(),
    .s02_axis_tvalid(),
    .s02_axis_tready(),
    .s02_axis_tlast(),
    .s02_axis_tid(),
    .s02_axis_tdest(),
    .s02_axis_tuser(),

    .s03_axis_tdata(),
    .s03_axis_tkeep(),
    .s03_axis_tvalid(),
    .s03_axis_tready(),
    .s03_axis_tlast(),
    .s03_axis_tid(),
    .s03_axis_tdest(),
    .s03_axis_tuser(),


    // rx
    .m00_axis_tdata(),
    .m00_axis_tkeep(),
    .m00_axis_tvalid(),
    .m00_axis_tready(),
    .m00_axis_tlast(),
    .m00_axis_tid(),
    .m00_axis_tdest(),
    .m00_axis_tuser(),

    .m01_axis_tdata(recon_s_axis_tdata),
    .m01_axis_tkeep(recon_s_axis_tkeep),
    .m01_axis_tvalid(recon_s_axis_tvalid),
    .m01_axis_tready(recon_s_axis_tready),
    .m01_axis_tlast(recon_s_axis_tlast),
    .m01_axis_tid(),
    .m01_axis_tdest(),
    .m01_axis_tuser(),

    .m02_axis_tdata(),
    .m02_axis_tkeep(),
    .m02_axis_tvalid(),
    .m02_axis_tready(),
    .m02_axis_tlast(),
    .m02_axis_tid(),
    .m02_axis_tdest(),
    .m02_axis_tuser(),

    // tx
    .m03_axis_tdata(),
    .m03_axis_tkeep(),
    .m03_axis_tvalid(),
    .m03_axis_tready(),
    .m03_axis_tlast(),
    .m03_axis_tid(),
    .m03_axis_tdest(),
    .m03_axis_tuser()
);

   // assign recon_s_axis_tdata = rmt_s_axis_tdata;
   // assign recon_s_axis_tkeep = rmt_s_axis_tkeep;
   // assign recon_s_axis_tvalid = rmt_s_axis_tvalid;
   // assign rmt_s_axis_tready = recon_s_axis_tready;
   // assign recon_s_axis_tlast = rmt_s_axis_tlast;
   
   
// recon_controller #(
//     .DATA_WIDTH(DATA_WIDTH),
//     .ADDR_WIDTH(AXI_DDR_ADDR_WIDTH),
//     .FIFO_DEPTH(AXIS_AXI_FIFO_DEPTH),
//     .ID_WIDTH(AXI_DDR_ID_WIDTH),
//     .DMA_DESC_LEN_WIDTH(DDR_ICAP_DMA_LEN_WIDTH),
//     .DMA_DESC_TAG_WIDTH(DDR_ICAP_DMA_TAG_WIDTH)
// )
// recon_controller_inst (
//     .s_axis_clk(clk),
//     .m_axi_aclk(ddr_clk),
//     .rst(rst),

//     .s_axis_tvalid(recon_s_axis_tvalid),
//     .s_axis_tdata(recon_s_axis_tdata),
//     .s_axis_tkeep(recon_s_axis_tkeep),
//     .s_axis_tlast(recon_s_axis_tlast),
//     .s_axis_tready(recon_s_axis_tready),

//     .s_axis_read_desc_addr(s_axis_read_desc_addr),
//     .s_axis_read_desc_len(s_axis_read_desc_len),
//     .s_axis_read_desc_tag(s_axis_read_desc_tag),
//     .s_axis_read_desc_id(s_axis_read_desc_id),
//     .s_axis_read_desc_dest(s_axis_read_desc_dest),
//     .s_axis_read_desc_user(s_axis_read_desc_user),
//     .s_axis_read_desc_valid(s_axis_read_desc_valid),
//     .s_axis_read_desc_ready(s_axis_read_desc_ready),

//     .m_axi_awready(m_axi_ddr_awready),
//     .m_axi_awid(m_axi_ddr_awid),
//     .m_axi_awaddr(m_axi_ddr_awaddr),
//     .m_axi_awlen(m_axi_ddr_awlen),
//     .m_axi_awsize(m_axi_ddr_awsize),
//     .m_axi_awburst(m_axi_ddr_awburst),
//     .m_axi_awlock(m_axi_ddr_awlock),
//     .m_axi_awcache(m_axi_ddr_awcache),
//     .m_axi_awprot(m_axi_ddr_awprot),
//     .m_axi_awvalid(m_axi_ddr_awvalid),
//     .m_axi_wready(m_axi_ddr_wready),
//     .m_axi_wdata(m_axi_ddr_wdata),
//     .m_axi_wstrb(m_axi_ddr_wstrb),
//     .m_axi_wlast(m_axi_ddr_wlast),
//     .m_axi_wvalid(m_axi_ddr_wvalid),
//     .m_axi_bid(m_axi_ddr_bid),
//     .m_axi_bresp(m_axi_ddr_bresp),
//     .m_axi_bvalid(m_axi_ddr_bvalid),
//     .m_axi_bready(m_axi_ddr_bready)
// );

// axi_dma #(
//     .AXI_DATA_WIDTH(AXI_DDR_DATA_WIDTH),
//     .AXI_ADDR_WIDTH(AXI_DDR_ADDR_WIDTH),
//     .AXI_STRB_WIDTH(AXI_DDR_STRB_WIDTH),
//     .AXI_ID_WIDTH(AXI_DDR_ID_WIDTH),
//     .LEN_WIDTH(DDR_ICAP_DMA_LEN_WIDTH)
// ) axi_dma_ddr_icap_inst (
//     .clk(clk),
//     .rst(rst),

//     .s_axis_read_desc_addr(s_axis_read_desc_addr),
//     .s_axis_read_desc_len(s_axis_read_desc_len),
//     .s_axis_read_desc_tag(s_axis_read_desc_tag),
//     .s_axis_read_desc_id(s_axis_read_desc_id),
//     .s_axis_read_desc_dest(s_axis_read_desc_dest),
//     .s_axis_read_desc_user(s_axis_read_desc_user),
//     .s_axis_read_desc_valid(s_axis_read_desc_valid),
//     .s_axis_read_desc_ready(s_axis_read_desc_ready),

//     .m_axis_read_desc_status_tag(),
//     .m_axis_read_desc_status_error(),
//     .m_axis_read_desc_status_valid(),

//     .m_axis_read_data_tdata(icap_s_axis_tdata),
//     .m_axis_read_data_tkeep(icap_s_axis_tkeep),
//     .m_axis_read_data_tvalid(icap_s_axis_tvalid),
//     .m_axis_read_data_tready(icap_s_axis_tready),
//     .m_axis_read_data_tlast(icap_s_axis_tlast),
//     .m_axis_read_data_tid(),
//     .m_axis_read_data_tdest(),
//     .m_axis_read_data_tuser(),

//     .s_axis_write_desc_addr(),
//     .s_axis_write_desc_len(),
//     .s_axis_write_desc_tag(),
//     .s_axis_write_desc_valid(),
//     .s_axis_write_desc_ready(),

//     .m_axis_write_desc_status_len(),
//     .m_axis_write_desc_status_tag(),
//     .m_axis_write_desc_status_id(),
//     .m_axis_write_desc_status_dest(),
//     .m_axis_write_desc_status_user(),
//     .m_axis_write_desc_status_error(),
//     .m_axis_write_desc_status_valid(),

//     .s_axis_write_data_tdata(),
//     .s_axis_write_data_tkeep(),
//     .s_axis_write_data_tvalid(),
//     .s_axis_write_data_tready(),
//     .s_axis_write_data_tlast(),
//     .s_axis_write_data_tid(),
//     .s_axis_write_data_tdest(),
//     .s_axis_write_data_tuser(),

//     .m_axi_awid(),
//     .m_axi_awaddr(),
//     .m_axi_awlen(),
//     .m_axi_awsize(),
//     .m_axi_awburst(),
//     .m_axi_awlock(),
//     .m_axi_awcache(),
//     .m_axi_awprot(),
//     .m_axi_awvalid(),
//     .m_axi_awready(),
//     .m_axi_wdata(),
//     .m_axi_wstrb(),
//     .m_axi_wlast(),
//     .m_axi_wvalid(),
//     .m_axi_wready(),
//     .m_axi_bid(),
//     .m_axi_bresp(),
//     .m_axi_bvalid(),
//     .m_axi_bready(),
//     .m_axi_arid(m_axi_async_dma_ddr_arid),
//     .m_axi_araddr(m_axi_async_dma_ddr_araddr),
//     .m_axi_arlen(m_axi_async_dma_ddr_arlen),
//     .m_axi_arsize(m_axi_async_dma_ddr_arsize),
//     .m_axi_arburst(m_axi_async_dma_ddr_arburst),
//     .m_axi_arlock(m_axi_async_dma_ddr_arlock),
//     .m_axi_arcache(m_axi_async_dma_ddr_arcache),
//     .m_axi_arprot(m_axi_async_dma_ddr_arprot),
//     .m_axi_arvalid(m_axi_async_dma_ddr_arvalid),
//     .m_axi_arready(m_axi_async_dma_ddr_arready),
//     .m_axi_rid(m_axi_async_dma_ddr_rid),
//     .m_axi_rdata(m_axi_async_dma_ddr_rdata),
//     .m_axi_rresp(m_axi_async_dma_ddr_rresp),
//     .m_axi_rlast(m_axi_async_dma_ddr_rlast),
//     .m_axi_rvalid(m_axi_async_dma_ddr_rvalid),
//     .m_axi_rready(m_axi_async_dma_ddr_rready),

//     .read_enable(1'b1),
//     .write_enable(1'b0),
//     .write_abort(1'b0)
// );


// xil_aximm_async_fifo 
// axi_async_fifo (
//   .m_aclk(ddr_clk),                  // input wire m_aclk
//   .s_aclk(clk),                  // input wire s_aclk
//   .s_aresetn(rst),            // input wire s_aresetn
  
//   .s_axi_arid(m_axi_async_dma_ddr_arid),          // input wire [7 : 0] s_axi_arid
//   .s_axi_araddr(m_axi_async_dma_ddr_araddr),      // input wire [33 : 0] s_axi_araddr
//   .s_axi_arlen(m_axi_async_dma_ddr_arlen),        // input wire [7 : 0] s_axi_arlen
//   .s_axi_arsize(m_axi_async_dma_ddr_arsize),      // input wire [2 : 0] s_axi_arsize
//   .s_axi_arburst(m_axi_async_dma_ddr_arburst),    // input wire [1 : 0] s_axi_arburst
//   .s_axi_arlock(m_axi_async_dma_ddr_arlock),      // input wire [0 : 0] s_axi_arlock
//   .s_axi_arcache(m_axi_async_dma_ddr_arcache),    // input wire [3 : 0] s_axi_arcache
//   .s_axi_arprot(m_axi_async_dma_ddr_arprot),      // input wire [2 : 0] s_axi_arprot
//   .s_axi_arqos(m_axi_async_dma_ddr_arqos),        // input wire [3 : 0] s_axi_arqos
//   .s_axi_arregion(),  // input wire [3 : 0] s_axi_arregion
//   .s_axi_arvalid(m_axi_async_dma_ddr_arvalid),    // input wire s_axi_arvalid
//   .s_axi_arready(m_axi_async_dma_ddr_arready),    // output wire s_axi_arready
//   .s_axi_rid(m_axi_async_dma_ddr_rid),            // output wire [7 : 0] s_axi_rid
//   .s_axi_rdata(m_axi_async_dma_ddr_rdata),        // output wire [511 : 0] s_axi_rdata
//   .s_axi_rresp(m_axi_async_dma_ddr_rresp),        // output wire [1 : 0] s_axi_rresp
//   .s_axi_rlast(m_axi_async_dma_ddr_rlast),        // output wire s_axi_rlast
//   .s_axi_rvalid(m_axi_async_dma_ddr_rvalid),      // output wire s_axi_rvalid
//   .s_axi_rready(m_axi_async_dma_ddr_rready),      // input wire s_axi_rready
  
//   .m_axi_arid(m_axi_ddr_arid),          // output wire [7 : 0] m_axi_arid
//   .m_axi_araddr(m_axi_ddr_araddr),      // output wire [33 : 0] m_axi_araddr
//   .m_axi_arlen(m_axi_ddr_arlen),        // output wire [7 : 0] m_axi_arlen
//   .m_axi_arsize(m_axi_ddr_arsize),      // output wire [2 : 0] m_axi_arsize
//   .m_axi_arburst(m_axi_ddr_arburst),    // output wire [1 : 0] m_axi_arburst
//   .m_axi_arlock(m_axi_ddr_arlock),      // output wire [0 : 0] m_axi_arlock
//   .m_axi_arcache(m_axi_ddr_arcache),    // output wire [3 : 0] m_axi_arcache
//   .m_axi_arprot(m_axi_ddr_arprot),      // output wire [2 : 0] m_axi_arprot
//   .m_axi_arqos(m_axi_ddr_arqos),        // output wire [3 : 0] m_axi_arqos
//   .m_axi_arregion(),  // output wire [3 : 0] m_axi_arregion
//   .m_axi_arvalid(m_axi_ddr_arvalid),    // output wire m_axi_arvalid
//   .m_axi_arready(m_axi_ddr_arready),    // input wire m_axi_arready
//   .m_axi_rid(m_axi_ddr_rid),            // input wire [7 : 0] m_axi_rid
//   .m_axi_rdata(m_axi_ddr_rdata),        // input wire [511 : 0] m_axi_rdata
//   .m_axi_rresp(m_axi_ddr_rresp),        // input wire [1 : 0] m_axi_rresp
//   .m_axi_rlast(m_axi_ddr_rlast),        // input wire m_axi_rlast
//   .m_axi_rvalid(m_axi_ddr_rvalid),      // input wire m_axi_rvalid
//   .m_axi_rready(m_axi_ddr_rready)      // output wire m_axi_rready
// );

   
   
// axi_async_fifo #(
//     .DATA_WIDTH(AXI_DDR_DATA_WIDTH),
//     .ADDR_WIDTH(AXI_DDR_ADDR_WIDTH)
// ) axi_async_ddr_read_fifo_inst (
//     .s_clk(clk),
//     .s_rst(rst),
//     .m_clk(ddr_clk),
//     .m_rst(ddr_rst),

//     .s_axi_awid(),
//     .s_axi_awaddr(),
//     .s_axi_awlen(),
//     .s_axi_awsize(),
//     .s_axi_awburst(),
//     .s_axi_awlock(),
//     .s_axi_awcache(),
//     .s_axi_awprot(),
//     .s_axi_awvalid(),
//     .s_axi_awready(),
//     .s_axi_wdata(),
//     .s_axi_wstrb(),
//     .s_axi_wlast(),
//     .s_axi_wvalid(),
//     .s_axi_wready(),
//     .s_axi_bid(),
//     .s_axi_bresp(),
//     .s_axi_bvalid(),
//     .s_axi_bready(),
//     .s_axi_arid(m_axi_async_dma_ddr_arid),
//     .s_axi_araddr(m_axi_async_dma_ddr_araddr),
//     .s_axi_arlen(m_axi_async_dma_ddr_arlen),
//     .s_axi_arsize(m_axi_async_dma_ddr_arsize),
//     .s_axi_arburst(m_axi_async_dma_ddr_arburst),
//     .s_axi_arlock(m_axi_async_dma_ddr_arlock),
//     .s_axi_arcache(m_axi_async_dma_ddr_arcache),
//     .s_axi_arprot(m_axi_async_dma_ddr_arprot),
//     .s_axi_arvalid(m_axi_async_dma_ddr_arvalid),
//     .s_axi_arready(m_axi_async_dma_ddr_arready),
//     .s_axi_rid(m_axi_async_dma_ddr_rid),
//     .s_axi_rdata(m_axi_async_dma_ddr_rdata),
//     .s_axi_rresp(m_axi_async_dma_ddr_rresp),
//     .s_axi_rlast(m_axi_async_dma_ddr_rlast),
//     .s_axi_rvalid(m_axi_async_dma_ddr_rvalid),
//     .s_axi_rready(m_axi_async_dma_ddr_rready),


//     .m_axi_awid(),
//     .m_axi_awaddr(),
//     .m_axi_awlen(),
//     .m_axi_awsize(),
//     .m_axi_awburst(),
//     .m_axi_awlock(),
//     .m_axi_awcache(),
//     .m_axi_awprot(),
//     .m_axi_awvalid(),
//     .m_axi_awready(),
//     .m_axi_wdata(),
//     .m_axi_wstrb(),
//     .m_axi_wlast(),
//     .m_axi_wvalid(),
//     .m_axi_wready(),
//     .m_axi_bid(),
//     .m_axi_bresp(),
//     .m_axi_bvalid(),
//     .m_axi_bready(),
//     .m_axi_arid(m_axi_ddr_arid),
//     .m_axi_araddr(m_axi_ddr_araddr),
//     .m_axi_arlen(m_axi_ddr_arlen),
//     .m_axi_arsize(m_axi_ddr_arsize),
//     .m_axi_arburst(m_axi_ddr_arburst),
//     .m_axi_arlock(m_axi_ddr_arlock),
//     .m_axi_arcache(m_axi_ddr_arcache),
//     .m_axi_arprot(m_axi_ddr_arprot),
//     .m_axi_arvalid(m_axi_ddr_arvalid),
//     .m_axi_arready(m_axi_ddr_arready),
//     .m_axi_rid(m_axi_ddr_rid),
//     .m_axi_rdata(m_axi_ddr_rdata),
//     .m_axi_rresp(m_axi_ddr_rresp),
//     .m_axi_rlast(m_axi_ddr_rlast),
//     .m_axi_rvalid(m_axi_ddr_rvalid),
//     .m_axi_rready(m_axi_ddr_rready)

// );

// axis_fifo_ex #(
//     .DATA_WIDTH(UART_DATA_WIDTH),
//     .FIFO_DEPTH(128)
// )
// uart_axis_async_fifo_inst
// (
//     .s_clk(clk),
//     .s_rst(rst),
//     .s_axis_tdata(icap_s_axis_tdata),
//     .s_axis_tkeep(icap_s_axis_tkeep),
//     .s_axis_tvalid(icap_s_axis_tvalid),
//     .s_axis_tready(icap_s_axis_tready),
//     .s_axis_tlast(icap_s_axis_tlast),
//     .s_axis_tid(),
//     .s_axis_tdest(),
//     .s_axis_tuser(),

//     .m_clk(uart_clk),
//     .m_rst(uart_rst),
//     .m_axis_tdata(uart_tx_axis_tdata),
//     .m_axis_tkeep(),
//     .m_axis_tvalid(uart_tx_axis_tvalid),
//     .m_axis_tready(uart_tx_axis_tready),
//     .m_axis_tlast(),
//     .m_axis_tid(),
//     .m_axis_tdest(),
//     .m_axis_tuser()
//  );


design_1_wrapper ila_dbg
       (.clk(clk),
        .ddr_clk(ddr_clk),
        .ddr_rst(!ddr_rst),
        .icap_s_axis_tdata(icap_s_axis_tdata),
        .icap_s_axis_tlast(icap_s_axis_tlast),
        .icap_s_axis_tready(icap_s_axis_tready),
        .icap_s_axis_tvalid(icap_s_axis_tvalid),
        .m_axi_async_dma_ddr_araddr(m_axi_async_dma_ddr_araddr),
        .m_axi_async_dma_ddr_arburst(m_axi_async_dma_ddr_arburst),
        .m_axi_async_dma_ddr_arcache(m_axi_async_dma_ddr_arcache),
        .m_axi_async_dma_ddr_arlen(m_axi_async_dma_ddr_arlen),
        .m_axi_async_dma_ddr_arlock(m_axi_async_dma_ddr_arlock),
        .m_axi_async_dma_ddr_arprot(m_axi_async_dma_ddr_arprot),
        .m_axi_async_dma_ddr_arqos(m_axi_async_dma_ddr_arqos),
        .m_axi_async_dma_ddr_arready(m_axi_async_dma_ddr_arready),
        .m_axi_async_dma_ddr_arregion(),
        .m_axi_async_dma_ddr_arsize(m_axi_async_dma_ddr_arsize),
        .m_axi_async_dma_ddr_arvalid(m_axi_async_dma_ddr_arvalid),
        .m_axi_async_dma_ddr_awaddr(),
        .m_axi_async_dma_ddr_awburst(),
        .m_axi_async_dma_ddr_awcache(),
        .m_axi_async_dma_ddr_awlen(),
        .m_axi_async_dma_ddr_awlock(),
        .m_axi_async_dma_ddr_awprot(),
        .m_axi_async_dma_ddr_awqos(),
        .m_axi_async_dma_ddr_awready(),
        .m_axi_async_dma_ddr_awregion(),
        .m_axi_async_dma_ddr_awsize(),
        .m_axi_async_dma_ddr_awvalid(),
        .m_axi_async_dma_ddr_bready(),
        .m_axi_async_dma_ddr_bresp(),
        .m_axi_async_dma_ddr_bvalid(),
        .m_axi_async_dma_ddr_rdata(m_axi_async_dma_ddr_rdata),
        .m_axi_async_dma_ddr_rlast(m_axi_async_dma_ddr_rlast),
        .m_axi_async_dma_ddr_rready(m_axi_async_dma_ddr_rready),
        .m_axi_async_dma_ddr_rresp(m_axi_async_dma_ddr_rresp),
        .m_axi_async_dma_ddr_rvalid(m_axi_async_dma_ddr_rvalid),
        .m_axi_async_dma_ddr_wdata(),
        .m_axi_async_dma_ddr_wlast(),
        .m_axi_async_dma_ddr_wready(),
        .m_axi_async_dma_ddr_wstrb(),
        .m_axi_async_dma_ddr_wvalid(),
        .m_axi_ddr_araddr(m_axi_ddr_araddr),
        .m_axi_ddr_arburst(m_axi_ddr_arburst),
        .m_axi_ddr_arcache(m_axi_ddr_arcache),
        .m_axi_ddr_arlen(m_axi_ddr_arlen),
        .m_axi_ddr_arlock(m_axi_ddr_arlock),
        .m_axi_ddr_arprot(m_axi_ddr_arprot),
        .m_axi_ddr_arqos(m_axi_ddr_arqos),
        .m_axi_ddr_arready(m_axi_ddr_arready),
        .m_axi_ddr_arregion(),
        .m_axi_ddr_arsize(m_axi_ddr_arsize),
        .m_axi_ddr_arvalid(m_axi_ddr_arvalid),
        .m_axi_ddr_awaddr(m_axi_ddr_awaddr),
        .m_axi_ddr_awburst(m_axi_ddr_awburst),
        .m_axi_ddr_awcache(m_axi_ddr_awcache),
        .m_axi_ddr_awlen(m_axi_ddr_awlen),
        .m_axi_ddr_awlock(m_axi_ddr_awlock),
        .m_axi_ddr_awprot(m_axi_ddr_awprot),
        .m_axi_ddr_awqos(m_axi_ddr_awqos),
        .m_axi_ddr_awready(m_axi_ddr_awready),
        .m_axi_ddr_awregion(),
        .m_axi_ddr_awsize(m_axi_ddr_awsize),
        .m_axi_ddr_awvalid(m_axi_ddr_awvalid),
        .m_axi_ddr_bready(m_axi_ddr_bready),
        .m_axi_ddr_bresp(m_axi_ddr_bresp),
        .m_axi_ddr_bvalid(m_axi_ddr_bvalid),
        .m_axi_ddr_rdata(m_axi_ddr_rdata),
        .m_axi_ddr_rlast(m_axi_ddr_rlast),
        .m_axi_ddr_rready(m_axi_ddr_rready),
        .m_axi_ddr_rresp(m_axi_ddr_rresp),
        .m_axi_ddr_rvalid(m_axi_ddr_rvalid),
        .m_axi_ddr_wdata(m_axi_ddr_wdata),
        .m_axi_ddr_wlast(m_axi_ddr_wlast),
        .m_axi_ddr_wready(m_axi_ddr_wready),
        .m_axi_ddr_wstrb(m_axi_ddr_wstrb),
        .m_axi_ddr_wvalid(m_axi_ddr_wvalid),
        .recon_s_axis_tdata(recon_s_axis_tdata),
        .recon_s_axis_tlast(recon_s_axis_tlast),
        .recon_s_axis_tready(recon_s_axis_tready),
        .recon_s_axis_tvalid(recon_s_axis_tvalid),
        .rmt_s_axis_tdata(rmt_s_axis_tdata),
        .rmt_s_axis_tlast(rmt_s_axis_tlast),
        .rmt_s_axis_tready(rmt_s_axis_tready),
        .rmt_s_axis_tvalid(rmt_s_axis_tvalid),
        .rst(!rst),
        .tap_s_axis_tdata(tap_s_axis_sync_tx_tdata),
        .tap_s_axis_tlast(tap_s_axis_sync_tx_tlast),
        .tap_s_axis_tready(tap_s_axis_sync_tx_tready),
        .tap_s_axis_tvalid(tap_s_axis_sync_tx_tvalid),
        .tap_s_axis_tdest(rmt_s_axis_tdest));

endmodule

`resetall
