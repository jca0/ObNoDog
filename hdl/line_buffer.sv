`default_nettype none

module line_buffer (
            input wire clk_in, //system clock
            input wire rst_in, //system reset

            input wire [10:0] hcount_in, //current hcount being read
            input wire [9:0] vcount_in, //current vcount being read
            input wire [15:0] pixel_data_in, //incoming pixel
            input wire data_valid_in, //incoming  valid data signal

            output logic [KERNEL_SIZE-1:0][15:0] line_buffer_out, //output pixels of data
            output logic [10:0] hcount_out, //current hcount being read
            output logic [9:0] vcount_out, //current vcount being read
            output logic data_valid_out //valid data out signal
  );
  parameter HRES = 1280;
  parameter VRES = 720;

  localparam KERNEL_SIZE = 3;

  logic [15:0] bram_dout [KERNEL_SIZE:0];
  logic [1:0] write_sel;

  logic [10:0] hcount_pipe [1:0];
  logic [9:0] vcount_pipe [1:0];
  logic data_valid_pipe [1:0];

  // generate 4 brams
  // to help you get started, here's a bram instantiation.
  // you'll want to create one BRAM for each row in the kernel, plus one more to
  // buffer incoming data from the wire:
  generate
    genvar i;
    for (i = 0; i < 4; i = i + 1)begin
      xilinx_true_dual_port_read_first_1_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(HRES),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE")) line_buffer_ram (
        .clka(clk_in),     // Clock
        //writing port:
        .addra(hcount_in),   // Port A address bus,
        .dina(pixel_data_in),     // Port A RAM input data
        .wea(data_valid_in && (write_sel == i)),       // Port A write enable
        //reading port:
        .addrb(hcount_in),   // Port B address bus,
        .doutb(bram_dout[i]),    // Port B RAM output data,
        .douta(),   // Port A RAM output data, width determined from RAM_WIDTH
        .dinb(0),     // Port B RAM input data, width determined from RAM_WIDTH
        .web(1'b0),       // Port B write enable
        .ena(1'b1),       // Port A RAM Enable
        .enb(1'b1),       // Port B RAM Enable,
        .rsta(1'b0),     // Port A output reset
        .rstb(1'b0),     // Port B output reset
        .regcea(1'b1), // Port A output register enable
        .regceb(1'b1) // Port B output register enable
      );
    end
  endgenerate

  // cycle through brams
  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      write_sel <= 0;
    end else begin
      if (data_valid_in)begin
        if (hcount_in == HRES-1)begin
          write_sel <= write_sel + 1;
        end
      end
    end
  end

  // pipeline
  always_ff @(posedge clk_in)begin
    // stage 1
    hcount_pipe[0] <= hcount_in;
    data_valid_pipe[0] <= data_valid_in;
    if (vcount_in < 2) begin
      vcount_pipe[0] <= VRES - (2 - vcount_in);
    end else begin
      vcount_pipe[0] <= vcount_in - 2;
    end
    
    // stage 2
    hcount_pipe[1] <= hcount_pipe[0];
    data_valid_pipe[1] <= data_valid_pipe[0];
    vcount_pipe[1] <= vcount_pipe[0];
  end

  always_comb begin
    case (write_sel)
      2'd0: begin
        line_buffer_out[0] = bram_dout[1];
        line_buffer_out[1] = bram_dout[2];
        line_buffer_out[2] = bram_dout[3];
      end
      2'd1: begin
        line_buffer_out[0] = bram_dout[2];
        line_buffer_out[1] = bram_dout[3];
        line_buffer_out[2] = bram_dout[0];
      end
      2'd2: begin
        line_buffer_out[0] = bram_dout[3];
        line_buffer_out[1] = bram_dout[0];
        line_buffer_out[2] = bram_dout[1];
      end
      2'd3: begin
        line_buffer_out[0] = bram_dout[0];
        line_buffer_out[1] = bram_dout[1];
        line_buffer_out[2] = bram_dout[2];
      end
    endcase

    hcount_out = hcount_pipe[1];
    vcount_out = vcount_pipe[1];
    data_valid_out = data_valid_pipe[1];
  end

endmodule


`default_nettype wire

