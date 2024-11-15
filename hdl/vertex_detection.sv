`timescale 1ns / 1ps
`default_nettype none


module vertex_detection (
    input wire clk_in,
    input wire rst_in,
    input wire [KERNEL_SIZE-1:0][15:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,
    
    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic is_vertex // 1 bit output for whether or not the given pixel is detected to be a vertex
    );

    parameter KERNEL_SIZE = 11; // changable parameter for kernel size based on how large we want our edge detection to be

    // cache of pixel values
    logic signed [KERNEL_SIZE-1:0] [KERNEL_SIZE-1:0] [15:0] pixel_cache;

    localparam BUF_WIDTH = 4; // how many stages is our buffer
    logic [BUF_WIDTH-1:0] data_valid_buf;
    logic [BUF_WIDTH-1:0] [10:0] hcount_buf;
    logic [BUF_WIDTH-1:0] [9:0] vcount_buf;


    // comb for outputs
    always_comb begin
        if(rst_in) begin
            data_valid_out = 0;
            hcount_out = 0;
            vcount_out = 0;
            is_vertex = 0;
        end 
        else begin
            
            //*********************CHANGE****************************************************
            data_valid_out = 0;
            hcount_out = 0;
            vcount_out = 0;
            is_vertex = 0;
        end
    end


    always_ff @(posedge clk_in) begin
      // Make sure to have your output be set with registered logic!
      // Otherwise you'll have timing violations.

        if(rst_in) begin
            // logics
            pixel_cache <= 0;

            data_valid_buf <= 0;
            hcount_buf <= 0;
            vcount_buf <= 0;

        end else begin

            //*********************CHANGE****************************************************
            pixel_cache <= 0;

            data_valid_buf <= 0;
            hcount_buf <= 0;
            vcount_buf <= 0;

        end

    end

    
endmodule

`default_nettype wire

