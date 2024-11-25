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
async def y_stays_same(dut):
    """cocotb test for seven segment controller"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut._log.info("Holding reset...")
    await FallingEdge(dut.clk_in)
    dut.rst_in.value = 1
    dut.cluster_id = 2
    await ClockCycles(dut.clk_in, 3, rising = False) #wait three clock cycles
    dut.rst_in.value = 0 #un reset device
    await ClockCycles(dut.clk_in, 1, rising = False)
    dut.valid_in.value = 1
    for i in range(10):
        dut.x_in.value = i
        dut.y_in.value = 10
        await ClockCycles(dut.clk_in, 1, rising = False)
    dut.tabulate_in.value = 1
    dut.valid_in.value = 0
    await ClockCycles(dut.clk_in, 1, rising = False)
    dut.tabulate_in.value = 0
    await ClockCycles(dut.clk_in, 100, rising = False)
    

def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "kmeans.sv"]
    sources += [proj_path / "hdl" / "divider.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="kmeans",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="kmeans",
        test_module="test_kmeans",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()
