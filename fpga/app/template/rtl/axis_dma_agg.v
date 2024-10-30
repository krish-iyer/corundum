`resetall
`timescale 1ns / 1ps
`default_nettype none

module axis_dma_agg #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8)
)
(
    input wire			 clk,
    input wire			 rst,
    //input stream
    input wire			 s_axis_tvalid,
    input wire [DATA_WIDTH-1:0]	 s_axis_tdata,
    input wire [KEEP_WIDTH-1:0]	 s_axis_tkeep,
    input wire			 s_axis_tlast,
    output wire			 s_axis_tready,

    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire [KEEP_WIDTH-1:0] m_axis_tkeep,
    output wire			 m_axis_tlast,
    output wire			 m_axis_tvalid,
    input wire			 m_axis_tready
);

reg [DATA_WIDTH-1:0]		 m_axis_tdata_int;
reg [KEEP_WIDTH-1:0]		 m_axis_tkeep_int;
reg				 m_axis_tlast_int;
reg				 m_axis_tvalid_int;
reg				 m_axis_tready_int;


reg [KEEP_WIDTH-1:0]		 s_axis_out_fifo_tkeep;
reg [DATA_WIDTH-1:0]		 s_axis_out_fifo_tdata;
reg				 s_axis_out_fifo_tvalid = 1'b0;
reg				 s_axis_out_fifo_tlast;
wire				 s_axis_out_fifo_tready;


reg [$clog2(KEEP_WIDTH):0] cur_frame_width=0, cur_frame_width_int=0, free_frame_width=KEEP_WIDTH,
				    free_frame_width_int=KEEP_WIDTH, split_frame_width=0, split_frame_width_int, frame_width;
reg [DATA_WIDTH-1:0]	     save_tdata={DATA_WIDTH{1'b0}}, save_tdata_int={DATA_WIDTH{1'b0}}, split_tdata=0, split_tdata_int;

localparam		     FULL_TRANSFER_TKEEP = {KEEP_WIDTH{1'b1}};

assign s_axis_tready = s_axis_out_fifo_tready;

   reg 			     save_tlast_int;
   reg 			     save_tlast;
   
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
    if (rst) begin
	//s_axis_tready <= 0;
	s_axis_out_fifo_tvalid <= 0;
	free_frame_width <= KEEP_WIDTH;
	cur_frame_width <= 0;
    end
    else begin
	cur_frame_width <= cur_frame_width_int;
	free_frame_width <= free_frame_width_int;
	save_tdata <= save_tdata_int;
	split_tdata <= split_tdata_int;
	split_frame_width <= split_frame_width_int;
        save_tlast <= save_tlast_int;
       
	s_axis_out_fifo_tdata <= m_axis_tdata_int;
	s_axis_out_fifo_tkeep <= m_axis_tkeep_int;
	s_axis_out_fifo_tvalid <= m_axis_tvalid_int;
	s_axis_out_fifo_tlast <= m_axis_tlast_int;

	//s_axis_tready <= s_axis_out_fifo_tready;
    end
end

always @* begin
    if (s_axis_tvalid && s_axis_out_fifo_tready) begin
	frame_width = count_ones(s_axis_tkeep); // bytes
        save_tlast_int = s_axis_tlast; 
	if (frame_width < KEEP_WIDTH) begin
	    if (frame_width <= free_frame_width) begin
		cur_frame_width_int = cur_frame_width + frame_width;
		free_frame_width_int = free_frame_width - frame_width;
	    end
	    // else if (frame_width > free_frame_width) begin
	    // 	split_frame_width_int = frame_width - free_frame_width;
	    // 	cur_frame_width_int = KEEP_WIDTH;
	    // 	free_frame_width_int = 0;
	    // 	split_tdata_int = s_axis_tdata >> free_frame_width;
	    // end
	    if (cur_frame_width == 0) begin
		save_tdata_int = (s_axis_tdata << (cur_frame_width * 8));
	    end
	    else begin
		save_tdata_int = save_tdata | (s_axis_tdata << (cur_frame_width * 8));
	    end
	end
	// if (split_frame_width_int > 0) begin
	//     cur_frame_width_int = split_frame_width_int;
	//     free_frame_width_int = KEEP_WIDTH - split_frame_width_int;
	//     split_frame_width_int = 0;
	//     save_tdata_int = split_tdata_int;
	// end
    end // if (s_axis_tvalid && s_axis_out_fifo_tready)
    if (s_axis_out_fifo_tready) begin
	if (free_frame_width == 0) begin
	    m_axis_tdata_int = save_tdata;
	    m_axis_tkeep_int = FULL_TRANSFER_TKEEP;
	    m_axis_tvalid_int = s_axis_out_fifo_tready;
	    m_axis_tlast_int = save_tlast;
	    free_frame_width_int = KEEP_WIDTH;
	    cur_frame_width_int = 0;
	end
	else begin
	    m_axis_tdata_int = {DATA_WIDTH{1'b0}};
	    m_axis_tkeep_int = {KEEP_WIDTH{1'b0}};
	    m_axis_tvalid_int = 1'b0;
	    m_axis_tlast_int = 1'b0;
	end // else: !if(free_frame_width_int == 0)
    end
end // always @ *

axis_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(8192),
    .FRAME_FIFO(0),
    //.LAST_ENABLE(1)
    .RAM_PIPELINE(5)
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

ila_icap dbg_recon_outstream (
    .clk(clk),
    .probe0(m_axis_tdata),
    .probe1(m_axis_tkeep),
    .probe2(m_axis_tlast),
    .probe3(m_axis_tvalid),
    .probe4(m_axis_tready)
    );

endmodule // axis_dma_agg

`resetall
