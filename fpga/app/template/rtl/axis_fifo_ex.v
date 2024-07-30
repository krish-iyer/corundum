`resetall
`timescale 1ns / 1ps
`default_nettype none

module axis_fifo_ex #
(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter FIFO_DEPTH = 8,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter USER_WIDTH = 1
)
(
    input wire			 s_clk,
    input wire			 s_rst,
    input wire [DATA_WIDTH-1:0]	 s_axis_tdata,
    input wire [KEEP_WIDTH-1:0]	 s_axis_tkeep,
    input wire			 s_axis_tvalid,
    output wire			 s_axis_tready,
    input wire			 s_axis_tlast,
    input wire [ID_WIDTH-1:0]	 s_axis_tid,
    input wire [DEST_WIDTH-1:0]	 s_axis_tdest,
    input wire [USER_WIDTH-1:0]	 s_axis_tuser,

    input wire			 m_clk,
    input wire			 m_rst,
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire [KEEP_WIDTH-1:0] m_axis_tkeep,
    output wire			 m_axis_tvalid,
    input wire			 m_axis_tready,
    output wire			 m_axis_tlast,
    output wire [ID_WIDTH-1:0]	 m_axis_tid,
    output wire [DEST_WIDTH-1:0] m_axis_tdest,
    output wire [USER_WIDTH-1:0] m_axis_tuser
);

localparam			 FIFO_WIDTH = DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH; // tlast
wire [FIFO_WIDTH-1:0]		 data_in;
wire [FIFO_WIDTH-1:0]		 data_out;
wire				 empty;
wire				 full;

assign s_axis_tready = full == 0 ? 1'b1 : 1'b0; // make ready false if fifo is false

assign data_in = {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};

assign m_axis_tdata = data_out[(FIFO_WIDTH-1) -: DATA_WIDTH]; // data_out [(fifo_width-1):(fifo_width-1)-512]
assign m_axis_tkeep = data_out[(USER_WIDTH+DEST_WIDTH+ID_WIDTH+1)+: KEEP_WIDTH]; // data_out [1:65]
assign m_axis_tlast = data_out[(USER_WIDTH+DEST_WIDTH+ID_WIDTH)];
assign m_axis_tid =   data_out[(USER_WIDTH+DEST_WIDTH)+:ID_WIDTH];
assign m_axis_tdest = data_out[USER_WIDTH+:DEST_WIDTH];
assign m_axis_tuser = data_out[USER_WIDTH-1:0];

// TODO: get arst and reset
// always @(posedge m_clk) begin
//     m_axis_tvalid <= (!empty) && m_axis_tready;
// end

assign m_axis_tvalid = (!empty) && m_axis_tready;

async_fifo #
(
    .DEPTH(FIFO_DEPTH),
    .WIDTH(FIFO_WIDTH)
)
fifo_inst
(
    .wr_clk(s_clk),
    .wr_rst(s_rst),

    .rd_clk(m_clk),
    .rd_rst(m_rst),

    .wr_en(s_axis_tvalid),
    .rd_en(m_axis_tready),
    .data_in(data_in),
    .data_out(data_out),

    .full(full),
    .empty(empty)
);

endmodule

`resetall
