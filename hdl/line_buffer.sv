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


  logic [1:0] write_cnt;        // keep track of which buffer we're writing to
  // logic [1:0] [1:0] write_cnt_buf;        // keep track of which buffer we're writing to
  logic [1:0] data_valid_buf;   // buffer data_valid
  logic [1:0] [10:0] hcount_buf;       // buffer hcount
  logic [1:0] [9:0] vcount_buf;       // buffer vcount
  // logic [15:0] store_pixel_data_in;
  // logic [10:0] store_hcount_in;

  // store all data coming out of buffers
  logic [KERNEL_SIZE:0] [15:0] store_line_buffer_out;


  // set line_buffer_out data based on the value of write_cnt
  always_comb begin

    if(rst_in) begin
      line_buffer_out = 0;
      // store_line_buffer_out = 0;
    end else begin
      case(write_cnt)
          0: begin
            line_buffer_out[0] = store_line_buffer_out[1];
            line_buffer_out[1] = store_line_buffer_out[2];
            line_buffer_out[2] = store_line_buffer_out[3];
          end
          1: begin
            line_buffer_out[0] = store_line_buffer_out[2];
            line_buffer_out[1] = store_line_buffer_out[3];
            line_buffer_out[2] = store_line_buffer_out[0];
          end
          2: begin
            line_buffer_out[0] = store_line_buffer_out[3];
            line_buffer_out[1] = store_line_buffer_out[0];
            line_buffer_out[2] = store_line_buffer_out[1];
          end
          3: begin
            line_buffer_out[0] = store_line_buffer_out[0];
            line_buffer_out[1] = store_line_buffer_out[1];
            line_buffer_out[2] = store_line_buffer_out[2];
          end
          default: line_buffer_out = 0;

      endcase
    end

    // case(write_cnt)
    //     0: begin
    //       line_buffer_out[0] = store_line_buffer_out[3];
    //       line_buffer_out[1] = store_line_buffer_out[2];
    //       line_buffer_out[2] = store_line_buffer_out[1];
    //     end
    //     1: begin
    //       line_buffer_out[0] = store_line_buffer_out[0];
    //       line_buffer_out[1] = store_line_buffer_out[3];
    //       line_buffer_out[2] = store_line_buffer_out[2];
    //     end
    //     2: begin
    //       line_buffer_out[0] = store_line_buffer_out[1];
    //       line_buffer_out[1] = store_line_buffer_out[0];
    //       line_buffer_out[2] = store_line_buffer_out[3];
    //     end
    //     3: begin
    //       line_buffer_out[0] = store_line_buffer_out[2];
    //       line_buffer_out[1] = store_line_buffer_out[1];
    //       line_buffer_out[2] = store_line_buffer_out[0];
    //     end
    //     default: line_buffer_out = 0;

    // endcase

    // if (rst_in) begin
    //   store_pixel_data_in = 0;
    //   store_hcount_in = 0;
    // end else if (data_valid_in) begin
    //   store_pixel_data_in = pixel_data_in;
    //   store_hcount_in = hcount_in;
    // end


    //for(int i = 0; i < 4; i = i+1) begin
      

    //     if(i != write_cnt) begin
    //       line_buffer_out[2'(i-write_cnt-1)] = store_line_buffer_out[i];
    //     end
    // end


  end

  always_comb begin
    if(rst_in) begin
      vcount_out = 0;
      hcount_out = 0;
      data_valid_out = 0;

    end else begin
      if(vcount_buf[1] == 0) begin
        vcount_out = VRES - 2;
      end else if (vcount_buf[1] == 1) begin
        vcount_out = VRES - 1;
      end else begin
        vcount_out = vcount_buf[1] - 2;
      end

      data_valid_out = data_valid_buf[1];
      hcount_out = hcount_buf[1];
    end
  end
  




  always_ff @(posedge clk_in) begin

    if(rst_in) begin
      // outputs
      // line_buffer_out <= 0;
      // hcount_out <= 0;
      // vcount_out <= 0;
      // data_valid_out <= 0;

      // logics
      write_cnt <= 3;
      // write_cnt_buf <= 3;
      data_valid_buf <= 0;
      hcount_buf <= 0;
      vcount_buf <= 0;

    end else begin

      // every time hcount hitsw the end of the wall, cycle hcount
      if(hcount_in == HRES-1 && data_valid_in) begin
        if(write_cnt == 0) begin
          write_cnt <= 3;
        end else begin
          write_cnt <= write_cnt - 1;
        end
      end



      // if(hcount_in == HRES-1 && data_valid_in) begin
      //   if(write_cnt == 0) begin
      //     write_cnt_buf[0] <= 3;
      //   end else begin
      //     write_cnt_buf[0] <= write_cnt - 1;
      //   end
      // end
      // write_cnt_buf[1] <= write_cnt_buf[0];
      // write_cnt <= write_cnt_buf[1];

      // buffer information --> two clock cycles of delay
      data_valid_buf[0] <= data_valid_in;
      data_valid_buf[1] <= data_valid_buf[0];
      // data_valid_out <= data_valid_buf[0];
      // data_valid_out <= data_valid_buf[1];
      // data_valid_buf <= data_valid_in;
      // data_valid_out <= data_valid_buf;


      // buffer hcount and vcount
      hcount_buf[0] <= hcount_in;
      hcount_buf[1] <= hcount_buf[0];
      // hcount_out <= hcount_buf[0];
      // hcount_out <= hcount_buf[1];
      // hcount_buf <= hcount_in;
      // hcount_out <= hcount_buf;

      // setting hcount and vcount
      vcount_buf[0] <= vcount_in;
      vcount_buf[1] <= vcount_buf[0];

      // vcount_buf[0] <= vcount_in;
      // // vcount_buf[1] <= vcount_buf[0];
      // vcount_out <= vcount_buf[0];
      // vcount_out <= vcount_buf[1];

      // if(vcount_in == 0) begin
      //   vcount_buf <= VRES - 2;
      // end else if (vcount_in == 1) begin
      //   vcount_buf = VRES - 1;
      // end else begin
      //   vcount_buf <= vcount_in - 2;
      // end
      // vcount_out <= vcount_buf;
    end
  end


  generate
    genvar i;
    for (i = 0; i < 4; i = i + 1) begin
      xilinx_true_dual_port_read_first_1_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(HRES),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE")) line_buffer_ram (
        .clka(clk_in),     // Clock
        //writing port:
        .addra(hcount_in),   // Port A address bus,
        .dina(pixel_data_in),     // Port A RAM input data
        .wea(data_valid_in && write_cnt == i),       // Port A write enable -- ONLY IF WE'RE ON THE LINE TO WRITE
        .ena(1'b1),       // Port A RAM Enable
        .regcea(1'b1), // Port A output register enable
        .rsta(1'b0),     // Port A output reset
        .douta(),   // Port A RAM output data, width determined from RAM_WIDTH

        //reading port:
        .addrb(hcount_in),   // Port B address bus,
        .doutb(store_line_buffer_out[i]),    // Port B RAM output data, ****FIX THIS LINE
        .dinb(0),     // Port B RAM input data, width determined from RAM_WIDTH
        .web(1'b0),       // Port B write enable
        .enb(1'b1),       // Port B RAM Enable,
        .rstb(1'b0),     // Port B output reset
        .regceb(1'b1) // Port B output register enable
      );
    end
  endgenerate




  // // to help you get started, here's a bram instantiation.
  // // you'll want to create one BRAM for each row in the kernel, plus one more to
  // // buffer incoming data from the wire:
  // xilinx_true_dual_port_read_first_1_clock_ram #(
  //   .RAM_WIDTH(16),
  //   .RAM_DEPTH(HRES),
  //   .RAM_PERFORMANCE("HIGH_PERFORMANCE")) line_buffer_ram (
  //   .clka(clk_in),     // Clock
  //   //writing port:
  //   .addra(hcount_in),   // Port A address bus,
  //   .dina(pixel_data_in),     // Port A RAM input data
  //   .wea(data_valid_in),       // Port A write enable
  //   .ena(1'b1),       // Port A RAM Enable
  //   .regcea(1'b1), // Port A output register enable
  //   .rsta(1'b0),     // Port A output reset
  //   .douta(),   // Port A RAM output data, width determined from RAM_WIDTH

  //   //reading port:
  //   .addrb(hcount_in),   // Port B address bus,
  //   .doutb(pixel_vals[i]),    // Port B RAM output data,
  //   .dinb(0),     // Port B RAM input data, width determined from RAM_WIDTH
  //   .web(1'b0),       // Port B write enable
  //   .enb(1'b1),       // Port B RAM Enable,
  //   .rstb(1'b0),     // Port B output reset
  //   .regceb(1'b1) // Port B output register enable
  // );




  // logic [10:0] f_hcount [5:0];  //hcount from filter modules
  // logic [9:0] f_vcount [5:0]; //vcount from filter modules
  // logic [15:0] f_pixel [5:0]; //pixel data from filter modules
  // logic f_valid [5:0]; //valid signals for filter modules

  // //using generate/genvar, create five *Different* instances of the
  // //filter module (you'll write that).  Each filter will implement a different
  // //kernel
  // generate
  //   genvar i;
  //   for (i=0; i<6; i=i+1)begin
  //     filter #(.K_SELECT(i),.HRES(320),.VRES(180))
  //       filterm(
  //       .clk_in(clk_pixel),
  //       .rst_in(sys_rst_pixel),
  //       .data_valid_in(lb_valid),
  //       .pixel_data_in(lb_pixel),
  //       .hcount_in(lb_hcount),
  //       .vcount_in(lb_vcount),
  //       .data_valid_out(f_valid[i]),
  //       .pixel_data_out(f_pixel[i]),
  //       .hcount_out(f_hcount[i]),
  //       .vcount_out(f_vcount[i])
  //     );
  //   end
  // endgenerate

endmodule


`default_nettype wire

