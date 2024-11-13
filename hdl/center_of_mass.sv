`default_nettype none
module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);
	
     parameter WIDTH = 1024;
     parameter HEIGHT = 768;

     enum {INTAKE, DIVIDE, OUTPUT} state;                        // state machine states

     logic [$clog2(HEIGHT*((WIDTH*(WIDTH+1))>>1)):0] x_sum;      // need n(n+1)/2 * m bits
     logic [$clog2(WIDTH*HEIGHT):0] x_count;                     // there are width*height pixels
     logic x_divide_valid;
     logic [31:0] x_quotient; // outputs of divider
     logic [31:0] x_remainder;
     logic x_data_valid_out;
     logic x_error_out;
     logic x_busy_out;
     logic x_divide_done_wait; // are we done dividing


     logic [$clog2(WIDTH*((HEIGHT*(HEIGHT+1))>>1)):0] y_sum;
     logic [$clog2(WIDTH*HEIGHT):0] y_count;
     logic y_divide_valid;
     logic [31:0] y_quotient;  // outputs of divider
     logic [31:0] y_remainder;
     logic y_data_valid_out;
     logic y_error_out;
     logic y_busy_out;
     logic y_divide_done_wait; // are we done dividing



     divider
          #(.WIDTH(32)
     ) x_divider
          (.clk_in(clk_in),
          .rst_in(rst_in),
          .dividend_in(x_sum),
          .divisor_in(x_count),
          .data_valid_in(x_divide_valid),
          .quotient_out(x_quotient), // outputs
          .remainder_out(x_remainder),
          .data_valid_out(x_data_valid_out),
          .error_out(x_error_out),
          .busy_out(x_busy_out)
          );

     divider
          #(.WIDTH(32)
     ) y_divider
          (.clk_in(clk_in),
          .rst_in(rst_in),
          .dividend_in(y_sum),
          .divisor_in(y_count),
          .data_valid_in(y_divide_valid),
          .quotient_out(y_quotient), // outputs
          .remainder_out(y_remainder),
          .data_valid_out(y_data_valid_out),
          .error_out(y_error_out),
          .busy_out(y_busy_out)
          );



     // set the states combinationally
     // always_comb begin
     //      if(rst_in || valid_out || (state == INTAKE && tabulate_in && x_count == 0 && y_count == 0)) begin // reset to beginning
     //           // return to the beginning of intaking values
     //           state = INTAKE;

     //           // we are not ready to input divide
     //           x_divide_valid = 0;
     //           y_divide_valid = 0;

     //           // the divide does not have a valid output
     //           x_divide_done_wait = 0;
     //           y_divide_done_wait = 0;

     //      end else if(state == INTAKE && tabulate_in && (x_count > 0) && (y_count > 0)) begin // if we're done intaking

     //           state = DIVIDE;               // go to divide
     //           x_divide_valid = 1;           // tell the dividers we have valid inputs
     //           y_divide_valid = 1;
     //           x_divide_done_wait = 0;       // we don't have valid outputs yet
     //           y_divide_done_wait = 0;
     //      end else if(state == DIVIDE && x_divide_done_wait && y_divide_done_wait) begin
     //           state = OUTPUT;
     //           x_divide_done_wait = 0;
     //           y_divide_done_wait = 0;
     //      end

          
     //      if(x_divide_valid && x_data_valid_out) begin    // if the x divider finishes, log it
     //           x_divide_valid = 0;
     //           x_divide_done_wait = 1;
     //      end
     //      if(y_divide_valid && y_data_valid_out) begin    // same thing with the y divider
     //           y_divide_valid = 0;
     //           y_divide_done_wait = 1;
     //      end

     // end


     // do the logic sequentially
     always_ff @(posedge clk_in)begin
          if(rst_in) begin // if we detect a reset, reset!
               //logics
               state <= INTAKE;
               x_sum <= 0;
               y_sum <= 0;
               x_count <= 0;
               y_count <= 0;

               // we are not ready to input divide
               x_divide_valid <= 0;
               y_divide_valid <= 0;

               // the divide does not have a valid output
               x_divide_done_wait <= 0;
               y_divide_done_wait <= 0;


               //outputs
               x_out <= 0;
               y_out <= 0;
               valid_out <= 0;
          end else begin

               case (state)
                    INTAKE: begin
                         valid_out <= 0;
                         
                         if(valid_in) begin
                              x_sum <= x_sum + x_in;   // add the position to the sum
                              y_sum <= y_sum + y_in;

                              x_count <= x_count + 1;  // add one to the count
                              y_count <= y_count + 1;
                         end
                         if (tabulate_in) begin
                              if(x_count == 0) begin // reset
                                   x_sum <= 0;
                                   y_sum <= 0;
                                   x_count <= 0;
                                   y_count <= 0;

                                   // we are not ready to input divide
                                   x_divide_valid <= 0;
                                   y_divide_valid <= 0;

                                   // the divide does not have a valid output
                                   x_divide_done_wait <= 0;
                                   y_divide_done_wait <= 0;


                                   //outputs
                                   x_out <= 0;
                                   y_out <= 0;
                                   valid_out <= 0;
                              end else begin
                                   state <= DIVIDE;               // go to divide
                                   x_divide_valid <= 1;           // tell the dividers we have valid inputs
                                   y_divide_valid <= 1;
                                   x_divide_done_wait <= 0;       // we don't have valid outputs yet
                                   y_divide_done_wait <= 0;
                              end
                         end
          
                    end
                    DIVIDE: begin

                          if(x_divide_valid && x_data_valid_out) begin    // if the x divider finishes, log it
                              x_divide_valid <= 0;
                              x_divide_done_wait <= 1;
                              x_out <= x_quotient;
                         end

                         if(y_divide_valid && y_data_valid_out) begin    // same thing with the y divider
                              y_divide_valid <= 0;
                              y_divide_done_wait <= 1;
                              y_out <= y_quotient;
                         end

                         if(x_divide_done_wait && y_divide_done_wait) begin
                              state <= OUTPUT;
                              x_divide_done_wait <= 0;
                              y_divide_done_wait <= 0;
                         end


                         // if(x_data_valid_out) begin
                         //      x_out <= x_quotient;
                         // end
                         // if(y_data_valid_out) begin
                         //      y_out <= y_quotient;
                         // end

                    end
                    OUTPUT: begin
                         valid_out <= 1;
                         state <= INTAKE;

                         // reset
                         x_sum <= 0;
                         y_sum <= 0;
                         x_count <= 0;
                         y_count <= 0;

                         // we are not ready to input divide
                         x_divide_valid <= 0;
                         y_divide_valid <= 0;

                         // the divide does not have a valid output
                         x_divide_done_wait <= 0;
                         y_divide_done_wait <= 0;
                    end
                    default: begin
                         valid_out <= 0;
                    end
               endcase
          end
     end

endmodule

`default_nettype wire
