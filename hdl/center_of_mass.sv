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
                         output logic [15:0] area_out,
                         output logic valid_out);
	 // your code here
     // Accumulators and counters
     logic [31:0] x_sum;
     logic [31:0] y_sum;
     logic [31:0] pixel_count;
 
     // Division variables
     logic div_start_x;
     logic div_start_y;
     logic [31:0] dividend_x;
     logic [31:0] dividend_y;
     logic [31:0] quotient_x;
     logic [31:0] quotient_y;
     logic div_valid_x;
     logic div_valid_y;
     logic valid_x_reg;
     logic valid_y_reg;

     enum { IDLE, ADDING, DIVIDING } state;

     divider #(.WIDTH(32)) div_x (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(dividend_x),
        .divisor_in(pixel_count),
        .data_valid_in(div_start_x),
        .quotient_out(quotient_x),
        .remainder_out(),
        .data_valid_out(div_valid_x),
        .error_out(),
        .busy_out()
    );

    divider #(.WIDTH(32)) div_y (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(dividend_y),
        .divisor_in(pixel_count),
        .data_valid_in(div_start_y),
        .quotient_out(quotient_y),
        .remainder_out(),
        .data_valid_out(div_valid_y),
        .error_out(),
        .busy_out()
    );
    
     always_ff @(posedge clk_in) begin
         if (rst_in) begin
             x_out <= 0;
             y_out <= 0;
             area_out <= 0;
             valid_out <= 0;
             state <= IDLE;
         end else begin
             case (state)
                IDLE: begin
                    x_sum <= x_in;
                    y_sum <= y_in;
                    pixel_count <= 1;
                    valid_out <= 0;

                    if (valid_in) begin
                        state <= ADDING;
                    end
                end

                ADDING: begin
                    if (valid_in)begin
                        x_sum <= x_sum + x_in;
                        y_sum <= y_sum + y_in;
                        pixel_count <= pixel_count + 1;
                    end

                    if (tabulate_in) begin
                        dividend_x <= x_sum;
                        dividend_y <= y_sum;
                        div_start_x <= 1;
                        div_start_y <= 1;
                        area_out <= pixel_count;
                        state <= DIVIDING;
                    end
                end

                DIVIDING: begin
                    div_start_x <= 0;
                    div_start_y <= 0;
                    if (pixel_count == 0) begin
                        state <= IDLE;
                        valid_out <= 0;
                    end
                    
                    if (div_valid_x) begin
                      x_out <= quotient_x[10:0];
                      valid_x_reg <= 1;
                    end
                    if (div_valid_y) begin
                      y_out <= quotient_y[9:0];
                      valid_y_reg <= 1;
                    end
                    if (valid_x_reg && valid_y_reg) begin
                      state <= IDLE;
                      valid_out <= 1;
                      valid_x_reg <= 0;
                      valid_y_reg <= 0;
                    end
                end
             endcase
         end
     end
endmodule

module divider #(parameter WIDTH = 32) (input wire clk_in,
                input wire rst_in,
                input wire[WIDTH-1:0] dividend_in,
                input wire[WIDTH-1:0] divisor_in,
                input wire data_valid_in,
                output logic[WIDTH-1:0] quotient_out,
                output logic[WIDTH-1:0] remainder_out,
                output logic data_valid_out,
                output logic error_out,
                output logic busy_out);
  localparam RESTING = 0;
  localparam DIVIDING = 1;
  logic [WIDTH-1:0] quotient, dividend;
  logic [WIDTH-1:0] divisor;
  logic state;
  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      quotient <= 0;
      dividend <= 0;
      divisor <= 0;
      remainder_out <= 0;
      busy_out <= 1'b0;
      error_out <= 1'b0;
      state <= RESTING;
      data_valid_out <= 1'b0;
    end else begin
      case (state)
        RESTING: begin
          if (data_valid_in)begin
            state <= DIVIDING;
            quotient <= 0;
            dividend <= dividend_in;
            divisor <= divisor_in;
            busy_out <= 1'b1;
            error_out <= 1'b0;
          end
          data_valid_out <= 1'b0;
        end
        DIVIDING: begin
          if (dividend<=0)begin
            state <= RESTING; //similar to return statement
            remainder_out <= dividend;
            quotient_out <= quotient;
            busy_out <= 1'b0; //tell outside world i'm done
            error_out <= 1'b0;
            data_valid_out <= 1'b1; //good stuff!
          end else if (divisor==0)begin
            state <= RESTING;
            remainder_out <= 0;
            quotient_out <= 0;
            busy_out <= 1'b0; //tell outside world i'm done
            error_out <= 1'b1; //ERROR
            data_valid_out <= 1'b1; //valid ERROR
          end else if (dividend < divisor) begin
            state <= RESTING;
            remainder_out <= dividend;
            quotient_out <= quotient;
            busy_out <= 1'b0;
            error_out <= 1'b0;
            data_valid_out <= 1'b1; //good stuff!
          end else begin
            //state staying in.
            state <= DIVIDING;
            quotient <= quotient + 1'b1;
            dividend <= dividend-divisor;
          end
        end
      endcase
    end
  end
endmodule

`default_nettype wire
