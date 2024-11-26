`timescale 1ns / 1ps
`default_nettype none

module connected_components #(
    parameter WIDTH = 320,        // Horizontal resolution
    parameter HEIGHT = 180,        // Vertical resolution
    parameter MAX_LABELS = 5, // Maximum number of labels supported
    parameter MIN_AREA = 20      // Minimum blob size to retain
)(
    input  logic         clk_in,          
    input  logic         rst_in,          
    input  logic [10:0]  x_in,       
    input  logic [9:0]   y_in,       
    input  logic         mask_in,         
    input  logic         valid_in,       

    output logic         valid_out,       // Valid output signal
    output logic         busy_out,        // Busy output signal
    output logic [MAX_LABELS-1:0][15:0]  blob_labels, // Array of distinct blob labels
    output logic [31:0]  num_blobs        // Number of distinct blobs
);



    

endmodule
