`timescale 1ns / 1ps
`default_nettype none

module connected_components #(
    parameter HRES = 320,        // Horizontal resolution
    parameter VRES = 180,        // Vertical resolution
    parameter MAX_LABELS = 1024, // Maximum number of labels supported
    parameter MIN_AREA = 10      // Minimum blob size to retain
)(
    input  logic         clk_in,          
    input  logic         rst_in,          
    input  logic [10:0]  hcount_in,       
    input  logic [9:0]   vcount_in,       
    input  logic         mask_in,         // Binary mask
    input  logic         valid_in,        
    output logic [15:0]  label_out,       // Labeled pixel output
    output logic [10:0]  hcount_out,      // Horizontal pixel coordinate output
    output logic [9:0]   vcount_out,      // Vertical pixel coordinate output
    output logic         valid_out,       // Valid output signal
    output logic [15:0]  blob_labels[MAX_LABELS], // Array of distinct blob labels
    output logic [31:0]  num_blobs,        // Number of distinct blobs
    // output logic [15:0] area
);

    logic [15:0] current_label;        // Label for the current pixel
    logic [15:0] neighbor_labels [1:0]; // Labels for left and above neighbors
    logic [15:0] label_memory [HRES-1:0]; // Line buffer for previous row labels
    logic [31:0] label_area [MAX_LABELS-1:0]; // Array to track the area of each label
    logic [15:0] label_equivalence [MAX_LABELS-1:0]; // Array to resolve label equivalences

    logic [31:0] blob_count;           // Counter for the number of valid blobs
    logic [15:0] temp_blob_labels[MAX_LABELS]; // Temporary storage for blob labels

    // Pipelining
    logic [10:0] hcount_d;
    logic [9:0] vcount_d;
    logic valid_d;

    // Reset logic
    always_ff @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            for (int i = 0; i < HRES; i++) label_memory[i] <= 0;
            for (int i = 0; i < MAX_LABELS; i++) begin
                label_area[i] <= 0;
                label_equivalence[i] <= i; // Each label points to itself initially
                temp_blob_labels[i] <= 0;
            end
            blob_count <= 0;
        end
    end

    // Neighbor labels (left and above)
    always_comb begin
        neighbor_labels[0] = (hcount_in == 0) ? 0 : label_memory[hcount_in - 1]; // Left
        neighbor_labels[1] = label_memory[hcount_in]; // Above
    end

    

    // Label assignment logic
    always_ff @(posedge clk_in) begin
        if (valid_in) begin
            if (mask_in) begin
                if (neighbor_labels[0] == 0 && neighbor_labels[1] == 0) begin
                    // New label
                    current_label <= current_label + 1;
                    label_area[current_label] <= 1;
                    label_memory[hcount_in] <= current_label;
                end else if (neighbor_labels[0] != 0 && neighbor_labels[1] == 0) begin
                    // Use left label
                    label_memory[hcount_in] <= neighbor_labels[0];
                    label_area[neighbor_labels[0]] <= label_area[neighbor_labels[0]] + 1;
                end else if (neighbor_labels[0] == 0 && neighbor_labels[1] != 0) begin
                    // Use above label
                    label_memory[hcount_in] <= neighbor_labels[1];
                    label_area[neighbor_labels[1]] <= label_area[neighbor_labels[1]] + 1;
                end else if (neighbor_labels[0] != neighbor_labels[1]) begin
                    // Use smaller label, mark equivalence
                    label_memory[hcount_in] <= (neighbor_labels[0] < neighbor_labels[1]) ? neighbor_labels[0] : neighbor_labels[1];
                    label_area[label_memory[hcount_in]] <= label_area[label_memory[hcount_in]] + 1;
                    label_equivalence[neighbor_labels[0]] <= label_memory[hcount_in];
                    label_equivalence[neighbor_labels[1]] <= label_memory[hcount_in];
                end
            end else begin
                label_memory[hcount_in] <= 0; // Background pixel
            end
        end
    end

    // Second pass: Resolve equivalences, filter small blobs, and populate blob_labels
    always_ff @(posedge clk_in) begin
        if (valid_in) begin
            label_out <= (label_area[label_memory[hcount_in]] >= MIN_AREA) ? label_equivalence[label_memory[hcount_in]] : 0;
            hcount_out <= hcount_in;
            vcount_out <= vcount_in;
            valid_out <= valid_in;

            // Track valid blob labels
            if (label_area[label_equivalence[label_memory[hcount_in]]] >= MIN_AREA) begin
                if (!temp_blob_labels[label_equivalence[label_memory[hcount_in]]]) begin
                    temp_blob_labels[label_equivalence[label_memory[hcount_in]]] <= 1;
                    blob_labels[blob_count] <= label_equivalence[label_memory[hcount_in]];
                    blob_count <= blob_count + 1;
                end
            end
        end
    end

    assign num_blobs = blob_count;

endmodule
