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
    input  logic         new_frame_in,         
    input  logic         valid_in,       

    output logic         valid_out,       // Valid output signal
    output logic         busy_out,        // Busy output signal
    output logic [MAX_LABELS-1:0][15:0]  blob_labels, // Array of distinct blob labels
    output logic [31:0]  num_blobs        // Number of distinct blobs
);

    typedef {IDLE, FIRST_PASS, SECOND_PASS, PRUNE, OUTPUT} state;
    logic [WIDTH*HEIGHT-1:0][15:0] first_pass_labels;
    logic [WIDTH*HEIGHT-1:0][15:0] second_pass_labels;
    logic [MAX_LABELS-1:0][15:0] pruned_labels;


    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            state <= IDLE;

            first_pass_labels <= 0;
            second_pass_labels <= 0
            pruned_labels <= 0;

            valid_out <= 0;
            busy_out <= 0;
            blob_labels <= 0;
            num_blobs <= 0;
        end else begin
            case(state)
                IDLE: begin
                    valid_out <= 0

                    if (new_frame_in) begin
                        state <= FIRST_PASS;
                        busy_out <= 1;
                    end
                end

                FIRST_PASS: begin
                end

                SECOND_PASS: begin
                end

                PRUNE: begin
                end

                OUTPUT: begin
                end
            endcase
        end
    end

    localparam FB_DEPTH = WIDTH*HEIGHT;
    localparam FB_SIZE = $clog2(FB_DEPTH);

    xilinx_true_dual_port_read_first_2_clock_ram
          #(.RAM_WIDTH(1),
          .RAM_DEPTH(FB_DEPTH))
          frame_buffer_1
          (
          // PORT A
          .addra(addra), //pixels are stored using this math
          .clka(clk_in),
          .wea(valid_in && state == STORE_FRAME),
          .dina(masked_in),
          .ena(1'b1),
          .douta(adj_raw[0][0]), //never read from this side
          .rsta(rst_in),
          .regcea(1'b1),

          // PORT B
          .addrb(addrb),//transformed lookup pixel
          .dinb(16'b0),
          .clkb(clk_in),
          .web(1'b0),
          .enb(1'b1),
          .doutb(frame_buff_pixel),
          .rstb(rst_in),
          .regceb(1'b1)
          );

    xilinx_true_dual_port_read_first_2_clock_ram
          #(.RAM_WIDTH(1),
          .RAM_DEPTH(FB_DEPTH))
          frame_buffer_1
          (
          // PORT A
          .addra(addra), //pixels are stored using this math
          .clka(clk_in),
          .wea(valid_in && state == STORE_FRAME),
          .dina(masked_in),
          .ena(1'b1),
          .douta(adj_raw[0][0]), //never read from this side
          .rsta(rst_in),
          .regcea(1'b1),

          // PORT B
          .addrb(addrb),//transformed lookup pixel
          .dinb(16'b0),
          .clkb(clk_in),
          .web(1'b0),
          .enb(1'b1),
          .doutb(frame_buff_pixel),
          .rstb(rst_in),
          .regceb(1'b1)
          );

endmodule
