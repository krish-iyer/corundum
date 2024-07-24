module streamCapture #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ADDR_WIDTH = 34,
    parameter FIFO_DEPTH = 32
)
(
    input		    s_axis_clk,
    input wire		    m_axi_aclk,
    input		    rst,
    //input stream
    input		    s_axis_tvalid,
    input [DATA_WIDTH-1:0]  s_axis_tdata,
    input [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input		    s_axis_tlast,
    output reg		    s_axis_tready,

    input		    m_axi_awready,
    output [5 : 0]	    m_axi_awid,
    output [ADDR_WIDTH-1:0] m_axi_awaddr,
    output [7 : 0]	    m_axi_awlen,
    output [2 : 0]	    m_axi_awsize,
    output [1 : 0]	    m_axi_awburst,
    output		    m_axi_awlock,
    output [3 : 0]	    m_axi_awcache,
    output [2 : 0]	    m_axi_awprot,
    output		    m_axi_awvalid,
    input		    m_axi_wready,
    output [DATA_WIDTH-1:0] m_axi_wdata,
    output [KEEP_WIDTH-1:0] m_axi_wstrb,
    output		    m_axi_wlast,
    output		    m_axi_wvalid,
    input		    m_axi_bid,
    input [1:0]		    m_axi_bresp,
    input		    m_axi_bvalid,
    output		    m_axi_bready,

    input		    startCapture,
    input [ADDR_WIDTH-1:0]  start_addr,
    output		    o_capture_start,
    output		    o_done,
    output wire		    rd_en,
    output wire [31 : 0]    rd_ptr,
    output wire [31 : 0]    rd_prev_ptr,
    output wire [1 : 0]	    wr_state,
    output wire		    empty,
    output wire		    full
    );


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

reg [2:0]	capture_state = HDR_CAPTURE, capture_state_next = HDR_CAPTURE;
reg [63:0]	recon_hdr;
reg [1:0]	func_type;
reg [7:0]	bitstream_id;
reg [31:0]	bitstream_size;
reg		bitstream_size_valid;
reg [7:0]	bitstream_id_int;
reg [31:0]	bitstream_size_int;
reg [31:0]	pending_transfer_size = 0;
reg [$clog2(DATA_WIDTH):0] frame_size = 0;

wire [DATA_WIDTH-1:0]		fifo_tdata;
wire [KEEP_WIDTH-1:0]		fifo_tkeep;
wire				fifo_tlast;
wire				fifo_tvalid;
wire				fifo_data_ready;


reg [DATA_WIDTH-1:0]		s_fifo_tdata;
reg [KEEP_WIDTH-1:0]		s_fifo_tkeep;
reg				s_fifo_tlast;
reg				s_fifo_tvalid;

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

localparam integer ETH_IP_RMT_HDR_DATA_WIDTH = 46; // bytes
localparam [63:0]  ETH_IP_RMT_HDR_KEEP_MASK = 64'h000000000003FFFF;

assign recon_hdr = ((capture_state == HDR_CAPTURE) && s_axis_tvalid) ? s_axis_tdata[46*8+:64] : 0; // hdr
assign func_type = ((capture_state == HDR_CAPTURE) && s_axis_tvalid) ? recon_hdr [1:0] : 0;
assign bitstream_id = ((capture_state == HDR_CAPTURE) && s_axis_tvalid) ? recon_hdr[2+:8] : 0;
assign bitstream_size_valid = ((capture_state == HDR_CAPTURE) && s_axis_tvalid) ? recon_hdr[31+:1] : 0;
assign bitstream_size = ((capture_state == HDR_CAPTURE) && s_axis_tvalid) ? recon_hdr[32+:32] : 0;


assign o_done = 1'b1;
assign o_capture_start = 1'b1;

always @(posedge s_axis_clk) begin
    capture_state <= capture_state_next;
    if (rst) begin
	capture_state <= HDR_CAPTURE;
	capture_state_next <= HDR_CAPTURE;
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
    end
end

always @(posedge m_axi_aclk) begin
    axi_base_addr <= axi_base_addr_int;
    axi_base_addr_valid <= axi_base_addr_valid_int;
end

always @* begin
    frame_size = 0;
    case (capture_state)
	HDR_CAPTURE: begin
	    if (s_axis_tready && s_axis_tvalid) begin
		case (func_type)
		    2'b00: begin
			if (!s_axis_tlast) begin
			    capture_state_next = FRAME_MEM_TRANSFER;
			end
			bitstream_id_int = bitstream_id;
			bitstream_size_int = bitstream_size;
			axi_base_addr_int = {ADDR_WIDTH{1'b0}};
			if (bitstream_size_valid) begin
			    pending_transfer_size = bitstream_size;
			    axi_base_addr_valid_int  = 1'b1;
			end
			else begin
			    axi_base_addr_valid_int = 1'b0;
			end
			// bitstream_addr_table[bitstream_id] = {bitstream_size, 0}; //add a check and figure out a way to calculate an addr
			s_fifo_tdata_int = s_axis_tdata >> (ETH_IP_RMT_HDR_DATA_WIDTH * 8);
			s_fifo_tkeep_int = ((s_axis_tkeep >> ETH_IP_RMT_HDR_DATA_WIDTH) & ETH_IP_RMT_HDR_KEEP_MASK) ;
			s_fifo_tvalid_int = s_axis_tvalid & s_axis_tready; // only commit if there's space
			s_fifo_tlast_int = s_axis_tlast;
			for (i = (KEEP_WIDTH - ETH_IP_RMT_HDR_DATA_WIDTH - 1); i >= 0; i = i - 1) begin // don't consider header
			    frame_size = frame_size + s_fifo_tkeep_int[i];
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
	    end
	end // case: HDR_CAPTURE
	FRAME_MEM_TRANSFER: begin
	    if (s_axis_tready && s_axis_tvalid) begin
		if (s_axis_tlast) begin
		    capture_state_next = HDR_CAPTURE;
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
		s_fifo_tvalid_int = s_axis_tvalid & s_axis_tready;
		s_fifo_tlast_int = s_axis_tlast;
		axi_base_addr_valid_int = 1'b0;
	    end // if (s_axis_tready && s_axis_tvalid)
	    // if (pending_transfer_size == 0) begin
	    // 	capture_state_next = CAPTURE_DONE;
	    // end
	end // case: FRAME_MEM_TRANSFER
    endcase
end // always @ *

// TODO: when fifo full pull down ready
axis_fifo_ex #
(
    .DATA_WIDTH(DATA_WIDTH),
    .KEEP_WIDTH(KEEP_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
)
axis_fifo_inst
(
    .s_axis_areset(rst),
    .s_axis_aclk(s_axis_clk),
    .s_axis_tvalid(s_fifo_tvalid),  // fifo: wr_en
    .s_axis_tready(s_fifo_tready),
    .s_axis_tdata(s_fifo_tdata),
    .s_axis_tkeep(s_fifo_tkeep),
    .s_axis_tlast(s_fifo_tlast),
    .m_axis_aclk(m_axi_aclk), // for FIFO it is axis and for streamCapture it is axi
    .m_axis_tvalid(m_fifo_tvalid),
    .m_axis_tready(m_fifo_tready), // fifo: rd_en
    .m_axis_tdata(m_fifo_tdata),
    .m_axis_tkeep(m_fifo_tkeep),
    .m_axis_tlast(m_fifo_tlast),
    .empty(empty),
    .full(full),
    .ptr(ptr),
    .mon_ptr(prev_ptr)
    );


axi_ctrl #
(
    .DATA_WIDTH(DATA_WIDTH),
    .KEEP_WIDTH(KEEP_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
)
axi_ctrl_inst
(
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
