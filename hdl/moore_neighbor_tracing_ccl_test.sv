`timescale 1ns / 1ps
`default_nettype none

module moore_neighbor_tracing_ccl_test #(
     parameter WIDTH=320, HEIGHT=180) (
                         input wire clk_in,
                         input wire rst_in,
                         input wire ready_in,     // are we ready to start reading from the frame buffers in top level
                         
                         // input wire pixel_upleft, // frame buffer direct outputs: neighboring pixels
                         // input wire pixel_up,
                         // input wire pixel_upright,
                         // input wire pixel_right,
                         // input wire pixel_downright,
                         // input wire pixel_down,
                         // input wire pixel_downleft,
                         // input wire pixel_left,

                         output logic [$clog2(WIDTH*HEIGHT)-1:0] addra_1, // addresses to read from --> frame buffers
                         output logic [$clog2(WIDTH*HEIGHT)-1:0] addrb_1,
                         output logic [$clog2(WIDTH*HEIGHT)-1:0] addra_2,
                         output logic [$clog2(WIDTH*HEIGHT)-1:0] addrb_2,
                         output logic [$clog2(WIDTH*HEIGHT)-1:0] addra_3,
                         output logic [$clog2(WIDTH*HEIGHT)-1:0] addrb_3,
                         output logic [$clog2(WIDTH*HEIGHT)-1:0] addra_4,
                         output logic [$clog2(WIDTH*HEIGHT)-1:0] addrb_4,
                         
                         output logic [$clog2(WIDTH*HEIGHT)-1:0] perimeter,
                         output logic busy_out,
                         output logic valid_out);
	




     // STATES:
     enum {IDLE, SEARCHING, TRACING, OUTPUT} state;
     // Idle: waiting for a valid frame signal
     // store_frame: NO MORE STORE FRAME
     // searching: scan from the top left corner for the first pixel in the mask
     // tracing: perform moore neighbor tracing algorithm
     // output: output the result


     // SEARCHING:
     logic [10:0] scan_x;          // what pixel we're scanning right now
     logic [9:0] scan_y;
     logic frame_buff_pixel; // center of frame


     // TRACING:
     logic [10:0] trace_start_x;        // where the trace started (return to start --> terminate)
     logic [9:0] trace_start_y;
     logic trace_started;               // has the trace started yet?
     logic [1:0] read_wait;             // it takes 2 cycles to read from frame buffers, so wait for 2 cycles
     enum {UP, DOWN, LEFT, RIGHT} from; // where we came from in the moore neighbor tracing influences order we check neighbors


     // FRAME BUFFER PIXELS:
     logic [2:0][2:0] adj_raw;     // raw output from frame buffers
     logic [2:0][2:0] adj;         // curated adjacent pixels to check






     // COMBINATIONAL LOGIC: handle setting frame buffer inputs and address outputs
     always_comb begin

          if(rst_in) begin
               adj_raw = 0;
               adj = 0;

               addra_1 = 0;   // upleft
               addrb_1 = 0;   // up
               addra_2 = 0;   // upright
               addrb_2 = 0;   // right
               addra_3 = 0;   // downright
               addrb_3 = 0;   // down
               addra_4 = 0;   // downleft
               addrb_4 = 0;   // left

               frame_buff_pixel = 0;

          end else begin
               // pull all the raw frame buffer neighbor inputs
               adj_raw[0][0] = pixel_upleft;
               adj_raw[0][1] = pixel_up;
               adj_raw[0][2] = pixel_upright;
               adj_raw[1][2] = pixel_right;
               adj_raw[2][2] = pixel_downright;
               adj_raw[2][1] = pixel_down;
               adj_raw[2][0] = pixel_downleft;
               adj_raw[1][0] = pixel_right;
               adj_raw[1][1] = 1; // doesn't matter



               if(state == SEARCHING) begin
                    
                    // UPLEFT IS CENTER DURING SEARCHING
                    addra_1 = scan_x + scan_y * WIDTH; // during searching, we pull values from the center (though we're reading from the upleft port)
                    frame_buff_pixel = pixel_upleft; // the center during scanning comes from upleft
 
               end else if (state == TRACING) begin

                    // set output addresses to read from
                    addra_1 = (scan_x != 0 && scan_y != 0)? (scan_x-1) + (scan_y-1)*WIDTH : 0;                  // up left
                    addrb_1 = (scan_y != 0)? (scan_x) + (scan_y-1)*WIDTH : 0;                                   // up
                    addra_2 = (scan_x != WIDTH-1 && scan_y != 0)? (scan_x+1) + (scan_y-1)*WIDTH : 0;          // up right
                    addrb_2 = (scan_x != WIDTH-1)? (scan_x+1) + (scan_y)*WIDTH : 0;                           // right
                    addra_3 = (scan_x != WIDTH-1 && scan_y != HEIGHT-1)? (scan_x+1) + (scan_y+1)*WIDTH : 0;   // down right
                    addrb_3 = (scan_y != HEIGHT-1)? (scan_x) + (scan_y+1)*WIDTH : 0;                          // down
                    addra_4 = (scan_x != 0 && scan_y != HEIGHT-1)? (scan_x-1) + (scan_y+1)*WIDTH : 0;         // down right
                    addrb_4 = (scan_x != 0)? (scan_x-1) + (scan_y)*WIDTH : 0;                                 // left

                    // actual adjacent pixels
                    adj[0][0] = (scan_x != 0 && scan_y != 0)? adj_raw[0][0] : 0;                              // up left
                    adj[0][1] = (scan_y != 0)? adj_raw[0][1] : 0;                                             // up
                    adj[0][2] = (scan_x != WIDTH-1 && scan_y != 0)? adj_raw[0][2] : 0;                        // up right
                    adj[1][2] = (scan_x != WIDTH-1)? adj_raw[1][2] : 0;                                       // right
                    adj[2][2] = (scan_x != WIDTH-1 && scan_y != HEIGHT-1)? adj_raw[2][2] : 0;                 // down right
                    adj[2][1] = (scan_y != HEIGHT-1)? adj_raw[2][1] : 0;                                      // down
                    adj[2][0] = (scan_x != 0 && scan_y != HEIGHT-1)? adj_raw[2][0] : 0;                       // down right
                    adj[1][0] = (scan_x != 0)? adj_raw[1][0] : 0;                                             // left
                    adj[1][1] = adj_raw[1][1]; // doesn't matter

               end
          end
     end







     // SEQUENTIAL LOGIC: determine state, next move, etc.
     always_ff @(posedge clk_in)begin
          if(rst_in) begin // if we detect a reset, reset!
               // === LOGICS ===
               // STATES:
               state <= IDLE;

               // SEARCHING:
               scan_x <= 0;
               scan_y <= 0;

               // TRACING:
               trace_start_x <= 0;
               trace_start_y <= 0;
               trace_started <= 0;
               read_wait <= 0;
               from <= UP;



               // === OUTPUTS ===
               busy_out <= 0;
               valid_out <= 0;
               perimeter <= 0;


              
          end else begin
               case(state)
                    IDLE: begin
                         valid_out <= 0;

                         if(ready_in) begin
                              state <= SEARCHING;
                              busy_out <= 1;
                              
                              scan_x <= 0;
                              scan_y <= 0;
                         end
                    end // IDLE


                    SEARCHING: begin
                         if(frame_buff_pixel == 1) begin
                              state <= TRACING;
                              perimeter <= 0; // start pixel
                              from <= UP;
                              trace_started <= 0;
                              read_wait <= 0;


                              scan_x <= (scan_x >= 2)? scan_x-2 : (WIDTH-2)+scan_x; // if we read frame_buff_pixel is high, then we know 2 cycles ago we saw a good pixel
                              scan_y <= (scan_x >= 2)? scan_y : scan_y - 1;

                              trace_start_x <= (scan_x >= 2)? scan_x-2 : (WIDTH-2)+scan_x;
                              trace_start_y <= (scan_x >= 2)? scan_y : scan_y - 1;
                         end else begin
                              if(scan_x == WIDTH-1) begin
                                   if(scan_y == HEIGHT-1) begin
                                        perimeter <= 0;
                                        state <= OUTPUT;
                                   end else begin
                                        scan_y <= scan_y + 1;
                                   end

                                   scan_x <= 0;
                              end else begin
                                   scan_x <= scan_x + 1;
                              end

                         end

                    end // SEARCHING


                    // THE ACTUAL MOORE NEIGHBOR ALGORITHM
                    TRACING: begin
                         
                         // perimeter <= perimeter + 1; //(!(scan_x == trace_start_x && scan_y == trace_start_y))? perimeter + 1 : perimeter; // dont add if this is the second time we hit the starting pixel? *********************set perimeter to be 1 when we move to this state and only add if it's not the starting pixel


                         if(trace_started && scan_x == trace_start_x && scan_y == trace_start_y) begin // if we're back to the start
                              state <= OUTPUT;
                         end else if(read_wait < 2) begin // we need to wait 2 cycles to read from the buffer
                              read_wait <= read_wait + 1;
                         end else begin
                              perimeter <= perimeter + 1;
                              read_wait <= 0;

                              trace_started <= 1; // we've started the trace

                              case(from) // based on where we came from, traversal order is different
                                   UP: begin // if we came from up, go up, upright, right, downright, down, downleft, left, upleft

                                        if(adj[0][1]) begin                // up --> should never happen
                                             scan_y <= scan_y - 1;
                                             from <= LEFT;                 // SHOULD NEVER HAPPEN
                                        end else if (adj[0][2]) begin      // upright
                                             scan_x <= scan_x + 1;
                                             scan_y <= scan_y - 1;
                                             from <= LEFT;
                                        end else if (adj[1][2]) begin      // right
                                             scan_x <= scan_x + 1;
                                             from <= UP;
                                        end else if (adj[2][2]) begin      // downright
                                             scan_x <= scan_x + 1;
                                             scan_y <= scan_y + 1;
                                             from <= UP;
                                        end else if (adj[2][1]) begin      // down
                                             scan_y <= scan_y + 1;
                                             from <= RIGHT;
                                        end else if (adj[2][0]) begin      // downleft
                                             scan_x <= scan_x - 1;
                                             scan_y <= scan_y + 1;
                                             from <= RIGHT;
                                        end else if (adj[1][0]) begin      // left
                                             scan_x <= scan_x - 1;
                                             from <= DOWN;
                                        end else if (adj[0][0]) begin      // upleft
                                             scan_x <= scan_x - 1;
                                             scan_y <= scan_y - 1;
                                             from <= DOWN;
                                        end

                                   end


                                   RIGHT: begin // if we came from right, go  right, downright, down, downleft, left, upleft, up, upright

                                        if (adj[1][2]) begin               // right
                                             scan_x <= scan_x + 1;
                                             from <= UP;                   // SHOULD NEVER HAPPEN
                                        end else if (adj[2][2]) begin      // downright
                                             scan_x <= scan_x + 1;
                                             scan_y <= scan_y + 1;
                                             from <= UP;
                                        end else if (adj[2][1]) begin      // down
                                             scan_y <= scan_y + 1;
                                             from <= RIGHT;
                                        end else if (adj[2][0]) begin      // downleft
                                             scan_x <= scan_x - 1;
                                             scan_y <= scan_y + 1;
                                             from <= RIGHT;
                                        end else if (adj[1][0]) begin      // left
                                             scan_x <= scan_x - 1;
                                             from <= DOWN;
                                        end else if (adj[0][0]) begin      // upleft
                                             scan_x <= scan_x - 1;
                                             scan_y <= scan_y - 1;
                                             from <= DOWN;
                                        end else if(adj[0][1]) begin       // up
                                             scan_y <= scan_y - 1;
                                             from <= LEFT;                 
                                        end else if (adj[0][2]) begin      // upright
                                             scan_x <= scan_x + 1;
                                             scan_y <= scan_y - 1;
                                             from <= LEFT;
                                        end

                                   end


                                   DOWN: begin // if we came from down, go down, downleft, left, upleft, up, upright, right, downright

                                        if (adj[2][1]) begin               // down
                                             scan_y <= scan_y + 1;
                                             from <= RIGHT;                // SHOULD NEVER HAPPEN
                                        end else if (adj[2][0]) begin      // downleft
                                             scan_x <= scan_x - 1;
                                             scan_y <= scan_y + 1;
                                             from <= RIGHT;
                                        end else if (adj[1][0]) begin      // left
                                             scan_x <= scan_x - 1;
                                             from <= DOWN;
                                        end else if (adj[0][0]) begin      // upleft
                                             scan_x <= scan_x - 1;
                                             scan_y <= scan_y - 1;
                                             from <= DOWN;
                                        end else if(adj[0][1]) begin       // up
                                             scan_y <= scan_y - 1;
                                             from <= LEFT;                 
                                        end else if (adj[0][2]) begin      // upright
                                             scan_x <= scan_x + 1;
                                             scan_y <= scan_y - 1;
                                             from <= LEFT;
                                        end else if (adj[1][2]) begin      // right
                                             scan_x <= scan_x + 1;
                                             from <= UP;                   
                                        end else if (adj[2][2]) begin      // downright
                                             scan_x <= scan_x + 1;
                                             scan_y <= scan_y + 1;
                                             from <= UP;
                                        end

                                   end


                                   LEFT: begin // if we came from left, go left, upleft, up, upright, right, downright, down, downleft, 

                                        if (adj[1][0]) begin               // left
                                             scan_x <= scan_x - 1;
                                             from <= DOWN;                 // SHOULD NEVER HAPPEN
                                        end else if (adj[0][0]) begin      // upleft
                                             scan_x <= scan_x - 1;
                                             scan_y <= scan_y - 1;
                                             from <= DOWN;
                                        end else if(adj[0][1]) begin       // up
                                             scan_y <= scan_y - 1;
                                             from <= LEFT;                 
                                        end else if (adj[0][2]) begin      // upright
                                             scan_x <= scan_x + 1;
                                             scan_y <= scan_y - 1;
                                             from <= LEFT;
                                        end else if (adj[1][2]) begin      // right
                                             scan_x <= scan_x + 1;
                                             from <= UP;                   
                                        end else if (adj[2][2]) begin      // downright
                                             scan_x <= scan_x + 1;
                                             scan_y <= scan_y + 1;
                                             from <= UP;
                                        end else if (adj[2][1]) begin      // down
                                             scan_y <= scan_y + 1;
                                             from <= RIGHT;                
                                        end else if (adj[2][0]) begin      // downleft
                                             scan_x <= scan_x - 1;
                                             scan_y <= scan_y + 1;
                                             from <= RIGHT;
                                        end

                                   end


                                   default: state <= OUTPUT; // something's wrong so just throw output

                              endcase
                         end

                    end // TRACING


                    // just set outputs to be ready
                    OUTPUT: begin
                         busy_out <= 0;
                         valid_out <= 1;
                         state <= IDLE;
                    end // OUTPUT

                    default: state <= IDLE;

               endcase


          end
     end // always_ff












// ================= TOP LEVEL STUFF ====================
logic [7:0][15:0] ccl_moore_addr_0;
logic [7:0][15:0] moore_addrs_0;
logic [15:0] perimeter_0;
logic moore_busy_0;
logic moore_valid_0;
logic [2:0][2:0] ccl_moore_pixels_0;


// MOORE INPUTS:
logic pixel_upleft; // frame buffer direct outputs: neighboring pixels
logic pixel_up;
logic pixel_upright;
logic pixel_right;
logic pixel_downright;
logic pixel_down;
logic pixel_downleft;
logic pixel_left;
//

always_comb begin

     moore_addrs_0[0] = addra_1;
     moore_addrs_0[1] = addrb_1;
     moore_addrs_0[2] = addra_2;
     moore_addrs_0[3] = addrb_2;
     moore_addrs_0[4] = addra_3;
     moore_addrs_0[5] = addrb_3;
     moore_addrs_0[6] = addra_4;
     moore_addrs_0[7] = addrb_4;

     perimeter_0 = perimeter;
     moore_busy_0 = busy_out;
     moore_valid_0 = valid_out;


     pixel_upleft = ccl_moore_pixels_0[0][0]; // frame buffer direct outputs: neighboring pixels
     pixel_up = ccl_moore_pixels_0[0][1];
     pixel_upright = ccl_moore_pixels_0[0][2];
     pixel_right = ccl_moore_pixels_0[1][2];
     pixel_downright = ccl_moore_pixels_0[2][2];
     pixel_down = ccl_moore_pixels_0[2][1];
     pixel_downleft = ccl_moore_pixels_0[2][0];
     pixel_left = ccl_moore_pixels_0[1][0];

end



// FBs to hold Moore data for Moore 0
  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180),
    .RAM_PERFORMANCE("HIGH_LATENCY"),
    .INIT_FILE(`FPATH(moore_bram_test_circle.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
     )
    moore_fb_00
    (
    // PORT A
    .addra(ccl_moore_addr_0[0]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[0]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_0[0][0]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_0[1]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_0[0][1]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );

  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180),
    .RAM_PERFORMANCE("HIGH_LATENCY"),
    .INIT_FILE(`FPATH(moore_bram_test_circle.mem))
    )
    moore_fb_01
    (
    // PORT A
    .addra(ccl_moore_addr_0[2]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[0]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_0[0][2]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_0[3]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_0[1][2]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );

  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180),
    .RAM_PERFORMANCE("HIGH_LATENCY"),
    .INIT_FILE(`FPATH(moore_bram_test_circle.mem))
    )
    moore_fb_02
    (
    // PORT A
    .addra(ccl_moore_addr_0[4]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[0]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_0[2][2]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_0[5]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_0[2][1]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );

  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180),
    .RAM_PERFORMANCE("HIGH_LATENCY"),
    .INIT_FILE(`FPATH(moore_bram_test_circle.mem))
    )
    moore_fb_03
    (
    // PORT A
    .addra(ccl_moore_addr_0[6]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[0]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_0[2][0]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_0[7]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_0[1][0]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );



endmodule


`default_nettype wire
