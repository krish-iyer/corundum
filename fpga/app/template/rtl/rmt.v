`resetall
`timescale 1ns / 1ps
`default_nettype none


module rmt #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter USER_WIDTH = 8,
    parameter PORT_COUNT = 1
)
(
    input				    clk,
    input				    rst,

    input wire [PORT_COUNT*DATA_WIDTH-1:0]  s_axis_tdata,
    input wire [PORT_COUNT*KEEP_WIDTH-1:0]  s_axis_tkeep,
    input wire [PORT_COUNT-1:0]		    s_axis_tvalid,
    output reg [PORT_COUNT-1:0]	    s_axis_tready,
    input wire [PORT_COUNT-1:0]		    s_axis_tlast,
    input wire [PORT_COUNT*USER_WIDTH-1:0]  s_axis_tuser,

    output reg [PORT_COUNT*DATA_WIDTH-1:0] m_axis_tdata,
    output reg [PORT_COUNT*KEEP_WIDTH-1:0] m_axis_tkeep,
    output reg [PORT_COUNT-1:0]	    m_axis_tvalid,
    input wire [PORT_COUNT-1:0]		    m_axis_tready,
    output reg [PORT_COUNT-1:0]	    m_axis_tlast,
    output reg [PORT_COUNT*USER_WIDTH-1:0] m_axis_tuser

);

localparam [1:0]
    STATE_IDLE = 2'd0,
    STATE_TRANSFER = 2'd1,
    STATE_DROP = 2'd2;

reg [1:0]	state_reg = STATE_IDLE, state_next = STATE_IDLE;
wire [15:0]	ether_type;

assign ether_type = state_reg == STATE_IDLE ? s_axis_tdata[12*8+:16] : 0;


reg [PORT_COUNT*DATA_WIDTH-1:0]	reg_axis_tdata;
reg [PORT_COUNT*KEEP_WIDTH-1:0]	reg_axis_tkeep;
reg [PORT_COUNT-1:0]		reg_axis_tvalid;
reg [PORT_COUNT-1:0]		reg_axis_tready;
reg [PORT_COUNT-1:0]		reg_axis_tlast;
reg [PORT_COUNT*USER_WIDTH-1:0]	reg_axis_tuser;

always @(posedge clk) begin
    state_reg <= state_next;

    if (rst) begin
        reg_axis_tvalid <= 1'b0;
        reg_axis_tready <= 1'b0;
	state_next <= STATE_IDLE;
	state_reg <= STATE_IDLE;
    end
    else begin
	m_axis_tdata <= reg_axis_tdata;
	m_axis_tkeep <= reg_axis_tkeep;
	m_axis_tvalid <= reg_axis_tvalid;
	reg_axis_tready <= m_axis_tready;
	s_axis_tready <= reg_axis_tready;
	m_axis_tlast <= reg_axis_tlast;
	m_axis_tuser <= reg_axis_tuser;
    end
end // always @ (posedge clk)

always @* begin

    case (state_reg)
	STATE_IDLE : begin
	    if (s_axis_tready && s_axis_tvalid && !s_axis_tlast) begin
		// received frame with header
		// check for udp due to byte ordering 0800 becomes 0008
		if (ether_type ==  16'h0008) begin
		    state_next = STATE_TRANSFER;
		    if (reg_axis_tready) begin
			reg_axis_tdata = s_axis_tdata;
			reg_axis_tkeep = s_axis_tkeep;
			reg_axis_tvalid = s_axis_tvalid && s_axis_tready;
			reg_axis_tlast = s_axis_tlast;
			reg_axis_tuser = s_axis_tuser;
		    end
		end
		else begin
		    state_next = STATE_DROP;
		end
	    end // if (s_axis_tready && s_axis_tvalid && !s_axis_tlast)
	    else begin
		reg_axis_tdata = {DATA_WIDTH{1'b0}};
		reg_axis_tkeep = {KEEP_WIDTH{1'b0}};
		reg_axis_tvalid = 1'b0;
		reg_axis_tlast = 1'b0;
		reg_axis_tuser = {USER_WIDTH{1'b0}};
	    end
	end
	STATE_TRANSFER : begin
	    if (reg_axis_tready) begin
		reg_axis_tdata = s_axis_tdata;
		reg_axis_tkeep = s_axis_tkeep;
		reg_axis_tvalid = s_axis_tvalid && s_axis_tready;
		reg_axis_tlast = s_axis_tlast;
		reg_axis_tuser = s_axis_tuser;
	    end
	    if (s_axis_tlast) begin
		state_next = STATE_IDLE;
	    end
	end
	STATE_DROP : begin
	   if (s_axis_tvalid && s_axis_tready) begin
	       if (s_axis_tlast) begin
		   state_next = STATE_IDLE;
	       end
	   end
	end
    endcase
end
endmodule

`resetall
