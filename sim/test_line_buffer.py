import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

@cocotb.test()
async def test_a(dut):
    """cocotb test?"""
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    
    # Reset values
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 2)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 2)

    test_sequence = [
        (0, 0, 0xFFFF, 1),  # Valid data
        (1, 0, 0xFFFF, 0),  # Invalid data
        (2, 0, 0xFFFF, 1),  # Valid data
        (3, 0, 0xFFFF, 0),  # Invalid data
    ]
    
    for hcount, vcount, pixel, valid in test_sequence:
        dut.hcount_in.value = hcount
        dut.vcount_in.value = vcount
        dut.pixel_data_in.value = pixel
        dut.data_valid_in.value = valid
        
        await RisingEdge(dut.clk_in)
        await ClockCycles(dut.clk_in, 2)

def line_buffer_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "line_buffer.sv"] #grow/modify this as needed.
    sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.v"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {} #!!! nice figured it out.
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
    line_buffer_runner()