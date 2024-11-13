`timescale 1ns / 1ps
`default_nettype none


module convolution (
    input wire clk_in,
    input wire rst_in,
    input wire [15:0] data_in [KERNEL_SIZE-1:0],
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

    logic signed [2:0][2:0][7:0] coeffs;
    logic signed [7:0] shift;
    kernels #(
        .K_SELECT(K_SELECT)
    ) kernels_inst (
        .rst_in(rst_in),
        .coeffs(coeffs),
        .shift(shift)
    );

    logic [15:0] pixel_cache [2:0][2:0];

    logic signed [31:0] red_products [2:0][2:0];
    logic signed [31:0] green_products [2:0][2:0];
    logic signed [31:0] blue_products [2:0][2:0];

    logic signed [31:0] red_sum;
    logic signed [31:0] green_sum;
    logic signed [31:0] blue_sum;

    logic [1:0] valid_pipeline;
    logic [10:0] hcount_pipeline [1:0];
    logic [9:0] vcount_pipeline [1:0];

    // stage 1 multiply
    always_ff @(posedge clk_in)begin
        if (rst_in) begin
            for (int i = 0; i < 3; i = i + 1) begin
                for (int j = 0; j < 3; j = j + 1) begin
                    pixel_cache[i][j] <= 0;
                end
            end
            valid_pipeline[0] <= 0;
            hcount_pipeline[0] <= 0;
            vcount_pipeline[0] <= 0;
            for (int i = 0; i < 3; i++) begin
                for (int j = 0; j < 3; j++) begin
                    red_products[i][j] <= 0;
                    green_products[i][j] <= 0;
                    blue_products[i][j] <= 0;
                end
            end
        end else begin
            if (data_valid_in) begin
                // shift the cache rows
                for (int i = 0; i < 3; i++) begin
                    for (int j = 0; j < 2; j++) begin
                        pixel_cache[i][j] <= pixel_cache[i][j+1];
                    end
                    pixel_cache[i][2] <= data_in[i];
                end
            end

            // compute products for each color channel
            for (int i = 0; i < 3; i++) begin
                for (int j = 0; j < 3; j++) begin
                    // red [15:11]
                    red_products[0][0] <= $signed(coeffs[0][0]) * $signed({1'b0, pixel_cache[0][0][15:11]});
                    red_products[0][1] <= $signed(coeffs[0][1]) * $signed({1'b0, pixel_cache[0][1][15:11]});
                    red_products[0][2] <= $signed(coeffs[0][2]) * $signed({1'b0, pixel_cache[0][2][15:11]});

                    red_products[1][0] <= $signed(coeffs[1][0]) * $signed({1'b0, pixel_cache[1][0][15:11]});
                    red_products[1][1] <= $signed(coeffs[1][1]) * $signed({1'b0, pixel_cache[1][1][15:11]});
                    red_products[1][2] <= $signed(coeffs[1][2]) * $signed({1'b0, pixel_cache[1][2][15:11]});

                    red_products[2][0] <= $signed(coeffs[2][0]) * $signed({1'b0, pixel_cache[2][0][15:11]});
                    red_products[2][1] <= $signed(coeffs[2][1]) * $signed({1'b0, pixel_cache[2][1][15:11]});
                    red_products[2][2] <= $signed(coeffs[2][2]) * $signed({1'b0, pixel_cache[2][2][15:11]});

                    // green [10:5]
                    green_products[0][0] <= $signed(coeffs[0][0]) * $signed({1'b0, pixel_cache[0][0][10:5]});
                    green_products[0][1] <= $signed(coeffs[0][1]) * $signed({1'b0, pixel_cache[0][1][10:5]});
                    green_products[0][2] <= $signed(coeffs[0][2]) * $signed({1'b0, pixel_cache[0][2][10:5]});

                    green_products[1][0] <= $signed(coeffs[1][0]) * $signed({1'b0, pixel_cache[1][0][10:5]});
                    green_products[1][1] <= $signed(coeffs[1][1]) * $signed({1'b0, pixel_cache[1][1][10:5]});
                    green_products[1][2] <= $signed(coeffs[1][2]) * $signed({1'b0, pixel_cache[1][2][10:5]});

                    green_products[2][0] <= $signed(coeffs[2][0]) * $signed({1'b0, pixel_cache[2][0][10:5]});
                    green_products[2][1] <= $signed(coeffs[2][1]) * $signed({1'b0, pixel_cache[2][1][10:5]});
                    green_products[2][2] <= $signed(coeffs[2][2]) * $signed({1'b0, pixel_cache[2][2][10:5]});

                    // blue [4:0]
                    blue_products[0][0] <= $signed(coeffs[0][0]) * $signed({1'b0, pixel_cache[0][0][4:0]});
                    blue_products[0][1] <= $signed(coeffs[0][1]) * $signed({1'b0, pixel_cache[0][1][4:0]});
                    blue_products[0][2] <= $signed(coeffs[0][2]) * $signed({1'b0, pixel_cache[0][2][4:0]});

                    blue_products[1][0] <= $signed(coeffs[1][0]) * $signed({1'b0, pixel_cache[1][0][4:0]});
                    blue_products[1][1] <= $signed(coeffs[1][1]) * $signed({1'b0, pixel_cache[1][1][4:0]});
                    blue_products[1][2] <= $signed(coeffs[1][2]) * $signed({1'b0, pixel_cache[1][2][4:0]});

                    blue_products[2][0] <= $signed(coeffs[2][0]) * $signed({1'b0, pixel_cache[2][0][4:0]});
                    blue_products[2][1] <= $signed(coeffs[2][1]) * $signed({1'b0, pixel_cache[2][1][4:0]});
                    blue_products[2][2] <= $signed(coeffs[2][2]) * $signed({1'b0, pixel_cache[2][2][4:0]});
                end
            end

            // pipeline
            valid_pipeline[0] <= data_valid_in;
            hcount_pipeline[0] <= hcount_in;
            vcount_pipeline[0] <= vcount_in;
        end
    end

    // stage 2 sum
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            red_sum <= 0;
            green_sum <= 0;
            blue_sum <= 0;
            valid_pipeline[1] <= 0;
            hcount_pipeline[1] <= 0;
            vcount_pipeline[1] <= 0;
        end else begin
            // sum up all products and apply shift
            // >>> to preserve sign
            red_sum <= (red_products[0][0] + red_products[0][1] + red_products[0][2] +
                       red_products[1][0] + red_products[1][1] + red_products[1][2] +
                       red_products[2][0] + red_products[2][1] + red_products[2][2]) >>> shift;
            
            green_sum <= (green_products[0][0] + green_products[0][1] + green_products[0][2] +
                         green_products[1][0] + green_products[1][1] + green_products[1][2] +
                         green_products[2][0] + green_products[2][1] + green_products[2][2]) >>> shift;
            
            blue_sum <= (blue_products[0][0] + blue_products[0][1] + blue_products[0][2] +
                        blue_products[1][0] + blue_products[1][1] + blue_products[1][2] +
                        blue_products[2][0] + blue_products[2][1] + blue_products[2][2]) >>> shift;

            // pipeline
            valid_pipeline[1] <= valid_pipeline[0];
            hcount_pipeline[1] <= hcount_pipeline[0];
            vcount_pipeline[1] <= vcount_pipeline[0];
        end
    end

    // output
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            line_out <= 0;
            data_valid_out <= 0;
            hcount_out <= 0;
            vcount_out <= 0;
        end else begin
            // red
            if ($signed(red_sum) < $signed(0)) begin
                line_out[15:11] <= 5'b00000;
            end else if ($signed(red_sum) > $signed(31)) begin
                line_out[15:11] <= 5'b11111;
            end else begin
                line_out[15:11] <= red_sum[4:0];
            end

            // green
            if ($signed(green_sum) < $signed(0)) begin
                line_out[10:5] <= 6'b000000;
            end else if ($signed(green_sum) > $signed(63)) begin
                line_out[10:5] <= 6'b111111;
            end else begin
                line_out[10:5] <= green_sum[5:0];
            end

            // blue
            if ($signed(blue_sum) < $signed(0)) begin
                line_out[4:0] <= 5'b00000;
            end else if ($signed(blue_sum) > $signed(31)) begin
                line_out[4:0] <= 5'b11111;
            end else begin
                line_out[4:0] <= blue_sum[4:0];
            end

            // output
            data_valid_out <= valid_pipeline[1];
            hcount_out <= hcount_pipeline[1];
            vcount_out <= vcount_pipeline[1];
        end
    end

    // // always_ff @(posedge clk_in) begin
    // //   // Make sure to have your output be set with registered logic!
    // //   // Otherwise you'll have timing violations.
    // // end
    // assign data_valid_out = 0;
    // assign hcount_out = 0;
    // assign vcount_out = 0;
    // assign line_out = 0;
endmodule

`default_nettype wire

