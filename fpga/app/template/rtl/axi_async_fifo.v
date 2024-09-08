`resetall
`timescale 1ns / 1ps
`default_nettype none

module axi_async_fifo #
(
    parameter DATA_WIDTH = 8,
    parameter STRB_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ADDR_WIDTH = 32,
    parameter ADDR_FIFO_DEPTH = 8,
    parameter DATA_FIFO_DEPTH = 8,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter RUSER_WIDTH = 1,
    parameter ARUSER_WIDTH = 1
)
(
    input wire			   s_clk,
    input wire			   s_rst,

    input wire [ID_WIDTH-1:0]	   s_axi_awid,
    input wire [ADDR_WIDTH-1:0]	   s_axi_awaddr,
    input wire [7:0]		   s_axi_awlen,
    input wire [2:0]		   s_axi_awsize,
    input wire [1:0]		   s_axi_awburst,
    input wire			   s_axi_awlock,
    input wire [3:0]		   s_axi_awcache,
    input wire [2:0]		   s_axi_awprot,
    input wire [3:0]		   s_axi_awqos,
    input wire [3:0]		   s_axi_awregion,
    input wire [ARUSER_WIDTH-1:0]  s_axi_awuser,
    input wire			   s_axi_awvalid,
    output wire			   s_axi_awready,
    input wire [DATA_WIDTH-1:0]	   s_axi_wdata,
    input wire [STRB_WIDTH-1:0]	   s_axi_wstrb,
    input wire			   s_axi_wlast,
    input wire [ARUSER_WIDTH-1:0]  s_axi_wuser,
    input wire			   s_axi_wvalid,
    output wire			   s_axi_wready,
    output wire [ID_WIDTH-1:0]	   s_axi_bid,
    output wire [1:0]		   s_axi_bresp,
    output wire [RUSER_WIDTH-1:0]  s_axi_buser,
    output wire			   s_axi_bvalid,
    input wire			   s_axi_bready,
    input wire [ID_WIDTH-1:0]	   s_axi_arid,
    input wire [ADDR_WIDTH-1:0]	   s_axi_araddr,
    input wire [7:0]		   s_axi_arlen,
    input wire [2:0]		   s_axi_arsize,
    input wire [1:0]		   s_axi_arburst,
    input wire			   s_axi_arlock,
    input wire [3:0]		   s_axi_arcache,
    input wire [2:0]		   s_axi_arprot,
    input wire [3:0]		   s_axi_arqos,
    input wire [3:0]		   s_axi_arregion,
    input wire [ARUSER_WIDTH-1:0]  s_axi_aruser,
    input wire			   s_axi_arvalid,
    output wire			   s_axi_arready,
    output wire [ID_WIDTH-1:0]	   s_axi_rid,
    output wire [DATA_WIDTH-1:0]   s_axi_rdata,
    output wire [1:0]		   s_axi_rresp,
    output wire			   s_axi_rlast,
    output wire [RUSER_WIDTH-1:0]  s_axi_ruser,
    output reg			   s_axi_rvalid,
    input wire			   s_axi_rready,

    input wire			   m_clk,
    input wire			   m_rst,

    output wire [ID_WIDTH-1:0]	   m_axi_awid,
    output wire [ADDR_WIDTH-1:0]   m_axi_awaddr,
    output wire [7:0]		   m_axi_awlen,
    output wire [2:0]		   m_axi_awsize,
    output wire [1:0]		   m_axi_awburst,
    output wire			   m_axi_awlock,
    output wire [3:0]		   m_axi_awcache,
    output wire [2:0]		   m_axi_awprot,
    output wire [3:0]		   m_axi_awqos,
    output wire [3:0]		   m_axi_awregion,
    output wire [ARUSER_WIDTH-1:0] m_axi_awuser,
    output wire			   m_axi_awvalid,
    input wire			   m_axi_awready,
    output wire [DATA_WIDTH-1:0]   m_axi_wdata,
    output wire [STRB_WIDTH-1:0]   m_axi_wstrb,
    output wire			   m_axi_wlast,
    output wire [RUSER_WIDTH-1:0]  m_axi_wuser,
    output wire			   m_axi_wvalid,
    input wire			   m_axi_wready,
    input wire [ID_WIDTH-1:0]	   m_axi_bid,
    input wire [1:0]		   m_axi_bresp,
    input wire [RUSER_WIDTH-1:0]   m_axi_buser,
    input wire			   m_axi_bvalid,
    output wire			   m_axi_bready,
    output wire [ID_WIDTH-1:0]	   m_axi_arid,
    output wire [ADDR_WIDTH-1:0]   m_axi_araddr,
    output wire [7:0]		   m_axi_arlen,
    output wire [2:0]		   m_axi_arsize,
    output wire [1:0]		   m_axi_arburst,
    output wire			   m_axi_arlock,
    output wire [3:0]		   m_axi_arcache,
    output wire [2:0]		   m_axi_arprot,
    output wire [3:0]		   m_axi_arqos,
    output wire [3:0]		   m_axi_arregion,
    output wire [ARUSER_WIDTH-1:0] m_axi_aruser,
    output reg			   m_axi_arvalid,
    input wire			   m_axi_arready,
    input wire [ID_WIDTH-1:0]	   m_axi_rid,
    input wire [DATA_WIDTH-1:0]	   m_axi_rdata,
    input wire [1:0]		   m_axi_rresp,
    input wire			   m_axi_rlast,
    input wire [RUSER_WIDTH-1:0]   m_axi_ruser,
    input wire			   m_axi_rvalid,
    output wire			   m_axi_rready
);

localparam			   ARLEN_WIDTH = 8;
localparam			   ARSIZE_WIDTH = 3;
localparam			   ARBURST_WIDTH = 2;
localparam			   ARLOCK_WIDTH = 1;
localparam			   ARCACHE_WIDTH = 4;
localparam			   ARPROT_WIDTH = 3;
localparam			   ARQOS_WIDTH = 4;
localparam			   ARREGION_WIDTH = 4;
localparam			   RRESP_WIDTH = 2;
localparam			   RLAST_WIDTH = 1;

localparam			   RADDR_FIFO_WIDTH = ID_WIDTH + ADDR_WIDTH + ARLEN_WIDTH +
				   ARSIZE_WIDTH + ARBURST_WIDTH + ARLOCK_WIDTH + ARCACHE_WIDTH +
				   ARPROT_WIDTH + ARQOS_WIDTH + ARREGION_WIDTH + ARUSER_WIDTH;

localparam			   RDATA_FIFO_WIDTH = ID_WIDTH + DATA_WIDTH + RRESP_WIDTH + RLAST_WIDTH + RUSER_WIDTH;

localparam [2:0]
		IDLE = 3'd0,
		TRANSFER_ADDR = 3'd1,
		TRANSFER_DATA = 3'd2,
		TRANSFER_DATA_WAIT = 3'd3,
		ADDR_IDLE_WAIT = 3'd4;

reg [2:0]	addr_state = IDLE, data_state = IDLE, addr_state_next, data_state_next;
reg		m_axi_arvalid_int = 1'b0;
reg		s_axi_rvalid_int = 1'b0;

wire [RADDR_FIFO_WIDTH-1:0] raddr_in;
wire [RADDR_FIFO_WIDTH-1:0] raddr_out;
wire [RDATA_FIFO_WIDTH-1:0] rdata_in;
wire [RDATA_FIFO_WIDTH-1:0] rdata_out;

wire			    raddr_empty;
wire			    raddr_full;
wire			    rdata_empty;
wire			    rdata_full;
reg			    raddr_fifo_rd_en_int;
reg			    rdata_fifo_rd_en_int;
reg			    raddr_fifo_rd_en;
reg			    rdata_fifo_rd_en;


reg [7:0]	    pending_len_int = 0;
reg [7:0]	    pending_len = 0;
reg [7:0]	    cur_pending_len_int = 0;
reg [7:0]	    cur_pending_len = 0;

reg [31:0]	    raddr_fifo_width = RADDR_FIFO_WIDTH;
reg		    data_transfer_done = 1'b0;

assign s_axi_arready = raddr_full == 0 ? 1'b1 : 1'b0; // make ready false if fifo is false
assign m_axi_rready = rdata_full == 0 ? 1'b1 : 1'b0;

// in/out signals
assign raddr_in = {s_axi_arid, s_axi_araddr, s_axi_arlen, s_axi_arsize, s_axi_arburst, s_axi_arlock, s_axi_arcache,
		  s_axi_arprot, s_axi_arqos, s_axi_arregion, s_axi_aruser};
assign m_axi_arid = raddr_out[(RADDR_FIFO_WIDTH-1) -:ID_WIDTH]; // raddr_out [(fifo_width-1):(fifo_width-1)-512]
assign m_axi_araddr = raddr_out[(RADDR_FIFO_WIDTH-ID_WIDTH-1) -:ADDR_WIDTH]; // raddr_out [1:65]
assign m_axi_arlen = raddr_out[(RADDR_FIFO_WIDTH-ID_WIDTH-ADDR_WIDTH-1) -:ARLEN_WIDTH];
assign m_axi_arsize = raddr_out[(RADDR_FIFO_WIDTH-ID_WIDTH-ADDR_WIDTH-ARLEN_WIDTH-1) -:ARSIZE_WIDTH];
assign m_axi_arburst = raddr_out[(RADDR_FIFO_WIDTH-ID_WIDTH-ADDR_WIDTH-ARLEN_WIDTH-ARSIZE_WIDTH-1) -:ARBURST_WIDTH];
assign m_axi_arlock = raddr_out[(RADDR_FIFO_WIDTH-ID_WIDTH-ADDR_WIDTH-ARLEN_WIDTH-ARSIZE_WIDTH-ARBURST_WIDTH-1)];
assign m_axi_arcache = raddr_out[(RADDR_FIFO_WIDTH-ID_WIDTH-ADDR_WIDTH-ARLEN_WIDTH-ARSIZE_WIDTH-ARBURST_WIDTH-
		       ARLOCK_WIDTH-1) -:ARCACHE_WIDTH];
assign m_axi_arprot = raddr_out[(RADDR_FIFO_WIDTH-ID_WIDTH-ADDR_WIDTH-ARLEN_WIDTH-ARSIZE_WIDTH-ARBURST_WIDTH-
		      ARLOCK_WIDTH-ARCACHE_WIDTH-1) -:ARPROT_WIDTH];
assign m_axi_arqos = raddr_out[(RADDR_FIFO_WIDTH-ID_WIDTH-ADDR_WIDTH-ARLEN_WIDTH-ARSIZE_WIDTH-ARBURST_WIDTH-
		     ARLOCK_WIDTH-ARCACHE_WIDTH-ARPROT_WIDTH-1) -:ARQOS_WIDTH];
assign m_axi_arregion = raddr_out[(RADDR_FIFO_WIDTH-ID_WIDTH-ADDR_WIDTH-ARLEN_WIDTH-ARSIZE_WIDTH-ARBURST_WIDTH-
			ARLOCK_WIDTH-ARCACHE_WIDTH-ARPROT_WIDTH-ARQOS_WIDTH-1) -:ARREGION_WIDTH];
assign m_axi_aruser = raddr_out[ARUSER_WIDTH-1:0];
assign s_axi_arready = !raddr_full ? 1'b1 : 1'b0;
assign rdata_in = {m_axi_rid, m_axi_rdata, m_axi_rresp, m_axi_rlast, m_axi_ruser};
assign s_axi_rid = rdata_out[(RDATA_FIFO_WIDTH-1) -:ID_WIDTH]; // raddr_out [(fifo_width-1):(fifo_width-1)-512]
assign s_axi_rdata = rdata_out[(RDATA_FIFO_WIDTH-ID_WIDTH-1) -:DATA_WIDTH];
assign s_axi_rresp = rdata_out[(RDATA_FIFO_WIDTH-ID_WIDTH-DATA_WIDTH-1) -:RRESP_WIDTH];
assign s_axi_rlast = rdata_out[(RDATA_FIFO_WIDTH-ID_WIDTH-DATA_WIDTH-RRESP_WIDTH-1)];
assign s_axi_ruser = rdata_out[(RDATA_FIFO_WIDTH-ID_WIDTH-DATA_WIDTH-RRESP_WIDTH-RLAST_WIDTH-1) -:RUSER_WIDTH];
assign m_axi_rready = !rdata_full ? 1'b1 : 1'b0;


always @(posedge m_clk) begin
    addr_state <= addr_state_next;
    if (m_rst) begin
	m_axi_arvalid <= 1'b0;
	raddr_fifo_rd_en <= 1'b0;
	addr_state <= IDLE;
    end
    else begin
	raddr_fifo_rd_en <= raddr_fifo_rd_en_int;
	m_axi_arvalid <= m_axi_arvalid_int;
    end
end

always @(posedge s_clk) begin
    data_state <= data_state_next;
    if (s_rst) begin
	s_axi_rvalid <= 1'b0;
	rdata_fifo_rd_en <= 1'b0;
	data_state = IDLE;
    end
    else begin
	rdata_fifo_rd_en <= rdata_fifo_rd_en_int;
	s_axi_rvalid <= s_axi_rvalid_int;
	cur_pending_len <= cur_pending_len_int;
    end
end

// send a addr
always @* begin
    addr_state_next = IDLE;
    case (addr_state)
	IDLE: begin
	    if (!raddr_empty && m_axi_arready) begin
		raddr_fifo_rd_en_int = 1'b1;
		m_axi_arvalid_int = 1'b1;
		pending_len_int = m_axi_arlen;
		addr_state_next = TRANSFER_ADDR;
	    end
	    else begin
		raddr_fifo_rd_en_int = 1'b0;
		m_axi_arvalid_int = 1'b0;
		addr_state_next = IDLE;
	    end
	end
	TRANSFER_ADDR: begin
	    if (m_axi_arready) begin
	    	raddr_fifo_rd_en_int = 1'b0;
		m_axi_arvalid_int = 1'b0;
		addr_state_next = TRANSFER_DATA_WAIT;
	    end
	    else begin
		addr_state_next = TRANSFER_ADDR;
	    end
	end
	TRANSFER_DATA_WAIT: begin
	    if (data_transfer_done) begin
		addr_state_next = IDLE;
	    end
	    else begin
		addr_state_next = TRANSFER_DATA_WAIT;
	    end
	end
    endcase
end

always @* begin
    data_state_next = IDLE;
    case (data_state)
	IDLE: begin
	    rdata_fifo_rd_en_int = 1'b0;
	    s_axi_rvalid_int = 1'b0;
	    data_transfer_done = 1'b0;
	    if(addr_state_next == TRANSFER_DATA_WAIT) begin
		cur_pending_len_int = pending_len_int;
		data_state_next = TRANSFER_DATA;
	    end
	    else begin
		data_state_next = IDLE;
	    end
	end
	TRANSFER_DATA: begin
	    if (!rdata_empty && s_axi_rready) begin
		rdata_fifo_rd_en_int = 1'b1;
		s_axi_rvalid_int = 1'b1;
		if (cur_pending_len == 0) begin
		    data_transfer_done = 1'b1;
		    data_state_next = ADDR_IDLE_WAIT;
		end
		else begin
		    data_transfer_done = 1'b0;
		    cur_pending_len_int = cur_pending_len - 1;
		    data_state_next = TRANSFER_DATA;
		end
	    end
	    else begin
		data_state_next = TRANSFER_DATA;
	    end
	end // case: TRANSFER_DATA
	ADDR_IDLE_WAIT: begin
	    if (s_axi_arready) begin
	    	rdata_fifo_rd_en_int = 1'b0;
		s_axi_rvalid_int = 1'b0;
	    end
	    if (addr_state_next == IDLE) begin
		data_state_next = IDLE;
	    end
	    //else begin
	    //	data_state_next = ADDR_IDLE_WAIT;
	    //end
	end
    endcase
end

async_fifo #
(
    .DEPTH(ADDR_FIFO_DEPTH),
    .WIDTH(RADDR_FIFO_WIDTH)
)
araddr_async_fifo_inst
(
    .wr_clk(s_clk),
    .wr_rst(s_rst),

    .rd_clk(m_clk),
    .rd_rst(m_rst),

    .wr_en(s_axi_arvalid),
    .rd_en(raddr_fifo_rd_en),
    .data_in(raddr_in),
    .data_out(raddr_out),

    .full(raddr_full),
    .empty(raddr_empty)
);


async_fifo #
(
    .DEPTH(DATA_FIFO_DEPTH),
    .WIDTH(RDATA_FIFO_WIDTH)
)
rdata_async_fifo_inst
(
    .wr_clk(m_clk),
    .wr_rst(m_rst),

    .rd_clk(s_clk),
    .rd_rst(s_rst),

    .wr_en(m_axi_rvalid),
    .rd_en(rdata_fifo_rd_en),
    .data_in(rdata_in),
    .data_out(rdata_out),

    .full(rdata_full),
    .empty(rdata_empty)
);

endmodule

`resetall
