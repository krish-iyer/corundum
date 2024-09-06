#!/usr/bin/env python3

import itertools
import logging
import os
import random

import cocotb_test.simulator
import pytest

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.regression import TestFactory

from cocotbext.axi import AxiStreamBus, AxiStreamFrame, AxiStreamSource, AxiStreamSink

class TB(object):
    def __init__(self, dut):
        self.dut = dut
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        wr_clk = int(os.getenv("S_CLK", "10"))
        rd_clk = int(os.getenv("M_CLK", "10"))

        cocotb.start_soon(Clock(dut.wr_clk, wr_clk, units="ns").start())
        cocotb.start_soon(Clock(dut.rd_clk, rd_clk, units="ns").start())

        self.dut.wr_en.setimmediatevalue(0)
        self.dut.rd_en.setimmediatevalue(0)

        self.dut.wr_rst.setimmediatevalue(0)
        self.dut.rd_rst.setimmediatevalue(0)

    async def write_frame(self, frame):
        await RisingEdge(self.dut.wr_clk)
        self.dut.data_in.value = frame
        self.dut.wr_en.value = 1
        await RisingEdge(self.dut.wr_clk)
        self.dut.wr_en.value = 0

    async def read_frame(self):
        await RisingEdge(self.dut.rd_clk)
        self.dut.rd_en.value = 1
        frame = self.dut.data_out
        await RisingEdge(self.dut.rd_clk)
        self.dut.rd_en.value = 0
        return frame

    async def reset_rd(self):
        self.dut.rd_rst.setimmediatevalue(0)
        for k in range(10):
            await RisingEdge(self.dut.rd_clk)
        self.dut.rd_rst.value = 1
        for k in range(10):
            await RisingEdge(self.dut.rd_clk)
        self.dut.rd_rst.value = 0
        for k in range(10):
            await RisingEdge(self.dut.rd_clk)

    async def reset_wr(self):
        self.dut.wr_rst.setimmediatevalue(0)
        for k in range(10):
            await RisingEdge(self.dut.wr_clk)
        self.dut.wr_rst.value = 1
        for k in range(10):
            await RisingEdge(self.dut.wr_clk)
        self.dut.wr_rst.value = 0
        for k in range(10):
            await RisingEdge(self.dut.wr_clk)

async def run_test(dut):

    tb = TB(dut)

    await tb.reset_rd()
    await tb.reset_wr()

    send_frame = bytes([x % 256 for x in range(64)])
    send_frame_int = int.from_bytes(send_frame, byteorder='big')

    for k in range(2):
        await tb.write_frame(send_frame_int)


    for k in range(1):
        recv_frame = await tb.read_frame()
        tb.log.info("send_frame {}".format(send_frame))
        tb.log.info("recv_frame {}".format(recv_frame))

        assert send_frame_int == recv_frame.value

    for k in range(7):
        await tb.write_frame(send_frame_int)

    for k in range(1):
        recv_frame = await tb.read_frame()
        tb.log.info("send_frame {}".format(send_frame))
        tb.log.info("recv_frame {}".format(recv_frame))

        assert send_frame_int == recv_frame.value


    await tb.write_frame(send_frame_int)

    recv_frame = await tb.read_frame()
    # recv_frame = await tb.read_frame()

    await RisingEdge(dut.wr_clk)
    await RisingEdge(dut.rd_clk)


if cocotb.SIM_NAME:

    factory = TestFactory(run_test)
    factory.generate_tests()

tests_dir = os.path.dirname(__file__)
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'rtl'))


def test_async_fifo():

    dut = "async_fifo"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.v"),
    ]

    parameters = {}

    parameters['DATA_WIDTH'] = 512
    parameters['DEPTH'] = 8

    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

    extra_env['S_CLK'] = str(wr_clk)
    extra_env['M_CLK'] = str(rd_clk)

    sim_build = os.path.join(tests_dir, "sim_build",
        request.node.name.replace('[', '-').replace(']', ''))

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        parameters=parameters,
        sim_build=sim_build,
        extra_env=extra_env,
    )
