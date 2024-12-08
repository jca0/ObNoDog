`timescale 1ns / 1ps
`default_nettype none

module pixel_reconstruct
	#(
	 parameter HCOUNT_WIDTH = 11,
	 parameter VCOUNT_WIDTH = 10
	 )
	(
	 input wire 										 clk_in,
	 input wire 										 rst_in,
	 input wire 										 camera_pclk_in,
	 input wire 										 camera_hs_in,
	 input wire 										 camera_vs_in,
	 input wire [7:0] 							 camera_data_in,
	 output logic 									 pixel_valid_out,
	 output logic [HCOUNT_WIDTH-1:0] pixel_hcount_out,
	 output logic [VCOUNT_WIDTH-1:0] pixel_vcount_out,
	 output logic [15:0] 						 pixel_data_out
	 );

	 // your code here! and here's a handful of logics that you may find helpful to utilize.
	 
	 // previous value of PCLK
	 logic 													 pclk_prev;

	 // can be assigned combinationally:
	 //  true when pclk transitions from 0 to 1
	 logic 													 camera_sample_valid;
	 assign camera_sample_valid = camera_pclk_in == 1 && pclk_prev == 0; // TODO: fix this assign // ***DONE***
	 

	 // previous value of camera data, from last valid sample!
	 // should NOT update on every cycle of clk_in, only
	 // when samples are valid.
	 logic 													 last_sampled_hs;
	 logic [7:0] 										 last_sampled_data;

	 // flag indicating whether the last byte has been transmitted or not.
	 logic 													 half_pixel_ready;

	 always_ff@(posedge clk_in) begin
			if (rst_in) begin

        //outputs
        pixel_valid_out <= 0;
        pixel_hcount_out <= -1;
        pixel_vcount_out <= 0;
        pixel_data_out <= 0;


        //logics
        pclk_prev <= 0;
        last_sampled_hs <= 0;
        last_sampled_data <= 0;
        half_pixel_ready <= 0;


      
			end else begin
        pclk_prev <= camera_pclk_in;

        // on the rising edge of pclk
        if(camera_sample_valid) begin
          last_sampled_hs <= camera_hs_in;
          last_sampled_data <= camera_data_in;

          // if we're in a sync region, don't get any info abt the pixels
          if(camera_vs_in == 0 || camera_hs_in == 0) begin
            half_pixel_ready <= 0; // throw away a half pixel

            if(camera_vs_in == 0) begin
              pixel_hcount_out <= -1; // next pixel we sample will set this to 0
              pixel_vcount_out <= 0;
            end else if (camera_hs_in == 0 && last_sampled_hs == 1) begin // only on the rising edge of hs
              pixel_hcount_out <= -1;
              pixel_vcount_out <= pixel_vcount_out + 1;
            end

          end else begin
          
            if(half_pixel_ready) begin  // if we already had half the byte, send
              pixel_hcount_out <= pixel_hcount_out + 1; // move
              pixel_data_out <= {last_sampled_data, camera_data_in};
              
              half_pixel_ready <= 0;
            end else begin              // otherwise just store
              half_pixel_ready <= 1;
            end
          end

				end
				
        // we have a valid pixel if 1. the camera sample is valid 2. we already had half a pixel before 3. we're not in a sync region
        pixel_valid_out <= (camera_sample_valid == 1 && half_pixel_ready == 1 && camera_vs_in == 1 && camera_hs_in == 1);

			end
	 end

endmodule

`default_nettype wire