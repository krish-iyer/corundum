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
    output reg [DATA_WIDTH-1:0] m_axi_wdata,
    output reg [KEEP_WIDTH-1:0] m_axi_wstrb,
    output			 m_axi_wlast,
    output reg			 m_axi_wvalid,
    input			 m_axi_bid,
    input [1:0]			 m_axi_bresp,
    input			 m_axi_bvalid,
    output reg			 m_axi_bready
);

integer				 i;
reg [ADDR_WIDTH-1:0]		m_axi_awaddr_int = {ADDR_WIDTH{1'b0}};
reg				m_axi_awvalid_int;
reg				m_axi_wvalid_int;
reg				s_axis_tready_int = 1'b1;
reg [KEEP_WIDTH-1:0]		s_axis_tkeep_int = {KEEP_WIDTH{1'b0}};
reg [DATA_WIDTH-1:0]		s_axis_tdata_int = {DATA_WIDTH{1'b0}};

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

// assign m_axi_wdata = s_axis_tdata;
// assign m_axi_wstrb = s_axis_tkeep;

integer	count = 0;
reg [5:0] wstrb_pos = 0;
reg [8:0] wdata_pos = 0;
reg [5:0] wstrb_pos_int = 0;

function integer count_ones;
    input reg [KEEP_WIDTH-1:0] data;
    integer i;
    begin
        count_ones = 0;
        for (i = 0; i < KEEP_WIDTH-1 ; i = i + 1) begin
            count_ones = count_ones + data[i];
        end
    end
endfunction

always @(posedge clk) begin
    state <= state_next;
    if(rst) begin
	m_axi_awvalid  <= 1'b0;
        m_axi_wvalid <= 1'b0;
	s_axis_tready <= 1'b0;
	wstrb_pos <= 1'b0;
	wdata_pos <= 1'b0;
	state <= IDLE;
    end
    else begin
	wstrb_pos <= wstrb_pos_int;
	m_axi_wdata <= s_axis_tdata_int << wdata_pos;
	s_axis_tready <= s_axis_tready_int;
	m_axi_awaddr <= m_axi_awaddr_int;
	m_axi_awvalid <= m_axi_awvalid_int;
	m_axi_wvalid <= m_axi_wvalid_int;
	m_axi_wstrb = s_axis_tkeep_int << wstrb_pos;
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
		s_axis_tkeep_int = s_axis_tkeep;
		s_axis_tdata_int = s_axis_tdata;
		state_next = WR_ADDR;
	    end
	    else begin
		s_axis_tready_int = m_axi_awready;
		state_next = IDLE;
	    end
	end // case: begin...
	WR_ADDR: begin
	    if(m_axi_wready) begin
		m_axi_awvalid_int = 1'b0;
		m_axi_wvalid_int = 1'b1;
		count = count_ones(s_axis_tkeep_int);
		wstrb_pos_int = wstrb_pos + count;
		wdata_pos = wstrb_pos << 3;
		m_axi_awaddr_int = m_axi_awaddr + count;
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
