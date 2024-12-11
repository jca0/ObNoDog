`timescale 1ns / 1ps
`default_nettype none

module ccl #(
    parameter WIDTH = 320,        // Horizontal resolution
    parameter HEIGHT = 180,        // Vertical resolution
    parameter MAX_LABELS = 64,
    parameter MIN_AREA = 50      // Minimum blob size to retain

)(
    input  wire                 clk_in,          
    input  wire                 rst_in,          
    input  wire [10:0]          x_in,       
    input  wire [9:0]           y_in,       
    input  wire                 mask_in,
    input  wire                 new_frame_in,         
    input  wire                 valid_in,       

    output logic                valid_out,          // Valid output signal
    output logic                busy_out,           // Busy output signal

    output logic [1:0][15:0]    blob_labels,        // Array of distinct blob labels
    output logic [10:0]         x_out,
    output logic [9:0]          y_out,
    output logic [1:0][15:0]    area_out,           // Array of blob areas
    output logic [1:0][15:0]    com_x_out,          // Array of blob centroid x-coordinates
    output logic [1:0][15:0]    com_y_out,          // Array of blob centroid y-coordinates
    output logic [15:0]         curr_pix_label,
    output logic                curr_pix_valid,
    output logic [3:0]          curr_state

);

parameter LABEL_WIDTH = $clog2(MAX_LABELS);

enum {IDLE, STORE_FRAME, FIRST_PASS, RESOLVE_EQUIV, PROPERTY_CALC, STORE_IN_ARRS, PRUNE, TL_FRAME, OUTPUT} state;
assign curr_state = state;

// logic [MAX_LABELS:0][15:0] first_pass_labels;
logic [MAX_LABELS:0][LABEL_WIDTH-1:0] second_pass_labels;

logic [MAX_LABELS:0][LABEL_WIDTH-1:0] equiv_table;
logic [LABEL_WIDTH-1:0] resolve_index;
logic [LABEL_WIDTH-1:0] resolve_pass;
logic [LABEL_WIDTH-1:0] max_passes;

logic [MAX_LABELS:0][15:0] area_table;
logic [MAX_LABELS:0][23:0] sum_x_table, sum_y_table; 


// ===== PRUNING =====
logic [MAX_LABELS:0][23:0] x_sums, y_sums; // x sums of positions of all blobs
logic [1:0][15:0] largest_areas;                    // areas of 3 largest blobs
logic [1:0][LABEL_WIDTH-1:0] largest_labels;         // labels of 3 largest blobs
logic [1:0][$clog2(WIDTH)-1:0] largest_x_coms;      // x coms of 3 largest blobs
logic [1:0][$clog2(HEIGHT)-1:0] largest_y_coms;     // y coms of 3 largest blobs
logic largest_smallest;                             // is the most recently looked at label greater than some value in our array of largest values
logic [1:0] largest_smallest_ind;                   // index of replaced value


logic [MAX_LABELS:0][15:0] areas;                 // areas of all blobs
logic [$clog2(MAX_LABELS):0] prune_iter;          // label to check for pruning
logic com_div_busy;                                 // are we currently doing a division in pruning
logic x_div_begin;                                  // is the x divider ready to begin
logic y_div_begin;                                  // is the y divider ready to begin
logic [23:0] x_dividend;                            // inputs into dividerrs
logic [23:0] y_dividend;                                
logic [15:0] x_divisor;
logic [15:0] y_divisor;
logic [$clog2(WIDTH)-1:0] x_quotient;               // outputs of dividers
logic [$clog2(HEIGHT)-1:0] y_quotient;
logic x_div_out_valid;                              // valid out signal
logic y_div_out_valid;
logic x_div_out_waiting;                            // have we recieved a valid out signal in the past and we're waiting on the other one
logic y_div_out_waiting;
// logic [MAX_LABELS:0][$clog2(WIDTH)-1:0] x_coms;   // x coms of all blobs
// logic [MAX_LABELS:0][$clog2(HEIGHT)-1:0] y_coms;  // y coms of all blobs
// ===== PRUNING =====


// ===== TL_FRAME =====
logic [$clog2(WIDTH)-1:0] x_tl;
logic [$clog2(HEIGHT)-1:0] y_tl;
logic [LABEL_WIDTH-1:0] label_tl;
logic [1:0] read_wait_tl;
logic valid_label_tl;
// ===== TL_FRAME =====


// ===== FIRST_PASS =====
logic [FB_SIZE-1:0] addra_mask, addrb_mask, addra_label, addrb_label;   // addresses for the two brams
logic [LABEL_WIDTH-1:0] label_a_out, label_b_out;                       // outpuot of label bram
logic mask_a_out, mask_b_out;                                           // mask bram
// logic [3:0][LABEL_WIDTH-1:0] new_neighbor_labels;                       // stored neighbor values for the current pixel's neighbors
logic [2:0] read_neighbor_wait;


// logic w_pixel_mask, nw_pixel_mask, n_pixel_mask, ne_pixel_mask;
logic [15:0] w_pixel_label, nw_pixel_label, n_pixel_label, ne_pixel_label;
// logic w_pixel_temp, nw_pixel_temp, n_pixel_temp, ne_pixel_temp;
// logic [15:0] w_pixel_temp_label, nw_pixel_temp_label, n_pixel_temp_label, ne_pixel_temp_label;

logic [10:0] curr_x;
logic [9:0] curr_y;
logic [LABEL_WIDTH-1:0] curr_label;
logic [LABEL_WIDTH-1:0] min_label;

logic [1:0] bram_wait;
logic read_signal; // if !read_signal, write to BRAM
logic [LABEL_WIDTH-1:0] store_label;

localparam FB_DEPTH = WIDTH*HEIGHT;
localparam FB_SIZE = $clog2(FB_DEPTH);
// logic fb_pixel_masked; // masked pixel coming out of the frame buffer
// logic fb_pixel_label; // label of the pixel coming out of the frame buffer
// logic [FB_SIZE-1:0] addra21, addrb21, addra22, addrb22, addra23, addrb23, addra24, addrb24; // for the second pass
// ===== FIRST_PASS =====


always_ff @(posedge clk_in) begin
    if (rst_in) begin
        state <= IDLE;
        // first_pass_labels <= 0;
        second_pass_labels <= 0;
        bram_wait <= 0;
        read_signal <= 1;
        
        busy_out <= 0;
        valid_out <= 0;
        blob_labels <= 0;
        curr_label <= 0;

        // initially label maps to itself
        for (int i = 0; i < MAX_LABELS+1; i=i+1) begin
            equiv_table[i] <= i;
        end
        area_table <= 0;
        sum_x_table <= 0;
        sum_y_table <= 0;

    end else begin
        case (state) 
            IDLE: begin
                valid_out <= 0;
                largest_areas <= 0;
                largest_labels <= 0;
                largest_x_coms <= 0;
                largest_y_coms <= 0;

                for (int i = 0; i < 16; i=i+1) begin
                    equiv_table[i] <= i;
                end
                area_table <= 0;
                sum_x_table <= 0;
                sum_y_table <= 0;



                if (new_frame_in) begin
                    state <= STORE_FRAME;
                    busy_out <= 1;
                end
            end

            STORE_FRAME: begin
                // stores masked frame in a frame buffer
                if (x_in == WIDTH-1 && y_in == HEIGHT-1) begin
                    state <= FIRST_PASS;
                    curr_x <= 0;
                    curr_y <= 0;
                    curr_label <= 1;
                    bram_wait <= 0;
                    read_neighbor_wait <= 0;
                    
                    for (int i = 0; i < 16; i=i+1) begin
                        equiv_table[i] <= i;
                    end
                    area_table <= 0;
                    sum_x_table <= 0;
                    sum_y_table <= 0;

                end
            end

            FIRST_PASS: begin
                // add areas 
                // x sums, y sums
                // reads from masked frame buffer and writes to label frame buffer
                if (bram_wait < 2) begin
                    // read_signal <= 1;
                    bram_wait <= bram_wait + 1;
                end else begin
                    bram_wait <= 0;
                    if (mask_a_out) begin // IF WE HAVE TO LABEL

                        if(read_neighbor_wait < 6) begin // TODO: think harder about how many cycles we need
                            read_neighbor_wait <= read_neighbor_wait + 1;
                        end else begin // IF WE'VE READ FROM ALL THE BRAMS & HAVE NEIGHBORS

                            // if we're doing a read currently (we just got all our values, determine minimum label)
                            if (read_signal) begin
                                // READ FROM BRAM
                                // find min label if any neighbors are labeled
                                if(w_pixel_label > 0 && w_pixel_label <= nw_pixel_label && w_pixel_label <= n_pixel_label && w_pixel_label <= ne_pixel_label) begin
                                    min_label <= w_pixel_label;
                                end else if(nw_pixel_label > 0 && nw_pixel_label <= w_pixel_label && nw_pixel_label <= n_pixel_label && nw_pixel_label <= ne_pixel_label) begin
                                    min_label <= nw_pixel_label;
                                end else if(n_pixel_label > 0 && n_pixel_label <= w_pixel_label && n_pixel_label <= nw_pixel_label && n_pixel_label <= ne_pixel_label) begin
                                    min_label <= n_pixel_label;
                                end else if(ne_pixel_label > 0 && ne_pixel_label <= w_pixel_label && ne_pixel_label <= nw_pixel_label && ne_pixel_label <= n_pixel_label) begin
                                    min_label <= ne_pixel_label;
                                end else begin
                                    min_label <= 6'b111111;
                                end
                                
                                read_signal <= 0; // write next cycle
                            end else begin // when we write to BRAM
                                // STORE INTO BRAM
                                // if no neighbors are labeled, assign new label
                                if (min_label == 6'b111111) begin
                                    // store label of current pixel in BRAM (ADD CODE)
                                    equiv_table[curr_label] <= curr_label;
                                    area_table[curr_label] <= area_table[curr_label] + 1;
                                    sum_x_table[curr_label] <= sum_x_table[curr_label] + curr_x;
                                    sum_y_table[curr_label] <= sum_y_table[curr_label] + curr_y;

                                    // DON'T OVERFLOW
                                    if(curr_label < MAX_LABELS-1) begin
                                        curr_label <= curr_label + 1;
                                    end
                                end else begin
                                    // the minimum label should be set for all neighbors
                                    // Should be handled in resolve equivalences? to deal with area mismatches
                                    // if (w_pixel_label > 0) begin
                                    //     equiv_table[w_pixel_label] <= min_label;
                                    // end
                                    // if (nw_pixel_label > 0) begin
                                    //     equiv_table[nw_pixel_label] <= min_label;
                                    // end
                                    // if (n_pixel_label > 0) begin
                                    //     equiv_table[n_pixel_label] <= min_label;
                                    // end
                                    // if (ne_pixel_label > 0) begin
                                    //     equiv_table[ne_pixel_label] <= min_label;
                                    // end

                                    equiv_table[curr_label] <= min_label;
                                    area_table[min_label] <= area_table[min_label] + 1;
                                    sum_x_table[min_label] <= sum_x_table[min_label] + curr_x;
                                    sum_y_table[min_label] <= sum_y_table[min_label] + curr_y;
                                end

                                read_signal <= 1; // read next cycle 

                                // UPDATE X AND Y
                                if (curr_x == WIDTH-1) begin
                                    curr_x <= 0;
                                    if (curr_y == HEIGHT-1) begin
                                        state <= RESOLVE_EQUIV;
                                        resolve_index <= 0;
                                        resolve_pass <= 0;
                                        max_passes <= curr_label;
                                        curr_y <= 0;
                                    end else begin
                                        curr_y <= curr_y + 1;
                                    end
                                end else begin
                                    curr_x <= curr_x + 1;
                                end

                            end
                        end
                    end else begin // mask_a_out
                        read_signal <= 0;

                        // UPDATE X AND Y
                        if (curr_x == WIDTH-1) begin
                            curr_x <= 0;
                            if (curr_y == HEIGHT-1) begin
                                state <= RESOLVE_EQUIV;
                                resolve_index <= 0;
                                resolve_pass <= 0;
                                max_passes <= curr_label;

                                curr_y <= 0;
                            end else begin
                                curr_y <= curr_y + 1;
                            end
                        end else begin
                            curr_x <= curr_x + 1;
                        end

                    end

                end
            end // END FIRST PASS



            RESOLVE_EQUIV: begin
                curr_label <= 1;
                equiv_table[resolve_index] <= equiv_table[equiv_table[resolve_index]];
                if (resolve_index >= max_passes - 1) begin
                    resolve_index <= 0;
                    if (resolve_pass >= max_passes) begin
                        state <= PROPERTY_CALC;
                        resolve_pass <= 0;
                    end else begin
                        resolve_pass <= resolve_pass + 1;
                    end 
                end else begin
                    resolve_index <= resolve_index + 1;
                end
            end

            PROPERTY_CALC: begin
                if (resolve_index != equiv_table[resolve_index]) begin
                    area_table[equiv_table[resolve_index]] <= area_table[equiv_table[resolve_index]] + area_table[resolve_index];
                    sum_x_table[equiv_table[resolve_index]] <= sum_x_table[equiv_table[resolve_index]] + sum_x_table[resolve_index];
                    sum_y_table[equiv_table[resolve_index]] <= sum_y_table[equiv_table[resolve_index]] + sum_y_table[resolve_index];
                end
                if (resolve_index >= max_passes - 1) begin
                    resolve_index <= 0;
                    if (resolve_pass >= max_passes) begin
                        state <= STORE_IN_ARRS;
                        resolve_pass <= 0;

                        second_pass_labels <= 0;
                        areas <= 0;
                        x_sums <= 0;
                        y_sums <= 0;
                    end else begin
                        resolve_pass <= resolve_pass + 1;
                    end 
                end else begin
                    resolve_index <= resolve_index + 1;
                end
            end

            STORE_IN_ARRS: begin
                second_pass_labels[equiv_table[resolve_index]] <= 1;
                areas[equiv_table[resolve_index]] <= area_table[equiv_table[resolve_index]];
                x_sums[equiv_table[resolve_index]] <= sum_x_table[equiv_table[resolve_index]];
                y_sums[equiv_table[resolve_index]] <= sum_y_table[equiv_table[resolve_index]];

                if (resolve_index >= max_passes) begin
                    // resolve_index <= 0;
                    // resolve_pass <= resolve_pass + 1;
                    // if (resolve_pass == max_passes) begin
                    state <= PRUNE;
                    prune_iter <= 0;
                    com_div_busy <= 0;
                    x_div_begin <= 0;
                    y_div_begin <= 0;
                    x_dividend <= 0;
                    x_divisor <= 0;
                    y_dividend <= 0;
                    y_divisor <= 0;
                    largest_areas <= 0;
                    largest_labels <= 0;
                    largest_x_coms <= 0;
                    largest_y_coms <= 0;
                    largest_smallest <= 0;
                    largest_smallest_ind <= 0;
                    // end else begin
                    //     resolve_pass <= resolve_pass + 1;
                    // end 
                end else begin
                    resolve_index <= resolve_index + 1;
                end
            end
            
            // ASSUME PRUNING STARTS WITH:
            // second_pass_labels --> equivalencies resolved, as in there should not exist two labels which are equivalent
            // areas --> equivalencies resolved
            // prune_iter = 0 
            // com_div_busy = 0
            // x_div_begin = 0
            // y_div_begin = 0
            // all dividends and divisors = 0
            // all largest_ = 0
            PRUNE: begin
                if(prune_iter > MAX_LABELS) begin
                    state <= TL_FRAME;
                    x_tl <= 0;
                    y_tl <= 0;
                    read_wait_tl <= 0;
                    valid_label_tl <= 0;
                end else begin

                    // if we're not dividing currently
                    if(!com_div_busy) begin

                        // if this label exists
                        if(second_pass_labels[prune_iter] == 1) begin

                            // if the area for this label is beneath the minimum area
                            if(areas[prune_iter] < MIN_AREA) begin
                                second_pass_labels[prune_iter] <= 0;    // then delete this label
                                prune_iter <= prune_iter + 1;           // and continue
                            
                            // otherwise, we have a label with a valid area
                            end else begin
                                
                                // if this area is smaller than the 3 largest, we don't care about dividing
                                if(areas[prune_iter] <= largest_areas[0] && areas[prune_iter] <= largest_areas[1]) begin
                                    prune_iter <= prune_iter + 1;           // and continue

                                end else begin
                                    com_div_busy <= 1;                      // keep track that we're busy dividing
                                    x_dividend <= x_sums[prune_iter];       // dividend is sum of all pixels
                                    x_divisor <= areas[prune_iter];         // divisor is the area
                                    y_dividend <= y_sums[prune_iter];
                                    y_divisor <= areas[prune_iter];
                                    x_div_begin <= 1;                       // tell the dividers to begin
                                    y_div_begin <= 1;
                                    x_div_out_waiting <= 0;                 // also keep track that we're still waiting for a divider output
                                    y_div_out_waiting <= 0;

                                    // keep track of 3 largest values
                                    if(areas[prune_iter] > largest_areas[0] && largest_areas[0] <= largest_areas[1]) begin
                                        largest_smallest <= 1;
                                        largest_smallest_ind <= 0;
                                        largest_areas[0] <= areas[prune_iter];
                                        largest_labels[0] <= second_pass_labels[prune_iter];

                                    end else if (areas[prune_iter] > largest_areas[1] && largest_areas[1] <= largest_areas[0]) begin
                                        largest_smallest <= 1;
                                        largest_smallest_ind <= 1;
                                        largest_areas[1] <= areas[prune_iter];
                                        largest_labels[1] <= second_pass_labels[prune_iter];

                                    end
                                end
                            end
                        end else begin
                            prune_iter <= prune_iter + 1;               // if this label is 0, just continue
                        end
                    end else begin                                      // if com_div_busy
                        x_div_begin <= 0;                               // we should only tell the dividers to begin for 1 cycle
                        y_div_begin <= 0;

                        // if x_div gives an output
                        if(x_div_out_valid && !x_div_out_waiting) begin 
                            // x_coms[prune_iter] <= x_quotient;           // store the output
                            x_div_out_waiting <= 1;                     // keep track that we have a valid output

                            // if we need to overwrite largest array
                            if(largest_smallest) begin
                                largest_x_coms[largest_smallest_ind] <= x_quotient;
                            end
                        end

                        // same thing for y
                        if(y_div_out_valid && !y_div_out_waiting) begin
                            // y_coms[prune_iter] <= y_quotient;
                            y_div_out_waiting <= 1; 

                            if(largest_smallest) begin
                                largest_y_coms[largest_smallest_ind] <= y_quotient;
                            end
                        end

                        // if we have both outputs, we can continue
                        if(x_div_out_waiting && y_div_out_waiting) begin
                            com_div_busy <= 0;                          // brings us back to the main cycle
                            prune_iter <= prune_iter + 1;               // increment the label we're looking at finally
                            largest_smallest <= 0;
                        end
                    end
                end

            end

            // TODO: logic to scan through and write to BRAMs in top level
            // TODO: combinational logic to set largest_ to the outputs

            TL_FRAME: begin
                if(read_wait_tl == 2) begin
                    valid_label_tl <= 1;
                    read_wait_tl <= 0;
                    if(x_tl == WIDTH-1) begin
                        x_tl <= 0;
                        if(y_tl == HEIGHT-1) begin
                            y_tl <= 0;
                            state <= OUTPUT; // TERMINATE once we hit the end
                        end else begin
                            y_tl <= y_tl + 1;
                        end
                    end else begin
                        x_tl <= x_tl + 1;
                    end
                end else begin
                    valid_label_tl <= 0;
                    read_wait_tl <= read_wait_tl + 1;
                end
                // read through BRAM based on the value

            end

            // TODO: MAKE SURE THERE ARENT ANY OTHER VALUES WE NEED
            OUTPUT: begin
                valid_label_tl <= 0;
                valid_out <= 1;
                state <= IDLE;
                busy_out <= 0;
            end
        endcase
    end 
end

// SETTING OUTPUTS FOR 3 LARGEST BLOBS
// CRITICAL FOR TL_FRAME
always_comb begin
    // if(rst_in) begin
    //     blob_labels = 0;
    //     area_out = 0;
    //     com_x_out = 0;
    //     com_y_out = 0;
    //     curr_pix_label = 0;
    //     curr_pix_valid = 0;
    //     x_out = 0;
    //     y_out = 0;
    // end else begin
    blob_labels = largest_labels;
    area_out = largest_areas;
    com_x_out = largest_x_coms;
    com_y_out = largest_y_coms;
    curr_pix_label = label_tl;
    curr_pix_valid = valid_label_tl;
    x_out = x_tl;
    y_out = y_tl;
    // end
end


divider #(.WIDTH(24)) div_x (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(x_dividend),
        .divisor_in(x_divisor),
        .data_valid_in(x_div_begin),
        .quotient_out(x_quotient),
        .remainder_out(),
        .data_valid_out(x_div_out_valid),
        .error_out(),
        .busy_out()
    );
divider #(.WIDTH(24)) div_y (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(y_dividend),
        .divisor_in(y_divisor),
        .data_valid_in(y_div_begin),
        .quotient_out(y_quotient),
        .remainder_out(),
        .data_valid_out(y_div_out_valid),
        .error_out(),
        .busy_out()
    );


always_comb begin
    // if(rst_in) begin
    //     addra_mask = 0;
    //     addrb_mask = 0;
    //     addra_label = 0;
    //     addrb_label = 0;

    //     store_label = 0;

    // end else begin
    if (state == STORE_FRAME) begin
        addra_mask = x_in + y_in * WIDTH; // STORING TO THIS INDEX
    end else if (state == FIRST_PASS) begin
        addra_mask = curr_x + curr_y * WIDTH; // get the mask pixel at the center index --> mask_a_out

        
        // SETTING ADDRS AND STORING NEIGHBORS
        // logic [15:0] w_pixel_label, nw_pixel_label, n_pixel_label, ne_pixel_label;
        if(mask_a_out) begin
            if(read_signal) begin
                if(read_neighbor_wait == 0 || read_neighbor_wait == 1) begin
                    addra_label = (curr_x != 0 && curr_y != 0)? (curr_x-1) + (curr_y-1)*WIDTH : 0;          // nw
                    addrb_label = (curr_y != 0)? (curr_x) + (curr_y-1)*WIDTH : 0;                           // n
                end else if(read_neighbor_wait == 2) begin
                    nw_pixel_label = (curr_x != 0 && curr_y != 0)? label_a_out : 0;
                    n_pixel_label = (curr_y != 0)? label_b_out : 0;
                end else if(read_neighbor_wait == 3 || read_neighbor_wait == 4) begin
                    addra_label = (curr_x != WIDTH-1 && curr_y != 0)? (curr_x+1) + (curr_y-1)*WIDTH : 0;    // ne
                    addrb_label = (curr_x != 0)? (curr_x-1) + (curr_y)*WIDTH : 0;                           // w
                end else if(read_neighbor_wait == 5) begin
                    ne_pixel_label = (curr_x != WIDTH-1 && curr_y != 0)? label_a_out : 0;
                    w_pixel_label = (curr_x != 0)? label_b_out : 0;
                end
            end else begin
                // if we need to store a label to BRAM, decide what label to store
                if(min_label == 6'b111111) begin
                    store_label = curr_label;   // store a new label
                end else begin
                    store_label = min_label;    // store the minimum label among neighbors
                end

                addra_label = curr_x + curr_y * WIDTH; // if we're writing, store to this label
            end
        end else begin // if there is no mask here, write 0 to label
            addra_label = curr_x + curr_y * WIDTH;
            store_label = 0;
        end

        // addra11 = (curr_x != 0 && curr_y != 0)? (curr_x-1) + (curr_y-1)*WIDTH : 0;                  // nw
        // addrb11 = (curr_y != 0)? (curr_x) + (curr_y-1)*WIDTH : 0;                                   // n
        // addra12 = (curr_x != WIDTH-1 && curr_y != 0)? (curr_x+1) + (curr_y-1)*WIDTH : 0;          // ne
        // addrb12 = (curr_x != 0)? (curr_x-1) + (curr_y)*WIDTH : 0;                                 // w
        // addra13 = curr_x + curr_y*WIDTH;

        // // labels
        // addra21 = curr_x + curr_y*WIDTH;
        // addra22 = curr_x + curr_y*WIDTH;
        // addra23 = curr_x + curr_y*WIDTH;
        // addra24 = curr_x + curr_y*WIDTH;
        // addrb21 = (curr_x != 0 && curr_y != 0)? (curr_x-1) + (curr_y-1)*WIDTH : 0;                  // nw
        // addrb22 = (curr_y != 0)? (curr_x) + (curr_y-1)*WIDTH : 0;                                   // n
        // addrb23 = (curr_x != WIDTH-1 && curr_y != 0)? (curr_x+1) + (curr_y-1)*WIDTH : 0;          // ne
        // addrb24 = (curr_x != 0)? (curr_x-1) + (curr_y)*WIDTH : 0;                                 // w

        // nw_pixel_mask = (curr_x != 0 && curr_y != 0)? nw_pixel_temp : 0;      
        // n_pixel_mask = (curr_y != 0)? n_pixel_temp : 0;                       
        // ne_pixel_mask = (curr_x != WIDTH-1 && curr_y != 0)? ne_pixel_temp : 0;
        // w_pixel_mask = (curr_x != 0)? w_pixel_temp : 0; 

        // nw_pixel_label = (curr_x != 0 && curr_y != 0)? nw_pixel_temp_label : 0;      
        // n_pixel_label = (curr_y != 0)? n_pixel_temp_label : 0;                       
        // ne_pixel_label = (curr_x != WIDTH-1 && curr_y != 0)? ne_pixel_temp_label : 0;
        // w_pixel_label = (curr_x != 0)? w_pixel_temp_label : 0; 



    end else if (state == TL_FRAME) begin
        addra_label = x_tl + y_tl*WIDTH; // read label from center & pull corresponding value
        label_tl = equiv_table[label_a_out];
    end
    // end
end



xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(FB_DEPTH))
    fb1_mask
    (
    // PORT A
    .addra(addra_mask), //pixels are stored using this math
    .clka(clk_in),
    .wea(valid_in && state == STORE_FRAME),
    .dina(mask_in),
    .ena(1'b1),
    .douta(mask_a_out), //never read from this side
    .rsta(rst_in),
    .regcea(1'b1),

    // PORT B
    .addrb(addrb_mask),//transformed lookup pixel
    .dinb(1'b0),
    .clkb(clk_in),
    .web(1'b0),
    .enb(1'b1),
    .doutb(mask_b_out),
    .rstb(rst_in),
    .regceb(1'b1)
    );


    
xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(LABEL_WIDTH),
    .RAM_DEPTH(FB_DEPTH))
    fb1_labels
    (
    // PORT A
    .addra(addra_label), //pixels are stored using this math
    .clka(clk_in),
    .wea(state == FIRST_PASS && !read_signal),
    .dina(store_label),
    .ena(1'b1),
    .douta(label_a_out), //never read from this side
    .rsta(rst_in),
    .regcea(1'b1),

    // PORT B
    .addrb(addrb_label),//transformed lookup pixel
    .dinb(16'b0),
    .clkb(clk_in),
    .web(1'b0),
    .enb(1'b1),
    .doutb(label_b_out),
    .rstb(rst_in),
    .regceb(1'b1)
    );

// xilinx_true_dual_port_read_first_2_clock_ram
//     #(.RAM_WIDTH(1),
//     .RAM_DEPTH(FB_DEPTH))
//     fb2_mask
//     (
//     // PORT A
//     .addra(addra12), //pixels are stored using this math
//     .clka(clk_in),
//     .wea(valid_in && state == STORE_FRAME),
//     .dina(mask_in),
//     .ena(1'b1),
//     .douta(n_pixel_temp), //never read from this side
//     .rsta(rst_in),
//     .regcea(1'b1),

//     // PORT B
//     .addrb(addrb12),//transformed lookup pixel
//     .dinb(1'b0),
//     .clkb(clk_in),
//     .web(1'b0),
//     .enb(1'b1),
//     .doutb(ne_pixel_temp),
//     .rstb(rst_in),
//     .regceb(1'b1)
//     );

// xilinx_true_dual_port_read_first_2_clock_ram
//     #(.RAM_WIDTH(1),
//     .RAM_DEPTH(FB_DEPTH))
//     fb3_mask
//     (
//     // PORT A
//     .addra(addra13), //pixels are stored using this math
//     .clka(clk_in),
//     .wea(valid_in && state == STORE_FRAME),
//     .dina(mask_in),
//     .ena(1'b1),
//     .douta(fb_pixel_masked), //never read from this side
//     .rsta(rst_in),
//     .regcea(1'b1),

//     // PORT B
//     .addrb(),//transformed lookup pixel
//     .dinb(1'b0),
//     .clkb(clk_in),
//     .web(1'b0),
//     .enb(1'b1),
//     .doutb(),
//     .rstb(),
//     .regceb(1'b1)
//     );





// xilinx_true_dual_port_read_first_2_clock_ram
//     #(.RAM_WIDTH(LABEL_WIDTH),
//     .RAM_DEPTH(FB_DEPTH))
//     fb2_labels
//     (
//     // PORT A
//     .addra(addra22), //pixels are stored using this math
//     .clka(clk_in),
//     .wea(state == FIRST_PASS && !read_signal),
//     .dina(curr_label),
//     .ena(1'b1),
//     .douta(), //never read from this side
//     .rsta(rst_in),
//     .regcea(1'b1),

//     // PORT B
//     .addrb(addrb22),//transformed lookup pixel
//     .dinb(16'b0),
//     .clkb(clk_in),
//     .web(1'b0),
//     .enb(1'b1),
//     .doutb(n_pixel_temp_label),
//     .rstb(rst_in),
//     .regceb(1'b1)
//     );

// xilinx_true_dual_port_read_first_2_clock_ram
//     #(.RAM_WIDTH(LABEL_WIDTH),
//     .RAM_DEPTH(FB_DEPTH))
//     fb3_labels
//     (
//     // PORT A
//     .addra(addra23), //pixels are stored using this math
//     .clka(clk_in),
//     .wea(state == FIRST_PASS && !read_signal),
//     .dina(curr_label),
//     .ena(1'b1),
//     .douta(), //never read from this side
//     .rsta(rst_in),
//     .regcea(1'b1),

//     // PORT B
//     .addrb(addrb23),//transformed lookup pixel
//     .dinb(16'b0),
//     .clkb(clk_in),
//     .web(1'b0),
//     .enb(1'b1),
//     .doutb(ne_pixel_temp_label),
//     .rstb(),
//     .regceb(1'b1)
//     );

// xilinx_true_dual_port_read_first_2_clock_ram
//     #(.RAM_WIDTH(LABEL_WIDTH),
//     .RAM_DEPTH(FB_DEPTH))
//     fb4_labels
//     (
//     // PORT A
//     .addra(addra24), //pixels are stored using this math
//     .clka(clk_in),
//     .wea(state == FIRST_PASS && !read_signal),
//     .dina(curr_label),
//     .ena(1'b1),
//     .douta(), //never read from this side
//     .rsta(rst_in),
//     .regcea(1'b1),

//     // PORT B
//     .addrb(addrb24),//transformed lookup pixel
//     .dinb(16'b0),
//     .clkb(clk_in),
//     .web(1'b0),
//     .enb(1'b1),
//     .doutb(w_pixel_temp_label),
//     .rstb(),
//     .regceb(1'b1)
//     );

endmodule

`default_nettype wire