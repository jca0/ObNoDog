`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module image_sprite_transparent_numbers_1 #(
  parameter WIDTH=24, HEIGHT = 24, NUM_IMGS = 10) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  input wire [3:0] number,
  //output logic [7:0] red_out,
  //output logic [7:0] green_out,
  //output logic [7:0] blue_out,
  output logic draw_out
  );

  
  //***PS10***
  //vary the packed width based on signal
  //vary the unpacked width based on pipelining depth needed
  logic [10:0] hcount_in_ps10 [4-1:0];
  logic [9:0] vcount_in_ps10 [4-1:0];

  always_ff @(posedge pixel_clk_in)begin
    hcount_in_ps10[0] <= hcount_in;
    vcount_in_ps10[0] <= vcount_in;

    for (int i = 1; i < 4; i = i + 1) begin
      hcount_in_ps10[i] <= hcount_in_ps10[i-1];
      vcount_in_ps10[i] <= vcount_in_ps10[i-1];
    end
  end
  



  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT*NUM_IMGS)-1:0] image_addr;
  // assign image_addr = (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH);
  assign image_addr = (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH) + number*WIDTH*HEIGHT;

  logic in_sprite;
  //assign in_sprite = ((hcount_in >= x_in && hcount_in < (x_in + WIDTH)) &&
  //                    (vcount_in >= y_in && vcount_in < (y_in + HEIGHT)));

  // use pipelined values
  assign in_sprite = ((hcount_in_ps10[3] >= x_in && hcount_in_ps10[3] < (x_in + WIDTH)) &&
                      (vcount_in_ps10[3] >= y_in && vcount_in_ps10[3] < (y_in + HEIGHT)));

  // Modify the module below to use your BRAMs!
  // assign red_out =    in_sprite ? 8'hF0 : 0;
  // assign green_out =  in_sprite ? 8'hF0 : 0;
  // assign blue_out =   in_sprite ? 8'hF0 : 0;

  logic color;

  //assign red_out =    0;
  //assign green_out =  in_sprite && color? 255;
  //assign blue_out =   0;
  assign draw_out = in_sprite && color; //(in_sprite && !(green_out == 63 && red_out == 31 && blue_out == 31));
  

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(1),                       // Specify RAM data width
    .RAM_DEPTH(WIDTH*HEIGHT*NUM_IMGS),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(numbers.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) pixel_BROM (
    .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(color)      // RAM output data, width determined from RAM_WIDTH
  );


endmodule






`default_nettype none
