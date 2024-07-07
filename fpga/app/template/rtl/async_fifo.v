/*
 1. On fifo full, write overwrites the data and reader reads the most recent data, flushing
 the rest of the output.
 2. Makes sure to notice the duration of read and write while debugging
 3. Reader pointer always lags one or more steps from the write and are never equal.
 4. data_out is asynchornous because read pointer is already buffered, so in total data_out
 gets delayed two cycles instead of one.
 5. This code is not tested against odd frequencies of reader and writer which are  non-divisible
 */

module fifo #
  (
   parameter integer DEPTH = 64,
   parameter integer WIDTH = 512 // bits
   )
   (
    input		     resetn,
    input		     wr_clk,
    input		     rd_clk,
    input		     wr_en,
    input		     rd_en,
    input [WIDTH-1 : 0]	     data_in,
    output reg [WIDTH-1 : 0] data_out,
    output reg		     fifo_full,
    output reg		     fifo_empty,
    output reg [31 : 0]	     ptr,
    input [31 : 0]	     mon_ptr
    );

   reg [WIDTH-1 : 0]	     mem [0 : DEPTH-1];
   // read ptr is initialised to DEPTH-1 and write ptr to 0
   // read ptr always lags 1 or more steps behind write ptr
   // read ptr points to last read buffer and write ptr points
   // to be written buffer
   reg [31 : 0]		     rd_ptr = DEPTH-1;
   reg [31 : 0]		     wr_ptr = 0;


   always @(posedge wr_clk) begin
      if (!resetn) begin
	 wr_ptr <= 0;
      end
      else if (wr_en) begin
	 mem[wr_ptr] <= data_in;
	 // implementation of circular buffer
	 if(wr_ptr == (DEPTH - 1)) begin
	    wr_ptr <= 0;
	 end
	 else begin
	    wr_ptr <= wr_ptr + 1;
	 end
      end
   end


   always @(posedge rd_clk) begin
      if (!resetn) begin
	 rd_ptr <= DEPTH-1;
      end
      else if (rd_en) begin
	 data_out <= mem[rd_ptr];
	 ptr <= rd_ptr;
	 // TODO:
	 // 1. make this optional
	 // 2. reimplement with fewer signals, this might result to only allow track monitor
	 //    module to only lag fewer steps behind.
	 if (mon_ptr == rd_ptr) begin
	    // edge case:
	    // 1. Donot increment ahead to equal to write ptr
	    // 2. handle for circular buffer case
	    if (~(((rd_ptr + 1) == wr_ptr) || ((rd_ptr == (DEPTH - 1)) && (wr_ptr == 0)))) begin
	       if( rd_ptr == (DEPTH - 1)) begin
		  rd_ptr <= 0;
	       end
	       else begin
		  rd_ptr <= rd_ptr + 1;
	       end
	    end
	 end
      end
   end


   always @(posedge wr_clk or posedge rd_clk) begin
      if (!resetn & wr_clk) begin
	 fifo_full <= 0;
	 fifo_empty <= 1;
      end
      else if(wr_clk & wr_en) begin
	 // full if write ptr catches up with read ptr
	 if((wr_ptr + 1) == rd_ptr) begin
	    fifo_full <= 1'b1;
	 end
	 fifo_empty <= 1'b0;
      end
      else if(rd_clk & rd_en) begin
	 // empty if read ptr catches up with write ptr
	 if(((rd_ptr + 1) == wr_ptr) || ((rd_ptr == (DEPTH - 1)) && (wr_ptr == 0))) begin
	    fifo_empty <= 1'b1;
	 end
	 fifo_full <= 1'b0;
      end
   end


endmodule
