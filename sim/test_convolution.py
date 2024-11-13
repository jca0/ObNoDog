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
from PIL import Image

im_input = Image.open("/Users/jingcao/Desktop/6.205/lab07/sim/preview.png")
im_input = im_input.convert('RGB')
width, height = im_input.size

# Create output image
im_output = Image.new('RGB', (width, height))

def rgb_to_rgb565(r, g, b):
    """Convert RGB (0-255) to RGB565 (16-bit)"""
    r5 = (r >> 3) & 0x1F
    g6 = (g >> 2) & 0x3F
    b5 = (b >> 3) & 0x1F
    return (r5 << 11) | (g6 << 5) | b5

def rgb565_to_rgb(pixel565):
    """Convert RGB565 (16-bit) back to RGB (0-255)"""
    r5 = (pixel565 >> 11) & 0x1F
    g6 = (pixel565 >> 5) & 0x3F
    b5 = pixel565 & 0x1F
    
    r8 = (r5 << 3) | (r5 >> 2)
    g8 = (g6 << 2) | (g6 >> 4)
    b8 = (b5 << 3) | (b5 >> 2)
    
    return (r8, g8, b8)

@cocotb.test()
async def test_a(dut):
    """Process image through convolution module"""
    # Start clock
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    
    # Reset values
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 2)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 2)

    # Process image pixel by pixel
    for y in range(height):
        for x in range(width):
            # Get current pixel and its neighbors
            for i in range(3):  # Assuming 3 pixel window
                if x >= i:
                    # Get RGB values for pixel
                    r, g, b = im_input.getpixel((x-i, y))
                    # Convert to RGB565
                    pixel565 = rgb_to_rgb565(r, g, b)
                    # Assign to data_in
                    dut.data_in[i].value = pixel565
                else:
                    # Pad with zeros at image boundary
                    dut.data_in[i].value = 0

            # Set coordinates and valid signal
            dut.hcount_in.value = x
            dut.vcount_in.value = y
            dut.data_valid_in.value = 1

            # Wait for one clock cycle
            await RisingEdge(dut.clk_in)
            await Timer(1, units='ns')

            # If output is valid, save to output image
            if dut.data_valid_out.value:
                # Get output value and convert back to RGB
                output_pixel = int(dut.line_out.value)
                r, g, b = rgb565_to_rgb(output_pixel)
                # Save to output image
                im_output.putpixel((x, y), (r, g, b))

    # Save output image
    im_output.save('../sim/output.png', 'PNG')

def convolution_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "convolution.sv"] #grow/modify this as needed.
    sources += [proj_path / "hdl" / "kernels.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {} #!!! nice figured it out.
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="convolution",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="convolution",
        test_module="test_convolution",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    convolution_runner()