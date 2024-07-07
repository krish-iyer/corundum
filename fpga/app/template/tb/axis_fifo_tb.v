`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04/08/2024 07:31:33 PM
// Design Name:
// Module Name: axis_fifo_tb
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module axis_fifo_tb();

   localparam integer TDATA_WIDTH = 4; // bytes
   localparam integer TKEEP_WIDTH = 64; // bits
   localparam integer FIFO_DEPTH = 64;

   // slave interface
   reg		      s_axis_aresetn;
   reg		      s_axis_aclk;
   reg		      s_axis_tvalid;
   reg		      s_axis_tready;
   reg [(TDATA_WIDTH << 3) - 1 : 0] s_axis_tdata;
   reg [TKEEP_WIDTH - 1 : 0]	    s_axis_tkeep;
   reg				    s_axis_tlast;
   // master interface
   reg				    m_axis_aclk;
   wire				    m_axis_tvalid;
   reg				    m_axis_tready;
   wire [(TDATA_WIDTH << 3) - 1 : 0] m_axis_tdata;
   wire [TKEEP_WIDTH - 1 : 0]	     m_axis_tkeep;
   wire				     m_axis_tlast;
   // aux signals
   wire				     full;
   wire				     empty;
   integer			     incr = 15;


   axis_fifo #
     (.TDATA_WIDTH(TDATA_WIDTH),
      .TKEEP_WIDTH(TKEEP_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH)
      )
   axis_fifo_inst
     (
      .s_axis_aresetn(s_axis_aresetn),
      .s_axis_aclk(s_axis_aclk),
      .s_axis_tvalid(s_axis_tvalid),
      .s_axis_tready(s_axis_tready),
      .s_axis_tdata(s_axis_tdata),
      .s_axis_tkeep(s_axis_tkeep),
      .s_axis_tlast(s_axis_tlast),
      .m_axis_aclk(m_axis_aclk),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tready(m_axis_tready),
      .m_axis_tdata(m_axis_tdata),
      .m_axis_tkeep(m_axis_tkeep),
      .m_axis_tlast(m_axis_tlast),
      .empty(empty),
      .full(full)
      );


   initial begin
      s_axis_aresetn = 0;
      s_axis_aclk = 0;
      m_axis_aclk = 0;
      s_axis_tdata = incr;
      s_axis_tready = 0;
      #0.008
	s_axis_aresetn = 1;
      s_axis_tvalid = 1;
      m_axis_tready = 1;
      s_axis_tkeep = 64'hffff_ffff_ffff_ffff;
      s_axis_tlast = 0;

      repeat (6) begin
	 #0.004
	   s_axis_tdata = incr;
	 incr = incr - 1;
      end
      s_axis_tvalid = 0;
      #1000 $finish;
   end


   initial begin
      repeat (40) begin
      #0.01
	$display("data out: %d",m_axis_tdata);
      end
      m_axis_tready = 0;
   end

   always #0.002 s_axis_aclk = ~s_axis_aclk; // 250 hz
   always #0.005 m_axis_aclk = ~m_axis_aclk; // 100 hz


endmodule
