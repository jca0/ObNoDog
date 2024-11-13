`timescale 1ns / 1ps
`default_nettype none


module convolution (
    input wire clk_in,
    input wire rst_in,
    input wire [KERNEL_SIZE-1:0][15:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,
    
    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic [15:0] line_out
    );

    parameter K_SELECT = 0;
    localparam KERNEL_SIZE = 3;
    // Your code here!

    /* Note that the coeffs output of the kernels module
     * is packed in all dimensions, so coeffs should be
     * defined as `logic signed [2:0][2:0][7:0] coeffs`
     *
     * This is because iVerilog seems to be weird about passing
     * signals between modules that are unpacked in more
     * than one dimension - even though this is perfectly
     * fine Verilog.
     */

    // Instantiate the kernel and its outputs
    logic signed [2:0] [2:0] [7:0] coeffs;
    logic signed [7:0] shift;
    kernels #(
        .K_SELECT(K_SELECT)
    ) kernel (
        .rst_in(rst_in),
        .coeffs(coeffs),
        .shift(shift)
    );



    // cache of pixel values
    logic signed [2:0] [2:0] [15:0] pixel_cache;

    localparam INT_COLOR_WIDTH = 24; // intermediate pixel coler value width
    logic signed [2:0] [2:0] [INT_COLOR_WIDTH-1:0] red_cache_multiplied;
    logic signed [2:0] [2:0] [INT_COLOR_WIDTH-1:0] green_cache_multiplied;
    logic signed [2:0] [2:0] [INT_COLOR_WIDTH-1:0] blue_cache_multiplied;

    logic signed [2:0] [2:0] [INT_COLOR_WIDTH-1:0] red_cache_multiplied_buf;
    logic signed [2:0] [2:0] [INT_COLOR_WIDTH-1:0] green_cache_multiplied_buf;
    logic signed [2:0] [2:0] [INT_COLOR_WIDTH-1:0] blue_cache_multiplied_buf;

    logic signed [INT_COLOR_WIDTH-1:0] red_cache_sum;
    logic signed [INT_COLOR_WIDTH-1:0] green_cache_sum;
    logic signed [INT_COLOR_WIDTH-1:0] blue_cache_sum;

    logic signed [INT_COLOR_WIDTH-1:0] red_cache_shifted;
    logic signed [INT_COLOR_WIDTH-1:0] green_cache_shifted;
    logic signed [INT_COLOR_WIDTH-1:0] blue_cache_shifted;


    localparam BUF_WIDTH = 4; // how many stages is our buffer
    logic [BUF_WIDTH-1:0] data_valid_buf;
    logic [BUF_WIDTH-1:0] [10:0] hcount_buf;
    logic [BUF_WIDTH-1:0] [9:0] vcount_buf;



    // compute sums of caches combinationally
    // always_comb begin

    //     if(rst_in) begin
    //         red_cache_sum = 0;
    //         green_cache_sum = 0;
    //         blue_cache_sum = 0;
    //     end
    //     else begin
    //         red_cache_sum = $signed(red_cache_multiplied[0][0]) + $signed(red_cache_multiplied[0][1]) + $signed(red_cache_multiplied[0][2]) + $signed(red_cache_multiplied[1][0]) + $signed(red_cache_multiplied[1][1]) + $signed(red_cache_multiplied[1][2]) + $signed(red_cache_multiplied[2][0]) + $signed(red_cache_multiplied[2][1]) + $signed(red_cache_multiplied[2][2]);
    //         blue_cache_sum = $signed(green_cache_multiplied[0][0]) + $signed(green_cache_multiplied[0][1]) + $signed(green_cache_multiplied[0][2]) + $signed(green_cache_multiplied[1][0]) + $signed(green_cache_multiplied[1][1]) + $signed(green_cache_multiplied[1][2]) + $signed(green_cache_multiplied[2][0]) + $signed(green_cache_multiplied[2][1]) + $signed(green_cache_multiplied[2][2]);
    //         green_cache_sum = $signed(blue_cache_multiplied[0][0]) + $signed(blue_cache_multiplied[0][1]) + $signed(blue_cache_multiplied[0][2]) + $signed(blue_cache_multiplied[1][0]) + $signed(blue_cache_multiplied[1][1]) + $signed(blue_cache_multiplied[1][2]) + $signed(blue_cache_multiplied[2][0]) + $signed(blue_cache_multiplied[2][1]) + $signed(blue_cache_multiplied[2][2]);
    //     end

    // end

    // comb for outputs
    always_comb begin
        if(rst_in) begin
            data_valid_out = 0;
            hcount_out = 0;
            vcount_out = 0;

            line_out = 0;
        end 
        else begin
            data_valid_out = data_valid_buf[BUF_WIDTH-1];
            hcount_out = hcount_buf[BUF_WIDTH-1];
            vcount_out = vcount_buf[BUF_WIDTH-1];

            // set red, green, and blue on line_out
            line_out[15:11] = (red_cache_shifted[INT_COLOR_WIDTH-1] == 1)? 5'b0 : ((red_cache_shifted >= 31)? 31 : red_cache_shifted[4:0]);
            line_out[10:5] = (green_cache_shifted[INT_COLOR_WIDTH-1] == 1)? 6'b0 : ((green_cache_shifted >= 63)? 63 : green_cache_shifted[5:0]);
            line_out[4:0] = (blue_cache_shifted[INT_COLOR_WIDTH-1] == 1)? 5'b0 : ((blue_cache_shifted >= 31)? 31 : blue_cache_shifted[4:0]);
        end
    end


    always_ff @(posedge clk_in) begin
      // Make sure to have your output be set with registered logic!
      // Otherwise you'll have timing violations.

        if(rst_in) begin
            // logics
            pixel_cache <= 0;

            red_cache_multiplied <= 0;
            green_cache_multiplied <= 0;
            blue_cache_multiplied <= 0;

            red_cache_sum <= 0;
            blue_cache_sum <= 0;
            green_cache_sum <= 0;

            red_cache_shifted <= 0;
            green_cache_shifted <= 0;
            blue_cache_shifted <= 0;


            data_valid_buf <= 0;
            hcount_buf <= 0;
            vcount_buf <= 0;

            // outputs
            // line_out <= 0;

        end else begin

            // buffer values
            for(int i = 0; i < BUF_WIDTH; i = i + 1) begin
                if(i == 0) begin
                    data_valid_buf[0] <= data_valid_in;
                    hcount_buf[0] <= hcount_in;
                    vcount_buf[0] <= vcount_in;
                end else begin
                    data_valid_buf[i] <= data_valid_buf[i-1];
                    hcount_buf[i] <= hcount_buf[i-1];
                    vcount_buf[i] <= vcount_buf[i-1];
                end
            end



            // if we have valid data, pull it into the pixel cache
            if(data_valid_in) begin
                pixel_cache[0] <= data_in; // based on kernel, most recent should go into 0
                pixel_cache[1] <= pixel_cache[0];
                pixel_cache[2] <= pixel_cache[1]; // throw out top line
            end

            // stage 1
            // multiplication + shifting
            for(int i = 0; i < 3; i = i + 1) begin
                for(int j = 0; j < 3; j = j + 1) begin
                    // red = $signed({1'b0, pixel_cache[i][j][15:11]}); // 8 bits each
                    // green = $signed({1'b0, pixel_cache[i][j][10:5]});
                    // blue = $signed({1'b0, pixel_cache[i][j][4:0]});

                    // these are larger bit values now
                    red_cache_multiplied[i][j] <= $signed({1'b0, pixel_cache[i][j][15:11]}) * $signed(coeffs[i][j]);
                    green_cache_multiplied[i][j] <= $signed({1'b0, pixel_cache[i][j][10:5]}) * $signed(coeffs[i][j]);
                    blue_cache_multiplied[i][j] <= $signed({1'b0, pixel_cache[i][j][4:0]}) * $signed(coeffs[i][j]);
                end
            end


            // red_cache_multiplied[0][0] <= ($signed({1'b0, pixel_cache[0][0][15:11]}) * $signed(coeffs[0][0])) >>> shift;
            // green_cache_multiplied[0][0] <= ($signed({1'b0, pixel_cache[0][0][10:5]}) *  $signed(coeffs[0][0])) >>> shift;
            // blue_cache_multiplied[0][0] <= ($signed({1'b0, pixel_cache[0][0][4:0]}) *  $signed(coeffs[0][0])) >>> shift;

            // red_cache_multiplied[0][1] <= ($signed({1'b0, pixel_cache[0][1][15:11]}) * $signed(coeffs[0][1])) >>> shift;
            // green_cache_multiplied[0][1] <= ($signed({1'b0, pixel_cache[0][1][10:5]}) *  $signed(coeffs[0][1])) >>> shift;
            // blue_cache_multiplied[0][1] <= ($signed({1'b0, pixel_cache[0][1][4:0]}) *  $signed(coeffs[0][1])) >>> shift;

            // red_cache_multiplied[0][2] <= ($signed({1'b0, pixel_cache[0][2][15:11]}) * $signed(coeffs[0][2])) >>> shift;
            // green_cache_multiplied[0][2] <= ($signed({1'b0, pixel_cache[0][2][10:5]}) *  $signed(coeffs[0][2])) >>> shift;
            // blue_cache_multiplied[0][2] <= ($signed({1'b0, pixel_cache[0][2][4:0]}) *  $signed(coeffs[0][2])) >>> shift;

            // red_cache_multiplied[1][0] <= ($signed({1'b0, pixel_cache[1][0][15:11]}) * $signed(coeffs[1][0])) >>> shift;
            // green_cache_multiplied[1][0] <= ($signed({1'b0, pixel_cache[1][0][10:5]}) *  $signed(coeffs[1][0])) >>> shift;
            // blue_cache_multiplied[1][0] <= ($signed({1'b0, pixel_cache[1][0][4:0]}) *  $signed(coeffs[1][0])) >>> shift;

            // red_cache_multiplied[1][1] <= ($signed({1'b0, pixel_cache[1][1][15:11]}) * $signed(coeffs[1][1])) >>> shift;
            // green_cache_multiplied[1][1] <= ($signed({1'b0, pixel_cache[1][1][10:5]}) *  $signed(coeffs[1][1])) >>> shift;
            // blue_cache_multiplied[1][1] <= ($signed({1'b0, pixel_cache[1][1][4:0]}) *  $signed(coeffs[1][1])) >>> shift;

            // red_cache_multiplied[1][2] <= ($signed({1'b0, pixel_cache[1][2][15:11]}) * $signed(coeffs[1][2])) >>> shift;
            // green_cache_multiplied[1][2] <= ($signed({1'b0, pixel_cache[1][2][10:5]}) *  $signed(coeffs[1][2])) >>> shift;
            // blue_cache_multiplied[1][2] <= ($signed({1'b0, pixel_cache[1][2][4:0]}) *  $signed(coeffs[1][2])) >>> shift;

            // red_cache_multiplied[2][0] <= ($signed({1'b0, pixel_cache[2][0][15:11]}) * $signed(coeffs[2][0])) >>> shift;
            // green_cache_multiplied[2][0] <= ($signed({1'b0, pixel_cache[2][0][10:5]}) *  $signed(coeffs[2][0])) >>> shift;
            // blue_cache_multiplied[2][0] <= ($signed({1'b0, pixel_cache[2][0][4:0]}) *  $signed(coeffs[2][0])) >>> shift;

            // red_cache_multiplied[2][1] <= ($signed({1'b0, pixel_cache[2][1][15:11]}) * $signed(coeffs[2][1])) >>> shift;
            // green_cache_multiplied[2][1] <= ($signed({1'b0, pixel_cache[2][1][10:5]}) *  $signed(coeffs[2][1])) >>> shift;
            // blue_cache_multiplied[2][1] <= ($signed({1'b0, pixel_cache[2][1][4:0]}) *  $signed(coeffs[2][1])) >>> shift;

            // red_cache_multiplied[2][2] <= ($signed({1'b0, pixel_cache[2][2][15:11]}) * $signed(coeffs[2][2])) >>> shift;
            // green_cache_multiplied[2][2] <= ($signed({1'b0, pixel_cache[2][2][10:5]}) *  $signed(coeffs[2][2])) >>> shift;
            // blue_cache_multiplied[2][2] <= ($signed({1'b0, pixel_cache[2][2][4:0]}) *  $signed(coeffs[2][2])) >>> shift;

            // stage 2
            red_cache_multiplied_buf <= red_cache_multiplied;
            green_cache_multiplied_buf <= green_cache_multiplied;
            blue_cache_multiplied_buf <= blue_cache_multiplied;

            // stage 3
            // red_cache_sum <= $signed(red_cache_multiplied[0][0]) + $signed(red_cache_multiplied[0][1]) + $signed(red_cache_multiplied[0][2]) + $signed(red_cache_multiplied[1][0]) + $signed(red_cache_multiplied[1][1]) + $signed(red_cache_multiplied[1][2]) + $signed(red_cache_multiplied[2][0]) + $signed(red_cache_multiplied[2][1]) + $signed(red_cache_multiplied[2][2]);
            // green_cache_sum <= $signed(green_cache_multiplied[0][0]) + $signed(green_cache_multiplied[0][1]) + $signed(green_cache_multiplied[0][2]) + $signed(green_cache_multiplied[1][0]) + $signed(green_cache_multiplied[1][1]) + $signed(green_cache_multiplied[1][2]) + $signed(green_cache_multiplied[2][0]) + $signed(green_cache_multiplied[2][1]) + $signed(green_cache_multiplied[2][2]);
            // blue_cache_sum <= $signed(blue_cache_multiplied[0][0]) + $signed(blue_cache_multiplied[0][1]) + $signed(blue_cache_multiplied[0][2]) + $signed(blue_cache_multiplied[1][0]) + $signed(blue_cache_multiplied[1][1]) + $signed(blue_cache_multiplied[1][2]) + $signed(blue_cache_multiplied[2][0]) + $signed(blue_cache_multiplied[2][1]) + $signed(blue_cache_multiplied[2][2]);
            red_cache_sum <= $signed(red_cache_multiplied_buf[0][0]) + $signed(red_cache_multiplied_buf[0][1]) + $signed(red_cache_multiplied_buf[0][2]) + $signed(red_cache_multiplied_buf[1][0]) + $signed(red_cache_multiplied_buf[1][1]) + $signed(red_cache_multiplied_buf[1][2]) + $signed(red_cache_multiplied_buf[2][0]) + $signed(red_cache_multiplied_buf[2][1]) + $signed(red_cache_multiplied_buf[2][2]);
            green_cache_sum <= $signed(green_cache_multiplied_buf[0][0]) + $signed(green_cache_multiplied_buf[0][1]) + $signed(green_cache_multiplied_buf[0][2]) + $signed(green_cache_multiplied_buf[1][0]) + $signed(green_cache_multiplied_buf[1][1]) + $signed(green_cache_multiplied_buf[1][2]) + $signed(green_cache_multiplied_buf[2][0]) + $signed(green_cache_multiplied_buf[2][1]) + $signed(green_cache_multiplied_buf[2][2]);
            blue_cache_sum <= $signed(blue_cache_multiplied_buf[0][0]) + $signed(blue_cache_multiplied_buf[0][1]) + $signed(blue_cache_multiplied_buf[0][2]) + $signed(blue_cache_multiplied_buf[1][0]) + $signed(blue_cache_multiplied_buf[1][1]) + $signed(blue_cache_multiplied_buf[1][2]) + $signed(blue_cache_multiplied_buf[2][0]) + $signed(blue_cache_multiplied_buf[2][1]) + $signed(blue_cache_multiplied_buf[2][2]);



            // stage 4
            red_cache_shifted <= red_cache_sum >>> shift;
            green_cache_shifted <= green_cache_sum >>> shift;
            blue_cache_shifted <= blue_cache_sum >>> shift;


        end

    end

    
endmodule

`default_nettype wire

