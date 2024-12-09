`timescale 1ns / 1ps
`default_nettype none

module temp_ccl #(
    parameter WIDTH = 320,        // Horizontal resolution
    parameter HEIGHT = 180,        // Vertical resolution
    // parameter MAX_LABELS = 10, // Maximum number of labels supported
    parameter MIN_AREA = 50      // Minimum blob size to retain
)(
    input  logic         clk_in,          
    input  logic         rst_in,          
    input  logic [10:0]  x_in,       
    input  logic [9:0]   y_in,       
    input  logic         mask_in,
    input  logic         new_frame_in,         
    input  logic         valid_in,       

    output logic         valid_out,       // Valid output signal
    output logic         busy_out,        // Busy output signal
    output logic [$clog2(WIDTH*HEIGHT):0][15:0]  blob_labels, // Array of distinct blob labels
    output logic [31:0]  num_blobs        // Number of distinct blobs
);

enum {IDLE, STORE_FRAME, FIRST_PASS, SECOND_PASS, PRUNE, OUTPUT} state;

logic [WIDTH*HEIGHT:0] first_pass_labels;
logic [WIDTH*HEIGHT:0] second_pass_labels;
logic [WIDTH*HEIGHT:0][15:0] equiv_table;
logic [WIDTH*HEIGHT:0][23:0] x_sums;
logic [WIDTH*HEIGHT:0][23:0] y_sums;

logic [WIDTH*HEIGHT:0][15:0] areas;
logic [$clog2(WIDTH*HEIGHT):0] prune_iter;
logic com_div_busy;
logic x_div_begin;
logic y_div_begin;
logic [23:0] x_dividend;
logic [23:0] y_dividend;
logic [15:0] x_divisor;
logic [15:0] y_divisor;
logic [$clog2(WIDTH)-1:0] x_quotient;
logic [$clog2(HEIGHT)-1:0] y_quotient;
logic x_div_out_valid;
logic y_div_out_valid;
logic x_div_out_waiting;
logic y_div_out_waiting;
logic [WIDTH*HEIGHT:0][$clog2(WIDTH)-1:0] x_coms;
logic [WIDTH*HEIGHT:0][$clog2(HEIGHT)-1:0] y_coms;




logic w_pixel_mask, nw_pixel_mask, n_pixel_mask, ne_pixel_mask;
logic [15:0] w_pixel_label, nw_pixel_label, n_pixel_label, ne_pixel_label;
logic [15:0] w_pixel_temp, nw_pixel_temp, n_pixel_temp, ne_pixel_temp;

logic [10:0] curr_x;
logic [9:0] curr_y;
logic [15:0] curr_label;
logic [15:0] min_label;

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        state <= IDLE;
        first_pass_labels <= 0;
        second_pass_labels <= 0;
        equiv_table <= 0;
        
        busy_out <= 0;
        valid_out <= 0;
        num_blobs <= 0;
        blob_labels <= 0;
        curr_label <= 0;
    end else begin
        case (state) 
            IDLE: begin
                valid_out <= 0;

                if (new_frame_in) begin
                    state <= STORE_FRAME;
                    busy_out <= 1;
                end
            end

            STORE_FRAME: begin
                // stores masked frame in a frame buffer
                if (x_in == 319 && y_in == 179) begin
                    state <= FIRST_PASS;
                    curr_x <= 0;
                    curr_y <= 0;
                end
            end

            FIRST_PASS: begin
                // reads from masked frame buffer and writes to label frame buffer
                if (fb_pixel_masked) begin
                    min_label <= 16'hFFFF;
                    // find min label if any neighbors are labeled
                    if (w_pixel_mask && w_pixel_label > 0) 
                        min_label <= w_pixel_label;
                    if (nw_pixel_mask && nw_pixel_label > 0 && nw_pixel_label < min_label)
                        min_label <= nw_pixel_label;
                    if (n_pixel_mask && n_pixel_label > 0 && n_pixel_label < min_label)
                        min_label <= n_pixel_label;
                    if (ne_pixel_mask && ne_pixel_label > 0 && ne_pixel_label < min_label)
                        min_label <= ne_pixel_label;
                    
                    // if no neighbors are labeled, assign new label
                    if (min_label == 16'hFFFF) begin
                        // store label of current pixel in BRAM (ADD CODE)
                        equiv_table[curr_label] <= curr_label;
                        curr_label <= curr_label + 1;
                    end else begin
                        // store label of current pixel in BRAM (ADD CODE)
                        if (w_pixel_mask && w_pixel_label > 0)
                            equiv_table[w_pixel_label] <= min_label;
                        if (nw_pixel_mask && nw_pixel_label > 0)
                            equiv_table[nw_pixel_label] <= min_label;
                        if (n_pixel_mask && n_pixel_label > 0)
                            equiv_table[n_pixel_label] <= min_label;
                        if (ne_pixel_mask && ne_pixel_label > 0)
                            equiv_table[ne_pixel_label] <= min_label;
                    end
                end

                if (curr_x == WIDTH-1) begin
                    curr_x <= 0;
                    if (curr_y == HEIGHT-1) begin
                        state <= SECOND_PASS;
                        curr_y <= 0;
                    end else begin
                        curr_y <= curr_y + 1;
                    end
                end else begin
                    curr_x <= curr_x + 1;
                end
            end

            SECOND_PASS: begin
                // updates the label frame buffer

            end


            // ASSUME PRUNING STARTS WITH:
            // second_pass_labels --> equivalencies resolved, as in there should not exist two labels which are equivalent
            // areas --> equivalencies resolved
            // prune_iter = 0 
            // com_div_busy = 0
            // x_div_begin = 0
            // y_div_begin = 0
            // all dividends and divisors = 0
            PRUNE: begin
                if(prune_iter > WIDTH*HEIGHT) begin
                    // TODO: MOVE ONTO NEXT STATE
                    
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
                                com_div_busy <= 1;                      // keep track that we're busy dividing
                                x_dividend <= x_sums[prune_iter];       // dividend is sum of all pixels
                                x_divisor <= areas[prune_iter];         // divisor is the area
                                y_dividend <= y_sums[prune_iter];
                                y_divisor <= areas[prune_iter];
                                x_div_begin <= 1;                       // tell the dividers to begin
                                y_div_begin <= 1;
                                x_div_out_waiting <= 0;                 // also keep track that we're still waiting for a divider output
                                y_div_out_waiting <= 0;
                            end
                        end else begin
                            prune_iter <= prune_iter + 1;               // if this label is 0, just continue
                        end
                    end else begin                                      // if com_div_busy
                        x_div_begin <= 0;                               // we should only tell the dividers to begin for 1 cycle
                        y_div_begin <= 0;

                        // if x_div gives an output
                        if(x_div_out_valid && !x_div_out_waiting) begin 
                            x_coms[prune_iter] <= x_quotient;           // store the output
                            x_div_out_waiting <= 1;                     // keep track that we have a valid output
                        end

                        // same thing for y
                        if(y_div_out_valid && !y_div_out_waiting) begin
                            y_coms[prune_iter] <= y_quotient;
                            y_div_out_waiting <= 1; 
                        end

                        // if we have both outputs, we can continue
                        if(x_div_out_waiting && y_div_out_waiting) begin
                            com_div_busy <= 0;                          // brings us back to the main cycle
                            prune_iter <= prune_iter + 1;               // increment the label we're looking at finally
                        end
                    end
                end

            end

            OUTPUT: begin
            end
        endcase
    end 
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







localparam FB_DEPTH = WIDTH*HEIGHT;
localparam FB_SIZE = $clog2(FB_DEPTH);
logic fb_pixel_masked; // masked pixel coming out of the frame buffer
logic [FB_SIZE-1:0] addra11, addrb11, addra12, addrb12, addra13; // for the first pass

logic [FB_SIZE-1:0] addra21, addrb21, addra22, addrb22, addra23; // for the second pass

always_comb begin
    if (state == STORE_FRAME) begin
        addra11 = x_in + y_in * WIDTH;
        addrb11 = curr_x + curr_y * WIDTH;
        addra12 = addra11;
        addrb12 = addrb11;
        addra13 = addra11;

        addra21 = curr_x + curr_y * WIDTH;
        addrb21 = curr_x + curr_y * WIDTH;
        addra22 = addra21;
        addrb22 = addrb21;
        addra23 = addra21;

    end else begin
        addra11 = (curr_x != 0 && curr_y != 0)? (curr_x-1) + (curr_y-1)*WIDTH : 0;                  // nw
        addrb11 = (curr_y != 0)? (curr_x) + (curr_y-1)*WIDTH : 0;                                   // n
        addra12 = (curr_x != WIDTH-1 && curr_y != 0)? (curr_x+1) + (curr_y-1)*WIDTH : 0;          // ne
        addrb12 = (curr_x != 0)? (curr_x-1) + (curr_y)*WIDTH : 0;                                 // w

        addra21 = (curr_x != 0 && curr_y != 0)? (curr_x-1) + (curr_y-1)*WIDTH : 0;                  // nw
        addrb21 = (curr_y != 0)? (curr_x) + (curr_y-1)*WIDTH : 0;                                   // n
        addra22 = (curr_x != WIDTH-1 && curr_y != 0)? (curr_x+1) + (curr_y-1)*WIDTH : 0;          // ne
        addrb22 = (curr_x != 0)? (curr_x-1) + (curr_y)*WIDTH : 0;                                 // w

        nw_pixel_mask = (curr_x != 0 && curr_y != 0)? nw_pixel_temp : 0;      
        n_pixel_mask = (curr_y != 0)? n_pixel_temp : 0;                       
        ne_pixel_mask = (curr_x != WIDTH-1 && curr_y != 0)? ne_pixel_temp : 0;
        w_pixel_mask = (curr_x != 0)? w_pixel_temp : 0; 
    end
end

xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(FB_DEPTH))
    fb1_mask
    (
    // PORT A
    .addra(addra11), //pixels are stored using this math
    .clka(clk_in),
    .wea(valid_in && state == STORE_FRAME),
    .dina(masked_in),
    .ena(1'b1),
    .douta(w_pixel_temp), //never read from this side
    .rsta(rst_in),
    .regcea(1'b1),

    // PORT B
    .addrb(addrb11),//transformed lookup pixel
    .dinb(16'b0),
    .clkb(clk_in),
    .web(1'b0),
    .enb(1'b1),
    .doutb(nw_pixel_temp),
    .rstb(rst_in),
    .regceb(1'b1)
    );

xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(FB_DEPTH))
    fb2_mask
    (
    // PORT A
    .addra(addra12), //pixels are stored using this math
    .clka(clk_in),
    .wea(valid_in && state == STORE_FRAME),
    .dina(masked_in),
    .ena(1'b1),
    .douta(n_pixel_temp), //never read from this side
    .rsta(rst_in),
    .regcea(1'b1),

    // PORT B
    .addrb(addrb12),//transformed lookup pixel
    .dinb(16'b0),
    .clkb(clk_in),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ne_pixel_temp),
    .rstb(rst_in),
    .regceb(1'b1)
    );

xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(FB_DEPTH))
    fb3_mask
    (
    // PORT A
    .addra(addra13), //pixels are stored using this math
    .clka(clk_in),
    .wea(valid_in && state == STORE_FRAME),
    .dina(masked_in),
    .ena(1'b1),
    .douta(fb_pixel_masked), //never read from this side
    .rsta(rst_in),
    .regcea(1'b1),

    // PORT B
    .addrb(),//transformed lookup pixel
    .dinb(16'b0),
    .clkb(clk_in),
    .web(1'b0),
    .enb(1'b1),
    .doutb(),
    .rstb(),
    .regceb(1'b1)
    );
    
// CHANGE THIS
xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(FB_DEPTH))
    fb1_labels
    (
    // PORT A
    .addra(addra), //pixels are stored using this math
    .clka(clk_in),
    .wea(valid_in && state == STORE_FRAME),
    .dina(curr_label),
    .ena(1'b1),
    .douta(w_pixel_temp), //never read from this side
    .rsta(rst_in),
    .regcea(1'b1),

    // PORT B
    .addrb(addrb),//transformed lookup pixel
    .dinb(16'b0),
    .clkb(clk_in),
    .web(1'b0),
    .enb(1'b1),
    .doutb(nw_pixel_temp),
    .rstb(rst_in),
    .regceb(1'b1)
    );

xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(FB_DEPTH))
    fb2_labels
    (
    // PORT A
    .addra(addra_2), //pixels are stored using this math
    .clka(clk_in),
    .wea(valid_in && state == STORE_FRAME),
    .dina(curr_label),
    .ena(1'b1),
    .douta(n_pixel_temp), //never read from this side
    .rsta(rst_in),
    .regcea(1'b1),

    // PORT B
    .addrb(addrb_2),//transformed lookup pixel
    .dinb(16'b0),
    .clkb(clk_in),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ne_pixel_temp),
    .rstb(rst_in),
    .regceb(1'b1)
    );

xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(FB_DEPTH))
    fb3_labels
    (
    // PORT A
    .addra(addra_2), //pixels are stored using this math
    .clka(clk_in),
    .wea(valid_in && state == STORE_FRAME),
    .dina(curr_label),
    .ena(1'b1),
    .douta(n_pixel_temp), //never read from this side
    .rsta(rst_in),
    .regcea(1'b1),

    // PORT B
    .addrb(),//transformed lookup pixel
    .dinb(16'b0),
    .clkb(clk_in),
    .web(1'b0),
    .enb(1'b1),
    .doutb(),
    .rstb(),
    .regceb(1'b1)
    );

endmodule