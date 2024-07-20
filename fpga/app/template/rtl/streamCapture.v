module streamCapture #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ADDR_WIDTH = 34,
    parameter FIFO_DEPTH = 32
)
(
    input			clk_stream,
    input wire			m_axi_aclk,
    input			reset_stream,
    //input stream
    input			s_axis_tvalid,
    input [DATA_WIDTH-1:0]	s_axis_tdata,
    input [KEEP_WIDTH-1:0]	s_axis_tkeep,
    input			s_axis_tlast,
    output wire			s_axis_tready,
    // AXI MM Interface
    input			axi_awready, // Indicates slave is ready to accept a write address
    output reg [5 : 0]		axi_awid, // Write ID
    output reg [ADDR_WIDTH-1:0]	axi_awaddr, // Write address
    output [7 : 0]		axi_awlen, // Write Burst Length
    output [2 : 0]		axi_awsize, // Write Burst size
    output [1 : 0]		axi_awburst, // Write Burst type
    output			axi_awlock, // Write lock type
    output [3 : 0]		axi_awcache, // Write Cache type
    output [2 : 0]		axi_awprot, // Write Protection type
    output reg			axi_awvalid, // Write address valid
    ////////////////////////////////////////////////////////////////////////////
    // Master Interface Write Data
    input			axi_wd_wready, // Write data ready
    output [DATA_WIDTH-1:0]	axi_wd_data, // Write data
    output [KEEP_WIDTH-1:0]	axi_wd_strb, // Write strobes
    output			axi_wd_last, // Last write transaction
    output reg			axi_wd_valid, // Write valid
    ////////////////////////////////////////////////////////////////////////////
    // Master Interface Write Response
    input			axi_wd_bid, // Response ID
    input [1:0]			axi_wd_bresp, // Write response
    input			axi_wd_bvalid, // Write reponse valid
    output reg			axi_wd_bready, // Response ready

    input			startCapture,
    input [ADDR_WIDTH-1:0]	start_addr,
    output			o_capture_start,
    output			o_done,
    output wire			rd_en,
    output wire [31 : 0]	rd_ptr,
    output wire [31 : 0]	rd_prev_ptr,
    output wire [1 : 0]		wr_state,
    output wire			empty,
    output wire			full
    );

wire				fifo_tvalid;
wire [DATA_WIDTH-1:0]		fifo_tdata;
wire [KEEP_WIDTH-1:0]		fifo_tkeep;
wire				fifo_tlast;
wire				fifo_data_ready;
integer				dataCounter;
wire [31:0]			captureSize;
//wire			 startCapture;
reg				startCapture_p;
reg				startCapture_p1;
reg				startCaptureInt;
reg				resetCounter;
reg				done;
reg [1:0]			state;
reg [1:0]			wrState;
reg				capturePulse;
//wire [31 : 0]	 start_addr;
integer				i;
reg [DATA_WIDTH-1:0]		prev_data;
reg [DATA_WIDTH-1:0]		commit_data;
reg				commit_data_valid;
reg				fifo_rd_en = 1'b1;
wire [31 : 0]			ptr;
reg [31 : 0]			prev_ptr = FIFO_DEPTH - 1;

localparam			IDLE    = 'd0,
				CAPTURE = 'd1,
				DONE    = 'd2,
				WR_ADDR = 'd1,
				WR_DATA = 'd2;

localparam [2:0]
		HDR_CAPTURE = 3'd0,
		FRAME_MEM_TRANSFER = 3'd1,
		FRAME_DROP = 3'd2,
		DMA_INIT = 3'd3,
		CAPTURE_DONE = 3'd4,
		RECON_CPL = 3'd5;

reg [KEEP_WIDTH-1:0] REMOVE_HDR_MASK = { {(KEEP_WIDTH-8){1'b1}}, 8'b0 };

reg [2:0]	capture_state = HDR_CAPTURE, capture_state_next = HDR_CAPTURE;
reg [63:0]	recon_hdr;
reg [1:0]	func_type;
reg [7:0]	bitstream_id;
reg [15:0]	bitstream_size;
reg [7:0]	bitstream_id_int;
reg [15:0]	bitstream_size_int;
reg [15:0]	pending_transfer_size;
reg [$clog2(DATA_WIDTH):0] frame_size;
reg [KEEP_WIDTH-1:0]	   fifo_tkeep_int;
reg [DATA_WIDTH-1:0]	   fifo_tdata_int;
reg			   fifo_tvalid_int;
reg			   fifo_tlast_int;

reg [7:0]	bitstream_addr_table [0:ADDR_WIDTH+16+1-1]; // [size][ADDR][Valid]

assign recon_hdr = (HDR_CAPTURE && s_axis_tvalid) ? s_axis_tdata[46*8+:64] : 0; // hdr
assign func_type = (HDR_CAPTURE && s_axis_tvalid) ? recon_hdr [1:0] : 0;
assign bitstream_id = (HDR_CAPTURE && s_axis_tvalid) ? recon_hdr[2+:8] : 0;
assign bitstream_size = (HDR_CAPTURE && s_axis_tvalid) ? recon_hdr[10+:16] : 0;

assign s_axis_tready = 1'b1;
assign rd_en = fifo_rd_en;
assign rd_ptr = ptr;
assign rd_prev_ptr = prev_ptr;
assign wr_state = wrState;
assign fifo_tlast    =  (dataCounter == captureSize-1);
assign fifo_tvalid   =  startCaptureInt & commit_data_valid;
assign fifo_tdata    =  commit_data;
//assign fifo_tkeep    =  s_axis_tkeep;
assign fifo_tkeep = 64'hffff_ffff_ffff_ffff;
assign o_done = done;
assign o_capture_start = startCapture_p1;
assign axi_awlen     = 8'd0;
assign axi_awsize    = 3'd6;
assign axi_awburst   = 2'd1;
assign axi_awcache   = 4'd0;
assign axi_awprot    = 3'd0;
//assign axi_awid      = 1'd0;
assign axi_awlock    = 1'd0;
assign axi_wd_last   = axi_wd_valid;


always @(posedge clk_stream) begin
    startCapture_p <= startCapture;
    startCapture_p1 <= startCapture_p;
    capturePulse <= startCapture_p&~startCapture_p1;
end


always @(posedge clk_stream) begin
    if(resetCounter)
        dataCounter <= 0;
    else if(s_axis_tvalid & dataCounter == captureSize-1)
    	dataCounter <= 0;
    else if(startCaptureInt & s_axis_tvalid)
	begin
    	    dataCounter <= dataCounter + 1;
	end
end

always @* begin
    case (capture_state)
	HDR_CAPTURE: begin
	    if (s_axis_tready && s_axis_tvalid) begin
		case (func_type)
		    2'b00: begin
			capture_state_next = FRAME_MEM_TRANSFER;
			for (i = KEEP_WIDTH-1; i >= 8; i = i - 1) begin // don't consider header
			    frame_size = frame_size + s_axis_tkeep[i];
			end
			pending_transfer_size -= frame_size;
			bitstream_id_int = bitstream_id;
			bitstream_size_int = bitstream_size;
			// bitstream_addr_table[bitstream_id] = {bitstream_size, 0}; //add a check and figure out a way to calculate an addr
			fifo_tdata_int = s_axis_tdata;
			fifo_tkeep_int = s_axis_tkeep & REMOVE_HDR_MASK;
			fifo_tvalid_int = s_axis_tvalid;
			fifo_tlast_int = s_axis_tlast;
		    end
		    2'b01: begin
			capture_state_next = DMA_INIT;
			// create DMA command
		    end
		endcase
	    end
	end // case: HDR_CAPTURE
	FRAME_MEM_TRANSFER: begin
	    if (s_axis_tready && s_axis_tvalid) begin
		for (i = KEEP_WIDTH-1; i >= 8; i = i - 1) begin // don't consider header
		    frame_size = frame_size + s_axis_tkeep[i];
		end
		pending_transfer_size -= frame_size; // check for negative conditions do only if frame_size <= pending_transfer_size
		bitstream_id_int = bitstream_id;
		bitstream_size_int = bitstream_size;
		// bitstream_addr_table[bitstream_id] = {bitstream_size, 0}; //add a check and figure out a way to calculate an addr
		fifo_tdata_int = s_axis_tdata;
		fifo_tkeep_int = s_axis_tkeep & REMOVE_HDR_MASK;
		fifo_tvalid_int = s_axis_tvalid;
		fifo_tlast_int = s_axis_tlast;
	    end // if (s_axis_tready && s_axis_tvalid)
	    if (pending_transfer_size == 0) begin
		capture_state_next = CAPTURE_DONE;
	    end
	end
    endcase
end // always @ *

// expected 64 byte payload received in chunks of two 64 byte packets.
// first packet contains header + 22 byte payload
// second packet contains rest of the payload.
// tlast signals second packet of the two, below code extracts
// payload from both packets and pack in a single 64 byte packet i.e
// data width off DDR axi bus.
always @(posedge clk_stream) begin
    if(resetCounter)
	begin
	    prev_data <= 0;
	    commit_data <= 0;
	    commit_data_valid <= 1'b0;
	end
    else if(s_axis_tvalid & startCapture & !s_axis_tlast) begin
	prev_data <= s_axis_tdata;
	commit_data_valid <= 1'b0;
    end
    else if(s_axis_tvalid & startCapture & s_axis_tlast)
	begin
	    commit_data <= prev_data >> 336 | s_axis_tdata << 176;
	    commit_data_valid <= 1'b1;
	end
    else begin
	commit_data_valid <= 1'b0;
    end
end


always @(posedge clk_stream) begin
    if(reset_stream) begin
        state <= IDLE;
        resetCounter <= 1'b1;
        done <= 1'b0;
    end
    else begin
        case(state)
            IDLE:begin
		if(startCapture_p1) begin
                    resetCounter <= 1'b1;
                    state <= CAPTURE;
		end
            end
            CAPTURE:begin
		startCaptureInt <= 1'b1;
		resetCounter <= 1'b0;
		if((dataCounter == captureSize-1) & s_axis_tvalid) begin
                    startCaptureInt <= 1'b0;
                    state <= DONE;
		end
            end
            DONE:begin
		done <= 1'b1;
		if(!startCapture_p1) begin
                    state <= IDLE;
                    done <= 1'b0;
		end
            end
        endcase
    end
end


always @(posedge m_axi_aclk) begin
    if(reset_stream) begin
        axi_awvalid  <= 1'b0;
        axi_wd_valid <= 1'b0;
        wrState <= IDLE;
    end
    else begin
        case(wrState)
            IDLE:begin
		if(capturePulse) begin
                    axi_awaddr <= start_addr;
		end
		// check is there's something to send
		if(fifo_data_ready && (ptr!=prev_ptr)) begin
                    axi_awvalid  <= 1'b1;
		    wrState      <= WR_ADDR;
                    //axi_awid <= axi_awid + 1'b1;
		    fifo_rd_en <= 1'b0; // no more read from the fifo in sending process
		end
            end
            WR_ADDR:begin
		if(axi_awready) begin
                    axi_awvalid  <= 1'b0;
                    axi_wd_valid <= 1'b1;
                    // for(i = 0; i < 64; i=i+1) begin
                    //    if(axi_wd_strb[i])
                    //      axi_awaddr = axi_awaddr+1;
		    // end
		    // increment address by 64 byte
		    axi_awaddr <= axi_awaddr + 64;
                    wrState <= WR_DATA;
		end
            end
            WR_DATA:begin
		if(axi_wd_wready) begin
                    axi_wd_valid <= 1'b0;
		    // account for cirular buffer
		    if(prev_ptr == (FIFO_DEPTH - 1)) begin
			prev_ptr <= 0;
		    end
		    else begin
			prev_ptr <= prev_ptr + 1;
		    end
		    fifo_rd_en <= 1'b1;
		    wrState <= IDLE;
		end
            end
        endcase
    end
end


always @(posedge m_axi_aclk) begin
    if(reset_stream)
        axi_wd_bready <= 1'b0;
    else if(axi_wd_bready)
        axi_wd_bready <= 1'b0;
    else if(axi_wd_bvalid)
        axi_wd_bready <= 1'b1;
end


// internal_regs #
//   (
//    .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
//    .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
//    )
// internal_regs_inst
//   (
//    .S_AXI_ACLK(s00_axi_aclk),
//    .S_AXI_ARESETN(s00_axi_aresetn),
//    .S_AXI_AWADDR(s00_axi_awaddr),
//    .S_AXI_AWPROT(s00_axi_awprot),
//    .S_AXI_AWVALID(s00_axi_awvalid),
//    .S_AXI_AWREADY(s00_axi_awready),
//    .S_AXI_WDATA(s00_axi_wdata),
//    .S_AXI_WSTRB(s00_axi_wstrb),
//    .S_AXI_WVALID(s00_axi_wvalid),
//    .S_AXI_WREADY(s00_axi_wready),
//    .S_AXI_BRESP(s00_axi_bresp),
//    .S_AXI_BVALID(s00_axi_bvalid),
//    .S_AXI_BREADY(s00_axi_bready),
//    .S_AXI_ARADDR(s00_axi_araddr),
//    .S_AXI_ARPROT(s00_axi_arprot),
//    .S_AXI_ARVALID(s00_axi_arvalid),
//    .S_AXI_ARREADY(s00_axi_arready),
//    .S_AXI_RDATA(s00_axi_rdata),
//    .S_AXI_RRESP(s00_axi_rresp),
//    .S_AXI_RVALID(s00_axi_rvalid),
//    .S_AXI_RREADY(s00_axi_rready),
//    .o_start_addr(start_addr),
//    .o_captureSize(captureSize),
//    .o_startCapture(startCapture),
//    .i_done(done)
//    );


axis_fifo_ex #
    (.DATA_WIDTH(DATA_WIDTH),
    .KEEP_WIDTH(KEEP_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
	)
axis_fifo_inst
    (
    .s_axis_areset(reset_stream),
    .s_axis_aclk(clk_stream),
    .s_axis_tvalid(fifo_tvalid),  // fifo: wr_en
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(fifo_tdata),
    .s_axis_tkeep(fifo_tkeep),
    .s_axis_tlast(fifo_tlast),
    .m_axis_aclk(m_axi_aclk), // for FIFO it is axis and for streamCapture it is axi
    .m_axis_tvalid(fifo_data_ready),
    .m_axis_tready(fifo_rd_en), // fifo: rd_en
    .m_axis_tdata(axi_wd_data),
    .m_axis_tkeep(axi_wd_strb),
    .m_axis_tlast(),
    .empty(empty),
    .full(full),
    .ptr(ptr),
    .mon_ptr(prev_ptr)
	);


endmodule
