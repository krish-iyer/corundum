`resetall
`timescale 1ns / 1ps
`default_nettype none


module rmt #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter USER_WIDTH = 8,
    parameter PORT_COUNT = 1,
    parameter DEST_WIDTH = 2
)
(
    input wire				   clk,
    input wire				   rst,

    input wire [DATA_WIDTH-1:0] s_axis_tdata,
    input wire [KEEP_WIDTH-1:0] s_axis_tkeep,
    input wire 		   s_axis_tvalid,
    output reg 		   s_axis_tready,
    input wire 		   s_axis_tlast,
    input wire [USER_WIDTH-1:0] s_axis_tuser,

    output reg [DATA_WIDTH-1:0] m_axis_tdata,
    output reg [KEEP_WIDTH-1:0] m_axis_tkeep,
    output reg 		   m_axis_tvalid,
    input wire 		   m_axis_tready,
    output reg 		   m_axis_tlast,
    output reg [USER_WIDTH-1:0] m_axis_tuser,
    output reg [DEST_WIDTH-1:0]		   m_axis_tdest
);

localparam [1:0]
    STATE_IDLE = 2'b00,
    STATE_TRANSFER = 2'b01,
    STATE_DROP = 2'b10;

reg [1:0]	state_reg = STATE_IDLE, state_next;
wire [15:0]	ether_type;
wire [15:0]	pkt_type;
wire [15:0]	func_type;

assign ether_type = ((state_reg == STATE_IDLE) && s_axis_tvalid) ? s_axis_tdata[12*8+:16] : 0;
assign pkt_type = ((state_reg == STATE_IDLE) && s_axis_tvalid) ? s_axis_tdata[42*8+:16] : 0; // delimeter
assign func_type = ((state_reg == STATE_IDLE) && s_axis_tvalid) ? s_axis_tdata[44*8+:16] : 0; // function type


reg [DATA_WIDTH-1:0]	reg_axis_tdata;
reg [KEEP_WIDTH-1:0]	reg_axis_tkeep;
reg 		reg_axis_tvalid;
reg 		reg_axis_tready;
reg 		reg_axis_tlast;
reg [USER_WIDTH-1:0]	reg_axis_tuser;
reg [DEST_WIDTH-1:0] reg_axis_tdest = 2'b00;

// Second stage registers (pipelined)
(* shreg_extract = "no" *)
reg [DATA_WIDTH-1:0]    reg_axis_tdata_reg;
(* shreg_extract = "no" *)
reg [KEEP_WIDTH-1:0]    reg_axis_tkeep_reg;
reg                     reg_axis_tvalid_reg;
reg                     reg_axis_tready_reg;
reg                     reg_axis_tlast_reg;
reg [USER_WIDTH-1:0]    reg_axis_tuser_reg;
reg [DEST_WIDTH-1:0]    reg_axis_tdest_reg = 2'b00;

(* shreg_extract = "no" *)
reg [DATA_WIDTH-1:0]    reg_axis_tdata_reg_stage1;
(* shreg_extract = "no" *)
reg [KEEP_WIDTH-1:0]    reg_axis_tkeep_reg_stage1;
reg                     reg_axis_tvalid_reg_stage1;
reg                     reg_axis_tready_reg_stage1;
reg                     reg_axis_tlast_reg_stage1;
reg [USER_WIDTH-1:0]    reg_axis_tuser_reg_stage1;
reg [DEST_WIDTH-1:0]    reg_axis_tdest_reg_stage1 = 2'b00;

(* shreg_extract = "no" *)
reg [DATA_WIDTH-1:0]    reg_axis_tdata_reg_stage2;
(* shreg_extract = "no" *)
reg [KEEP_WIDTH-1:0]    reg_axis_tkeep_reg_stage2;
reg                     reg_axis_tvalid_reg_stage2;
reg                     reg_axis_tready_reg_stage2;
reg                     reg_axis_tlast_reg_stage2;
reg [USER_WIDTH-1:0]    reg_axis_tuser_reg_stage2;
reg [DEST_WIDTH-1:0]    reg_axis_tdest_reg_stage2 = 2'b00;

   
// Main always block
always @(posedge clk) begin
    // State machine update
    state_reg <= state_next;

    // Reset condition
    if (rst) begin
        // First stage reset
        //reg_axis_tvalid <= 1'b0;
        //reg_axis_tready <= 1'b0;

        // Second stage reset
        reg_axis_tvalid_reg <= 1'b0;
        reg_axis_tready_reg <= 1'b0;

        state_reg <= STATE_IDLE;
    end else begin
        reg_axis_tready <= m_axis_tready;

       	reg_axis_tdata_reg  <= reg_axis_tdata;
        reg_axis_tkeep_reg  <= reg_axis_tkeep;
        reg_axis_tvalid_reg <= reg_axis_tvalid;
        reg_axis_tlast_reg  <= reg_axis_tlast;
        reg_axis_tuser_reg  <= reg_axis_tuser;
        reg_axis_tdest_reg  <= reg_axis_tdest;
        reg_axis_tready_reg <= reg_axis_tready;

	// reg_axis_tdata_reg_stage2  <= reg_axis_tdata_reg_stage1;
        // reg_axis_tkeep_reg_stage2  <= reg_axis_tkeep_reg_stage1;
        // reg_axis_tvalid_reg_stage2 <= reg_axis_tvalid_reg_stage1;
        // reg_axis_tlast_reg_stage2  <= reg_axis_tlast_reg_stage1;
        // reg_axis_tuser_reg_stage2  <= reg_axis_tuser_reg_stage1;
        // reg_axis_tdest_reg_stage2  <= reg_axis_tdest_reg_stage1;
        // reg_axis_tready_reg_stage2 <= reg_axis_tready_reg_stage1;

        // Second stage (reg_axis_*_reg signals)

        // reg_axis_tdata_reg  <= reg_axis_tdata_reg_stage2;
        // reg_axis_tkeep_reg  <= reg_axis_tkeep_reg_stage2;
        // reg_axis_tvalid_reg <= reg_axis_tvalid_reg_stage2;
        // reg_axis_tlast_reg  <= reg_axis_tlast_reg_stage2;
        // reg_axis_tuser_reg  <= reg_axis_tuser_reg_stage2;
        // reg_axis_tdest_reg  <= reg_axis_tdest_reg_stage2;
        // reg_axis_tready_reg <= reg_axis_tready_reg_stage2;       

        // Output assignments from second stage
        m_axis_tdata  <= reg_axis_tdata_reg;
        m_axis_tkeep  <= reg_axis_tkeep_reg;
        m_axis_tvalid <= reg_axis_tvalid_reg;
        m_axis_tlast  <= reg_axis_tlast_reg;
        m_axis_tuser  <= reg_axis_tuser_reg;
        m_axis_tdest  <= reg_axis_tdest_reg;
        s_axis_tready <= reg_axis_tready;
    end
end

   
// always @(posedge clk) begin
//     state_reg <= state_next;

//     if (rst) begin
//         //reg_axis_tvalid <= 1'b0;
//         //reg_axis_tready <= 1'b0;
// 	state_reg <= STATE_IDLE;
//     end
//     else begin
// 	m_axis_tdata <= reg_axis_tdata;
// 	m_axis_tkeep <= reg_axis_tkeep;
// 	m_axis_tvalid <= reg_axis_tvalid;
// 	reg_axis_tready <= m_axis_tready;
// 	s_axis_tready <= reg_axis_tready;
// 	m_axis_tlast <= reg_axis_tlast;
// 	m_axis_tuser <= reg_axis_tuser;
// 	m_axis_tdest <= reg_axis_tdest;
//     end
// end // always @ (posedge clk)

always @* begin
    state_next = STATE_IDLE;
    case (state_reg)
	STATE_IDLE : begin
	    if (m_axis_tready && s_axis_tvalid ) begin
		// received frame with header
		// check for udp due to byte ordering 0800 becomes 0008
		if (ether_type ==  16'h0008 && pkt_type == 16'hF0E1) begin
			reg_axis_tdata = s_axis_tdata;
			reg_axis_tkeep = s_axis_tkeep;
			reg_axis_tvalid = s_axis_tvalid && s_axis_tready;
			reg_axis_tlast = s_axis_tlast;
			reg_axis_tuser = s_axis_tuser;

			case (func_type)
			    16'h0001:
				reg_axis_tdest = 2'b01;
			    default:
				reg_axis_tdest = 2'b00;
			endcase
		   
		   if (!s_axis_tlast) begin // if single packet, no need to change state
			state_next = STATE_TRANSFER;
		    end
		end
		else if (!s_axis_tlast) begin
		   state_next = STATE_DROP;
		end
	    end // if (s_axis_tready && s_axis_tvalid && !s_axis_tlast)
	    else begin
		// this cannot be moved to the begin as with
		// subsequent packet, the state cannot to IDLE till tlast
		reg_axis_tdata = {DATA_WIDTH{1'b0}};
		reg_axis_tkeep = {KEEP_WIDTH{1'b0}};
		reg_axis_tvalid = 1'b0;
		reg_axis_tlast = 1'b0;
		reg_axis_tuser = {USER_WIDTH{1'b0}};
		reg_axis_tdest = {DEST_WIDTH{1'b0}};
		state_next = STATE_IDLE;
	    end
	end
	STATE_TRANSFER : begin
	    if (m_axis_tready && s_axis_tvalid) begin
		// if (reg_axis_tready) begin
		    reg_axis_tdata = s_axis_tdata;
		    reg_axis_tkeep = s_axis_tkeep;
		    reg_axis_tvalid = s_axis_tvalid && s_axis_tready;
		    reg_axis_tlast = s_axis_tlast;
		    reg_axis_tuser = s_axis_tuser;
		// end
		if (s_axis_tlast) begin
		    state_next = STATE_IDLE;
		end
		else begin
		    state_next = STATE_TRANSFER;
		end
	    end // if (s_axis_tready && s_axis_tvalid)
	    else begin
		state_next = STATE_TRANSFER;
	    end
	end
	STATE_DROP : begin
	   if (s_axis_tvalid && m_axis_tready) begin
	       if (s_axis_tlast) begin
		   state_next = STATE_IDLE;
	       end
	       else begin
		   state_next = STATE_DROP;
	       end
	   end
	   else begin
	       state_next = STATE_DROP;
	   end
	end
    endcase
end // always @ *

   ila_0 rmt_ila (
	.clk(clk), // input wire clk


	.probe0(ether_type), // input wire [15:0]  probe0  
	.probe1(pkt_type), // input wire [15:0]  probe1 
	.probe2(func_type), // input wire [15:0]  probe2 
	.probe3(state_reg), // input wire [1:0]  probe3 
		  .probe4(s_axis_tvalid), // input wire [0:0]  probe4 
	.probe5(m_axis_tvalid), // input wire [0:0]  probe5 
	.probe6(reg_axis_tvalid), // input wire [0:0]  probe6 
	.probe7(0), // input wire [0:0]  probe7 
	.probe8(0), // input wire [0:0]  probe8 
	.probe9(0) // input wire [0:0]  probe9
);
   
endmodule

`resetall
