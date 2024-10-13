`resetall
`timescale 1ns / 1ps
`default_nettype none

module axis_mm_bridge #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ADDR_WIDTH = 34,
    parameter ID_WIDTH = 8
)
(
    input wire			clk,
    input wire			rst,

    input wire [ADDR_WIDTH-1:0]	axi_base_addr,
    input wire			axi_base_addr_valid,

    input wire [KEEP_WIDTH-1:0]	s_axis_tkeep,
    input wire [DATA_WIDTH-1:0]	s_axis_tdata,
    input wire			s_axis_tlast,
    input wire			s_axis_tvalid,
    output reg			s_axis_tready,

    input wire			m_axi_awready,
    output wire [ID_WIDTH-1:0]	m_axi_awid,
    output reg [ADDR_WIDTH-1:0]	m_axi_awaddr,
    output wire [7:0]		m_axi_awlen,
    output wire [2:0]		m_axi_awsize,
    output wire [1:0]		m_axi_awburst,
    output wire			m_axi_awlock,
    output wire [3:0]		m_axi_awcache,
    output wire [2:0]		m_axi_awprot,
    output reg			m_axi_awvalid,
    input wire			m_axi_wready,
    output reg [DATA_WIDTH-1:0]	m_axi_wdata,
    output reg [KEEP_WIDTH-1:0]	m_axi_wstrb,
    output wire			m_axi_wlast,
    output reg			m_axi_wvalid,
    input wire [ID_WIDTH-1:0]	m_axi_bid,
    input wire [1:0]		m_axi_bresp,
    input wire			m_axi_bvalid,
    output reg			m_axi_bready
);

integer				 i;
reg [ADDR_WIDTH-1:0]		m_axi_awaddr_int = {ADDR_WIDTH{1'b0}};
reg				m_axi_awvalid_int;
reg				m_axi_wvalid_int;
reg				s_axis_tready_int = 1'b1;
reg [KEEP_WIDTH-1:0]		s_axis_tkeep_int = {KEEP_WIDTH{1'b0}};
reg [DATA_WIDTH-1:0]		s_axis_tdata_int = {DATA_WIDTH{1'b0}};

reg [ADDR_WIDTH-1:0]		m_axi_awaddr_reg = {ADDR_WIDTH{1'b0}};
reg				m_axi_awvalid_reg;
reg				m_axi_wvalid_reg;
reg				s_axis_tready_reg = 1'b1;
reg [DATA_WIDTH-1:0]		m_axi_wdata_reg = {DATA_WIDTH{1'b0}};
reg [KEEP_WIDTH-1:0]		m_axi_wstrb_reg ={KEEP_WIDTH{1'b0}};

reg [ADDR_WIDTH-1:0]    m_axi_awaddr_stage1;
reg                     m_axi_awvalid_stage1;
reg [DATA_WIDTH-1:0]    m_axi_wdata_stage1;
reg [KEEP_WIDTH-1:0]    m_axi_wstrb_stage1;
reg                     m_axi_wvalid_stage1;

// Stage 2 registers
reg [ADDR_WIDTH-1:0]    m_axi_awaddr_stage2;
reg                     m_axi_awvalid_stage2;
reg [DATA_WIDTH-1:0]    m_axi_wdata_stage2;
reg [KEEP_WIDTH-1:0]    m_axi_wstrb_stage2;
reg                     m_axi_wvalid_stage2;


reg [ADDR_WIDTH-1:0]    m_axi_awaddr_stage3;
reg                     m_axi_awvalid_stage3;
reg [DATA_WIDTH-1:0]    m_axi_wdata_stage3;
reg [KEEP_WIDTH-1:0]    m_axi_wstrb_stage3;
reg                     m_axi_wvalid_stage3;

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
assign m_axi_awid = 0;
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
	wstrb_pos <= 0;
	//wdata_pos <= 1'b0;
	state <= IDLE;
       m_axi_awvalid_stage1 <= 1'b0;
        m_axi_awvalid_stage2 <= 1'b0;
	m_axi_awvalid_stage3 <= 1'b0;
       m_axi_awvalid_reg <= 1'b0;
        m_axi_wvalid_stage1 <= 1'b0;
        m_axi_wvalid_stage2 <= 1'b0;
	m_axi_wvalid_stage3 <= 1'b0;
        m_axi_wvalid_reg <= 1'b0;
    end
   else begin
        // Pipeline stage 1: Capture initial signals
        wstrb_pos <= wstrb_pos_int;

        m_axi_awaddr_stage1 <= m_axi_awaddr_int;
        m_axi_awvalid_stage1 <= m_axi_awvalid_int;
        m_axi_wdata_stage1 <= s_axis_tdata_int << wdata_pos;
        m_axi_wstrb_stage1 <= s_axis_tkeep_int << wstrb_pos;
        m_axi_wvalid_stage1 <= m_axi_wvalid_int;

        // Pipeline stage 2: Pass stage 1 to stage 2
        m_axi_awaddr_stage2 <= m_axi_awaddr_stage1;
        m_axi_awvalid_stage2 <= m_axi_awvalid_stage1;
        m_axi_wdata_stage2 <= m_axi_wdata_stage1;
        m_axi_wstrb_stage2 <= m_axi_wstrb_stage1;
        m_axi_wvalid_stage2 <= m_axi_wvalid_stage1;

        m_axi_awaddr_stage3 <= m_axi_awaddr_stage2;
        m_axi_awvalid_stage3 <= m_axi_awvalid_stage2;
        m_axi_wdata_stage3 <= m_axi_wdata_stage2;
        m_axi_wstrb_stage3 <= m_axi_wstrb_stage2;
        m_axi_wvalid_stage3 <= m_axi_wvalid_stage2;
	// Pipeline stage 3: Pass stage 2 to final stage
        m_axi_awaddr_reg <= m_axi_awaddr_stage3;
        m_axi_awvalid_reg <= m_axi_awvalid_stage3;
        m_axi_wdata_reg <= m_axi_wdata_stage3;
        m_axi_wstrb_reg <= m_axi_wstrb_stage3;
        m_axi_wvalid_reg <= m_axi_wvalid_stage3;

        m_axi_awaddr <= m_axi_awaddr_reg;
        m_axi_awvalid <= m_axi_awvalid_reg;
        m_axi_wdata <= m_axi_wdata_reg;
        m_axi_wstrb <= m_axi_wstrb_reg;
        m_axi_wvalid <= m_axi_wvalid_reg;
        s_axis_tready <= s_axis_tready_int;
    end

    // else begin
    //     // Pipeline stage 1: Register the address and control signals
    // 	wstrb_pos <= wstrb_pos_int;

    //     m_axi_awaddr_reg <= m_axi_awaddr_int;
    //     m_axi_awvalid_reg <= m_axi_awvalid_int;
    //     s_axis_tready_reg <= s_axis_tready_int;

    //     // Pipeline stage 2: Register the data and write strobe
    //     m_axi_wdata_reg <= s_axis_tdata_int << wdata_pos;
    //     m_axi_wstrb_reg <= s_axis_tkeep_int << wstrb_pos;
    //     m_axi_wvalid_reg <= m_axi_wvalid_int;

    //     // Pipeline stage 3: Assign the pipelined signals to the outputs
    //     m_axi_awaddr <= m_axi_awaddr_reg;
    //     m_axi_awvalid <= m_axi_awvalid_reg;
    //     m_axi_wdata <= m_axi_wdata_reg;
    //     m_axi_wstrb <= m_axi_wstrb_reg;
    //     m_axi_wvalid <= m_axi_wvalid_reg;
    //     s_axis_tready <= s_axis_tready_reg;
    // end

    // else begin
    // 	wstrb_pos <= wstrb_pos_int;
    // 	m_axi_wdata <= s_axis_tdata_int << wdata_pos;
    // 	s_axis_tready <= s_axis_tready_int;
    // 	m_axi_awaddr <= m_axi_awaddr_int;
    // 	m_axi_awvalid <= m_axi_awvalid_int;
    // 	m_axi_wvalid <= m_axi_wvalid_int;
    // 	m_axi_wstrb = s_axis_tkeep_int << wstrb_pos;
    // end
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
		m_axi_awaddr_int = m_axi_awaddr_stage1 + count;
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
