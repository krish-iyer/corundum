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

from cocotbext.axi import AxiBus, AxiMaster, AxiRam


class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.s_clk, 4, units="ns").start())
        cocotb.start_soon(Clock(dut.m_clk, 2, units="ns").start())

        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, "s_axi"), dut.s_clk, dut.s_rst)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, "m_axi"), dut.m_clk, dut.m_rst, size=2**16)

    def set_idle_generator(self, generator=None):
        if generator:
            self.source.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.sink.set_pause_generator(generator())

    async def reset(self):
        self.dut.m_rst.setimmediatevalue(0)
        self.dut.s_rst.setimmediatevalue(0)
        for k in range(10):
            await RisingEdge(self.dut.s_clk)
        self.dut.m_rst.value = 1
        self.dut.s_rst.value = 1
        for k in range(10):
            await RisingEdge(self.dut.s_clk)
        self.dut.m_rst.value = 0
        self.dut.s_rst.value = 0
        for k in range(10):
            await RisingEdge(self.dut.s_clk)

    async def reset_source(self):
        self.dut.s_rst.setimmediatevalue(0)
        for k in range(10):
            await RisingEdge(self.dut.s_clk)
        self.dut.s_rst.value = 1
        for k in range(10):
            await RisingEdge(self.dut.s_clk)
        self.dut.s_rst.value = 0
        for k in range(10):
            await RisingEdge(self.dut.s_clk)

    async def reset_sink(self):
        self.dut.m_rst.setimmediatevalue(0)
        for k in range(10):
            await RisingEdge(self.dut.m_clk)
        self.dut.m_rst.value = 1
        for k in range(10):
            await RisingEdge(self.dut.m_clk)
        self.dut.m_rst.value = 0
        for k in range(10):
            await RisingEdge(self.dut.m_clk)


async def run_test_read(dut, data_in=None, idle_inserter=None, backpressure_inserter=None, size=None):

    tb = TB(dut)

    byte_lanes = tb.axi_master.write_if.byte_lanes
    max_burst_size = tb.axi_master.write_if.max_burst_size

    if size is None:
        size = max_burst_size

    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    for length in list(range(1, byte_lanes*2))+[1024]:
        for offset in list(range(byte_lanes, byte_lanes*2))+[4096-byte_lanes]:
            tb.log.info("length %d, offset %d, size %d", length, offset, size)
            addr = offset+0x1000
            test_data = bytearray([x % 256 for x in range(length)])

            tb.axi_ram.write(addr, test_data)
            data = tb.axi_ram.read(addr, length)
            print("data : {}".format(data))
            #assert data.data == test_data

            data = await tb.axi_master.read(addr, length, size=size)

            assert data.data == test_data

    await RisingEdge(dut.s_clk)
    await RisingEdge(dut.s_clk)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])


if cocotb.SIM_NAME:

    data_width = len(cocotb.top.s_axi_wdata)
    byte_lanes = data_width // 8
    max_burst_size = (byte_lanes-1).bit_length()

    # for test in [run_test_write, run_test_read]:

    #     factory = TestFactory(test)
    #     factory.add_option("idle_inserter", [None, cycle_pause])
    #     factory.add_option("backpressure_inserter", [None, cycle_pause])
    #     factory.add_option("size", [None]+list(range(max_burst_size)))
    #     factory.generate_tests()

    factory = TestFactory(run_test_read)
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'rtl'))


@pytest.mark.parametrize("data_width", [8, 16, 32])
def test_axi_adapter(request, data_width):
    dut = "axi_async_fifo"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.v"),
        os.path.join(rtl_dir, f"async_fifo.v"),
    ]

    parameters = {}

    parameters['ADDR_WIDTH'] = 32
    parameters['DATA_WIDTH'] = data_width
    parameters['STRB_WIDTH'] = parameters['DATA_WIDTH'] // 8
    parameters['ID_WIDTH'] = 8
    parameters['ADDR_FIFO_DEPTH'] = 128
    parameters['DATA_FIFO_DEPTH'] = 128
    parameters['DEST_WIDTH'] = 8
    parameters['RUSER_WIDTH'] = 1
    parameters['ARUSER_WIDTH'] = 1

    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

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
