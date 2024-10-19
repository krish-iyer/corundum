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
    input wire				clk,
    input wire				rst,
    //input stream
    input wire				s_axis_tvalid,
    input wire [DATA_WIDTH-1:0]		s_axis_tdata,
    input wire [KEEP_WIDTH-1:0]		s_axis_tkeep,
    input wire				s_axis_tlast,
    output wire				s_axis_tready,

    output reg [ADDR_WIDTH-1:0]		m_axis_read_desc_addr,
    output reg [DMA_DESC_LEN_WIDTH-1:0]	m_axis_read_desc_len,
    output reg [DMA_DESC_TAG_WIDTH-1:0]	m_axis_read_desc_tag,
    output reg [ID_WIDTH-1:0]		m_axis_read_desc_id,
    output reg [DEST_WIDTH-1:0]		m_axis_read_desc_dest,
    output reg [USER_WIDTH-1:0]		m_axis_read_desc_user,
    output reg				m_axis_read_desc_valid,
    input wire				m_axis_read_desc_ready,

    output reg [ADDR_WIDTH-1:0]		m_axis_write_desc_addr,
    output reg [DMA_DESC_LEN_WIDTH-1:0]	m_axis_write_desc_len,
    output reg [DMA_DESC_TAG_WIDTH-1:0]	m_axis_write_desc_tag,
    output reg				m_axis_write_desc_valid,
    input wire				m_axis_write_desc_ready,

    output wire				m_axis_tvalid,
    output wire [DATA_WIDTH-1:0]	m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]	m_axis_tkeep,
    output wire				m_axis_tlast,
    input wire				m_axis_tready
);

localparam integer ETH_IP_RMT_HDR_DATA_WIDTH = 46; // bytes
localparam [63:0]  ETH_IP_RMT_HDR_KEEP_MASK  = 64'h000000000003FFFF; // + bitstream_addr
localparam [63:0]  ETH_IP_RMT_HDR_KEEP_MASK2 = 64'h00003FFFFFFFFFFF; // + bitstream_addr
localparam [63:0]  ETH_IP_RMT_HDR_RECON_HDR_KEEP_MASK = 64'h00000000000000FF; // + bitstream_addr
localparam [63:0]  FULL_TRANSFER_TKEEP = 64'hFFFF_FFFF_FFFF_FFFF; // + bitstream_addr

localparam integer RECON_HDR_WIDTH = 10; //bytes

reg [ADDR_WIDTH-1:0] m_axis_read_desc_addr_int = {ADDR_WIDTH{1'b0}};
reg [DMA_DESC_LEN_WIDTH-1:0] m_axis_read_desc_len_int = {DMA_DESC_LEN_WIDTH{1'b0}};
reg [DMA_DESC_TAG_WIDTH-1:0] m_axis_read_desc_tag_int = {DMA_DESC_TAG_WIDTH{1'b0}};
reg [ID_WIDTH-1:0]	     m_axis_read_desc_id_int = {ID_WIDTH{1'b0}};
reg [DEST_WIDTH-1:0]	     m_axis_read_desc_dest_int = {DEST_WIDTH{1'b0}};
reg [USER_WIDTH-1:0]	     m_axis_read_desc_user_int = {USER_WIDTH{1'b0}};
reg			     m_axis_read_desc_valid_int = 0;
reg			     m_axis_read_desc_ready_int = 0;

reg [ADDR_WIDTH-1:0]	     m_axis_write_desc_addr_int = {ADDR_WIDTH{1'b0}};
reg [DMA_DESC_LEN_WIDTH-1:0] m_axis_write_desc_len_int = {DMA_DESC_LEN_WIDTH{1'b0}};
reg [DMA_DESC_TAG_WIDTH-1:0] m_axis_write_desc_tag_int = {DMA_DESC_TAG_WIDTH{1'b0}};
reg [ID_WIDTH-1:0]	     m_axis_write_desc_id_int = {ID_WIDTH{1'b0}};
reg [DEST_WIDTH-1:0]	     m_axis_write_desc_dest_int = {DEST_WIDTH{1'b0}};
reg [USER_WIDTH-1:0]	     m_axis_write_desc_user_int = {USER_WIDTH{1'b0}};
reg			     m_axis_write_desc_valid_int = 0;
reg			     m_axis_write_desc_ready_int = 0;

integer			    i;
wire [31 : 0]		    ptr;
reg [31 : 0]		    prev_ptr = FIFO_DEPTH - 1;

localparam [2:0]
		HDR_CAPTURE = 3'd0,
		DMA_READ_INIT = 3'd1,
		DMA_WRITE_INIT = 3'd2,
		DMA_WRITE_TRANSFER  = 3'd3
		;

reg [2:0]	capture_state = HDR_CAPTURE, capture_state_next;
wire [RECON_HDR_WIDTH*8:0] recon_hdr;
wire [1:0]	func_type;
wire [7:0]	bitstream_id;
wire [31:0]	bitstream_size;
wire [34:0]	bitstream_addr;
wire		bitstream_size_valid;

reg [7:0]	bitstream_id_int;
reg [31:0]	bitstream_size_int;
reg [34:0]	bitstream_addr_int;

reg [34:0]	save_bitstream_addr = 0;
reg [7:0]	save_bitstream_id = 0;
reg [31:0]	save_bitstream_size = 0;

reg [31:0]	pending_transfer_size = 0;
reg [31:0]	pending_transfer_size_int = 0;

reg [$clog2(DATA_WIDTH):0] frame_size = 0;
reg [$clog2(DATA_WIDTH):0] frame_size_int = 0;

reg [DATA_WIDTH-1:0]	   save_tdata=0;
reg [DATA_WIDTH-1:0]	   save_tdata_int=0;

reg [KEEP_WIDTH-1:0]	   s_axis_tkeep_int;
reg [DATA_WIDTH-1:0]	   s_axis_tdata_int;
reg			   s_axis_tvalid_int = 1'b0;
reg			   s_axis_tlast_int;
reg			   s_axis_tready_int;


reg [KEEP_WIDTH-1:0]	   s_axis_out_fifo_tkeep;
reg [DATA_WIDTH-1:0]	   s_axis_out_fifo_tdata;
reg			   s_axis_out_fifo_tvalid = 1'b0;
reg			   s_axis_out_fifo_tlast;
wire			   s_axis_out_fifo_tready;


wire [KEEP_WIDTH-1:0]	   m_axis_in_fifo_tkeep;
wire [DATA_WIDTH-1:0]	   m_axis_in_fifo_tdata;
wire			   m_axis_in_fifo_tvalid;
wire			   m_axis_in_fifo_tlast;
reg			   m_axis_in_fifo_tready = 1'b1;

reg			   m_axis_in_fifo_tready_int = 1'b1;


reg [KEEP_WIDTH-1:0]	   m_axis_tkeep_int;
reg [DATA_WIDTH-1:0]	   m_axis_tdata_int;
reg			   m_axis_tvalid_int = 1'b0;
reg			   m_axis_tlast_int;
reg			   m_axis_tready_int;

reg [7:0]		   bitstream_addr_table [0:ADDR_WIDTH+16+1-1]; // [size][ADDR][Valid]


assign recon_hdr = ((capture_state == HDR_CAPTURE) && m_axis_in_fifo_tvalid) ?
		   m_axis_in_fifo_tdata[ETH_IP_RMT_HDR_DATA_WIDTH*8+:RECON_HDR_WIDTH*8] : 0;
assign func_type = ((capture_state == HDR_CAPTURE) && m_axis_in_fifo_tvalid) ? recon_hdr [1:0] : 0;
assign bitstream_size_valid = ((capture_state == HDR_CAPTURE) && m_axis_in_fifo_tvalid) ? recon_hdr[2] : 0;
assign bitstream_addr = ((capture_state == HDR_CAPTURE) && m_axis_in_fifo_tvalid) ? recon_hdr[3+:34] : 0;
assign bitstream_id = ((capture_state == HDR_CAPTURE) && m_axis_in_fifo_tvalid) ? recon_hdr[37+:8] : 0;
assign bitstream_size = ((capture_state == HDR_CAPTURE) && m_axis_in_fifo_tvalid) ? recon_hdr[45+:32] : 0;

integer		count_ones_var = 0;

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
    capture_state <= capture_state_next;
    if (rst) begin
	capture_state <= HDR_CAPTURE;
	//s_fifo_tvalid_int <= 1'b0;
	//s_fifo_tready_int <= 1'b0;
	frame_size <= 0;
    end
    else begin

	pending_transfer_size <= pending_transfer_size_int;
	frame_size <= frame_size_int;
	save_tdata <= save_tdata_int;
	save_bitstream_addr <= bitstream_addr_int;
	save_bitstream_size <= bitstream_size_int;

	m_axis_in_fifo_tready <= m_axis_in_fifo_tready_int;

	s_axis_out_fifo_tdata <= s_axis_tdata_int;
	s_axis_out_fifo_tkeep <= s_axis_tkeep_int;
	s_axis_out_fifo_tvalid <= s_axis_tvalid_int;
	s_axis_out_fifo_tlast <= s_axis_tlast_int;

	// DMA read signals
	m_axis_read_desc_addr <= m_axis_read_desc_addr_int;
	m_axis_read_desc_len <= m_axis_read_desc_len_int;
	m_axis_read_desc_tag <= m_axis_read_desc_tag_int;
	m_axis_read_desc_id <= m_axis_read_desc_id_int;
	m_axis_read_desc_dest <= m_axis_read_desc_dest_int;
	m_axis_read_desc_user <= m_axis_read_desc_user_int;
	m_axis_read_desc_valid <= m_axis_read_desc_valid_int;
	m_axis_read_desc_ready_int <= m_axis_read_desc_ready;

	// DMA write signals
	m_axis_write_desc_addr <= m_axis_write_desc_addr_int;
	m_axis_write_desc_len <= m_axis_write_desc_len_int;
	m_axis_write_desc_tag <= m_axis_write_desc_tag_int;
	m_axis_write_desc_valid <= m_axis_write_desc_valid_int;
	m_axis_write_desc_ready_int <= m_axis_write_desc_ready;

    end
end

always @* begin
    capture_state_next = HDR_CAPTURE;
    frame_size = 0;
    case (capture_state)
	HDR_CAPTURE: begin
	    if (m_axis_in_fifo_tvalid) begin
		if (bitstream_size_valid) begin
		    bitstream_id_int = bitstream_id;
		    bitstream_size_int = bitstream_size;
		    bitstream_addr_int = bitstream_addr;
		    pending_transfer_size_int = bitstream_size;
		    m_axis_in_fifo_tready_int = 1'b0;
		    // initiate DMA_WRITE
		    case (func_type)
			2'b00: begin
			    capture_state_next = DMA_WRITE_INIT;
			end
			2'b01: begin
			    capture_state_next = DMA_READ_INIT;
			end
		    endcase
		end // if (bitstream_size_valid)
		else begin
		    // +1 byte for func_type and bitstream_size_valid
		    if (func_type == 0) begin
			save_tdata_int = m_axis_in_fifo_tdata >> ((ETH_IP_RMT_HDR_DATA_WIDTH + 1)  * 8);
			s_axis_tkeep_int = ((m_axis_in_fifo_tkeep >> (ETH_IP_RMT_HDR_DATA_WIDTH + 1)) &
					   ETH_IP_RMT_HDR_KEEP_MASK);
			m_axis_write_desc_valid_int = 1'b0;
			frame_size_int = count_ones(s_axis_tkeep_int);
			m_axis_in_fifo_tready_int = 1'b1;
			s_axis_tlast_int = 1'b0;
			if (!m_axis_in_fifo_tlast) begin
			    capture_state_next = DMA_WRITE_TRANSFER;
			end
		    end
		    else begin // received data in just one packet
			s_axis_tdata_int = save_tdata_int; // TODO: might contain checksum. beware
			s_axis_tvalid_int = s_axis_tvalid && s_axis_tready;
		    end
		end
	    end
	    else begin
	        s_axis_tdata_int = {DATA_WIDTH{1'b0}};
		s_axis_tkeep_int = {KEEP_WIDTH{1'b0}};
		s_axis_tlast_int = 1'b0;
		s_axis_tvalid_int = 1'b0;
		m_axis_in_fifo_tready_int = 1'b1;
		capture_state_next = HDR_CAPTURE;
	    end // else: !if(m_axis_in_fifo_tvalid)
	    m_axis_read_desc_valid_int = 1'b0;
	    m_axis_write_desc_valid_int = 1'b0;
	end // case: HDR_CAPTURE
	DMA_WRITE_INIT: begin
	    if (m_axis_write_desc_ready) begin
		m_axis_write_desc_addr_int = save_bitstream_addr;
		m_axis_write_desc_len_int = save_bitstream_size;
		m_axis_write_desc_valid_int = 1'b1;
		m_axis_in_fifo_tready_int = 1'b1;
		capture_state_next = HDR_CAPTURE;
	    end
	    else begin
		capture_state_next = DMA_WRITE_INIT;
	    end
	end
	DMA_READ_INIT: begin
	    if (m_axis_read_desc_ready) begin
		m_axis_read_desc_addr_int = save_bitstream_addr;
		m_axis_read_desc_len_int = save_bitstream_size;
		m_axis_read_desc_valid_int = 1'b1;
		m_axis_in_fifo_tready_int = 1'b1;
		capture_state_next = HDR_CAPTURE;
	    end
	    else begin
		capture_state_next = DMA_READ_INIT;
	    end
	end // case: DMA_READ_INIT
	DMA_WRITE_TRANSFER: begin
	    if (m_axis_in_fifo_tvalid && m_axis_in_fifo_tready) begin
		if (m_axis_in_fifo_tlast) begin
		    capture_state_next = HDR_CAPTURE;
		end
		else begin
		    capture_state_next = DMA_WRITE_TRANSFER;
		end
		s_axis_tdata_int = save_tdata | m_axis_in_fifo_tdata << 136; // 17*8
		s_axis_tkeep_int = FULL_TRANSFER_TKEEP;
		s_axis_tvalid_int = m_axis_in_fifo_tvalid && m_axis_in_fifo_tready;
		s_axis_tlast_int = 1'b0;
	    end
	    else begin
		capture_state_next = DMA_WRITE_TRANSFER;
	    end// if (s_axis_tready && s_axis_tvalid)
	    m_axis_write_desc_valid_int = 1'b0;
	    m_axis_read_desc_valid_int = 1'b0;
	end // case: DMA_WRITE_TRANSFER
    endcase
end // always @ *

axis_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(2048),
    .FRAME_FIFO(1),
    .RAM_PIPELINE(1)
)
axis_in_fifo_inst
(
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(),
    .s_axis_tdest(),
    .s_axis_tuser(),

    .m_axis_tdata(m_axis_in_fifo_tdata),
    .m_axis_tkeep(m_axis_in_fifo_tkeep),
    .m_axis_tvalid(m_axis_in_fifo_tvalid),
    .m_axis_tready(m_axis_in_fifo_tready),
    .m_axis_tlast(m_axis_in_fifo_tlast),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser(),

    .pause_req(),
    .pause_ack(),

    .status_depth(),
    .status_depth_commit(),
    .status_overflow(),
    .status_bad_frame(),
    .status_good_frame()
 );


axis_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(2048),
    .FRAME_FIFO(0),
    .RAM_PIPELINE(3)
)
axis_out_fifo_inst
(
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(s_axis_out_fifo_tdata),
    .s_axis_tkeep(s_axis_out_fifo_tkeep),
    .s_axis_tvalid(s_axis_out_fifo_tvalid),
    .s_axis_tready(s_axis_out_fifo_tready),
    .s_axis_tlast(s_axis_out_fifo_tlast),
    .s_axis_tid(),
    .s_axis_tdest(),
    .s_axis_tuser(),

    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser(),

    .pause_req(),
    .pause_ack(),

    .status_depth(),
    .status_depth_commit(),
    .status_overflow(),
    .status_bad_frame(),
    .status_good_frame()
 );


// ila_recon recon_ila_inst (
//     .clk(clk), // input wire clk
//     .probe0(capture_state), // input wire [2:0]  probe0
//     .probe1(func_type), // input wire [1:0]  probe1
//     .probe2(bitstream_id), // input wire [7:0]  probe2
//     .probe3(bitstream_size), // input wire [31:0]  probe3
//     .probe4(bitstream_size_valid), // input wire [0:0]  probe4
//     .probe5(bitstream_addr), // input wire [33:0]  probe5
//     .probe6(m_axis_read_desc_len), // input wire [22:0]  probe6
//     .probe7(m_axis_read_desc_valid), // input wire [0:0]  probe7
//     .probe8(m_axis_read_desc_addr), // input wire [33:0]  probe8
//     .probe9(m_axis_read_desc_ready), // input wire [0:0]  probe9
//     .probe10(m_axis_write_desc_len), // input wire [22:0]  probe10
//     .probe11(m_axis_write_desc_valid), // input wire [0:0]  probe11
//     .probe12(m_axis_write_desc_addr), // input wire [33:0]  probe12
//     .probe13(m_axis_write_desc_ready) // input wire [0:0]  probe13
//     );



endmodule

`resetall
