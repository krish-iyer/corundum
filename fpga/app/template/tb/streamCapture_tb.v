//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03/30/2024 03:55:33 PM
// Design Name:
// Module Name: streamCapture_tb
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

`timescale 1ns / 1ps

module streamCapture_tb();

   localparam S00_AXI_DATA_WIDTH = 32;
   localparam S00_AXI_ADDR_WIDTH = 7;

   // AXI-Lite control Interface to write baseAddr
   // axi clock
   reg	      m00_axi_aclk;
   reg	      m00_axi_aresetn; // active low
   reg	      m_axi_aclk;
   wire [31 : 0] axis_rd_data_count;
   wire [31 : 0] axis_wr_data_count;
   wire		 almost_empty;
   wire		 almost_full;
   // axi addr write
   reg [S00_AXI_ADDR_WIDTH - 1 : 0] m00_axi_awaddr;
   reg [2 : 0]			    m00_axi_awprot;
   reg				    m00_axi_awvalid;
   wire				    m00_axi_awready;
   // axi write channel
   reg [S00_AXI_DATA_WIDTH - 1 : 0]   m00_axi_wdata;
   reg [S00_AXI_DATA_WIDTH/8 - 1 : 0] m00_axi_wstrb;
   reg				      m00_axi_wvalid;
   wire				      m00_axi_wready;
   // axi resp
   wire [1 : 0]			      m00_axi_bresp;
   wire				      m00_axi_bvalid;
   reg				      m00_axi_bready;
   // axi addr read
   reg [S00_AXI_ADDR_WIDTH - 1 : 0]   m00_axi_araddr;
   reg [2 : 0]			      m00_axi_arprot;
   reg				      m00_axi_arvalid;
   wire				      m00_axi_arready;
   // axi read
   wire [S00_AXI_DATA_WIDTH - 1 : 0]  m00_axi_rdata;
   wire [1 : 0]			      m00_axi_rresp;
   wire				      m00_axi_rvalid;
   reg				      m00_axi_rready;

   // AXI Stream Interface
   // clk
   reg				      clk_stream;
   reg				      resetn_stream; // active low
   // data
   reg				      m_axis_tvalid;
   reg [511 : 0]		      m_axis_tdata;
   reg [63 : 0]			      m_axis_tkeep;
   reg				      m_axis_tlast;
   // AXI MM Slave
   // axi addr write
   reg				      s_axi_awready;
   wire [5 : 0]			      s_axi_awid;
   wire [31 : 0]		      s_axi_awaddr;
   wire [7 : 0]			      s_axi_awlen;
   wire [2 : 0]			      s_axi_awsize;
   wire [1 : 0]			      s_axi_awburst;
   wire				      s_axi_awlock;
   wire [3 : 0]			      s_axi_awcache;
   wire [2 : 0]			      s_axi_awprot;
   wire				      s_axi_awvalid;
   // axi write
   wire				      s_axi_wd_wready;
   wire [511 : 0]		      s_axi_wd_data;
   wire [63 : 0]		      s_axi_wd_strb;
   wire				      s_axi_wd_last;
   wire				      s_axi_wd_last;
   wire				      s_axi_wd_valid;
   // axi resp
   reg				      s_axi_wd_bid;
   reg [1 : 0]			      s_axi_wd_bresp;
   reg				      s_axi_wd_bvalid;
   wire				      s_axi_wd_bready;

   // i/o
   wire				      s_o_capture_start;
   wire				      s_o_done;


   streamCapture streamCaptureTbInst
     (
      .clk_stream(clk_stream),
      .m_axis_aclk(m_axi_aclk),
      .resetn_stream(resetn_stream),
      // axi stream
      .s_axis_tvalid(m_axis_tvalid),
      .s_axis_tdata(m_axis_tdata),
      .s_axis_tkeep(m_axis_tkeep),
      .s_axis_tlast(m_axis_tlast),
      // axi lite
      .s00_axi_aclk(m00_axi_aclk),
      .s00_axi_aresetn(m00_axi_aresetn),
      .s00_axi_awaddr(m00_axi_awaddr),
      .s00_axi_awprot(m00_axi_awprot),
      .s00_axi_awvalid(m00_axi_awvalid),
      .s00_axi_awready(m00_axi_awready),
      .s00_axi_wdata(m00_axi_wdata),
      .s00_axi_wstrb(m00_axi_wstrb),
      .s00_axi_wvalid(m00_axi_wvalid),
      .s00_axi_wready(m00_axi_wready),
      .s00_axi_bresp(m00_axi_bresp),
      .s00_axi_bvalid(m00_axi_bvalid),
      .s00_axi_bready(m00_axi_bready),
      .s00_axi_araddr(m00_axi_araddr),
      .s00_axi_arprot(m00_axi_arprot),
      .s00_axi_arvalid(m00_axi_arvalid),
      .s00_axi_arready(m00_axi_arready),
      .s00_axi_rdata(m00_axi_rdata),
      .s00_axi_rresp(m00_axi_rresp),
      .s00_axi_rvalid(m00_axi_rvalid),
      .s00_axi_rready(m00_axi_rready),
      // aix mm
      .axi_awready(s_axi_awready),
      .axi_awid(s_axi_awid),
      .axi_awaddr(s_axi_awaddr),
      .axi_awlen(s_axi_awlen),
      .axi_awsize(s_axi_awsize),
      .axi_awburst(s_axi_awburst),
      .axi_awlock(s_axi_awlock),
      .axi_awcache(s_axi_awcache),
      .axi_awprot(s_axi_awprot),
      .axi_awvalid(s_axi_awvalid),
      .axi_wd_wready(s_axi_wd_wready),
      .axi_wd_data(s_axi_wd_data),
      .axi_wd_strb(s_axi_wd_strb),
      .axi_wd_last(s_axi_wd_last),
      .axi_wd_valid(s_axi_wd_valid),
      .axi_wd_bid(s_axi_wd_bid),
      .axi_wd_bresp(s_axi_wd_bresp),
      .axi_wd_bvalid(s_axi_wd_bvalid),
      .axi_wd_bready(s_axi_wd_bready),

      //i/o
      .o_capture_start(s_o_capture_start),
      .o_done(s_o_done),
      .empty(almost_empty),
      .full(almost_full)
      );


   initial begin
      $display("initialising vars");
      // clk and rese<t
      m00_axi_aclk = 0;
      m00_axi_aresetn = 0;
      m_axi_aclk = 0;
      clk_stream = 0;
      resetn_stream = 0;
      m_axis_tdata = 0;
      m_axis_tkeep = 0;
      m_axis_tlast = 0;
      m_axis_tvalid = 0;
      #20
	m00_axi_aresetn = 1;
      resetn_stream = 1;

      // prot
      m00_axi_awprot = 3'b000;
      m00_axi_arprot = 3'b000;

      // ready signal
      m00_axi_bready = 1;
      m00_axi_rready = 1;
      //s_axi_awready = 1;
      //s_axi_wd_wready = 1;

      // valid signal
      m00_axi_awvalid = 0;
      m00_axi_wvalid = 0;
      s_axi_wd_bvalid = 0;

      // set baseAddr for AXI MM
      #30
	m00_axi_awaddr = 32'h00000008;
      m00_axi_awvalid = 1'b1;
      //#1 m00_axi_awvalid = 1'b0;
      #30
	m00_axi_wdata = 32'h08000000;
      m00_axi_wstrb = 4'hf;
      m00_axi_wvalid = 1'b1;
      wait(m00_axi_bvalid)
	m00_axi_wvalid = 1'b0;
      m00_axi_awvalid = 1'b0;

      #30
	m00_axi_awaddr = 32'h00000000;
      m00_axi_awvalid = 1'b1;
      #30
	m00_axi_wdata = 32'h00000001;
      m00_axi_wstrb = 4'h1;
      m00_axi_wvalid = 1'b1;
      wait(m00_axi_bvalid)
        m00_axi_wvalid = 1'b0;
      m00_axi_awvalid = 1'b0;
      #30
	if(s_axi_awaddr == 32'h08000000)
	  $display("Successfully set Address");
	else
	  $display("Failed to set Address");
      if(s_o_capture_start == 1'b1)
	$display("Successfully intiated Capture");
      else
	$display("Failed to start Capture");
      // send some PCIe packets
      s_axi_awready = 1'b1;
      #12

	repeat (3) begin
	   #12
	     m_axis_tdata = 512'h1514_1312_1110_0f0e_0d0c_0b0a_0908_0706_0504_0302_0100_0000_1e00_007b_007b_0d0c_0b0a_0403_0201_9060_1140_0000_0000_4000_0045_0008_1a19_1817_1615_1a19_1817_1615;
         m_axis_tkeep = 64'hffff_ffff_ffff_ffff;
           m_axis_tvalid = 1'b1;
           m_axis_tlast = 1'b0;
	   #12
	     m_axis_tdata = 512'h0000_0000_0000_0000_0000_0000_0000_7f7e_7d7c_7b7a_0000_3f3e_3d3c_3b3a_3938_3736_3534_3332_3130_2f2e_2d2c_2b2a_2928_2726_2524_2322_2120_1f1e_1d1c_1b1a_1918_1716;
           m_axis_tkeep = 64'h0000_03ff_ffff_ffff;
           m_axis_tlast = 1'b1;
	   #12
	     m_axis_tdata = 512'h5554_5352_5150_4f4e_4d4c_4b4a_4948_4746_4544_4342_4140_0000_1e00_007b_007b_0d0c_0b0a_0403_0201_9060_1140_0000_0000_4000_0045_0008_1a19_1817_1615_1a19_1817_1615;
           m_axis_tkeep = 64'hffff_ffff_ffff_ffff;
           //m_axis_tvalid = 1'b1;
           m_axis_tlast = 1'b0;
	   #12
	     m_axis_tdata = 512'h2040_1901_4300_0010_006a_02c0_0000_0000_0000_0000_0000_7f7e_7d7c_7b7a_7978_7776_7574_7372_7170_6f6e_6d6c_6b6a_6968_6766_6564_6362_6160_5f5e_5d5c_5b5a_5958_1756;
           m_axis_tkeep = 64'h0000_03ff_ffff_ffff;
           m_axis_tlast = 1'b1;
	   #12
	     m_axis_tvalid = 1'b0;
	   #12
	     m_axis_tdata = 512'h9594_9392_9190_8f8e_8d8c_8b8a_8988_8786_8584_8382_8180_0000_1e00_007b_007b_0d0c_0b0a_0403_0201_9060_1140_0000_0000_4000_0045_0008_1a19_1817_1615_1a19_1817_1615;
           m_axis_tkeep = 64'hffff_ffff_ffff_ffff;
	   m_axis_tvalid = 1'b1;
           m_axis_tlast = 1'b0;
	   #12
	     m_axis_tdata = 512'h2040_1902_4300_001b_406a_0980_0000_0000_0000_0000_0000_bfbe_bdbc_bbba_b9b8_b7b6_b5b4_b3b2_b1b0_afae_adac_abaa_a9a8_a7a6_a5a4_a3a2_a1a0_9f9e_9d9c_9b9a_9998_9796;
           m_axis_tkeep = 64'h0000_03ff_ffff_ffff;
           m_axis_tlast = 1'b1;
	end
      #12
	m_axis_tvalid = 1'b0;
      m_axis_tlast = 1'b0;
      #10000000 $finish;
   end


   always #6  clk_stream = ~clk_stream;     // 250 MHz
   always #15 m00_axi_aclk = ~m00_axi_aclk; // 100 MHz
   always #3  m_axi_aclk = ~m_axi_aclk;     // 300 MHz


   //assign s_axi_awready = 1;;
   assign s_axi_wd_wready = s_axi_wd_valid;


   always@(negedge s_axi_awvalid) begin
       s_axi_awready = 1'b0;
      #6
	s_axi_awready = 1'b1;
   end


   always@(negedge s_axi_wd_valid) begin
     #6
	s_axi_wd_bresp <= 2'b00;
	s_axi_wd_bvalid <= 1;
      #6
	s_axi_wd_bvalid <= 0;
   end


   always@(posedge m_axi_aclk) begin
      if(s_axi_awvalid) begin
	 $write("addr: %x ", s_axi_awaddr);
      end
      if(s_axi_wd_valid) begin
	 $write("data: %x \n", s_axi_wd_data);
      end
   end


endmodule
