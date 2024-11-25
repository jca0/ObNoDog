`default_nettype none

module line_buffer_above (
            input wire clk_in, // System clock
            input wire rst_in, // System reset

            input wire [10:0] hcount_in, // Current hcount being read
            input wire [9:0] vcount_in, // Current vcount being read
            input wire [15:0] pixel_data_in, // Incoming pixel
            input wire data_valid_in, // Incoming valid data signal

            output logic [15:0] current_row_data, // Current row pixel
            output logic [15:0] above_row_data,   // Above row pixel
            output logic [10:0] hcount_out,       // Current hcount being read
            output logic [9:0] vcount_out,        // Current vcount being read
            output logic data_valid_out           // Valid data out signal
);
    parameter HRES = 1280;
    parameter VRES = 720;

    // Dual BRAM logic
    logic [15:0] bram_dout_current;
    logic [15:0] bram_dout_above;
    logic write_sel;

    logic [10:0] hcount_pipe;
    logic [9:0] vcount_pipe;
    logic data_valid_pipe;

    // Instantiate BRAM for current row
    xilinx_true_dual_port_read_first_1_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(HRES),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE")
    ) current_row_ram (
        .clka(clk_in),        // Clock
        .addra(hcount_in),    // Port A address bus
        .dina(pixel_data_in), // Port A RAM input data
        .wea(data_valid_in && !write_sel), // Port A write enable
        .addrb(hcount_in),    // Port B address bus
        .doutb(bram_dout_current), // Port B RAM output data
        .douta(),             // Port A RAM output data
        .dinb(0),             // Port B RAM input data
        .web(1'b0),           // Port B write enable
        .ena(1'b1),           // Port A RAM Enable
        .enb(1'b1),           // Port B RAM Enable
        .rsta(1'b0),          // Port A output reset
        .rstb(1'b0),          // Port B output reset
        .regcea(1'b1),        // Port A output register enable
        .regceb(1'b1)         // Port B output register enable
    );

    // Instantiate BRAM for above row
    xilinx_true_dual_port_read_first_1_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(HRES),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE")
    ) above_row_ram (
        .clka(clk_in),        // Clock
        .addra(hcount_in),    // Port A address bus
        .dina(pixel_data_in), // Port A RAM input data
        .wea(data_valid_in && write_sel), // Port A write enable
        .addrb(hcount_in),    // Port B address bus
        .doutb(bram_dout_above), // Port B RAM output data
        .douta(),             // Port A RAM output data
        .dinb(0),             // Port B RAM input data
        .web(1'b0),           // Port B write enable
        .ena(1'b1),           // Port A RAM Enable
        .enb(1'b1),           // Port B RAM Enable
        .rsta(1'b0),          // Port A output reset
        .rstb(1'b0),          // Port B output reset
        .regcea(1'b1),        // Port A output register enable
        .regceb(1'b1)         // Port B output register enable
    );

    // Write select logic to alternate between current and above row BRAM
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            write_sel <= 0;
        end else begin
            if (data_valid_in && (hcount_in == HRES - 1)) begin
                write_sel <= ~write_sel;
            end
        end
    end

    // Pipeline
    always_ff @(posedge clk_in) begin
        hcount_pipe <= hcount_in;
        vcount_pipe <= (vcount_in == 0) ? VRES - 1 : vcount_in - 1;
        data_valid_pipe <= data_valid_in;
    end

    // Outputs
    assign current_row_data = bram_dout_current;
    assign above_row_data = bram_dout_above;
    assign hcount_out = hcount_pipe;
    assign vcount_out = vcount_pipe;
    assign data_valid_out = data_valid_pipe;

endmodule
`default_nettype wire
