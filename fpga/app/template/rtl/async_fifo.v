`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 1. On fifo full, write overwrites the data and reader reads the most recent data, flushing
 the rest of the output.
 2. Makes sure to notice the duration of read and write while debugging
 3. Reader pointer always lags one or more steps from the write and are never equal.
 4. data_out is asynchornous because read pointer is already buffered, so in total data_out
 gets delayed two cycles instead of one.
 5. This code is not tested against odd frequencies of reader and writer which are  non-divisible
 */

module async_fifo #
(
    parameter DEPTH = 64,
    parameter WIDTH = 512 // bits
)
(
    input		    wr_clk,
    input		    wr_rst,
    input		    wr_en,
    input [WIDTH-1:0]	    data_in,

    input		    rd_clk,
    input		    rd_rst,
    input		    rd_en,
    output wire [WIDTH-1:0] data_out,

    output		    full,
    output		    empty
);

parameter		   ADDR_WIDTH = $clog2(DEPTH);
reg [WIDTH-1:0]		   mem [0:DEPTH-1];
// read ptr is initialised to DEPTH-1 and write ptr to 0
// read ptr always lags 1 or more steps behind write ptr
// read ptr points to last read buffer and write ptr points
// to be written buffer
reg [ADDR_WIDTH-1:0]	   rd_ptr = 0;
reg [ADDR_WIDTH-1:0]	   wr_ptr = 0;

reg [ADDR_WIDTH-1:0]	   m_wr_rd_sync_ptr = {ADDR_WIDTH{1'b0}};
reg [ADDR_WIDTH-1:0]	   s_wr_rd_sync_ptr = {ADDR_WIDTH{1'b0}};
reg [ADDR_WIDTH-1:0]	   m_rd_wr_sync_ptr = {ADDR_WIDTH{1'b0}};
reg [ADDR_WIDTH-1:0]	   s_rd_wr_sync_ptr = {ADDR_WIDTH{1'b0}};

reg [ADDR_WIDTH-1:0]	   rd_sync_commit_ptr = {ADDR_WIDTH{1'b0}};
reg [ADDR_WIDTH-1:0]	   wr_sync_commit_ptr = {ADDR_WIDTH{1'b0}};

assign full = ((wr_ptr + 1'b1) == rd_ptr);
assign empty =  wr_ptr == rd_ptr;

assign data_out = mem[rd_ptr];

reg			   wr_sync_rst = 1'b0;
reg			   rd_sync_rst = 1'b0;
reg			   wr_sync_rst_int = 1'b0;
reg			   rd_sync_rst_int = 1'b0;


always @(posedge wr_clk) begin
    if (wr_rst || (wr_sync_rst != wr_sync_rst_int)) begin
	wr_ptr <= 0;
	wr_sync_commit_ptr <= {ADDR_WIDTH{1'b0}};
	if (wr_sync_rst != wr_sync_rst_int)
	    wr_sync_rst_int <= wr_sync_rst;
	else
	    rd_sync_rst <= rd_sync_rst ^ 1'b1;
    end
    else begin
	if (!full && wr_en) begin
	    mem[wr_ptr] <= data_in;
	    wr_ptr <= wr_ptr + 1'b1;
	    m_wr_rd_sync_ptr <= wr_ptr + 1'b1;
	end
	if (m_wr_rd_sync_ptr == s_rd_wr_sync_ptr)
	    wr_sync_commit_ptr <= m_wr_rd_sync_ptr;
    end
end

always @(posedge rd_clk) begin
    if (rd_rst || (rd_sync_rst != rd_sync_rst_int)) begin
	rd_ptr <= {ADDR_WIDTH{1'b0}};
	rd_sync_commit_ptr <= {ADDR_WIDTH{1'b0}};
	if ((rd_sync_rst != rd_sync_rst_int))
	    rd_sync_rst_int <= rd_sync_rst;
	else
	    wr_sync_rst <= wr_sync_rst ^ 1'b1;
    end
    else begin
	if (!empty && rd_en) begin
	    rd_ptr <= rd_ptr + 1'b1;
	    m_rd_wr_sync_ptr <= rd_ptr + 1'b1;
	end
	if(m_rd_wr_sync_ptr == s_wr_rd_sync_ptr)
	    rd_sync_commit_ptr <= m_rd_wr_sync_ptr;
    end
end

always @* begin
    if(s_rd_wr_sync_ptr != m_wr_rd_sync_ptr)
	s_rd_wr_sync_ptr = m_wr_rd_sync_ptr;
    if (s_wr_rd_sync_ptr != m_rd_wr_sync_ptr)
	s_wr_rd_sync_ptr = m_rd_wr_sync_ptr;
end

endmodule

`resetall
