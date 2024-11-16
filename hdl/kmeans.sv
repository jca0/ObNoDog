`default_nettype none

module kmeans_center_of_mass #(
    parameter K = 4,  // Number of clusters
    parameter WIDTH = 32
)(
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] x_in,
    input wire [9:0] y_in,
    input wire valid_in,
    input wire tabulate_in,
    input wire [$clog2(K)-1:0] cluster_id,  // Specifies which cluster the input belongs to
    output logic [10:0] x_out [K-1:0],
    output logic [9:0] y_out [K-1:0],
    output logic [15:0] area_out [K-1:0],
    output logic valid_out [K-1:0]
);

    // Accumulators and counters for each cluster
    logic [WIDTH-1:0] x_sum [K-1:0];
    logic [WIDTH-1:0] y_sum [K-1:0];
    logic [WIDTH-1:0] pixel_count [K-1:0];

    // Division signals
    logic div_start_x [K-1:0];
    logic div_start_y [K-1:0];
    logic [WIDTH-1:0] dividend_x [K-1:0];
    logic [WIDTH-1:0] dividend_y [K-1:0];
    logic [WIDTH-1:0] quotient_x [K-1:0];
    logic [WIDTH-1:0] quotient_y [K-1:0];
    logic div_valid_x [K-1:0];
    logic div_valid_y [K-1:0];
    logic valid_x_reg [K-1:0];
    logic valid_y_reg [K-1:0];

    enum {IDLE, ADDING, DIVIDING} state;

    // Division modules for each cluster
    genvar i;
    generate
        for (i = 0; i < K; i = i + 1) begin : dividers
            divider #(.WIDTH(WIDTH)) div_x (
                .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(dividend_x[i]),
                .divisor_in(pixel_count[i]),
                .data_valid_in(div_start_x[i]),
                .quotient_out(quotient_x[i]),
                .remainder_out(),
                .data_valid_out(div_valid_x[i]),
                .error_out(),
                .busy_out()
            );

            divider #(.WIDTH(WIDTH)) div_y (
                .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(dividend_y[i]),
                .divisor_in(pixel_count[i]),
                .data_valid_in(div_start_y[i]),
                .quotient_out(quotient_y[i]),
                .remainder_out(),
                .data_valid_out(div_valid_y[i]),
                .error_out(),
                .busy_out()
            );
        end
    endgenerate

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset all accumulators and counters
            for (int i = 0; i < K; i++) begin
                x_out[i] <= 0;
                y_out[i] <= 0;
                area_out[i] <= 0;
                x_sum[i] <= 0;
                y_sum[i] <= 0;
                pixel_count[i] <= 0;
                valid_out[i] <= 0;
            end
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (valid_in) begin
                        // Initialize cluster data
                        x_sum[cluster_id] <= x_in;
                        y_sum[cluster_id] <= y_in;
                        pixel_count[cluster_id] <= 1;
                        valid_out[cluster_id] <= 0;
                        state <= ADDING;
                    end
                end

                ADDING: begin
                    if (valid_in) begin
                        // Update sums and counts for the selected cluster
                        x_sum[cluster_id] <= x_sum[cluster_id] + x_in;
                        y_sum[cluster_id] <= y_sum[cluster_id] + y_in;
                        pixel_count[cluster_id] <= pixel_count[cluster_id] + 1;
                    end

                    if (tabulate_in) begin
                        // Prepare for division
                        for (int i = 0; i < K; i++) begin
                            dividend_x[i] <= x_sum[i];
                            dividend_y[i] <= y_sum[i];
                            div_start_x[i] <= 1;
                            div_start_y[i] <= 1;
                            area_out[i] <= pixel_count[i];
                        end
                        state <= DIVIDING;
                    end
                end

                DIVIDING: begin
                    for (int i = 0; i < K; i++) begin
                        div_start_x[i] <= 0;
                        div_start_y[i] <= 0;

                        if (pixel_count[i] == 0) begin
                            valid_out[i] <= 0;
                        end else if (div_valid_x[i]) begin
                            x_out[i] <= quotient_x[i][10:0];
                            valid_x_reg[i] <= 1;
                        end else if (div_valid_y[i]) begin
                            y_out[i] <= quotient_y[i][9:0];
                            valid_y_reg[i] <= 1;
                        end

                        if (valid_x_reg[i] && valid_y_reg[i]) begin
                            valid_out[i] <= 1;
                            valid_x_reg[i] <= 0;
                            valid_y_reg[i] <= 0;
                        end
                    end

                    // Return to IDLE if all clusters are processed
                    if (&valid_out) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule

`default_nettype wire
