`resetall
`timescale 1ns / 1ps
`default_nettype none

module axis_mm_bridge #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ADDR_WIDTH = 34
)
(
    input			 clk,
    input			 rst,

    input [ADDR_WIDTH-1:0]	 axi_base_addr,
    input			 axi_base_addr_valid,

    input [KEEP_WIDTH-1:0]	 s_axis_tkeep,
    input [DATA_WIDTH-1:0]	 s_axis_tdata,
    input			 s_axis_tlast,
    input			 s_axis_tvalid,
    output reg			 s_axis_tready,

    input			 m_axi_awready,
    output reg [5:0]		 m_axi_awid,
    output reg [ADDR_WIDTH-1:0]	 m_axi_awaddr,
    output [7:0]		 m_axi_awlen,
    output [2:0]		 m_axi_awsize,
    output [1:0]		 m_axi_awburst,
    output			 m_axi_awlock,
    output [3:0]		 m_axi_awcache,
    output [2:0]		 m_axi_awprot,
    output reg			 m_axi_awvalid,
    input			 m_axi_wready,
    output wire [DATA_WIDTH-1:0] m_axi_wdata,
    output wire [KEEP_WIDTH-1:0] m_axi_wstrb,
    output			 m_axi_wlast,
    output reg			 m_axi_wvalid,
    input			 m_axi_bid,
    input [1:0]			 m_axi_bresp,
    input			 m_axi_bvalid,
    output reg			 m_axi_bready
);

integer				 i;
reg [ADDR_WIDTH-1:0]		m_axi_awaddr_int = {KEEP_WIDTH{1'b0}};
reg				m_axi_awvalid_int;
reg				m_axi_wvalid_int;
reg				s_axis_tready_int = 1'b1;

localparam [1:0]
		IDLE    = 'd0,
		WR_ADDR = 'd1,
		WR_DATA = 'd2;

reg [1:0]	state = IDLE, state_next;

assign m_axi_awlen     = 8'd0;
assign m_axi_awsize    = 3'd6;
assign m_axi_awburst   = 2'd1;
assign m_axi_awcache   = 4'd0;
assign m_axi_awprot    = 3'd0;

assign m_axi_awlock  = 1'd0;
assign m_axi_wlast   = m_axi_wvalid;

assign m_axi_wdata = s_axis_tdata;
assign m_axi_wstrb = s_axis_tkeep;

always @(posedge clk) begin
    state <= state_next;
    if(rst) begin
	m_axi_awvalid  <= 1'b0;
        m_axi_wvalid <= 1'b0;
        s_axis_tready <= 1'b0;
	state <= IDLE;
    end
    else begin
	s_axis_tready <= s_axis_tready_int && m_axi_awready;
	m_axi_awaddr <= m_axi_awaddr_int;
	m_axi_awvalid <= m_axi_awvalid_int;
	m_axi_wvalid <= m_axi_wvalid_int;
    end
end

always @* begin
    state_next = IDLE;
    case(state)
	IDLE: begin
	    if(axi_base_addr_valid) begin
		m_axi_awaddr_int = axi_base_addr;
	    end
	    if(s_axis_tvalid && m_axi_awready) begin
		m_axi_awvalid_int = 1'b1;
		s_axis_tready_int = 1'b0;
		state_next = WR_ADDR;
	    end
	    else begin
		state_next = IDLE;
		s_axis_tready_int = 1'b1;
		//m_axi_awaddr_int = 1'b0;
	    end
	end // case: begin...
	WR_ADDR: begin
	    if(m_axi_wready) begin
		m_axi_awvalid_int = 1'b0;
		m_axi_wvalid_int = 1'b1;
		for(i = 0; i < KEEP_WIDTH-1; i=i+1) begin
                    m_axi_awaddr_int = m_axi_awaddr_int + s_axis_tkeep[i];
		end
		state_next = WR_DATA;
	    end
	    else begin
		state_next = WR_ADDR;
	    end
	end
	WR_DATA: begin
	    if(m_axi_wready) begin
		m_axi_wvalid_int = 1'b0;
		s_axis_tready_int = 1'b1;
		state_next = IDLE;
	    end
	    else begin
		state_next = WR_DATA;
	    end
	end
    endcase
end

always @(posedge clk) begin
    if(rst)
        m_axi_bready <= 1'b0;
    else if(m_axi_bready)
        m_axi_bready <= 1'b0;
    else if(m_axi_bvalid)
        m_axi_bready <= 1'b1;
end

endmodule

`resetall
