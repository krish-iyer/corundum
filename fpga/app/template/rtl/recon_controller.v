`resetall
`timescale 1ns / 1ps
`default_nettype none

module recon_controller #(
    parameter DATA_WIDTH = 8,
    parameter ID_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ADDR_WIDTH = 34,
    parameter FIFO_DEPTH = 32,
    parameter DMA_DESC_LEN_WIDTH = 20,
    parameter DMA_DESC_TAG_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter USER_WIDTH = 8
)
(
    input				s_axis_clk,
    input wire				m_axi_aclk,
    input				rst,
    //input stream
    input				s_axis_tvalid,
    input [DATA_WIDTH-1:0]		s_axis_tdata,
    input [KEEP_WIDTH-1:0]		s_axis_tkeep,
    input				s_axis_tlast,
    output reg				s_axis_tready,

    output reg [ADDR_WIDTH-1:0]		s_axis_read_desc_addr,
    output reg [DMA_DESC_LEN_WIDTH-1:0]	s_axis_read_desc_len,
    output reg [DMA_DESC_TAG_WIDTH-1:0]	s_axis_read_desc_tag,
    output reg [ID_WIDTH-1:0]		s_axis_read_desc_id,
    output reg [DEST_WIDTH-1:0]		s_axis_read_desc_dest,
    output reg [USER_WIDTH-1:0]		s_axis_read_desc_user,
    output reg				s_axis_read_desc_valid,
    input wire				s_axis_read_desc_ready,

    input				m_axi_awready,
    output [ID_WIDTH-1:0]		m_axi_awid,
    output [ADDR_WIDTH-1:0]		m_axi_awaddr,
    output [7:0]			m_axi_awlen,
    output [2:0]			m_axi_awsize,
    output [1:0]			m_axi_awburst,
    output				m_axi_awlock,
    output [3:0]			m_axi_awcache,
    output [2:0]			m_axi_awprot,
    output				m_axi_awvalid,
    input				m_axi_wready,
    output [DATA_WIDTH-1:0]		m_axi_wdata,
    output [KEEP_WIDTH-1:0]		m_axi_wstrb,
    output				m_axi_wlast,
    output				m_axi_wvalid,
    input [ID_WIDTH-1:0]		m_axi_bid,
    input [1:0]				m_axi_bresp,
    input				m_axi_bvalid,
    output				m_axi_bready
);

localparam integer ETH_IP_RMT_HDR_DATA_WIDTH = 46; // bytes
localparam [63:0]  ETH_IP_RMT_HDR_KEEP_MASK = 64'h000000000003FFFF; // + bitstream_addr
localparam [63:0]  ETH_IP_RMT_HDR_RECON_HDR_KEEP_MASK = 64'h00000000000000FF; // + bitstream_addr
localparam integer RECON_HDR_WIDTH = 10; //bytes

reg [ADDR_WIDTH-1:0]			s_axis_read_desc_addr_int = {ADDR_WIDTH{1'b0}};
reg [DMA_DESC_LEN_WIDTH-1:0]		s_axis_read_desc_len_int = {DMA_DESC_LEN_WIDTH{1'b0}};
reg [DMA_DESC_TAG_WIDTH-1:0]		s_axis_read_desc_tag_int = {DMA_DESC_TAG_WIDTH{1'b0}};
reg [ID_WIDTH-1:0]			s_axis_read_desc_id_int = {ID_WIDTH{1'b0}};
reg [DEST_WIDTH-1:0]			s_axis_read_desc_dest_int = {DEST_WIDTH{1'b0}};
reg [USER_WIDTH-1:0]			s_axis_read_desc_user_int = {USER_WIDTH{1'b0}};
reg					s_axis_read_desc_valid_int = 0;
reg					s_axis_read_desc_ready_int = 0;


reg [ADDR_WIDTH-1:0]	    axi_base_addr = {ADDR_WIDTH{1'b0}};
reg [ADDR_WIDTH-1:0]	    axi_base_addr_int = {ADDR_WIDTH{1'b0}};

reg			    axi_base_addr_valid = 1'b0;
reg			    axi_base_addr_valid_int = 1'b0;

integer			    i;
wire [31 : 0]		    ptr;
reg [31 : 0]		    prev_ptr = FIFO_DEPTH - 1;


localparam [2:0]
		HDR_CAPTURE = 3'd0,
		FRAME_MEM_TRANSFER = 3'd1,
		FRAME_DROP = 3'd2,
		DMA_INIT = 3'd3,
		CAPTURE_DONE = 3'd4,
		RECON_CPL = 3'd5;

reg [2:0]	capture_state = HDR_CAPTURE, capture_state_next;
reg [RECON_HDR_WIDTH*8:0]	recon_hdr;
reg [1:0]	func_type;
reg [7:0]	bitstream_id;
reg [31:0]	bitstream_size;
reg		bitstream_size_valid;
reg [7:0]	bitstream_id_int;
reg [31:0]	bitstream_size_int;
reg [31:0]	pending_transfer_size = 0;
reg [34:0]	bitstream_addr;
reg [34:0]	bitstream_addr_int;
reg [$clog2(DATA_WIDTH):0] frame_size = 0;

reg [DATA_WIDTH-1:0]		s_fifo_tdata;
reg [KEEP_WIDTH-1:0]		s_fifo_tkeep;
reg				s_fifo_tlast;
reg				s_fifo_tvalid;
wire				s_fifo_tready;

wire [DATA_WIDTH-1:0]		m_fifo_tdata;
wire [KEEP_WIDTH-1:0]		m_fifo_tkeep;
wire				m_fifo_tlast;
wire				m_fifo_tvalid;
wire				m_fifo_tready;

reg [KEEP_WIDTH-1:0]		s_fifo_tkeep_int;
reg [DATA_WIDTH-1:0]		s_fifo_tdata_int;
reg				s_fifo_tvalid_int = 1'b0;
reg				s_fifo_tlast_int;
reg				s_fifo_tready_int;

reg [7:0]	bitstream_addr_table [0:ADDR_WIDTH+16+1-1]; // [size][ADDR][Valid]


assign recon_hdr = ((capture_state == HDR_CAPTURE) && s_axis_tvalid) ? s_axis_tdata[ETH_IP_RMT_HDR_DATA_WIDTH*8+:RECON_HDR_WIDTH*8] : 0;
assign func_type = ((capture_state == HDR_CAPTURE) && s_axis_tvalid) ? recon_hdr [1:0] : 0;
assign bitstream_size_valid = ((capture_state == HDR_CAPTURE) && s_axis_tvalid) ? recon_hdr[2] : 0;
assign bitstream_addr = ((capture_state == HDR_CAPTURE) && s_axis_tvalid) ? recon_hdr[3+:34] : 0;
assign bitstream_id = ((capture_state == HDR_CAPTURE) && s_axis_tvalid) ? recon_hdr[37+:8] : 0;
assign bitstream_size = ((capture_state == HDR_CAPTURE) && s_axis_tvalid) ? recon_hdr[45+:32] : 0;

always @(posedge s_axis_clk) begin
    capture_state <= capture_state_next;
    if (rst) begin
	capture_state <= HDR_CAPTURE;
	s_fifo_tvalid_int <= 1'b0;
	s_fifo_tready_int <= 1'b0;
    end
    else begin
	s_fifo_tdata <= s_fifo_tdata_int;
	s_fifo_tkeep <= s_fifo_tkeep_int;
	s_fifo_tvalid <= s_fifo_tvalid_int;
	s_fifo_tlast <= s_fifo_tlast_int;
	s_fifo_tready_int <= s_fifo_tready;
	s_axis_tready <= s_fifo_tready_int;

	// DMA signals
	s_axis_read_desc_addr = s_axis_read_desc_ready_int;
	s_axis_read_desc_len = s_axis_read_desc_ready_int;
	s_axis_read_desc_tag = s_axis_read_desc_ready_int;
	s_axis_read_desc_id = s_axis_read_desc_ready_int;
	s_axis_read_desc_dest = s_axis_read_desc_ready_int;
	s_axis_read_desc_user = s_axis_read_desc_ready_int;
	s_axis_read_desc_valid = s_axis_read_desc_ready_int;
	s_axis_read_desc_ready_int = s_axis_read_desc_ready;
    end
end

always @(posedge m_axi_aclk) begin
    axi_base_addr <= axi_base_addr_int;
    axi_base_addr_valid <= axi_base_addr_valid_int;
end

always @* begin
    capture_state_next = HDR_CAPTURE;
    frame_size = 0;
    case (capture_state)
	HDR_CAPTURE: begin
	    if (s_axis_tvalid && s_fifo_tready) begin
		case (func_type)
		    2'b00: begin
			if (!s_axis_tlast) begin
			    capture_state_next = FRAME_MEM_TRANSFER;
			end
			if (bitstream_size_valid) begin
			    bitstream_id_int = bitstream_id;
			    bitstream_size_int = bitstream_size;
			    bitstream_addr_int = bitstream_addr;
			    axi_base_addr_int = {ADDR_WIDTH{1'b0}};

			    pending_transfer_size = bitstream_size;
			    axi_base_addr_valid_int  = 1'b1;

			    // bitstream_addr_table[bitstream_id] = {bitstream_size, 0}; //add a check and figure out a way to calculate an addr
			    // also account for bitstream addr
			    s_fifo_tdata_int = s_axis_tdata >> ((ETH_IP_RMT_HDR_DATA_WIDTH + RECON_HDR_WIDTH)  * 8);
			    s_fifo_tkeep_int = ((s_axis_tkeep >> (ETH_IP_RMT_HDR_DATA_WIDTH + RECON_HDR_WIDTH)) & ETH_IP_RMT_HDR_RECON_HDR_KEEP_MASK) ;
			    s_fifo_tvalid_int = s_axis_tvalid && s_fifo_tready; // only commit if there's space
			    s_fifo_tlast_int = s_axis_tlast;
			    for (i = (KEEP_WIDTH - ETH_IP_RMT_HDR_DATA_WIDTH - RECON_HDR_WIDTH - 1); i >= 0; i = i - 1) begin // don't consider header
				frame_size = frame_size + s_fifo_tkeep_int[i];
			    end
			end // if (bitstream_size_valid)
			else begin
			    // +1 byte for func_type and bitstream_size_valid
			    s_fifo_tdata_int = s_axis_tdata >> ((ETH_IP_RMT_HDR_DATA_WIDTH + 1)  * 8);
			    s_fifo_tkeep_int = ((s_axis_tkeep >> (ETH_IP_RMT_HDR_DATA_WIDTH + 1)) & ETH_IP_RMT_HDR_KEEP_MASK);
			    s_fifo_tvalid_int = s_axis_tvalid && s_fifo_tready; // only commit if there's space
			    s_fifo_tlast_int = s_axis_tlast;
			    for (i = (KEEP_WIDTH - ETH_IP_RMT_HDR_DATA_WIDTH - 1); i >= 0; i = i - 1) begin // don't consider header
				frame_size = frame_size + s_fifo_tkeep_int[i];
			    end
			    axi_base_addr_valid_int = 1'b0;
			end
			if (pending_transfer_size >= frame_size) begin
			    pending_transfer_size -= frame_size;
			end
		    end
		    2'b01: begin
			capture_state_next = DMA_INIT;
			// create DMA command
		    end
		endcase
	    end // if (s_axis_tready && s_axis_tvalid)
	    else begin
	        s_fifo_tdata_int = {DATA_WIDTH{1'b0}};
		s_fifo_tkeep_int = {KEEP_WIDTH{1'b0}};
		s_fifo_tlast_int = 1'b0;
		s_fifo_tvalid_int = 1'b0;
		axi_base_addr_valid_int = 1'b0;
		capture_state_next = HDR_CAPTURE;
	    end
	end // case: HDR_CAPTURE
	FRAME_MEM_TRANSFER: begin
	    if (s_axis_tvalid && s_fifo_tready) begin
		if (s_axis_tlast) begin
		    capture_state_next = HDR_CAPTURE;
		end
		else begin
		    capture_state_next = FRAME_MEM_TRANSFER;
		end
		for (i = KEEP_WIDTH-1; i >= 0; i = i - 1) begin // don't consider header
		    frame_size = frame_size + s_axis_tkeep[i];
		end
		if(pending_transfer_size >= frame_size) begin
		    pending_transfer_size -= frame_size; // check for negative conditions do only if frame_size <= pending_transfer_size, if not then enable bad frame signal
		end
		// bitstream_addr_table[bitstream_id] = {bitstream_size, 0}; //add a check and figure out a way to calculate an addr
		s_fifo_tdata_int = s_axis_tdata;
		s_fifo_tkeep_int = s_axis_tkeep;
		s_fifo_tvalid_int = s_axis_tvalid && s_fifo_tready;
		s_fifo_tlast_int = s_axis_tlast;
		axi_base_addr_valid_int = 1'b0;
	    end
	    else begin
		capture_state_next = FRAME_MEM_TRANSFER;
	    end// if (s_axis_tready && s_axis_tvalid)
	    // if (pending_transfer_size == 0) begin
	    // 	capture_state_next = CAPTURE_DONE;
	    // end
	end // case: FRAME_MEM_TRANSFER
	// DMA_INIT: begin
	//     if (s_axis_read_desc_ready) begin

	//     end
	//     else begin
	// 	capture_state_next = DMA_INIT;
	//     end
	// end
    endcase
end // always @ *

// TODO: when fifo full pull down ready

axis_fifo_ex #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(1024)
)
axis_async_fifo_inst
(
    .s_clk(s_axis_clk),
    .s_rst(rst),
    .s_axis_tdata(s_fifo_tdata),
    .s_axis_tkeep(s_fifo_tkeep),
    .s_axis_tvalid(s_fifo_tvalid),
    .s_axis_tready(s_fifo_tready),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(),
    .s_axis_tdest(),
    .s_axis_tuser(),

    .m_clk(m_axi_aclk),
    .m_rst(rst),
    .m_axis_tdata(m_fifo_tdata),
    .m_axis_tkeep(m_fifo_tkeep),
    .m_axis_tvalid(m_fifo_tvalid),
    .m_axis_tready(m_fifo_tready),
    .m_axis_tlast(m_fifo_tlast),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser()
 );

axis_mm_bridge #
(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH),
    .ID_WIDTH(ID_WIDTH)
)
axis_mm_bridge_inst
(
    .clk(m_axi_aclk),
    .rst(rst),

    .s_axis_tdata(m_fifo_tdata),
    .s_axis_tkeep(m_fifo_tkeep),
    .s_axis_tlast(m_fifo_tlast),
    .s_axis_tvalid(m_fifo_tvalid),
    .s_axis_tready(m_fifo_tready),

    .axi_base_addr(axi_base_addr),
    .axi_base_addr_valid(axi_base_addr_valid),

    .m_axi_awready(m_axi_awready),
    .m_axi_awid(m_axi_awid),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awlen(m_axi_awlen),
    .m_axi_awsize(m_axi_awsize),
    .m_axi_awburst(m_axi_awburst),
    .m_axi_awlock(m_axi_awlock),
    .m_axi_awcache(m_axi_awcache),
    .m_axi_awprot(m_axi_awprot),
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_wready(m_axi_wready),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wstrb(m_axi_wstrb),
    .m_axi_wlast(m_axi_wlast),
    .m_axi_wvalid(m_axi_wvalid),
    .m_axi_bid(m_axi_bid),
    .m_axi_bresp(m_axi_bresp),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_bready(m_axi_bready)
    );

endmodule

`resetall
