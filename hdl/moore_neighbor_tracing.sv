`timescale 1ns / 1ps
`default_nettype none

module moore_neighbor_tracing (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in, // is this a valid pixel
                         input wire masked, // is this pixel masked?
                         input wire new_frame, // is this a new frame? 

                         output logic [$clog2(WIDTH*HEIGHT):0] perimeter,
                         output logic busy_out,
                         output logic valid_out);
	
     parameter WIDTH = 320;
     parameter HEIGHT = 180;

     logic [10:0] scan_x;
     logic [9:0] scan_y;

     logic [10:0] trace_start_x;
     logic [9:0] trace_start_y;
     logic trace_started;

     logic [2:0][2:0] adj_raw;
     logic [2:0][2:0] adj;

     enum {IDLE, STORE_FRAME, SEARCHING, TRACING, OUTPUT} state;                        // state machine states
     // Idle: waiting for a valid frame signal
     // store_frame: storign the frame to the frame buffer (do we need to do this? can we somehow get the frame from the buffer in toplevel?)
     // searching: scan from the top left corner for the first pixel in the mask
     // tracing: perform moore neighbor tracing algorithm
     // output: output the result

     enum {UP, DOWN, LEFT, RIGHT} from; // where we came from in the moore neighbor tracing


     // do the logic sequentially
     always_ff @(posedge clk_in)begin
          if(rst_in) begin // if we detect a reset, reset!
               //logics
               state <= IDLE;
               from <= UP;
               trace_started <= 0;

               //outputs
               busy_out <= 0;
               valid_out <= 0;
               perimeter <= 0;

              
          end else begin
               case(state)
                    IDLE: begin
                         valid_out <= 0;

                         if(new_frame) begin
                              state <= STORE_FRAME;
                              busy_out <= 1;
                         end
                    end // IDLE


                    STORE_FRAME: begin
                         if(x_in == 319 && y_in == 179) begin
                              state <= SEARCHING;
                              scan_x <= 0;
                              scan_y <= 0;
                         end
                    end // STORE_FRAME


                    SEARCHING: begin
                         if(frame_buff_pixel == 1) begin

                         end else begin
                              if(scan_x == WIDTH-1) begin
                                   if(scan_y == HEIGHT-1) begin
                                        scan_y <= 0;
                                   end else begin
                                        scan_y <= scan_y + 1;
                                   end

                                   scan_x <= 0;
                              end else begin
                                   scan_x <= scan_x + 1;
                              end

                              if(frame_buff_pixel == 1) begin
                                   state <= TRACING;
                                   perimeter <= 1; // start pixel
                                   from <= UP;
                                   trace_started <= 0;

                                   trace_start_x <= scan_x;
                                   trace_start_y <= scan_y;
                              end else if (scan_x == WIDTH-1 && scan_y == HEIGHT-1) begin
                                   perimeter <= 0;
                                   state <= OUTPUT;
                              end

                         end

                    end // SEARCHING


                    // THE ACTUAL MOORE NEIGHBOR ALGORITHM
                    TRACING: begin
                         
                         perimeter <= (!(scan_x == trace_start_x && scan_y == trace_start_y))? perimeter + 1 : perimeter; // dont add if this is the second time we hit the starting pixel? *********************set perimeter to be 1 when we move to this state and only add if it's not the starting pixel


                         if(trace_started && scan_x == trace_start_x && scan_y == trace_start_y) begin // if we're back to the start
                              state <= OUTPUT;
                         end else begin
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
     end

endmodule









localparam FB_DEPTH = WIDTH*HEIGHT;
localparam FB_SIZE = $clog2(FB_DEPTH);
logic [FB_SIZE-1:0] addra; //used to specify address to write to in frame buffer
logic frame_buff_pixel; //data out of frame buffer (masked 1-bit pixel)
logic [FB_SIZE-1:0] addrb; //used to lookup address in memory for reading from buffer


logic [FB_SIZE-1:0] addra_2; //used to specify address to write to in frame buffer
logic [FB_SIZE-1:0] addrb_2; //used to lookup address in memory for reading from buffer
logic [FB_SIZE-1:0] addra_3; //used to specify address to write to in frame buffer
logic [FB_SIZE-1:0] addrb_3; //used to lookup address in memory for reading from buffer
logic [FB_SIZE-1:0] addra_4; //used to specify address to write to in frame buffer
logic [FB_SIZE-1:0] addrb_4; //used to lookup address in memory for reading from buffer


// logic to keep track of bram reads and writes
// we have 4 brams because we need to read 8 pixels in a given cycle (neighbors), but we can only read from 2 ports at once with a single bram. during the store phase, we make 4 bram copies, then during the trace phase, read from all 4 to get 8 values simultaneously
always_comb begin

     // while writing to the bram
     if(state != TRACING) begin
          addra = x_in + v_in * WIDTH; // where to store values
          addrb = scan_x + scan_y * WIDTH; // where to pull vcalues from

          addra_2 = addra;
          addrb_2 = addrb;
          addra_3 = addra;
          addrb_3 = addrb;
          addra_4 = addra;
          addrb_4 = addrb;

     // COMBINATIONALLY PULL ALL ADJACENT PIXLES IF IN TRACING
     end else begin

          addra = (scan_x != 0 && scan_y != 0)? (scan_x-1) + (scan_y-1)*WIDTH : 0;                  // up left
          addrb = (scan_y != 0)? (scan_x) + (scan_y-1)*WIDTH : 0;                                   // up
          addra_2 = (scan_x != WIDTH-1 && scan_y != 0)? (scan_x+1) + (scan_y-1)*WIDTH : 0;          // up right
          addrb_2 = (scan_x != WIDTH-1)? (scan_x+1) + (scan_y)*WIDTH : 0;                           // right
          addra_3 = (scan_x != WIDTH-1 && scan_y != HEGIHT-1)? (scan_x+1) + (scan_y+1)*WIDTH : 0;   // down right
          addrb_3 = (scan_y != HEGIHT-1)? (scan_x) + (scan_y+1)*WIDTH : 0;                          // down
          addra_4 = (scan_x != 0 && scan_y != HEGIHT-1)? (scan_x-1) + (scan_y+1)*WIDTH : 0;         // down right
          addrb_4 = (scan_x != 0)? (scan_x-1) + (scan_y)*WIDTH : 0;                                 // left

          adj[0][0] = (scan_x != 0 && scan_y != 0)? adj_raw[0][0] : 0;                       // up left
          adj[0][1] = (scan_y != 0)? adj_raw[0][1]  : 0;                                     // up
          adj[0][2] = (scan_x != WIDTH-1 && scan_y != 0)? adj_raw[0][2]  : 0;                // up right
          adj[1][2] = (scan_x != WIDTH-1)? adj_raw[1][2] : 0;                                // right
          adj[2][2] = (scan_x != WIDTH-1 && scan_y != HEGIHT-1)? adj_raw[2][2]  : 0;         // down right
          adj[2][1] = (scan_y != HEGIHT-1)? adj_raw[2][1] : 0;                               // down
          adj[2][0] = (scan_x != 0 && scan_y != HEGIHT-1)? adj_raw[2][0] : 0;                // down right
          adj[1][0] = (scan_x != 0)? adj_raw[1][0] : 0;                                      // left
          
          adj[1][1] = 0; // doesn't matter

     end
end 

//frame buffer from IP
blk_mem_gen_0 frame_buffer_1 (
.addra(addra), //pixels are stored using this math
.clka(clk_in),
.wea(valid_in && state == STORE_FRAME),
.dina(masked),
.ena(1'b1),
.douta(adj_raw[0][0]), //never read from this side
.addrb(addrb),//transformed lookup pixel
.dinb(16'b0),
.clkb(clk_in),
.web(1'b0),
.enb(1'b1),
.doutb((state == TRACING)? adj_raw[0][1] : frame_buff_pixel)
);


blk_mem_gen_0 frame_buffer_2 (
.addra(addra_2), //pixels are stored using this math
.clka(clk_in),
.wea(valid_in && state == STORE_FRAME),
.dina(masked),
.ena(1'b1),
.douta(adj_raw[0][2]), //never read from this side
.addrb(addrb_2),//transformed lookup pixel
.dinb(16'b0),
.clkb(clk_in),
.web(1'b0),
.enb(1'b1),
.doutb(adj_raw[1][2])
);


blk_mem_gen_0 frame_buffer_3 (
.addra(addra_3), //pixels are stored using this math
.clka(clk_in),
.wea(valid_in && state == STORE_FRAME),
.dina(masked),
.ena(1'b1),
.douta(adj_raw[2][2]), //never read from this side
.addrb(addrb_3),//transformed lookup pixel
.dinb(16'b0),
.clkb(clk_in),
.web(1'b0),
.enb(1'b1),
.doutb(adj_raw[2][1])
);


blk_mem_gen_0 frame_buffer_4 (
.addra(addra_4), //pixels are stored using this math
.clka(clk_in),
.wea(valid_in && state == STORE_FRAME),
.dina(masked),
.ena(1'b1),
.douta(adj_raw[2][0]), //never read from this side
.addrb(addrb_4),//transformed lookup pixel
.dinb(16'b0),
.clkb(clk_in),
.web(1'b0),
.enb(1'b1),
.doutb(adj_raw[1][0])
);


`default_nettype wire
