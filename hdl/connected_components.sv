`default_nettype none

module connected_components #(
    parameter HRES = 1280,        // Horizontal resolution
    parameter VRES = 720,         // Vertical resolution
    parameter MAX_LABELS = 1024,  // Maximum number of labels supported
    parameter MIN_AREA = 10       // Minimum blob size to retain
)(
    input  wire         clk_in,          
    input  wire         rst_in,          
    input  wire [10:0]  hcount_in,       
    input  wire [9:0]   vcount_in,       
    input  wire         mask_in,         // Binary mask
    input  wire         valid_in,        
    output logic [15:0] label_out,       // Labeled pixel output
    output logic [10:0] hcount_out,      // Horizontal pixel coordinate output
    output logic [9:0]  vcount_out,      // Vertical pixel coordinate output
    output logic        valid_out        // Valid output signal
);

    // Intermediate signals for the line buffer
    logic [15:0] current_row_pixel;
    logic [15:0] above_row_pixel;

    // Line buffer instantiation
    line_buffer_above #(
        .HRES(HRES),
        .VRES(VRES)
    ) line_buffer_inst (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .pixel_data_in({15'b0, mask_in}), // Send mask_in as the pixel data (last bit only)
        .data_valid_in(valid_in),
        .current_row_data(current_row_pixel),
        .above_row_data(above_row_pixel),
        .hcount_out(hcount_out),
        .vcount_out(vcount_out),
        .data_valid_out(valid_out)
    );

    // CCL variables
    logic [15:0] current_label;                       // Label for the current pixel
    logic [15:0] neighbor_labels [1:0];               // Labels for left and above neighbors
    logic [15:0] label_equivalence [MAX_LABELS-1:0];  // Array to resolve label equivalences
    logic [31:0] label_area [MAX_LABELS-1:0];         // Array to track blob sizes
    logic [15:0] label_memory [HRES-1:0];             // Line buffer for current row labels
    logic [15:0] min_label;

    // Reset logic
    always_ff @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            current_label <= 1;
            for (int i = 0; i < MAX_LABELS; i++) begin
                label_equivalence[i] <= i; // Each label initially points to itself
                label_area[i] <= 0;
            end
        end
    end

    // Neighbor labels
    always_comb begin
        neighbor_labels[0] = (hcount_in == 0) ? 0 : label_memory[hcount_in - 1]; // Left neighbor
        neighbor_labels[1] = above_row_pixel[0] ? above_row_pixel[15:1] : 0;     // Above neighbor
    end

    // First pass: Label assignment and equivalence resolution
    always_ff @(posedge clk_in) begin
        if (valid_in) begin
            if (mask_in) begin
                if (neighbor_labels[0] == 0 && neighbor_labels[1] == 0) begin
                    // New label
                    label_memory[hcount_in] <= current_label;
                    label_area[current_label] <= label_area[current_label] + 1;
                    current_label <= current_label + 1;
                end else if (neighbor_labels[0] != 0 && neighbor_labels[1] == 0) begin
                    // Use left neighbor's label
                    label_memory[hcount_in] <= neighbor_labels[0];
                    label_area[neighbor_labels[0]] <= label_area[neighbor_labels[0]] + 1;
                end else if (neighbor_labels[0] == 0 && neighbor_labels[1] != 0) begin
                    // Use above neighbor's label
                    label_memory[hcount_in] <= neighbor_labels[1];
                    label_area[neighbor_labels[1]] <= label_area[neighbor_labels[1]] + 1;
                end else if (neighbor_labels[0] != neighbor_labels[1]) begin
                    // Merge labels (choose smaller label and record equivalence)
                    min_label = (neighbor_labels[0] < neighbor_labels[1]) ? neighbor_labels[0] : neighbor_labels[1];
                    label_memory[hcount_in] <= min_label;
                    label_equivalence[neighbor_labels[0]] <= min_label;
                    label_equivalence[neighbor_labels[1]] <= min_label;
                    label_area[min_label] <= label_area[min_label] + 1;
                end
            end else begin
                // Background pixel
                label_memory[hcount_in] <= 0;
            end
        end
    end

    // Second pass: Resolve equivalences and filter small blobs
    always_ff @(posedge clk_in) begin
        if (valid_in) begin
            label_out <= (label_area[label_memory[hcount_in]] >= MIN_AREA)
                          ? label_equivalence[label_memory[hcount_in]]
                          : 0; // Background if area is too small
        end
    end

endmodule

`default_nettype wire
