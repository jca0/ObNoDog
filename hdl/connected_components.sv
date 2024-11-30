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
    output logic [MAX_LABELS-1:0][$clog2(WIDTH*HEIGHT):0] area,
    output logic [MAX_LABELS-1:0][10:0] com_x,
    output logic [MAX_LABELS-1:0][10:0] com_y,
    output logic [MAX_LABELS-1:0][15:0]  blob_labels, // Array of distinct blob labels
    output logic [31:0]  num_blobs        // Number of distinct blobs
);

    typedef {IDLE, STORE_FRAME, FIRST_PASS, SECOND_PASS, PRUNE, COM_CALC, OUTPUT} state;
    logic [WIDTH*HEIGHT-1:0][15:0] first_pass_labels;
    logic [WIDTH*HEIGHT-1:0][15:0] second_pass_labels;
    logic [WIDTH*HEIGHT-1:0][15:0] labels;
    logic [WIDTH*HEIGHT-1:0][15:0] equiv_table;

    logic w_pixel_mask;
    logic nw_pixel_mask;
    logic n_pixel_mask;
    logic ne_pixel_mask;
    
    logic [15:0] w_pixel_label;
    logic [15:0] nw_pixel_label;
    logic [15:0] n_pixel_label;
    logic [15:0] ne_pixel_label;

    logic [15:0] w_pixel_temp;
    logic [15:0] nw_pixel_temp;
    logic [15:0] n_pixel_temp;
    logic [15:0] ne_pixel_temp;

    logic [10:0] curr_x;
    logic [9:0] curr_y;


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
                        state <= STORE_PIXELS;
                        busy_out <= 1;
                    end
                end

                STORE_PIXELS: begin
                    if (x_in==319 && y_in==179) begin
                        state <= FIRST_PASS;
                        curr_x <= 0;
                        curr_y <= 0;
                    end
                    
                end

                FIRST_PASS: begin

                end

                SECOND_PASS: begin
                end

                PRUNE: begin
                end

                COM_CALC: begin
                end

                OUTPUT: begin
                    busy_out <= 0;
                    valid_out <= 1;
                end
                end
            endcase
        end
    end

    localparam FB_DEPTH = WIDTH*HEIGHT;
    localparam FB_SIZE = $clog2(FB_DEPTH);
    logic [FB_SIZE-1:0] addra; //used to specify address to write to in frame buffer
    logic frame_buff_pixel; //data out of frame buffer (masked 1-bit pixel)
    logic [FB_SIZE-1:0] addrb; //used to lookup address in memory for reading from buffer

    always_comb begin
        if (state != FIRST_PASS || state != SECOND_PASS) begin
            addra = x_in + y_in * WIDTH; // store values
            addrb = curr_x + curr_y * WIDTH; // lookup values

            addra_2 = addra;
            addrb_2 = addrb;
            addra_3 = addra;
            addrb_3 = addrb;
            addra_4 = addra;
            addrb_4 = addrb;
        end else begin
            addra = (scan_x != 0 && scan_y != 0)? (scan_x-1) + (scan_y-1)*WIDTH : 0;                  // nw
            addrb = (scan_y != 0)? (scan_x) + (scan_y-1)*WIDTH : 0;                                   // n
            addra_2 = (scan_x != WIDTH-1 && scan_y != 0)? (scan_x+1) + (scan_y-1)*WIDTH : 0;          // ne
            addrb_2 = (scan_x != 0)? (scan_x-1) + (scan_y)*WIDTH : 0;                                 // w

            nw_pixel_mask = (scan_x != 0 && scan_y != 0)? nw_pixel_temp : 0;      
            n_pixel_mask = (scan_y != 0)? n_pixel_temp : 0;                       
            ne_pixel_mask = (scan_x != WIDTH-1 && scan_y != 0)? ne_pixel_temp : 0;
            w_pixel_mask = (scan_x != 0)? w_pixel_temp : 0; 

            nw_pixel_label = (scan_x != 0 && scan_y != 0)? nw_pixel_temp : 0;      
            n_pixel_label = (scan_y != 0)? n_pixel_temp : 0;                       
            ne_pixel_label = (scan_x != WIDTH-1 && scan_y != 0)? ne_pixel_temp : 0;
            w_pixel_label = (scan_x != 0)? w_pixel_temp : 0; 
        end
    end

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
          .douta(w_pixel_temp), //never read from this side
          .rsta(rst_in),
          .regcea(1'b1),

          // PORT B
          .addrb(addrb),//transformed lookup pixel
          .dinb(16'b0),
          .clkb(clk_in),
          .web(1'b0),
          .enb(1'b1),
          .doutb(nw_pixel_temp),
          .rstb(rst_in),
          .regceb(1'b1)
          );

    xilinx_true_dual_port_read_first_2_clock_ram
          #(.RAM_WIDTH(1),
          .RAM_DEPTH(FB_DEPTH))
          frame_buffer_2
          (
          // PORT A
          .addra(addra_2), //pixels are stored using this math
          .clka(clk_in),
          .wea(valid_in && state == STORE_FRAME),
          .dina(masked_in),
          .ena(1'b1),
          .douta(n_pixel_temp), //never read from this side
          .rsta(rst_in),
          .regcea(1'b1),

          // PORT B
          .addrb(addrb_2),//transformed lookup pixel
          .dinb(16'b0),
          .clkb(clk_in),
          .web(1'b0),
          .enb(1'b1),
          .doutb(ne_pixel_temp),
          .rstb(rst_in),
          .regceb(1'b1)
          );

    xilinx_true_dual_port_read_first_2_clock_ram
          #(.RAM_WIDTH(1),
          .RAM_DEPTH(FB_DEPTH))
          label_buffer_1
          (
          // PORT A
          .addra(addra), //pixels are stored using this math
          .clka(clk_in),
          .wea(valid_in && state == STORE_FRAME),
          .dina(masked_in),
          .ena(1'b1),
          .douta(w_pixel_temp), //never read from this side
          .rsta(rst_in),
          .regcea(1'b1),

          // PORT B
          .addrb(addrb),//transformed lookup pixel
          .dinb(16'b0),
          .clkb(clk_in),
          .web(1'b0),
          .enb(1'b1),
          .doutb(nw_pixel_temp),
          .rstb(rst_in),
          .regceb(1'b1)
          );

    xilinx_true_dual_port_read_first_2_clock_ram
          #(.RAM_WIDTH(1),
          .RAM_DEPTH(FB_DEPTH))
          label_buffer_2
          (
          // PORT A
          .addra(addra_2), //pixels are stored using this math
          .clka(clk_in),
          .wea(valid_in && state == STORE_FRAME),
          .dina(masked_in),
          .ena(1'b1),
          .douta(n_pixel_temp), //never read from this side
          .rsta(rst_in),
          .regcea(1'b1),

          // PORT B
          .addrb(addrb_2),//transformed lookup pixel
          .dinb(16'b0),
          .clkb(clk_in),
          .web(1'b0),
          .enb(1'b1),
          .doutb(ne_pixel_temp),
          .rstb(rst_in),
          .regceb(1'b1)
          );

endmodule
