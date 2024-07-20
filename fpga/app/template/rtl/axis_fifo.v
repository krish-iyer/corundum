module axis_fifo_ex #
  (
   parameter integer DATA_WIDTH = 8,
   parameter integer KEEP_WIDTH = ((DATA_WIDTH+7)/8),
   parameter integer FIFO_DEPTH = 8
   )
   (
    // slave interface
    input wire		    s_axis_aresetn,
    input wire		    s_axis_aclk,
    input wire		    s_axis_tvalid,
    input		    s_axis_tready,
    input [DATA_WIDTH-1:0]  s_axis_tdata,
    input [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input		    s_axis_tlast,
    // master interface
    input wire		    m_axis_aclk,
    output		    m_axis_tvalid,
    input wire		    m_axis_tready,
    output [DATA_WIDTH-1:0] m_axis_tdata,
    output [KEEP_WIDTH-1:0] m_axis_tkeep,
    output		    m_axis_tlast,
    // aux signals
    output wire		    full,
    output wire		    empty,
    output [31:0]	    ptr,
    input wire [31:0]	    mon_ptr
    );

wire [fifo_width-1:0]	      data_in;
wire [fifo_width-1:0]	      data_out;

localparam integer	      fifo_width = DATA_WIDTH + KEEP_WIDTH + 3; // tvalid + tready + tlast

assign data_in = {s_axis_tvalid, s_axis_tready, s_axis_tdata, s_axis_tkeep, s_axis_tlast};
assign m_axis_tvalid = data_out[fifo_width - 1];
assign m_axis_tdata = data_out[(fifo_width - 3) -: DATA_WIDTH]; // data_out [(fifo_width - 3) :  (fifo_width - 3) - 512]
assign m_axis_tkeep = data_out[ 1+: KEEP_WIDTH]; // data_out [1 : 65]
assign m_axis_tlast = data_out[0];


fifo #
(
    .DEPTH(FIFO_DEPTH),
    .WIDTH(fifo_width)
)
fifo_inst
(
    .resetn(s_axis_aresetn),
    .wr_clk(s_axis_aclk),
    .rd_clk(m_axis_aclk),
    .wr_en(s_axis_tvalid),
    .rd_en(m_axis_tready),
    .data_in(data_in),
    .data_out(data_out),
    .fifo_full(full),
    .fifo_empty(empty),
    .ptr(ptr),
    .mon_ptr(mon_ptr)
);


endmodule
