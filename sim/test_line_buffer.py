import cocotb
import os
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner



@cocotb.test()
async def test_a(dut):
    """cocotb test for line_buffer"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 0
    dut.hcount_in.value = 0
    dut.vcount_in.value = 0
    dut.pixel_data_in.value = 0
    dut.data_valid_in.value = 0
    await ClockCycles(dut.clk_in,1)
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,5)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,20)

    dut.data_valid_in.value = 1
    dut.pixel_data_in = 0xFFFF
    dut.vcount_in = 1
    dut.hcount_in = 1
    await ClockCycles(dut.clk_in, 1)
    dut.data_valid_in.value = 0
    dut.pixel_data_in = 0
    
    await ClockCycles(dut.clk_in,5)
    dut.data_valid_in.value = 1
    dut.pixel_data_in = 0xAAAA
    dut.vcount_in = 2
    dut.hcount_in = 2
    await ClockCycles(dut.clk_in, 1)
    dut.data_valid_in.value = 0
    dut.pixel_data_in = 0
    await ClockCycles(dut.clk_in,5)




    #await FallingEdge(dut.clk_in)
    dut.hcount_in.value = 1279
    dut.data_valid_in.value = 1
    dut.pixel_data_in = 0x1111
    await ClockCycles(dut.clk_in, 1)

    #await FallingEdge(dut.clk_in)
    dut.hcount_in.value = 0
    dut.data_valid_in.value = 0
    dut.pixel_data_in = 0
    await ClockCycles(dut.clk_in, 20)
    






def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "line_buffer.sv"]
    sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.v"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="line_buffer",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="line_buffer",
        test_module="test_line_buffer",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()
