/*

Copyright (c) 2018-2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream 4x4 switch (wrapper)
 */
module axis_switch_wrap_4x4 #
(
    // Width of AXI stream interfaces in bits
    parameter DATA_WIDTH = 8,
    // Propagate tkeep signal
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    // tkeep signal width (words per cycle)
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    // Propagate tid signal
    parameter ID_ENABLE = 0,
    // input tid signal width
    parameter S_ID_WIDTH = 8,
    // output tid signal width
    parameter M_ID_WIDTH = S_ID_WIDTH+2,
    // output tdest signal width
    parameter M_DEST_WIDTH = 1,
    // input tdest signal width
    // must be wide enough to uniquely address outputs
    parameter S_DEST_WIDTH = M_DEST_WIDTH+2,
    // Propagate tuser signal
    parameter USER_ENABLE = 1,
    // tuser signal width
    parameter USER_WIDTH = 1,
    // Output interface routing base tdest selection
    // Port selected if M_BASE <= tdest <= M_TOP
    parameter M00_BASE = 0,
    // Output interface routing top tdest selection
    // Port selected if M_BASE <= tdest <= M_TOP
    parameter M00_TOP = 0,
    // Interface connection control
    parameter M00_CONNECT = 4'b1111,
    // Output interface routing base tdest selection
    // Port selected if M_BASE <= tdest <= M_TOP
    parameter M01_BASE = 1,
    // Output interface routing top tdest selection
    // Port selected if M_BASE <= tdest <= M_TOP
    parameter M01_TOP = 1,
    // Interface connection control
    parameter M01_CONNECT = 4'b1111,
    // Output interface routing base tdest selection
    // Port selected if M_BASE <= tdest <= M_TOP
    parameter M02_BASE = 2,
    // Output interface routing top tdest selection
    // Port selected if M_BASE <= tdest <= M_TOP
    parameter M02_TOP = 2,
    // Interface connection control
    parameter M02_CONNECT = 4'b1111,
    // Output interface routing base tdest selection
    // Port selected if M_BASE <= tdest <= M_TOP
    parameter M03_BASE = 3,
    // Output interface routing top tdest selection
    // Port selected if M_BASE <= tdest <= M_TOP
    parameter M03_TOP = 3,
    // Interface connection control
    parameter M03_CONNECT = 4'b1111,
    // Update tid with routing information
    parameter UPDATE_TID = 0,
    // Input interface register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_REG_TYPE = 0,
    // Output interface register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_REG_TYPE = 2,
    // select round robin arbitration
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    // LSB priority selection
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                  clk,
    input  wire                  rst,

    /*
     * AXI Stream inputs
     */
    input  wire [DATA_WIDTH-1:0]    s00_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]    s00_axis_tkeep,
    input  wire                     s00_axis_tvalid,
    output wire                     s00_axis_tready,
    input  wire                     s00_axis_tlast,
    input  wire [S_ID_WIDTH-1:0]    s00_axis_tid,
    input  wire [S_DEST_WIDTH-1:0]  s00_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s00_axis_tuser,

    input  wire [DATA_WIDTH-1:0]    s01_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]    s01_axis_tkeep,
    input  wire                     s01_axis_tvalid,
    output wire                     s01_axis_tready,
    input  wire                     s01_axis_tlast,
    input  wire [S_ID_WIDTH-1:0]    s01_axis_tid,
    input  wire [S_DEST_WIDTH-1:0]  s01_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s01_axis_tuser,

    input  wire [DATA_WIDTH-1:0]    s02_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]    s02_axis_tkeep,
    input  wire                     s02_axis_tvalid,
    output wire                     s02_axis_tready,
    input  wire                     s02_axis_tlast,
    input  wire [S_ID_WIDTH-1:0]    s02_axis_tid,
    input  wire [S_DEST_WIDTH-1:0]  s02_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s02_axis_tuser,

    input  wire [DATA_WIDTH-1:0]    s03_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]    s03_axis_tkeep,
    input  wire                     s03_axis_tvalid,
    output wire                     s03_axis_tready,
    input  wire                     s03_axis_tlast,
    input  wire [S_ID_WIDTH-1:0]    s03_axis_tid,
    input  wire [S_DEST_WIDTH-1:0]  s03_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s03_axis_tuser,

    /*
     * AXI Stream outputs
     */
    output wire [DATA_WIDTH-1:0]    m00_axis_tdata,
    output wire [KEEP_WIDTH-1:0]    m00_axis_tkeep,
    output wire                     m00_axis_tvalid,
    input  wire                     m00_axis_tready,
    output wire                     m00_axis_tlast,
    output wire [M_ID_WIDTH-1:0]    m00_axis_tid,
    output wire [M_DEST_WIDTH-1:0]  m00_axis_tdest,
    output wire [USER_WIDTH-1:0]    m00_axis_tuser,

    output wire [DATA_WIDTH-1:0]    m01_axis_tdata,
    output wire [KEEP_WIDTH-1:0]    m01_axis_tkeep,
    output wire                     m01_axis_tvalid,
    input  wire                     m01_axis_tready,
    output wire                     m01_axis_tlast,
    output wire [M_ID_WIDTH-1:0]    m01_axis_tid,
    output wire [M_DEST_WIDTH-1:0]  m01_axis_tdest,
    output wire [USER_WIDTH-1:0]    m01_axis_tuser,

    output wire [DATA_WIDTH-1:0]    m02_axis_tdata,
    output wire [KEEP_WIDTH-1:0]    m02_axis_tkeep,
    output wire                     m02_axis_tvalid,
    input  wire                     m02_axis_tready,
    output wire                     m02_axis_tlast,
    output wire [M_ID_WIDTH-1:0]    m02_axis_tid,
    output wire [M_DEST_WIDTH-1:0]  m02_axis_tdest,
    output wire [USER_WIDTH-1:0]    m02_axis_tuser,

    output wire [DATA_WIDTH-1:0]    m03_axis_tdata,
    output wire [KEEP_WIDTH-1:0]    m03_axis_tkeep,
    output wire                     m03_axis_tvalid,
    input  wire                     m03_axis_tready,
    output wire                     m03_axis_tlast,
    output wire [M_ID_WIDTH-1:0]    m03_axis_tid,
    output wire [M_DEST_WIDTH-1:0]  m03_axis_tdest,
    output wire [USER_WIDTH-1:0]    m03_axis_tuser
);

// parameter sizing helpers
function [S_DEST_WIDTH-1:0] w_dw(input [S_DEST_WIDTH-1:0] val);
    w_dw = val;
endfunction

function [3:0] w_s(input [3:0] val);
    w_s = val;
endfunction

axis_switch #(
    .S_COUNT(4),
    .M_COUNT(4),
    .DATA_WIDTH(DATA_WIDTH),
    .KEEP_ENABLE(KEEP_ENABLE),
    .KEEP_WIDTH(KEEP_WIDTH),
    .ID_ENABLE(ID_ENABLE),
    .S_ID_WIDTH(S_ID_WIDTH),
    .M_ID_WIDTH(M_ID_WIDTH),
    .S_DEST_WIDTH(S_DEST_WIDTH),
    .M_DEST_WIDTH(M_DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH),
    .M_BASE({ w_dw(M03_BASE), w_dw(M02_BASE), w_dw(M01_BASE), w_dw(M00_BASE) }),
    .M_TOP({ w_dw(M03_TOP), w_dw(M02_TOP), w_dw(M01_TOP), w_dw(M00_TOP) }),
    .M_CONNECT({ w_s(M03_CONNECT), w_s(M02_CONNECT), w_s(M01_CONNECT), w_s(M00_CONNECT) }),
    .UPDATE_TID(UPDATE_TID),
    .S_REG_TYPE(S_REG_TYPE),
    .M_REG_TYPE(M_REG_TYPE),
    .ARB_TYPE_ROUND_ROBIN(ARB_TYPE_ROUND_ROBIN),
    .ARB_LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
)
axis_switch_inst (
    .clk(clk),
    .rst(rst),
    // AXI inputs
    .s_axis_tdata({ s03_axis_tdata, s02_axis_tdata, s01_axis_tdata, s00_axis_tdata }),
    .s_axis_tkeep({ s03_axis_tkeep, s02_axis_tkeep, s01_axis_tkeep, s00_axis_tkeep }),
    .s_axis_tvalid({ s03_axis_tvalid, s02_axis_tvalid, s01_axis_tvalid, s00_axis_tvalid }),
    .s_axis_tready({ s03_axis_tready, s02_axis_tready, s01_axis_tready, s00_axis_tready }),
    .s_axis_tlast({ s03_axis_tlast, s02_axis_tlast, s01_axis_tlast, s00_axis_tlast }),
    .s_axis_tid({ s03_axis_tid, s02_axis_tid, s01_axis_tid, s00_axis_tid }),
    .s_axis_tdest({ s03_axis_tdest, s02_axis_tdest, s01_axis_tdest, s00_axis_tdest }),
    .s_axis_tuser({ s03_axis_tuser, s02_axis_tuser, s01_axis_tuser, s00_axis_tuser }),
    // AXI outputs
    .m_axis_tdata({ m03_axis_tdata, m02_axis_tdata, m01_axis_tdata, m00_axis_tdata }),
    .m_axis_tkeep({ m03_axis_tkeep, m02_axis_tkeep, m01_axis_tkeep, m00_axis_tkeep }),
    .m_axis_tvalid({ m03_axis_tvalid, m02_axis_tvalid, m01_axis_tvalid, m00_axis_tvalid }),
    .m_axis_tready({ m03_axis_tready, m02_axis_tready, m01_axis_tready, m00_axis_tready }),
    .m_axis_tlast({ m03_axis_tlast, m02_axis_tlast, m01_axis_tlast, m00_axis_tlast }),
    .m_axis_tid({ m03_axis_tid, m02_axis_tid, m01_axis_tid, m00_axis_tid }),
    .m_axis_tdest({ m03_axis_tdest, m02_axis_tdest, m01_axis_tdest, m00_axis_tdest }),
    .m_axis_tuser({ m03_axis_tuser, m02_axis_tuser, m01_axis_tuser, m00_axis_tuser })
);

endmodule

`resetall
