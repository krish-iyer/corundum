module fifo_tb();

   localparam integer WIDTH = 32;
   localparam integer DEPTH = 9;

   reg		      resetn;
   reg		      wr_clk;
   reg		      rd_clk;
   reg		      wr_en;
   reg		      rd_en;
   reg [WIDTH-1 : 0]  data_in;
   wire [WIDTH-1 : 0] data_out;
   wire		      fifo_full;
   wire		      fifo_empty;
   integer	      incr = 0;


   fifo #
     (.DEPTH(DEPTH),
      .WIDTH(WIDTH)
      )
   fifo_inst
     (
      .resetn(resetn),
      .wr_clk(wr_clk),
      .rd_clk(rd_clk),
      .wr_en(wr_en),
      .rd_en(rd_en),
      .data_in(data_in),
      .data_out(data_out),
      .fifo_full(fifo_full),
      .fifo_empty(fifo_empty)
      );


   initial begin
      resetn = 0;
      wr_clk = 0;
      rd_clk = 0;
      data_in = 0;
      #0.008
	resetn = 1;
      wr_en <= 1;
      rd_en <= 1;
      repeat (11) begin
	 #0.004
	   data_in <= incr;
	 incr = incr + 1;
      end
      wr_en = 0;
      #1000 $finish;
   end


   initial begin
      repeat (40) begin
	 #0.01
	   $display("data out: %d",data_out);
      end
      rd_en = 0;
   end


   always #0.002 wr_clk = ~wr_clk; // 250 hz
   always #0.005 rd_clk = ~rd_clk; // 100 hz


endmodule
