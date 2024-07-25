`resetall
`timescale 1ns / 1ps
`default_nettype none

module axis_fifo_ex #
  (
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter FIFO_DEPTH = 8
   )
   (
    // slave interface
    input wire		    s_axis_areset,
    input wire		    s_axis_aclk,
    input wire		    s_axis_tvalid,
    output		    s_axis_tready,
    input [DATA_WIDTH-1:0]  s_axis_tdata,
    input [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input		    s_axis_tlast,
    // master interface
    input wire		    m_axis_aclk,
    output reg		    m_axis_tvalid,
    input		    m_axis_tready,
    output [DATA_WIDTH-1:0] m_axis_tdata,
    output [KEEP_WIDTH-1:0] m_axis_tkeep,
    output		    m_axis_tlast
	      );

wire [fifo_width-1:0]	      data_in;
wire [fifo_width-1:0]	      data_out;
wire			      empty;
wire			      full;
wire [31:0]		      ptr;
localparam integer	      fifo_width = DATA_WIDTH + KEEP_WIDTH + 3; // tvalid + tready + tlast

assign s_axis_tready = full == 0 ? 1'b1 : 1'b0; // make ready false if fifo is false

assign data_in = {s_axis_tvalid, s_axis_tready, s_axis_tdata, s_axis_tkeep, s_axis_tlast};
// assign m_axis_tvalid = data_out[fifo_width - 1];
assign m_axis_tdata = data_out[(fifo_width - 3) -: DATA_WIDTH]; // data_out [(fifo_width - 3) :  (fifo_width - 3) - 512]
assign m_axis_tkeep = data_out[ 1+: KEEP_WIDTH]; // data_out [1 : 65]
assign m_axis_tlast = data_out[0];

// TODO: get arst and reset
always @(posedge m_axis_aclk) begin
    m_axis_tvalid <= (!empty) & m_axis_tready;
end

fifo #
(
    .DEPTH(FIFO_DEPTH),
    .WIDTH(fifo_width)
)
fifo_inst
(
    .reset(s_axis_areset),
    .wr_clk(s_axis_aclk),
    .rd_clk(m_axis_aclk),
    .wr_en(s_axis_tvalid),
    .rd_en(m_axis_tready),
    .data_in(data_in),
    .data_out(data_out),
    .fifo_full(full),
    .fifo_empty(empty),
    .ptr(ptr)
);

endmodule

`resetall
