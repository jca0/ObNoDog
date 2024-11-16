`timescale 1ns / 1ps
`default_nettype none

module connected_components (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire frame_valid_in,

                         output logic [$clog2(WIDTH*HEIGHT):0] perimeter,
                         output logic busy_out,
                         output logic valid_out);
	
     parameter WIDTH = 320;
     parameter HEIGHT = 180;



endmodule