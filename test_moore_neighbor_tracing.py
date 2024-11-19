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
from make_images import get_image_data


@cocotb.test()
async def test_a(dut):
    """cocotb test for moore_neighbor_tracing"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 0
    masked_arr = get_image_data("images/square.png")
    for x in range(320):
        for y in range(180):
            await RisingEdge(dut.clk_in)
            dut.x_in <= x
            dut.y_in <= y
            dut.rst_in <= 1
            dut.masked_in <= masked_arr[y*320 + x]
            dut.new_frame_in <= 0
            await RisingEdge(dut.clk_in)
            dut.rst_in <= 0
            await RisingEdge(dut.clk_in)
            dut._log.info(f"({x},{y}): {dut.out.value}")

def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "moore_neighbor_tracing.sv"]
    sources += [proj_path / "ip" / "blk_mem_gen_0" / "blk_mem_gen_0.xci"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="moore_neighbor_tracing",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="moore_neighbor_tracing",
        test_module="test_moore_neighbor_tracing",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()
