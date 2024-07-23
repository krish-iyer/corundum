module axi_ctrl #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ADDR_WIDTH = 34,
    parameter FIFO_DEPTH = 32
)
(
    input			 clk,
    input			 rst,

    input [KEEP_WIDTH-1:0]	 s_axis_tkeep,
    input [DATA_WIDTH-1:0]	 s_axis_tdata,
    input			 s_axis_tlast,
    input			 s_axis_tvalid,
    output reg			 s_axis_tready,

    input			 m_axi_awready,
    output reg [5:0]		 m_axi_awid,
    output reg [ADDR_WIDTH-1:0]	 m_axi_awaddr,
    output [7:0]		 m_axi_awlen,
    output [2:0]		 m_axi_awsize,
    output [1:0]		 m_axi_awburst,
    output			 m_axi_awlock,
    output [3:0]		 m_axi_awcache,
    output [2:0]		 m_axi_awprot,
    output reg			 m_axi_awvalid,
    input			 m_axi_wready,
    output wire [DATA_WIDTH-1:0] m_axi_wdata,
    output wire [KEEP_WIDTH-1:0] m_axi_wstrb,
    output			 m_axi_wlast,
    output reg			 m_axi_wvalid,
    input			 m_axi_bid,
    input [1:0]			 m_axi_bresp,
    input			 m_axi_bvalid,
    output reg			 m_axi_bready
);

assign axi_awlen     = 8'd0;
assign m_axi_awsize    = 3'd6;
assign m_axi_awburst   = 2'd1;
assign m_axi_awcache   = 4'd0;
assign m_axi_awprot    = 3'd0;

assign m_axi_awlock    = 1'd0;
assign m_axi_wlast   = m_axi_wvalid;

assign m_axi_wdata = s_axis_tdata;
assign m_axi_wstrb = s_axis_tkeep;

wire [31 : 0]			ptr;
reg [31 : 0]			prev_ptr = FIFO_DEPTH - 1;

reg [1:0]			wrState;
reg				capturePulse;

reg [ADDR_WIDTH-1:0]		start_addr;

localparam			IDLE    = 'd0,
				CAPTURE = 'd1,
				DONE    = 'd2,
				WR_ADDR = 'd1,
				WR_DATA = 'd2;


always @(posedge clk) begin
    if(rst) begin
        m_axi_awvalid  <= 1'b0;
        m_axi_wvalid <= 1'b0;
        wrState <= IDLE;
    end
    else begin
        case(wrState)
            IDLE:begin
		if(capturePulse) begin
                    m_axi_awaddr <= start_addr;
		end
		// check is there's something to send
		if(s_axis_tvalid && (ptr!=prev_ptr)) begin
                    m_axi_awvalid  <= 1'b1;
		    wrState      <= WR_ADDR;
                    //axi_awid <= m_axi_awid + 1'b1;
		    s_axis_tready <= 1'b0; // no more read from the fifo in sending process
		end
            end
            WR_ADDR:begin
		if(m_axi_awready) begin
                    m_axi_awvalid  <= 1'b0;
                    m_axi_wvalid <= 1'b1;
                    // for(i = 0; i < 64; i=i+1) begin
                    //    if(s_axis_tkeep[i])
                    //      m_axi_awaddr = m_axi_awaddr+1;
		    // end
		    // increment address by 64 byte
		    m_axi_awaddr <= m_axi_awaddr + 64;
                    wrState <= WR_DATA;
		end
            end
            WR_DATA:begin
		if(m_axi_wready) begin
                    m_axi_wvalid <= 1'b0;
		    // account for cirular buffer
		    if(prev_ptr == (FIFO_DEPTH - 1)) begin
			prev_ptr <= 0;
		    end
		    else begin
			prev_ptr <= prev_ptr + 1;
		    end
		    s_axis_tready <= 1'b1;
		    wrState <= IDLE;
		end
            end
        endcase
    end
end

always @(posedge clk) begin
    if(rst)
        m_axi_bready <= 1'b0;
    else if(m_axi_bready)
        m_axi_bready <= 1'b0;
    else if(m_axi_bvalid)
        m_axi_bready <= 1'b1;
end

endmodule
