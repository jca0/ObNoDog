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
    """cocotb test for circularity"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 0
    dut.area.value = 0
    dut.perimeter.value = 0
    dut.data_valid_in.value = 0

    await ClockCycles(dut.clk_in,1)
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,5)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,5)

    # circle (d = 128) --> 95
    dut.data_valid_in.value = 1
    dut.area.value = 12868
    dut.perimeter.value = 402
    await ClockCycles(dut.clk_in,1)
    dut.data_valid_in.value = 0
    dut.area.value = 0
    dut.perimeter.value = 0
    await ClockCycles(dut.clk_in,100)

    # square --> 76
    dut.data_valid_in.value = 1
    dut.area.value = 16384
    dut.perimeter.value = 508
    await ClockCycles(dut.clk_in,1)
    dut.data_valid_in.value = 0
    dut.area.value = 0
    dut.perimeter.value = 0
    await ClockCycles(dut.clk_in,100)

    # triangle --> 57
    dut.data_valid_in.value = 1
    dut.area.value = 7094
    dut.perimeter.value = 384
    await ClockCycles(dut.clk_in,1)
    dut.data_valid_in.value = 0
    dut.area.value = 0
    dut.perimeter.value = 0
    await ClockCycles(dut.clk_in,100)

    # cross (5/9 tictactoe spaces) --> 42
    dut.data_valid_in.value = 1
    dut.area.value = 9102
    dut.perimeter.value = 508
    await ClockCycles(dut.clk_in,1)
    dut.data_valid_in.value = 0
    dut.area.value = 0
    dut.perimeter.value = 0
    await ClockCycles(dut.clk_in,100)










def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "circularity.sv"]
    sources += [proj_path / "hdl" / "divider.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="circularity",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="circularity",
        test_module="test_circularity",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()
