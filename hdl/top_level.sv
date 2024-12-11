`timescale 1ns / 1ps
`default_nettype none

module top_level
  (
   input wire          clk_100mhz,
   output logic [15:0] led,
   // camera bus
   input wire [7:0]    camera_d, // 8 parallel data wires
   output logic        cam_xclk, // XC driving camera
   input wire          cam_hsync, // camera hsync wire
   input wire          cam_vsync, // camera vsync wire
   input wire          cam_pclk, // camera pixel clock
   inout wire          i2c_scl, // i2c inout clock
   inout wire          i2c_sda, // i2c inout data
   input wire [15:0]   sw,
   input wire [3:0]    btn,
   output logic [2:0]  rgb0,
   output logic [2:0]  rgb1,
   // seven segment
   output logic [3:0]  ss0_an,//anode control for upper four digits of seven-seg display
   output logic [3:0]  ss1_an,//anode control for lower four digits of seven-seg display
   output logic [6:0]  ss0_c, //cathode controls for the segments of upper four digits
   output logic [6:0]  ss1_c, //cathod controls for the segments of lower four digits
   // hdmi port
   output logic [2:0]  hdmi_tx_p, //hdmi output signals (positives) (blue, green, red)
   output logic [2:0]  hdmi_tx_n, //hdmi output signals (negatives) (blue, green, red)
   output logic        hdmi_clk_p, hdmi_clk_n //differential hdmi clock
   );

  // shut up those RGBs
  assign rgb0 = 0;
  assign rgb1 = 0;

  // Clock and Reset Signals
  logic          sys_rst_camera;
  logic          sys_rst_pixel;

  logic          clk_camera;
  logic          clk_pixel;
  logic          clk_5x;
  logic          clk_xc;

  logic          clk_100_passthrough;

  // clocking wizards to generate the clock speeds we need for our different domains
  // clk_camera: 200MHz, fast enough to comfortably sample the cameera's PCLK (50MHz)
  cw_hdmi_clk_wiz wizard_hdmi
    (.sysclk(clk_100_passthrough),
     .clk_pixel(clk_pixel),
     .clk_tmds(clk_5x),
     .reset(0));

  cw_fast_clk_wiz wizard_migcam
    (.clk_in1(clk_100mhz),
     .clk_camera(clk_camera),
     .clk_xc(clk_xc),
     .clk_100(clk_100_passthrough),
     .reset(0));

  // assign camera's xclk to pmod port: drive the operating clock of the camera!
  // this port also is specifically set to high drive by the XDC file.
  assign cam_xclk = clk_xc;

  assign sys_rst_camera = btn[0]; //use for resetting camera side of logic
  assign sys_rst_pixel = btn[0]; //use for resetting hdmi/draw side of logic


  // video signal generator signals
  logic          hsync_hdmi;
  logic          vsync_hdmi;
  logic [10:0]  hcount_hdmi;
  logic [9:0]    vcount_hdmi;
  logic          active_draw_hdmi;
  logic          new_frame_hdmi;
  logic [5:0]    frame_count_hdmi;
  logic          nf_hdmi;

  // rgb output values
  logic [7:0]          red,green,blue;

  // ** Handling input from the camera **

  // synchronizers to prevent metastability
  logic [7:0]    camera_d_buf [1:0];
  logic          cam_hsync_buf [1:0];
  logic          cam_vsync_buf [1:0];
  logic          cam_pclk_buf [1:0];

  always_ff @(posedge clk_camera) begin
     camera_d_buf <= {camera_d, camera_d_buf[1]};
     cam_pclk_buf <= {cam_pclk, cam_pclk_buf[1]};
     cam_hsync_buf <= {cam_hsync, cam_hsync_buf[1]};
     cam_vsync_buf <= {cam_vsync, cam_vsync_buf[1]};
  end

  logic [10:0] camera_hcount;
  logic [9:0]  camera_vcount;
  logic [15:0] camera_pixel;
  logic        camera_valid;

  // your pixel_reconstruct module, from week 5 and 6
  // hook it up to buffered inputs.
  //same as it ever was.

  pixel_reconstruct mod
    (.clk_in(clk_camera),
     .rst_in(sys_rst_camera),
     .camera_pclk_in(cam_pclk_buf[0]),
     .camera_hs_in(cam_hsync_buf[0]),
     .camera_vs_in(cam_vsync_buf[0]),
     .camera_data_in(camera_d_buf[0]),
     .pixel_valid_out(camera_valid),
     .pixel_hcount_out(camera_hcount),
     .pixel_vcount_out(camera_vcount),
     .pixel_data_out(camera_pixel));

  //----------------BEGIN NEW STUFF FOR LAB 07------------------

  // //clock domain cross (from clk_camera to clk_pixel)
  // //switching from camera clock domain to pixel clock domain early
  // //this lets us do convolution on the 74.25 MHz clock rather than the
  // //200 MHz clock domain that the camera lives on.
  // logic empty;
  // logic cdc_valid;
  // logic [15:0] cdc_pixel;
  // logic [10:0] cdc_hcount;
  // logic [9:0] cdc_vcount;

  // //cdc fifo (AXI IP). Remember to include that IP folder.
  // fifo cdc_fifo
  //   (.wr_clk(clk_camera),
  //    .full(),
  //    .din({camera_hcount, camera_vcount, camera_pixel}),
  //    .wr_en(camera_valid),

  //    .rd_clk(clk_pixel),
  //    .empty(empty),
  //    .dout({cdc_hcount, cdc_vcount, cdc_pixel}),
  //    .rd_en(1) //always read
  //   );
  // assign cdc_valid = ~empty; //watch when empty. Ready immediately if something there

  // //----
  // //Filter 0: 1280x720 convolution of gaussian blur
  // logic [10:0] f0_hcount;  //hcount from filter0 module
  // logic [9:0] f0_vcount; //vcount from filter0 module
  // logic [15:0] f0_pixel; //pixel data from filter0 module
  // logic f0_valid; //valid signals for filter0 module
  // //full resolution filter
  // filter #(.K_SELECT(1),.HRES(1280),.VRES(720))
  //   filtern(
  //   .clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .data_valid_in(cdc_valid),
  //   .pixel_data_in(cdc_pixel),
  //   .hcount_in(cdc_hcount),
  //   .vcount_in(cdc_vcount),
  //   .data_valid_out(f0_valid),
  //   .pixel_data_out(f0_pixel),
  //   .hcount_out(f0_hcount),
  //   .vcount_out(f0_vcount)
  // );

  // //----
  // logic [10:0] lb_hcount;  //hcount to filter modules
  // logic [9:0] lb_vcount; //vcount to filter modules
  // logic [15:0] lb_pixel; //pixel data to filter modules
  // logic lb_valid; //valid signals to filter modules

  // //selection logic to either go through (btn[1]=1)
  // //or bypass (btn[1]==0) the first filter
  // //in the first part of lab as you develop line buffer, you'll want to bypass
  // //since your filter won't be working, but it would be good to test the
  // //downsampling line buffer below on its own
  // always_ff @(posedge clk_pixel) begin
  //   if (btn[1])begin
  //     ds_hcount = cdc_hcount;
  //     ds_vcount = cdc_vcount;
  //     ds_pixel = cdc_pixel;
  //     ds_valid = cdc_valid;
  //   end else begin
  //     ds_hcount = f0_hcount;
  //     ds_vcount = f0_vcount;
  //     ds_pixel = f0_pixel;
  //     ds_valid = f0_valid;
  //   end
  // end

  // //----
  // //A line buffer that, in conjunction with the control signal will down sample
  // //the camera (or f0 filter) values from 1280x720 to 320x180
  // //in reality we could get by without this, but it does make things a little easier
  // //and we've also added it since it gives us a means of testing the line buffer
  // //design outside of the filter.
  // logic [2:0][15:0] lb_buffs; //grab output of down sample line buffer
  // logic ds_control; //controlling when to write (every fourth pixel and line)
  // logic [10:0] ds_hcount;  //hcount to downsample line buffer
  // logic [9:0] ds_vcount; //vcount to downsample line buffer
  // logic [15:0] ds_pixel; //pixel data to downsample line buffer
  // logic ds_valid; //valid signals to downsample line buffer
  // assign ds_control = ds_valid&&(ds_hcount[1:0]==2'b0)&&(ds_vcount[1:0]==2'b0);
  // line_buffer #(.HRES(320),
  //               .VRES(180))
  //   ds_lbuff (
  //   .clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .data_valid_in(ds_control),
  //   .pixel_data_in(ds_pixel),
  //   .hcount_in(ds_hcount[10:2]),
  //   .vcount_in(ds_vcount[9:2]),
  //   .data_valid_out(lb_valid),
  //   .line_buffer_out(lb_buffs),
  //   .hcount_out(lb_hcount),
  //   .vcount_out(lb_vcount)
  // );

  // assign lb_pixel = lb_buffs[1]; //pass on only the middle one.

  // //----
  // //Create six different filters that all exist in parallel
  // //The outputs of all six filters are fed into the unpacked arrays below:
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

  // //combine hor and vert signals from filters 4 and 5 for special signal:
  // logic [7:0] fcomb_r, fcomb_g, fcomb_b;
  // assign fcomb_r = (f_pixel[4][15:11]+f_pixel[5][15:11])>>1;
  // assign fcomb_g = (f_pixel[4][10:5]+f_pixel[5][10:5])>>1;
  // assign fcomb_b = (f_pixel[4][4:0]+f_pixel[5][4:0])>>1;

  // //------
  // //Choose which filter to use
  // //based on values of sw[2:0] select which filter output gets handed on to the
  // //next module. We must make sure to route hcount, vcount, pixels and valid signal
  // // for each module.  Could have done this with a for loop as well!  Think
  // // about it!
  // logic [10:0] fmux_hcount; //hcount from filter mux
  // logic [9:0]  fmux_vcount; //vcount from filter mux
  // logic [15:0] fmux_pixel; //pixel data from filter mux
  // logic fmux_valid; //data valid from filter mux

  // //000 Identity Kernel
  // //001 Gaussian Blur
  // //010 Sharpen
  // //011 Ridge Detection
  // //100 Sobel Y-axis Edge Detection
  // //101 Sobel X-axis Edge Detection
  // //110 Total Sobel Edge Detection
  // //111 Output of Line Buffer Directly (Helpful for debugging line buffer in first part)
  
  // //REMOVED sw[2:0]
  // always_ff @(posedge clk_pixel)begin
  //   case (3'b001)
  //     3'b000: begin
  //       fmux_hcount <= f_hcount[0];
  //       fmux_vcount <= f_vcount[0];
  //       fmux_pixel <= f_pixel[0];
  //       fmux_valid <= f_valid[0];
  //     end
  //     3'b001: begin
  //       fmux_hcount <= f_hcount[1];
  //       fmux_vcount <= f_vcount[1];
  //       fmux_pixel <= f_pixel[1];
  //       fmux_valid <= f_valid[1];
  //     end
  //     3'b010: begin
  //       fmux_hcount <= f_hcount[2];
  //       fmux_vcount <= f_vcount[2];
  //       fmux_pixel <= f_pixel[2];
  //       fmux_valid <= f_valid[2];
  //     end
  //     3'b011: begin
  //       fmux_hcount <= f_hcount[3];
  //       fmux_vcount <= f_vcount[3];
  //       fmux_pixel <= f_pixel[3];
  //       fmux_valid <= f_valid[3];
  //     end
  //     3'b100: begin
  //       fmux_hcount <= f_hcount[4];
  //       fmux_vcount <= f_vcount[4];
  //       fmux_pixel <= f_pixel[4];
  //       fmux_valid <= f_valid[4];
  //     end
  //     3'b101: begin
  //       fmux_hcount <= f_hcount[5];
  //       fmux_vcount <= f_vcount[5];
  //       fmux_pixel <= f_pixel[5];
  //       fmux_valid <= f_valid[5];
  //     end
  //     3'b110: begin
  //       fmux_hcount <= f_hcount[4];
  //       fmux_vcount <= f_vcount[4];
  //       fmux_pixel <= {fcomb_r[4:0],fcomb_g[5:0],fcomb_b[4:0]};
  //       fmux_valid <= f_valid[4]&&f_valid[5];
  //     end
  //     default: begin
  //       fmux_hcount <= lb_hcount;
  //       fmux_vcount <= lb_vcount;
  //       fmux_pixel <= lb_pixel;
  //       fmux_valid <= lb_valid;
  //     end
  //   endcase
  // end

  // localparam FB_DEPTH = 320*180;
  // localparam FB_SIZE = $clog2(FB_DEPTH);
  // logic [FB_SIZE-1:0] addra; //used to specify address to write to in frame buffer
  // logic valid_camera_mem; //used to enable writing pixel data to frame buffer
  // logic [15:0] camera_mem; //used to pass pixel data into frame buffer

  // //because the down sampling already happened upstream, there's no need to do here.
  // always_ff @(posedge clk_pixel) begin
  //   if(fmux_valid) begin
  //     addra <= fmux_hcount + fmux_vcount * 320;
  //     camera_mem <= fmux_pixel;
  //     valid_camera_mem <= 1;
  //   end else begin
  //     valid_camera_mem <= 0;
  //   end
  // end


  // // ========== LAB 5 ==========
  // // localparam FB_DEPTH = 320*180;
  // // localparam FB_SIZE = $clog2(FB_DEPTH);
  // // logic [FB_SIZE-1:0] addra; //used to specify address to write to in frame buffer

  // // logic valid_camera_mem; //used to enable writing pixel data to frame buffer
  // // logic [15:0] camera_mem; //used to pass pixel data into frame buffer


  // // //TO DO in camera part 1: ***DONE***
  // // always_ff @(posedge clk_camera)begin
  // //   //create logic to handle wriiting of camera.
  // //   //we want to down sample the data from the camera by a factor of four in both
  // //   //the x and y dimensions! TO DO

  // //   // if the camera pixel is valid and the lower 2 bits of v and h are 0 (divisible by 4)
  // //   if(camera_valid && (camera_hcount[0] == 0 && camera_hcount[1] == 0) && (camera_vcount[0] == 0 && camera_vcount[1] == 0)) begin
  // //     valid_camera_mem <= 1;      // say we have a valid input to memory
  // //     camera_mem <= camera_pixel; // set that input
  // //     addra <= ((1280-camera_hcount) >> 2) + 320*(camera_vcount >> 2);
  // //   end else begin
  // //     valid_camera_mem <= 0;      // we don't have a valid input to memory
  // //   end
  // // end
  // // ========== LAB 5 ==========


  // //frame buffer from IP
  // blk_mem_gen_0 frame_buffer (
  //   .addra(addra), //pixels are stored using this math
  //   .clka(clk_pixel),
  //   .wea(valid_camera_mem),
  //   .dina(camera_mem),
  //   .ena(1'b1),
  //   .douta(), //never read from this side
  //   .addrb(addrb),//transformed lookup pixel
  //   .dinb(16'b0),
  //   .clkb(clk_pixel),
  //   .web(1'b0),
  //   .enb(1'b1),
  //   .doutb(frame_buff_raw)
  // );
  // logic [15:0] frame_buff_raw; //data out of frame buffer (565)
  // logic [FB_SIZE-1:0] addrb; //used to lookup address in memory for reading from buffer
  // logic good_addrb; //used to indicate within valid frame for scaling
  // //brought in from lab 5...just do 4X upscale
  // always_ff @(posedge clk_pixel)begin
  //   if(!btn[2]) begin // 4x upsampling
  //     addrb <= (319-(hcount_hdmi >> 2)) + 320*(vcount_hdmi >> 2);
  //     good_addrb <= (hcount_hdmi<1280)&&(vcount_hdmi<720);
  //   end else begin //1X scaling from frame buffer
  //     addrb <= (319-hcount_hdmi) + 320*vcount_hdmi;
  //     good_addrb <= (hcount_hdmi<320) && (vcount_hdmi<180);
  //   end
  // end

  // //--------------------------END NEW STUFF-------------------

  // //split fame_buff into 3 8 bit color channels (5:6:5 adjusted accordingly)
  // //remapped frame_buffer outputs with 8 bits for r, g, b
  // logic [7:0] fb_red, fb_green, fb_blue;
  // always_ff @(posedge clk_pixel)begin
  //   fb_red <= good_addrb?{frame_buff_raw[15:11],3'b0}:8'b0;
  //   fb_green <= good_addrb?{frame_buff_raw[10:5], 2'b0}:8'b0;
  //   fb_blue <= good_addrb?{frame_buff_raw[4:0],3'b0}:8'b0;
  // end
  // // Pixel Processing pre-HDMI output



  // 1 BIT FRAME BUFFER FOR SCREEN OUTPUT:
  // output from camera
  logic [7:0] fb_red, fb_green, fb_blue;
  always_comb begin
    fb_red = {camera_pixel[15:11], 3'b0};
    fb_green = {camera_pixel[10:5], 2'b0};
    fb_blue = {camera_pixel[4:0], 3'b0};
  end

  // RGB to YCrCb

  //output of rgb to ycrcb conversion (10 bits due to module):
  logic [9:0] y_full, cr_full, cb_full; //ycrcb conversion of full pixel
  //bottom 8 of y, cr, cb conversions:
  logic [7:0] y, cr, cb; //ycrcb conversion of full pixel
  //Convert RGB of full pixel to YCrCb
  //See lecture 07 for YCrCb discussion.
  //Module has a 3 cycle latency
  rgb_to_ycrcb rgbtoycrcb_m(
    .clk_in(clk_camera), // --CHANGED CROM CLK_PIXEL
    .r_in(fb_red),
    .g_in(fb_green),
    .b_in(fb_blue),
    .y_out(y_full),
    .cr_out(cr_full),
    .cb_out(cb_full)
  );

  //channel select module (select which of six color channels to mask):
  logic [2:0] channel_sel;
  logic [7:0] selected_channel; //selected channels
  //selected_channel could contain any of the six color channels depend on selection

  //threshold module (apply masking threshold):
  logic [7:0] lower_threshold;
  logic [7:0] upper_threshold;
  logic mask; //Whether or not thresholded pixel is 1 or 0

  //Center of Mass variables (tally all mask=1 pixels for a frame and calculate their center of mass)
  // logic [10:0] x_com, x_com_calc; //long term x_com and output from module, resp
  // logic [9:0] y_com, y_com_calc; //long term y_com and output from module, resp
  logic new_com; //used to know when to update x_com and y_com ...

  //take lower 8 of full outputs.
  // treat cr and cb as signed numbers, invert the MSB to get an unsigned equivalent ( [-128,128) maps to [0,256) )
  assign y = y_full[7:0];
  assign cr = {!cr_full[7],cr_full[6:0]};
  assign cb = {!cb_full[7],cb_full[6:0]};

  // WE ALWAYS SAY CR
  assign channel_sel = 3'b101; //{1'b1, sw[4:3]}; //[3:1];
  //modified from before...ignoring red, green, blue
  // * 3'b000: green (not possible now)
  // * 3'b001: red (not possible now)
  // * 3'b010: blue (not possible now)
  // * 3'b011: not valid
  // * 3'b100: y (luminance)
  // * 3'b101: Cr (Chroma Red)
  // * 3'b110: Cb (Chroma Blue)
  // * 3'b111: not valid
  //Channel Select: Takes in the full RGB and YCrCb information and
  // chooses one of them to output as an 8 bit value
  channel_select mcs(
     .sel_in(channel_sel),
     .r_in(fb_red),    //: needs to use pipelined signal (PS1)
     .g_in(fb_green),  //: needs to use pipelined signal (PS1)
     .b_in(fb_blue),   //: needs to use pipelined signal (PS1)
     .y_in(y),
     .cr_in(cr),
     .cb_in(cb),
     .channel_out(selected_channel)
  );

  //threshold values used to determine what value  passes:
  // assign lower_threshold = 8'b1010_0000;
  // assign upper_threshold = 8'b1111_0000;
  assign lower_threshold = {sw[11:8],4'b0};
  assign upper_threshold = {sw[15:12],4'b1111};

  //Thresholder: Takes in the full selected channedl and
  //based on upper and lower bounds provides a binary mask bit
  // * 1 if selected channel is within the bounds (inclusive)
  // * 0 if selected channel is not within the bounds

  assign mask = (selected_channel > lower_threshold) && (selected_channel <= upper_threshold);
  // threshold mt(
  //    .clk_in(clk_pixel),
  //    .rst_in(sys_rst_pixel),
  //    .pixel_in(selected_channel),
  //    .lower_bound_in(lower_threshold),
  //    .upper_bound_in(upper_threshold),
  //    .mask_out(mask) //single bit if pixel within mask.
  // );





  // 1 BIT CAMERA MASK
  localparam FB_DEPTH = 320*180;
  localparam FB_SIZE = $clog2(FB_DEPTH);
  logic [FB_SIZE-1:0] addra; //used to specify address to write to in frame buffer
  logic valid_camera_mem;
  logic camera_mem;

  localparam CAM_BUFF_WIDTH = 3;
  logic [CAM_BUFF_WIDTH-1:0][10:0] camera_hcount_buff;
  logic [CAM_BUFF_WIDTH-1:0][9:0] camera_vcount_buff;
  logic [CAM_BUFF_WIDTH-1:0] camera_valid_buff;

  always_ff @(posedge clk_camera) begin
    camera_hcount_buff[0] <= camera_hcount;
    camera_hcount_buff[1] <= camera_hcount_buff[0];
    camera_hcount_buff[2] <= camera_hcount_buff[1];
    // camera_hcount_buff[3] <= camera_hcount_buff[2];

    camera_vcount_buff[0] <= camera_vcount;
    camera_vcount_buff[1] <= camera_vcount_buff[0];
    camera_vcount_buff[2] <= camera_vcount_buff[1];
    // camera_vcount_buff[3] <= camera_vcount_buff[2];

    camera_valid_buff[0] <= camera_valid;
    camera_valid_buff[1] <= camera_valid_buff[0];
    camera_valid_buff[2] <= camera_valid_buff[1];
    // camera_valid_buff[3] <= camera_valid_buff[2]; 
  end


  always_ff @(posedge clk_camera)begin
    //create logic to handle wriiting of camera.
    //we want to down sample the data from the camera by a factor of four in both
    //the x and y dimensions! TO DO

    // if the camera pixel is valid and the lower 2 bits of v and h are 0 (divisible by 4)
    if(camera_valid_buff[2] && (camera_hcount_buff[2][0] == 0 && camera_hcount_buff[2][1] == 0) && (camera_vcount_buff[2][0] == 0 && camera_vcount_buff[2][1] == 0)) begin
      valid_camera_mem <= 1;      // say we have a valid input to memory
      camera_mem <= mask; // set that input
      addra <= ((1280-camera_hcount_buff[2]) >> 2) + 320*(camera_vcount_buff[2] >> 2);
    end else begin
      valid_camera_mem <= 0;      // we don't have a valid input to memory
    end
  end



  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(FB_DEPTH))
    frame_buffer
    (
    // PORT A
    .addra(addra), //pixels are stored using this math
    .clka(clk_camera),
    .wea(valid_camera_mem),
    .dina(camera_mem),
    .ena(1'b1),
    .douta(), //never read from this side
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(addrb),//transformed lookup pixel
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(frame_buff_raw),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );

  logic frame_buff_raw;
  logic [FB_SIZE-1:0] addrb;
  logic good_addrb;

  always_ff @(posedge clk_pixel)begin
    addrb <= (319-(hcount_hdmi >> 2)) + 320*(vcount_hdmi >> 2);
    good_addrb <= (hcount_hdmi<1280)&&(vcount_hdmi<720);
  end





  logic [6:0] ss_c;

  logic [1:0][15:0] cap_largest_labels;
  logic [1:0][15:0] cap_largest_x_coms, cap_largest_y_coms;

  always_comb begin
    if(ccl_pixel_valid) begin
      cap_largest_labels[0] = largest_labels[0];
      cap_largest_labels[1] = largest_labels[1];

      cap_largest_x_coms[0] = largest_x_coms[0];
      cap_largest_x_coms[1] = largest_x_coms[1];
      cap_largest_y_coms[0] = largest_y_coms[0];
      cap_largest_y_coms[1] = largest_y_coms[1];
    end
  end

  //modified version of seven segment display for showing
  // thresholds and selected channel
  // special customized version
  lab05_ssc mssc(.clk_in(clk_pixel),
                 .rst_in(sys_rst_pixel),
                 .lt_in((perim_temp[0] > 8'hFF)? 8'hFF : perim_temp[0][7:0]), // changed from lower, upper threshold
                 .ut_in((area_temp[0] > 8'hFF)? 8'hFF : area_temp[0][7:0]),
                 .channel_sel_in((circ_temp[0] > 8'hFF)? 8'hFF : circ_temp[0][7:0]),
                 //.channel_sel_in(max_seen_label),
                 .cat_out(ss_c),
                 .an_out({ss0_an, ss1_an})
  );
  assign ss0_c = ss_c; //control upper four digit's cathodes!
  assign ss1_c = ss_c; //same as above but for lower four digits!









  //Center of Mass Calculation:
  //using x_com_calc and y_com_calc values
  //Center of Mass:
  // center_of_mass com_m(
  //   .clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(hcount_hdmi),  //: needs to use pipelined signal! (PS3)
  //   .y_in(vcount_hdmi), //: needs to use pipelined signal! (PS3)
  //   .valid_in(mask), //aka threshold
  //   .tabulate_in((nf_hdmi)),
  //   .x_out(x_com_calc),
  //   .y_out(y_com_calc),
  //   .area_out(area_raw),
  //   .valid_out(new_com)
  // );








  // NOW USING CCL:
  logic ccl_valid_out;
  logic ccl_busy_out;
  logic [1:0][15:0] largest_labels;
  logic [1:0][15:0] largest_areas;
  logic [1:0][15:0] largest_x_coms;
  logic [1:0][15:0] largest_y_coms;
  logic [10:0] ccl_x_out;
  logic [9:0] ccl_y_out;
  logic [15:0] ccl_pixel_label;
  logic ccl_pixel_valid;
  logic [7:0] ccl_state;
  logic [7:0] curr_label_out;
  logic [7:0] min_label_out;
  logic [7:0] pix_label_out;

  ccl #(
    .WIDTH(320),        // Horizontal resolution
    .HEIGHT(180),       // Vertical resolution
    .MAX_LABELS(64),    // how many labels? hopefully this leads to no noise
    .MIN_AREA(50)       // Minimum blob size to retain
  ) my_ccl (
  .clk_in(clk_pixel),    
  .rst_in(sys_rst_pixel),          
  .x_in(hcount_hdmi >> 2),       
  .y_in(vcount_hdmi >> 2), // TODO: if something is fucked up, this shifting could very well be why
  .mask_in(frame_buff_raw),
  .new_frame_in(hcount_hdmi == 0 && vcount_hdmi == 0 && !moore_busy_0 && !moore_busy_1 /* && !moore_busy_2 */),         
  .valid_in(hcount_hdmi[1:0] == 1 && vcount_hdmi[1:0] == 1), // only give valid once every 4 pixels sure

  .valid_out(ccl_valid_out),
  .busy_out(ccl_busy_out),

  .blob_labels(largest_labels),
  .x_out(ccl_x_out),
  .y_out(ccl_y_out),
  .area_out(largest_areas),
  .com_x_out(largest_x_coms),
  .com_y_out(largest_y_coms),
  .curr_pix_label(ccl_pixel_label),
  .curr_pix_valid(ccl_pixel_valid),
  .curr_state(ccl_state),
  .curr_label_out(curr_label_out),
  .min_label_out(min_label_out),
  .pix_label_out(pix_label_out)
  );



  // logic to handle whether addresses should come from moore or ccl
  logic [7:0][15:0] ccl_moore_addr_0;
  logic [7:0][15:0] ccl_moore_addr_1;
  // logic [7:0][15:0] ccl_moore_addr_2;
  logic [2:0][2:0] ccl_moore_pixels_0;
  logic [2:0][2:0] ccl_moore_pixels_1;
  // logic [2:0][2:0] ccl_moore_pixels_2;

  always_comb begin
    // if(sys_rst_pixel) begin
    //   ccl_moore_addr_0 = 0;
    //   ccl_moore_addr_1 = 0;
    //   // ccl_moore_addr_2 = 0;
    // end else begin
    if(!moore_busy_0) begin
      //fb0
      ccl_moore_addr_0[0] = ccl_x_out + ccl_y_out*320;
      ccl_moore_addr_0[2] = ccl_moore_addr_0[0];
      ccl_moore_addr_0[4] = ccl_moore_addr_0[0];
      ccl_moore_addr_0[6] = ccl_moore_addr_0[0];

      ccl_moore_addr_0[1] = 0;
      ccl_moore_addr_0[3] = 0;
      ccl_moore_addr_0[5] = 0;
      ccl_moore_addr_0[7] = 0;




      // //fb2
      // ccl_moore_addr_2[0] = ccl_x_out + ccl_y_out*320;
      // ccl_moore_addr_2[2] = ccl_moore_addr_2[0];
      // ccl_moore_addr_2[4] = ccl_moore_addr_2[0];
      // ccl_moore_addr_2[6] = ccl_moore_addr_2[0];

      // ccl_moore_addr_2[1] = 0;
      // ccl_moore_addr_2[3] = 0;
      // ccl_moore_addr_2[5] = 0;
      // ccl_moore_addr_2[7] = 0;

    end else begin
      ccl_moore_addr_0[0] = moore_addrs_0[0];
      ccl_moore_addr_0[1] = moore_addrs_0[1];
      ccl_moore_addr_0[2] = moore_addrs_0[2];
      ccl_moore_addr_0[3] = moore_addrs_0[3];
      ccl_moore_addr_0[4] = moore_addrs_0[4];
      ccl_moore_addr_0[5] = moore_addrs_0[5];
      ccl_moore_addr_0[6] = moore_addrs_0[6];
      ccl_moore_addr_0[7] = moore_addrs_0[7];


      // ccl_moore_addr_2[0] = moore_addrs_2[0];
      // ccl_moore_addr_2[1] = moore_addrs_2[1];
      // ccl_moore_addr_2[2] = moore_addrs_2[2];
      // ccl_moore_addr_2[3] = moore_addrs_2[3];
      // ccl_moore_addr_2[4] = moore_addrs_2[4];
      // ccl_moore_addr_2[5] = moore_addrs_2[5];
      // ccl_moore_addr_2[6] = moore_addrs_2[6];
      // ccl_moore_addr_2[7] = moore_addrs_2[7];
    end

    if(!moore_busy_1) begin

      // // fb1
      ccl_moore_addr_1[0] = ccl_x_out + ccl_y_out*320;
      ccl_moore_addr_1[2] = ccl_moore_addr_1[0];
      ccl_moore_addr_1[4] = ccl_moore_addr_1[0];
      ccl_moore_addr_1[6] = ccl_moore_addr_1[0];

      ccl_moore_addr_1[1] = 0;
      ccl_moore_addr_1[3] = 0;
      ccl_moore_addr_1[5] = 0;
      ccl_moore_addr_1[7] = 0;

    end else begin

      
      ccl_moore_addr_1[0] = moore_addrs_1[0];
      ccl_moore_addr_1[1] = moore_addrs_1[1];
      ccl_moore_addr_1[2] = moore_addrs_1[2];
      ccl_moore_addr_1[3] = moore_addrs_1[3];
      ccl_moore_addr_1[4] = moore_addrs_1[4];
      ccl_moore_addr_1[5] = moore_addrs_1[5];
      ccl_moore_addr_1[6] = moore_addrs_1[6];
      ccl_moore_addr_1[7] = moore_addrs_1[7];

    end
    // end
  end




  // FBs to hold Moore data for Moore 0
  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180) /*,
    .RAM_PERFORMANCE("HIGH_LATENCY"),
    .INIT_FILE("moore_bram_test_.mem") 
    */)
    moore_fb_00
    (
    // PORT A
    .addra(ccl_moore_addr_0[0]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[0]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_0[0][0]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_0[1]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_0[0][1]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );

  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180) /*, 
    .RAM_PERFORMANCE("HIGH_LATENCY"),
    .INIT_FILE("moore_bram_test_circle.mem") 
    */)
    moore_fb_01
    (
    // PORT A
    .addra(ccl_moore_addr_0[2]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[0]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_0[0][2]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_0[3]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_0[1][2]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );

  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180) /*, 
    .RAM_PERFORMANCE("HIGH_LATENCY"),
    .INIT_FILE("moore_bram_test_circle.mem") 
    */)
    moore_fb_02
    (
    // PORT A
    .addra(ccl_moore_addr_0[4]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[0]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_0[2][2]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_0[5]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_0[2][1]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );

  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180) /*,
    .RAM_PERFORMANCE("HIGH_LATENCY"),
    .INIT_FILE("moore_bram_test_circle.mem") 
    */)
    moore_fb_03
    (
    // PORT A
    .addra(ccl_moore_addr_0[6]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[0]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_0[2][0]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_0[7]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_0[1][0]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );







// MOORE FB 1
xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180))
    moore_fb_10
    (
    // PORT A
    .addra(ccl_moore_addr_1[0]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[1]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_1[0][0]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_1[1]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_1[0][1]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );

  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180))
    moore_fb_11
    (
    // PORT A
    .addra(ccl_moore_addr_1[2]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[1]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_1[0][2]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_1[3]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_1[1][2]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );

  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180))
    moore_fb_12
    (
    // PORT A
    .addra(ccl_moore_addr_1[4]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[1]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_1[2][2]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_1[5]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_1[2][1]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );

  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180))
    moore_fb_13
    (
    // PORT A
    .addra(ccl_moore_addr_1[6]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[1]),
    .ena(1'b1),
    .douta(ccl_moore_pixels_1[2][0]),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb(ccl_moore_addr_1[7]),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(ccl_moore_pixels_1[1][0]),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );






  // FB 2
  // xilinx_true_dual_port_read_first_2_clock_ram
  //   #(.RAM_WIDTH(1),
  //   .RAM_DEPTH(320*180))
  //   moore_fb_20
  //   (
  //   // PORT A
  //   .addra(ccl_moore_addr_2[0]), 
  //   .clka(clk_pixel),
  //   .wea(ccl_pixel_valid),
  //   .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[2]),
  //   .ena(1'b1),
  //   .douta(ccl_moore_pixels_2[0][0]),
  //   .rsta(sys_rst_pixel),
  //   .regcea(1'b1),

  //   // PORT B
  //   .addrb(ccl_moore_addr_2[1]),
  //   .dinb(1'b0),
  //   .clkb(clk_pixel),
  //   .web(1'b0),
  //   .enb(1'b1),
  //   .doutb(ccl_moore_pixels_2[0][1]),
  //   .rstb(sys_rst_pixel),
  //   .regceb(1'b1)
  //   );

  // xilinx_true_dual_port_read_first_2_clock_ram
  //   #(.RAM_WIDTH(1),
  //   .RAM_DEPTH(320*180))
  //   moore_fb_21
  //   (
  //   // PORT A
  //   .addra(ccl_moore_addr_2[2]), 
  //   .clka(clk_pixel),
  //   .wea(ccl_pixel_valid),
  //   .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[2]),
  //   .ena(1'b1),
  //   .douta(ccl_moore_pixels_2[0][2]),
  //   .rsta(sys_rst_pixel),
  //   .regcea(1'b1),

  //   // PORT B
  //   .addrb(ccl_moore_addr_2[3]),
  //   .dinb(1'b0),
  //   .clkb(clk_pixel),
  //   .web(1'b0),
  //   .enb(1'b1),
  //   .doutb(ccl_moore_pixels_2[1][2]),
  //   .rstb(sys_rst_pixel),
  //   .regceb(1'b1)
  //   );

  // xilinx_true_dual_port_read_first_2_clock_ram
  //   #(.RAM_WIDTH(1),
  //   .RAM_DEPTH(320*180))
  //   moore_fb_22
  //   (
  //   // PORT A
  //   .addra(ccl_moore_addr_2[4]), 
  //   .clka(clk_pixel),
  //   .wea(ccl_pixel_valid),
  //   .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[2]),
  //   .ena(1'b1),
  //   .douta(ccl_moore_pixels_2[2][2]),
  //   .rsta(sys_rst_pixel),
  //   .regcea(1'b1),

  //   // PORT B
  //   .addrb(ccl_moore_addr_2[5]),
  //   .dinb(1'b0),
  //   .clkb(clk_pixel),
  //   .web(1'b0),
  //   .enb(1'b1),
  //   .doutb(ccl_moore_pixels_2[2][1]),
  //   .rstb(sys_rst_pixel),
  //   .regceb(1'b1)
  //   );

  // xilinx_true_dual_port_read_first_2_clock_ram
  //   #(.RAM_WIDTH(1),
  //   .RAM_DEPTH(320*180))
  //   moore_fb_23
  //   (
  //   // PORT A
  //   .addra(ccl_moore_addr_2[6]), 
  //   .clka(clk_pixel),
  //   .wea(ccl_pixel_valid),
  //   .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[2]),
  //   .ena(1'b1),
  //   .douta(ccl_moore_pixels_2[2][0]),
  //   .rsta(sys_rst_pixel),
  //   .regcea(1'b1),

  //   // PORT B
  //   .addrb(ccl_moore_addr_2[7]),
  //   .dinb(1'b0),
  //   .clkb(clk_pixel),
  //   .web(1'b0),
  //   .enb(1'b1),
  //   .doutb(ccl_moore_pixels_2[1][0]),
  //   .rstb(sys_rst_pixel),
  //   .regceb(1'b1)
  //   );










  // for writing mask to display
  logic mask_fb_0;
  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180))
    moore_fb_04
    (
    // PORT A
    .addra(ccl_moore_addr_0[0]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[0]),
    .ena(1'b1),
    .douta(),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb((hcount_hdmi >> 2) + (vcount_hdmi >> 2)*320),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(mask_fb_0),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );


  logic mask_fb_1;
  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(1),
    .RAM_DEPTH(320*180))
    moore_fb_14
    (
    // PORT A
    .addra(ccl_moore_addr_1[0]), 
    .clka(clk_pixel),
    .wea(ccl_pixel_valid),
    .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[1]),
    .ena(1'b1),
    .douta(),
    .rsta(sys_rst_pixel),
    .regcea(1'b1),

    // PORT B
    .addrb((hcount_hdmi >> 2) + (vcount_hdmi >> 2)*320),
    .dinb(1'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(mask_fb_1),
    .rstb(sys_rst_pixel),
    .regceb(1'b1)
    );

  // logic mask_fb_2;
  // xilinx_true_dual_port_read_first_2_clock_ram
  //   #(.RAM_WIDTH(1),
  //   .RAM_DEPTH(320*180))
  //   moore_fb_24
  //   (
  //   // PORT A
  //   .addra(ccl_moore_addr_2[0]), 
  //   .clka(clk_pixel),
  //   .wea(ccl_pixel_valid),
  //   .dina(ccl_pixel_label > 0 && ccl_pixel_label == largest_labels[2]),
  //   .ena(1'b1),
  //   .douta(),
  //   .rsta(sys_rst_pixel),
  //   .regcea(1'b1),

  //   // PORT B
  //   .addrb(hcount_hdmi + vcount_hdmi*320),
  //   .dinb(1'b0),
  //   .clkb(clk_pixel),
  //   .web(1'b0),
  //   .enb(1'b1),
  //   .doutb(mask_fb_2),
  //   .rstb(sys_rst_pixel),
  //   .regceb(1'b1)
  //   );


  





  






  logic [7:0][15:0] moore_addrs_0;
  logic [15:0] perimeter_0;
  logic moore_busy_0;
  logic moore_valid_0;
  logic [10:0] moore_scan_x_0, moore_scan_x_1;
  logic [9:0] moore_scan_y_0, moore_scan_y_1;

  moore_neighbor_tracing_ccl #(
    .WIDTH(320),
    .HEIGHT(180))
    mnt_ccl_0 
    (
    .clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .ready_in(ccl_valid_out),
    .pixel_upleft(ccl_moore_pixels_0[0][0]), // frame buffer direct outputs: neighboring pixels
    .pixel_up(ccl_moore_pixels_0[0][1]),
    .pixel_upright(ccl_moore_pixels_0[0][2]),
    .pixel_right(ccl_moore_pixels_0[1][2]),
    .pixel_downright(ccl_moore_pixels_0[2][2]),
    .pixel_down(ccl_moore_pixels_0[2][1]),
    .pixel_downleft(ccl_moore_pixels_0[2][0]),
    .pixel_left(ccl_moore_pixels_0[1][0]),
    .addra_1(moore_addrs_0[0]),
    .addrb_1(moore_addrs_0[1]),
    .addra_2(moore_addrs_0[2]),
    .addrb_2(moore_addrs_0[3]),
    .addra_3(moore_addrs_0[4]),
    .addrb_3(moore_addrs_0[5]),
    .addra_4(moore_addrs_0[6]),
    .addrb_4(moore_addrs_0[7]),
                         
    .perimeter(perimeter_0),
    .busy_out(moore_busy_0),
    .valid_out(moore_valid_0),

    .scan_x_out(moore_scan_x_0),
    .scan_y_out(moore_scan_y_0)
  );



  logic [7:0][15:0] moore_addrs_1;
  logic [15:0] perimeter_1;
  logic moore_busy_1;
  logic moore_valid_1;
  moore_neighbor_tracing_ccl #(
    .WIDTH(320),
    .HEIGHT(180))
    mnt_ccl_1
    (
    .clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .ready_in(ccl_valid_out),
    .pixel_upleft(ccl_moore_pixels_1[0][0]), // frame buffer direct outputs: neighboring pixels
    .pixel_up(ccl_moore_pixels_1[0][1]),
    .pixel_upright(ccl_moore_pixels_1[0][2]),
    .pixel_right(ccl_moore_pixels_1[1][2]),
    .pixel_downright(ccl_moore_pixels_1[2][2]),
    .pixel_down(ccl_moore_pixels_1[2][1]),
    .pixel_downleft(ccl_moore_pixels_1[2][0]),
    .pixel_left(ccl_moore_pixels_1[1][0]),
    .addra_1(moore_addrs_1[0]),
    .addrb_1(moore_addrs_1[1]),
    .addra_2(moore_addrs_1[2]),
    .addrb_2(moore_addrs_1[3]),
    .addra_3(moore_addrs_1[4]),
    .addrb_3(moore_addrs_1[5]),
    .addra_4(moore_addrs_1[6]),
    .addrb_4(moore_addrs_1[7]),
                         
    .perimeter(perimeter_1),
    .busy_out(moore_busy_1),
    .valid_out(moore_valid_1),
  
  	.scan_x_out(moore_scan_x_1),
    .scan_y_out(moore_scan_y_1)
  );




  // logic [7:0][15:0] moore_addrs_2;
  // logic [15:0] perimeter_2;
  // logic moore_busy_2;
  // logic moore_valid_2;
  // moore_neighbor_tracing_ccl #(
  //   .WIDTH(320),
  //   .HEIGHT(180))
  //   mnt_ccl_2
  //   (
  //   .clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .ready_in(ccl_valid_out),
  //   .pixel_upleft(ccl_moore_pixels_2[0][0]), // frame buffer direct outputs: neighboring pixels
  //   .pixel_up(ccl_moore_pixels_2[0][1]),
  //   .pixel_upright(ccl_moore_pixels_2[0][2]),
  //   .pixel_right(ccl_moore_pixels_2[1][2]),
  //   .pixel_downright(ccl_moore_pixels_2[2][2]),
  //   .pixel_down(ccl_moore_pixels_2[2][1]),
  //   .pixel_downleft(ccl_moore_pixels_2[2][0]),
  //   .pixel_left(ccl_moore_pixels_2[1][0]),
  //   .addra_1(moore_addrs_2[0]),
  //   .addrb_1(moore_addrs_2[1]),
  //   .addra_2(moore_addrs_2[2]),
  //   .addrb_2(moore_addrs_2[3]),
  //   .addra_3(moore_addrs_2[4]),
  //   .addrb_3(moore_addrs_2[5]),
  //   .addra_4(moore_addrs_2[6]),
  //   .addrb_4(moore_addrs_2[7]),
                         
  //   .perimeter(perimeter_2),
  //   .busy_out(moore_busy_2),
  //   .valid_out(moore_valid_2)
  // );





  logic [15:0] area_0, area_1;//, area_2;

  logic [10:0] x_com_calc_0, x_com_calc_1; //, x_com_calc_2; //long term x_com and output from module, resp
  logic [9:0] y_com_calc_0, y_com_calc_1; //, y_com_calc_2; //long term y_com and output from module, resp

  // SET COM X AND Y AND VALID BASED ON THE OUTPUTS FROM CCL[0]
  // *** THIS SHOULD BE REPLACED LATER WHEN WE DECIDE TO DETECT MORE THAN 1 SHAPE
  always_comb begin
    // area = (area_raw >> 4);

    if(ccl_pixel_valid || ccl_valid_out) begin
      area_0 = largest_areas[0];
      area_1 = largest_areas[1];
      // area_2 = largest_areas[2];

      x_com_calc_0 = largest_x_coms[0] << 2; // shift over by 4x to display on screen properly
      y_com_calc_0 = largest_y_coms[0] << 2;

      x_com_calc_1 = largest_x_coms[1] << 2;
      y_com_calc_1 = largest_y_coms[1] << 2;

      // x_com_calc_2 = largest_x_coms[2];
      // y_com_calc_2 = largest_y_coms[2];

    end

    new_com = ccl_valid_out; // just set this because it works with previous code
  end




  logic com_waiting_0, com_waiting_1; //, com_waiting_2;
  logic [31:0] area_stored_0, area_stored_1; //, area_stored_2;
  logic moore_waiting_0, moore_waiting_1; //, moore_waiting_2;
  logic [31:0] perimeter_stored_0, perimeter_stored_1; //, perimeter_stored_2;

  logic [15:0] area_saved_0, area_saved_1; //, area_saved_2;
  logic [15:0] perimeter_saved_0, perimeter_saved_1; //, perimeter_saved_2;
  
  logic both_valid_0, both_valid_1; //, both_valid_2;
  logic circularity_busy_0, circularity_busy_1; //, circularity_busy_2;

  // using this for now
  always_ff @(posedge clk_pixel)begin
    if (new_com && !both_valid_0 && !circularity_busy_0) begin
      com_waiting_0 <= 1;
      area_stored_0 <= area_0;
    end
    if (moore_valid_0 && !both_valid_0 && !circularity_busy_0) begin
      moore_waiting_0 <= 1;
      perimeter_stored_0 <= perimeter_0;
    end
    if (com_waiting_0 && moore_waiting_0) begin
      both_valid_0 <= 1;
      com_waiting_0 <= 0;
      moore_waiting_0 <= 0;
    end
    if (both_valid_0 && !circularity_busy_0) begin
      both_valid_0 <= 0;
      area_saved_0 <= area_stored_0;
      perimeter_saved_0 <= perimeter_stored_0;
    end
  end


  always_ff @(posedge clk_pixel) begin
    if (new_com && !both_valid_1 && !circularity_busy_1) begin
        com_waiting_1 <= 1;
        area_stored_1 <= area_1;
    end
    if (moore_valid_1 && !both_valid_1 && !circularity_busy_1) begin
        moore_waiting_1 <= 1;
        perimeter_stored_1 <= perimeter_1;
    end
    if (com_waiting_1 && moore_waiting_1) begin
        both_valid_1 <= 1;
        com_waiting_1 <= 0;
        moore_waiting_1 <= 0;
    end
    if (both_valid_1 && !circularity_busy_1) begin
        both_valid_1 <= 0;
        area_saved_1 <= area_stored_1;
        perimeter_saved_1 <= perimeter_stored_1;
    end
  end


  // always_ff @(posedge clk_pixel) begin
  //   if (new_com && !both_valid_2 && !circularity_busy_2) begin
  //       com_waiting_2 <= 1;
  //       area_stored_2 <= area_2;
  //   end
  //   if (moore_valid_2 && !both_valid_2 && !circularity_busy_2) begin
  //       moore_waiting_2 <= 1;
  //       perimeter_stored_2 <= perimeter_2;
  //   end
  //   if (com_waiting_2 && moore_waiting_2) begin
  //       both_valid_2 <= 1;
  //       com_waiting_2 <= 0;
  //       moore_waiting_2 <= 0;
  //   end
  //   if (both_valid_2 && !circularity_busy_2) begin
  //       both_valid_2 <= 0;
  //       area_saved_2 <= area_stored_2;
  //       perimeter_saved_2 <= perimeter_stored_2;
  //   end
  // end








  logic [31:0] dividend_0, dividend_1; //, dividend_2;
  logic [31:0] divisor_0, divisor_1; //, divisor_2;
  logic [31:0] circularity_raw_0, circularity_raw_1; //, circularity_raw_2;
  assign dividend_0 = 4 * area_stored_0 * 314;
  assign dividend_1 = 4 * area_stored_1 * 314;
  // assign dividend_2 = 4 * area_stored_2 * 314;

  assign divisor_0 = perimeter_stored_0 * perimeter_stored_0; // area is 16* what it should be --> divide out without losing information
  assign divisor_1 = perimeter_stored_1 * perimeter_stored_1; // area is 16* what it should be --> divide out without losing information
  // assign divisor_2 = perimeter_stored_2 * perimeter_stored_2; // area is 16* what it should be --> divide out without losing information



  logic circularity_valid_0, circularity_valid_1; //, circularity_valid_2;

  divider
    #(.WIDTH(32)
    ) my_divider_0
    (.clk_in(clk_pixel),
        .rst_in(sys_rst_pixel),
        .dividend_in(dividend_0),
        .divisor_in(divisor_0),
        .data_valid_in(both_valid_0 && !circularity_busy_0),
        .quotient_out(circularity_raw_0), // outputs
        .remainder_out(),
        .data_valid_out(circularity_valid_0),
        .error_out(),
        .busy_out(circularity_busy_0)
    );

  divider
    #(.WIDTH(32)
    ) my_divider_1
    (.clk_in(clk_pixel),
        .rst_in(sys_rst_pixel),
        .dividend_in(dividend_1),
        .divisor_in(divisor_1),
        .data_valid_in(both_valid_1 && !circularity_busy_1),
        .quotient_out(circularity_raw_1), // outputs
        .remainder_out(),
        .data_valid_out(circularity_valid_1),
        .error_out(),
        .busy_out(circularity_busy_1)
    );

  // divider
  //   #(.WIDTH(32)
  //   ) my_divider_2
  //   (.clk_in(clk_pixel),
  //       .rst_in(sys_rst_pixel),
  //       .dividend_in(dividend_2),
  //       .divisor_in(divisor_2),
  //       .data_valid_in(both_valid_2 && !circularity_busy_2),
  //       .quotient_out(circularity_raw_2), // outputs
  //       .remainder_out(),
  //       .data_valid_out(circularity_valid_2),
  //       .error_out(),
  //       .busy_out(circularity_busy_2)
  //   );





  logic [7:0] circularity_0, circularity_1; //, circularity_2;
  logic [1:0] shape_0, shape_1; //, shape_2;

  logic [15:0] circ_temp [4:0];     // 2D array for circ_temp[stage]
  logic [15:0] area_temp [4:0];
  logic [15:0] perim_temp [4:0];

  logic [15:0] circ_temp_0, circ_temp_1; //, perim_temp_2;
  logic [15:0] area_temp_0, area_temp_1; //, perim_temp_2;
  logic [15:0] perim_temp_0, perim_temp_1; //, perim_temp_2;

  always_ff @(posedge clk_pixel) begin
    if(circularity_valid_0 && circularity_raw_0 < 200) begin // throw out obviously garbage circularity values --> should be in the 0-100 range (but circle can be a bit bigger)
      circularity_0 <= circularity_raw_0;
      circ_temp_0 <= circularity_raw_0;
      area_temp_0 <= area_saved_0; // area is 16* what it should be because the screen is 4x larger in both directions
      perim_temp_0 <= perimeter_saved_0;

      if(sw[4:3] == 2'b01) begin
        circ_temp[0] <= circularity_raw_0;
        area_temp[0] <= {8'b0, area_saved_0[15:8]};         // lower 8 bits of area and perim were always outputting FF --> upper 8 are more important
        perim_temp[0] <= {8'b0, perimeter_saved_0[15:8]};
      end
    end

    if(circularity_valid_1 && circularity_raw_1 < 200) begin // throw out obviously garbage circularity values --> should be in the 0-100 range (but circle can be a bit bigger)
      circularity_1 <= circularity_raw_1;
      circ_temp_1 <= circularity_raw_1;
      area_temp_1 <= area_saved_1;
      perim_temp_1 <= perimeter_saved_1;

      if(sw[4:3] == 2'b11) begin
        circ_temp[0] <= circularity_raw_1;
        area_temp[0] <= {8'b0, area_saved_1[15:8]};
        perim_temp[0] <= {8'b0, perimeter_saved_1[15:8]};
      end
    end


    if(sw[4:3] == 2'b00) begin
      circ_temp[0] <= 0;
      area_temp[0] <= 0;
      perim_temp[0] <= 0;
    end else if (sw[4:3] == 2'b10) begin // TODO: Remove this temp state
      // if(ccl_pixel_valid || ccl_valid_out) begin
      // area_temp[0] <= ccl_pixel_label;
      // circ_temp[0] <= largest_labels[0];
      // perim_temp[0] <= ccl_pixel_valid;


      // area_temp[0] <= area_temp_0; //{3'b0, moore_busy_0, 3'b0, ccl_busy_out};
      // perim_temp[0] <= 8'hCD;
      // circ_temp[0] <= {3'b0, moore_busy_0, 3'b0, ccl_busy_out};

      area_temp[0] <= {1'b0, moore_scan_x_0[10:4]};
      perim_temp[0] <= {moore_scan_x_0[3:0], 2'b0, moore_scan_y_0[9:8]};
      circ_temp[0] <= moore_scan_y_0[7:0];

      // end
    end



    // if(circularity_valid_2 && circularity_raw_2 < 200) begin // throw out obviously garbage circularity values --> should be in the 0-100 range (but circle can be a bit bigger)
    //   circularity_2 <= circularity_raw_2;
    //   perim_temp_2 <= perimeter_saved_2;
    // end

  end



  parameter CIRC_MIN = 8'h80;
  parameter SQ_MIN = 8'h50;
  parameter TRI_MIN = 8'h49;

  always_comb begin
    if (circularity_0 > CIRC_MIN)begin
      shape_0 = 0; // circle
    end else if (circularity_0 > SQ_MIN)begin
      shape_0 = 1; // square
    end else if (circularity_0 > TRI_MIN)begin
      shape_0 = 2; // triangle
    end else begin
      shape_0 = 3; // plus
    end
    

    if (circularity_1 > CIRC_MIN) begin
      shape_1 = 0; // circle
    end else if (circularity_1 > SQ_MIN) begin
      shape_1 = 1; // square
    end else if (circularity_1 > TRI_MIN) begin
      shape_1 = 2; // triangle
    end else begin
      shape_1 = 3; // plus
    end


    // if (circularity_2 > CIRC_MIN) begin
    //   shape_2 = 0; // circle
    // end else if (circularity_2 > SQ_MIN) begin
    //   shape_2 = 1; // square
    // end else if (circularity_2 > TRI_MIN) begin
    //   shape_2 = 2; // triangle
    // end else begin
    //   shape_2 = 3; // plus
    // end

  end



  //image_sprite output:
  logic [7:0] img_red, img_green, img_blue;
  assign img_red = 0;
  assign img_green = 0;
  assign img_blue = 0;
  logic draw_sprite;
  //image sprite removed to keep builds focused.

  //if any of the draw_outs from any of the sprite modules are true, then set draw_out to be true
  always_comb begin                                                                                    // commenting this out removes all of the upstream label[3] logic
    if ((draw_classifier_0 /*&& !(perim_temp_0 == 0)*/ && !(x_com_0 == 0 && y_com_0 == 0)) || (draw_classifier_1 && !(x_com_1 == 0 && y_com_1 == 0) /*&& !(perim_temp_1 == 0)*/) || /*(draw_classifier_2 && !(perim_temp_2 == 0)) ||*/ draw_number[0] || draw_number[1] || draw_number[2] || draw_number[3] || draw_number[4] || draw_number[5] || draw_number[6] || draw_number[7] || draw_number[8] || draw_number[9] || draw_number[10] || draw_number[11]) begin
      draw_sprite = 1;
    end else begin
      draw_sprite = 0;
    end
  end




  //grab logic for above
  //update center of mass x_com, y_com based on new_com signal

  logic [10:0] x_com_0, x_com_1; //, x_com_2; //long term x_com and output from module, resp
  logic [9:0] y_com_0, y_com_1; //, y_com_2; //long term y_com and output from module, resp

  always_ff @(posedge clk_pixel)begin
    if (sys_rst_pixel)begin
      x_com_0 <= 0;
      y_com_0 <= 0;

      x_com_1 <= 0;
      y_com_1 <= 0;

      // x_com_2 <= 0;
      // y_com_2 <= 0;
    end if(new_com)begin
      x_com_0 <= x_com_calc_0;
      y_com_0 <= y_com_calc_0;

      x_com_1 <= x_com_calc_1;
      y_com_1 <= y_com_calc_1;

      // x_com_2 <= x_com_calc_2;
      // y_com_2 <= y_com_calc_2;
    end
  end


  parameter IMG_SPRITE_WIDTH = 128;

  // TODO: make 2 more of these for the other 2 shapes
  logic draw_classifier_0;
  image_sprite_transparent #(
    .WIDTH(IMG_SPRITE_WIDTH),
    .HEIGHT(IMG_SPRITE_WIDTH),
    .NUM_IMGS(4)
  ) classifier_0 (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(x_com_0>(IMG_SPRITE_WIDTH>>1) ? x_com_0-(IMG_SPRITE_WIDTH>>1) : 0),
    .y_in(y_com_0>(IMG_SPRITE_WIDTH>>1) ? y_com_0-(IMG_SPRITE_WIDTH>>1) : 0),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .shape(shape_0),
    .draw_out(draw_classifier_0)
  );

  logic draw_classifier_1;
  image_sprite_transparent_1 #(
    .WIDTH(IMG_SPRITE_WIDTH),
    .HEIGHT(IMG_SPRITE_WIDTH),
    .NUM_IMGS(4)
  ) classifier_1 (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(x_com_1>(IMG_SPRITE_WIDTH>>1) ? x_com_1-(IMG_SPRITE_WIDTH>>1) : 0),
    .y_in(y_com_1>(IMG_SPRITE_WIDTH>>1) ? y_com_1-(IMG_SPRITE_WIDTH>>1) : 0),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .shape(shape_1),
    .draw_out(draw_classifier_1)
  );

  // logic draw_classifier_2;
  // image_sprite_transparent_2 #(
  //   .WIDTH(IMG_SPRITE_WIDTH),
  //   .HEIGHT(IMG_SPRITE_WIDTH),
  //   .NUM_IMGS(4)
  // ) classifier_2 (
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(x_com_2>(IMG_SPRITE_WIDTH>>1) ? x_com_2-(IMG_SPRITE_WIDTH>>1) : 0),
  //   .y_in(y_com_2>(IMG_SPRITE_WIDTH>>1) ? y_com_2-(IMG_SPRITE_WIDTH>>1) : 0),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .shape(shape_2),
  //   .draw_out(draw_classifier_2)
  // );



logic [3:0] number [4:0][3:0];    // 2D array for number_[stage][digit]

always_ff @(posedge clk_pixel) begin
    // Stage 1: Calculate THOUSANDS place
    if (circ_temp[0] >= 10000) begin
        number[1][0] <= 9;
        number[1][1] <= 9;
        number[1][2] <= 9;
        number[1][3] <= 9;
        circ_temp[1] <= circ_temp[0];
    end else begin
      if (circ_temp[0] >= 9000) begin
          number[1][0] <= 9;
          circ_temp[1] <= circ_temp[0] - 9000;
      end else if (circ_temp[0] >= 8000) begin
          number[1][0] <= 8;
          circ_temp[1] <= circ_temp[0] - 8000;
      end else if (circ_temp[0] >= 7000) begin
          number[1][0] <= 7;
          circ_temp[1] <= circ_temp[0] - 7000;
      end else if (circ_temp[0] >= 6000) begin
          number[1][0] <= 6;
          circ_temp[1] <= circ_temp[0] - 6000;
      end else if (circ_temp[0] >= 5000) begin
          number[1][0] <= 5;
          circ_temp[1] <= circ_temp[0] - 5000;
      end else if (circ_temp[0] >= 4000) begin
          number[1][0] <= 4;
          circ_temp[1] <= circ_temp[0] - 4000;
      end else if (circ_temp[0] >= 3000) begin
          number[1][0] <= 3;
          circ_temp[1] <= circ_temp[0] - 3000;
      end else if (circ_temp[0] >= 2000) begin
          number[1][0] <= 2;
          circ_temp[1] <= circ_temp[0] - 2000;
      end else if (circ_temp[0] >= 1000) begin
          number[1][0] <= 1;
          circ_temp[1] <= circ_temp[0] - 1000;
      end else begin
          number[1][0] <= 0;
          circ_temp[1] <= circ_temp[0];
      end

      number[1][1] <= number[0][1];
      number[1][2] <= number[0][2];
      number[1][3] <= number[0][3];
    end


    // Stage 2: Calculate HUNDREDS place
    if (circ_temp[1] >= 10000) begin
        number[2][0] <= 9;
        number[2][1] <= 9;
        number[2][2] <= 9;
        number[2][3] <= 9;
        circ_temp[2] <= circ_temp[1];
    end else begin
        if (circ_temp[1] >= 900) begin
          number[2][1] <= 9;
          circ_temp[2] <= circ_temp[1] - 900;
      end else if (circ_temp[1] >= 800) begin
          number[2][1] <= 8;
          circ_temp[2] <= circ_temp[1] - 800;
      end else if (circ_temp[1] >= 700) begin
          number[2][1] <= 7;
          circ_temp[2] <= circ_temp[1] - 700;
      end else if (circ_temp[1] >= 600) begin
          number[2][1] <= 6;
          circ_temp[2] <= circ_temp[1] - 600;
      end else if (circ_temp[1] >= 500) begin
          number[2][1] <= 5;
          circ_temp[2] <= circ_temp[1] - 500;
      end else if (circ_temp[1] >= 400) begin
          number[2][1] <= 4;
          circ_temp[2] <= circ_temp[1] - 400;
      end else if (circ_temp[1] >= 300) begin
          number[2][1] <= 3;
          circ_temp[2] <= circ_temp[1] - 300;
      end else if (circ_temp[1] >= 200) begin
          number[2][1] <= 2;
          circ_temp[2] <= circ_temp[1] - 200;
      end else if (circ_temp[1] >= 100) begin
          number[2][1] <= 1;
          circ_temp[2] <= circ_temp[1] - 100;
      end else begin
          number[2][1] <= 0;
          circ_temp[2] <= circ_temp[1];
      end

      number[2][0] <= number[1][0];
      number[2][2] <= number[1][2];
      number[2][3] <= number[1][3];
    end


    // Stage 3: Calculate TENS and ONES places
    // Calculate TENS
    if (circ_temp[2] >= 10000) begin
        number[3][0] <= 9;
        number[3][1] <= 9;
        number[3][2] <= 9;
        number[3][3] <= 9;
        circ_temp[3] <= circ_temp[2];
    end else begin
      
      if (circ_temp[2] >= 90) begin
        number[3][2] <= 9;
        circ_temp[3] <= circ_temp[2] - 90;
      end else if (circ_temp[2] >= 80) begin
          number[3][2] <= 8;
          circ_temp[3] <= circ_temp[2] - 80;
      end else if (circ_temp[2] >= 70) begin
          number[3][2] <= 7;
          circ_temp[3] <= circ_temp[2] - 70;
      end else if (circ_temp[2] >= 60) begin
          number[3][2] <= 6;
          circ_temp[3] <= circ_temp[2] - 60;
      end else if (circ_temp[2] >= 50) begin
          number[3][2] <= 5;
          circ_temp[3] <= circ_temp[2] - 50;
      end else if (circ_temp[2] >= 40) begin
          number[3][2] <= 4;
          circ_temp[3] <= circ_temp[2] - 40;
      end else if (circ_temp[2] >= 30) begin
          number[3][2] <= 3;
          circ_temp[3] <= circ_temp[2] - 30;
      end else if (circ_temp[2] >= 20) begin
          number[3][2] <= 2;
          circ_temp[3] <= circ_temp[2] - 20;
      end else if (circ_temp[2] >= 10) begin
          number[3][2] <= 1;
          circ_temp[3] <= circ_temp[2] - 10;
      end else begin
          number[3][2] <= 0;
          circ_temp[3] <= circ_temp[2];
      end

      number[3][0] <= number[2][0];
      number[3][1] <= number[2][1];
      number[3][3] <= number[2][3];
    end

    // CALCULATE ONES
    if (circ_temp[3] >= 10000) begin
        number[4][0] <= 9;
        number[4][1] <= 9;
        number[4][2] <= 9;
        number[4][3] <= 9;
        circ_temp[4] <= circ_temp[3];
    end else begin
      if (circ_temp[3] <= 9) begin
          number[4][3] <= circ_temp[3];
      end else begin
          number[4][3] <= 0;
      end

      number[4][0] <= number[3][0];
      number[4][1] <= number[3][1];
      number[4][2] <= number[3][2];
    end
end







logic [3:0] a_number [4:0][3:0];    // 2D array for a_number_[stage][digit]

always_ff @(posedge clk_pixel) begin
    // Stage 1: Calculate THOUSANDS place
    if (area_temp[0] >= 10000) begin
        a_number[1][0] <= 9;
        a_number[1][1] <= 9;
        a_number[1][2] <= 9;
        a_number[1][3] <= 9;
        area_temp[1] <= area_temp[0];
    end else begin
        if (area_temp[0] >= 9000) begin
            a_number[1][0] <= 9;
            area_temp[1] <= area_temp[0] - 9000;
        end else if (area_temp[0] >= 8000) begin
            a_number[1][0] <= 8;
            area_temp[1] <= area_temp[0] - 8000;
        end else if (area_temp[0] >= 7000) begin
            a_number[1][0] <= 7;
            area_temp[1] <= area_temp[0] - 7000;
        end else if (area_temp[0] >= 6000) begin
            a_number[1][0] <= 6;
            area_temp[1] <= area_temp[0] - 6000;
        end else if (area_temp[0] >= 5000) begin
            a_number[1][0] <= 5;
            area_temp[1] <= area_temp[0] - 5000;
        end else if (area_temp[0] >= 4000) begin
            a_number[1][0] <= 4;
            area_temp[1] <= area_temp[0] - 4000;
        end else if (area_temp[0] >= 3000) begin
            a_number[1][0] <= 3;
            area_temp[1] <= area_temp[0] - 3000;
        end else if (area_temp[0] >= 2000) begin
            a_number[1][0] <= 2;
            area_temp[1] <= area_temp[0] - 2000;
        end else if (area_temp[0] >= 1000) begin
            a_number[1][0] <= 1;
            area_temp[1] <= area_temp[0] - 1000;
        end else begin
            a_number[1][0] <= 0;
            area_temp[1] <= area_temp[0];
        end

        a_number[1][1] <= a_number[0][1];
        a_number[1][2] <= a_number[0][2];
        a_number[1][3] <= a_number[0][3];
    end

    // Stage 2: Calculate HUNDREDS place
    if (area_temp[1] >= 10000) begin
        a_number[2][0] <= 9;
        a_number[2][1] <= 9;
        a_number[2][2] <= 9;
        a_number[2][3] <= 9;
        area_temp[2] <= area_temp[1];
    end else begin
        if (area_temp[1] >= 900) begin
            a_number[2][1] <= 9;
            area_temp[2] <= area_temp[1] - 900;
        end else if (area_temp[1] >= 800) begin
            a_number[2][1] <= 8;
            area_temp[2] <= area_temp[1] - 800;
        end else if (area_temp[1] >= 700) begin
            a_number[2][1] <= 7;
            area_temp[2] <= area_temp[1] - 700;
        end else if (area_temp[1] >= 600) begin
            a_number[2][1] <= 6;
            area_temp[2] <= area_temp[1] - 600;
        end else if (area_temp[1] >= 500) begin
            a_number[2][1] <= 5;
            area_temp[2] <= area_temp[1] - 500;
        end else if (area_temp[1] >= 400) begin
            a_number[2][1] <= 4;
            area_temp[2] <= area_temp[1] - 400;
        end else if (area_temp[1] >= 300) begin
            a_number[2][1] <= 3;
            area_temp[2] <= area_temp[1] - 300;
        end else if (area_temp[1] >= 200) begin
            a_number[2][1] <= 2;
            area_temp[2] <= area_temp[1] - 200;
        end else if (area_temp[1] >= 100) begin
            a_number[2][1] <= 1;
            area_temp[2] <= area_temp[1] - 100;
        end else begin
            a_number[2][1] <= 0;
            area_temp[2] <= area_temp[1];
        end

        a_number[2][0] <= a_number[1][0];
        a_number[2][2] <= a_number[1][2];
        a_number[2][3] <= a_number[1][3];
    end

    // Stage 3: Calculate TENS and ONES places
    // Calculate TENS
    if (area_temp[2] >= 10000) begin
        a_number[3][0] <= 9;
        a_number[3][1] <= 9;
        a_number[3][2] <= 9;
        a_number[3][3] <= 9;
        area_temp[3] <= area_temp[2];
    end else begin
        if (area_temp[2] >= 90) begin
            a_number[3][2] <= 9;
            area_temp[3] <= area_temp[2] - 90;
        end else if (area_temp[2] >= 80) begin
            a_number[3][2] <= 8;
            area_temp[3] <= area_temp[2] - 80;
        end else if (area_temp[2] >= 70) begin
            a_number[3][2] <= 7;
            area_temp[3] <= area_temp[2] - 70;
        end else if (area_temp[2] >= 60) begin
            a_number[3][2] <= 6;
            area_temp[3] <= area_temp[2] - 60;
        end else if (area_temp[2] >= 50) begin
            a_number[3][2] <= 5;
            area_temp[3] <= area_temp[2] - 50;
        end else if (area_temp[2] >= 40) begin
            a_number[3][2] <= 4;
            area_temp[3] <= area_temp[2] - 40;
        end else if (area_temp[2] >= 30) begin
            a_number[3][2] <= 3;
            area_temp[3] <= area_temp[2] - 30;
        end else if (area_temp[2] >= 20) begin
            a_number[3][2] <= 2;
            area_temp[3] <= area_temp[2] - 20;
        end else if (area_temp[2] >= 10) begin
            a_number[3][2] <= 1;
            area_temp[3] <= area_temp[2] - 10;
        end else begin
            a_number[3][2] <= 0;
            area_temp[3] <= area_temp[2];
        end

        a_number[3][0] <= a_number[2][0];
        a_number[3][1] <= a_number[2][1];
        a_number[3][3] <= a_number[2][3];
    end

    // CALCULATE ONES
    if (area_temp[3] >= 10000) begin
        a_number[4][0] <= 9;
        a_number[4][1] <= 9;
        a_number[4][2] <= 9;
        a_number[4][3] <= 9;
        area_temp[4] <= area_temp[3];
    end else begin
        if (area_temp[3] <= 9) begin
            a_number[4][3] <= area_temp[3];
        end else begin
            a_number[4][3] <= 0;
        end

        a_number[4][0] <= a_number[3][0];
        a_number[4][1] <= a_number[3][1];
        a_number[4][2] <= a_number[3][2];
    end
end






// perimeter
logic [3:0] p_number [4:0][3:0];    // 2D array for p_number_[stage][digit]

// Stage 1: Calculate THOUSANDS place
always_ff @(posedge clk_pixel) begin
    if (perim_temp[0] >= 10000) begin
        p_number[1][0] <= 9;
        p_number[1][1] <= 9;
        p_number[1][2] <= 9;
        p_number[1][3] <= 9;
        perim_temp[1] <= perim_temp[0];
    end else begin
        if (perim_temp[0] >= 9000) begin
            p_number[1][0] <= 9;
            perim_temp[1] <= perim_temp[0] - 9000;
        end else if (perim_temp[0] >= 8000) begin
            p_number[1][0] <= 8;
            perim_temp[1] <= perim_temp[0] - 8000;
        end else if (perim_temp[0] >= 7000) begin
            p_number[1][0] <= 7;
            perim_temp[1] <= perim_temp[0] - 7000;
        end else if (perim_temp[0] >= 6000) begin
            p_number[1][0] <= 6;
            perim_temp[1] <= perim_temp[0] - 6000;
        end else if (perim_temp[0] >= 5000) begin
            p_number[1][0] <= 5;
            perim_temp[1] <= perim_temp[0] - 5000;
        end else if (perim_temp[0] >= 4000) begin
            p_number[1][0] <= 4;
            perim_temp[1] <= perim_temp[0] - 4000;
        end else if (perim_temp[0] >= 3000) begin
            p_number[1][0] <= 3;
            perim_temp[1] <= perim_temp[0] - 3000;
        end else if (perim_temp[0] >= 2000) begin
            p_number[1][0] <= 2;
            perim_temp[1] <= perim_temp[0] - 2000;
        end else if (perim_temp[0] >= 1000) begin
            p_number[1][0] <= 1;
            perim_temp[1] <= perim_temp[0] - 1000;
        end else begin
            p_number[1][0] <= 0;
            perim_temp[1] <= perim_temp[0];
        end

        p_number[1][1] <= p_number[0][1];
        p_number[1][2] <= p_number[0][2];
        p_number[1][3] <= p_number[0][3];
    end

    // Stage 2: Calculate HUNDREDS place
    if (perim_temp[1] >= 10000) begin
        p_number[2][0] <= 9;
        p_number[2][1] <= 9;
        p_number[2][2] <= 9;
        p_number[2][3] <= 9;
        perim_temp[2] <= perim_temp[1];
    end else begin
        if (perim_temp[1] >= 900) begin
            p_number[2][1] <= 9;
            perim_temp[2] <= perim_temp[1] - 900;
        end else if (perim_temp[1] >= 800) begin
            p_number[2][1] <= 8;
            perim_temp[2] <= perim_temp[1] - 800;
        end else if (perim_temp[1] >= 700) begin
            p_number[2][1] <= 7;
            perim_temp[2] <= perim_temp[1] - 700;
        end else if (perim_temp[1] >= 600) begin
            p_number[2][1] <= 6;
            perim_temp[2] <= perim_temp[1] - 600;
        end else if (perim_temp[1] >= 500) begin
            p_number[2][1] <= 5;
            perim_temp[2] <= perim_temp[1] - 500;
        end else if (perim_temp[1] >= 400) begin
            p_number[2][1] <= 4;
            perim_temp[2] <= perim_temp[1] - 400;
        end else if (perim_temp[1] >= 300) begin
            p_number[2][1] <= 3;
            perim_temp[2] <= perim_temp[1] - 300;
        end else if (perim_temp[1] >= 200) begin
            p_number[2][1] <= 2;
            perim_temp[2] <= perim_temp[1] - 200;
        end else if (perim_temp[1] >= 100) begin
            p_number[2][1] <= 1;
            perim_temp[2] <= perim_temp[1] - 100;
        end else begin
            p_number[2][1] <= 0;
            perim_temp[2] <= perim_temp[1];
        end

        p_number[2][0] <= p_number[1][0];
        p_number[2][2] <= p_number[1][2];
        p_number[2][3] <= p_number[1][3];
    end

    // Stage 3: Calculate TENS and ONES places
    // Calculate TENS
    if (perim_temp[2] >= 10000) begin
        p_number[3][0] <= 9;
        p_number[3][1] <= 9;
        p_number[3][2] <= 9;
        p_number[3][3] <= 9;
        perim_temp[3] <= perim_temp[2];
    end else begin
        if (perim_temp[2] >= 90) begin
            p_number[3][2] <= 9;
            perim_temp[3] <= perim_temp[2] - 90;
        end else if (perim_temp[2] >= 80) begin
            p_number[3][2] <= 8;
            perim_temp[3] <= perim_temp[2] - 80;
        end else if (perim_temp[2] >= 70) begin
            p_number[3][2] <= 7;
            perim_temp[3] <= perim_temp[2] - 70;
        end else if (perim_temp[2] >= 60) begin
            p_number[3][2] <= 6;
            perim_temp[3] <= perim_temp[2] - 60;
        end else if (perim_temp[2] >= 50) begin
            p_number[3][2] <= 5;
            perim_temp[3] <= perim_temp[2] - 50;
        end else if (perim_temp[2] >= 40) begin
            p_number[3][2] <= 4;
            perim_temp[3] <= perim_temp[2] - 40;
        end else if (perim_temp[2] >= 30) begin
            p_number[3][2] <= 3;
            perim_temp[3] <= perim_temp[2] - 30;
        end else if (perim_temp[2] >= 20) begin
            p_number[3][2] <= 2;
            perim_temp[3] <= perim_temp[2] - 20;
        end else if (perim_temp[2] >= 10) begin
            p_number[3][2] <= 1;
            perim_temp[3] <= perim_temp[2] - 10;
        end else begin
            p_number[3][2] <= 0;
            perim_temp[3] <= perim_temp[2];
        end

        p_number[3][0] <= p_number[2][0];
        p_number[3][1] <= p_number[2][1];
        p_number[3][3] <= p_number[2][3];
    end

    // CALCULATE ONES
    if (perim_temp[3] >= 10000) begin
        p_number[4][0] <= 9;
        p_number[4][1] <= 9;
        p_number[4][2] <= 9;
        p_number[4][3] <= 9;
        perim_temp[4] <= perim_temp[3];
    end else begin
        if (perim_temp[3] <= 9) begin
            p_number[4][3] <= perim_temp[3];
        end else begin
            p_number[4][3] <= 0;
        end

        p_number[4][0] <= p_number[3][0];
        p_number[4][1] <= p_number[3][1];
        p_number[4][2] <= p_number[3][2];
    end
end




  // for placing the numbers easier
  localparam circ_number_x = 6;
  localparam circ_number_y = 4;
  localparam circ_number_spacing = 4;
  localparam number_img_size = 24; // doesnt change
  logic [11:0] draw_number;

  assign draw_number = 0; // REMOVE IF YOU WANT TO BRING IMG SPRITE TRNASP BACK


  // logic draw_number_0;
  // image_sprite_transparent_numbers #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_0(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x),
  //   .y_in(circ_number_y),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(number[4][0]),
  //   .draw_out(draw_number[0])
  // );

  // // logic draw_number_1;
  // image_sprite_transparent_numbers_1 #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_1(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x + (number_img_size + circ_number_spacing)*1),
  //   .y_in(circ_number_y),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(number[4][1]),
  //   .draw_out(draw_number[1])
  // );

  // // logic draw_number_2;
  // image_sprite_transparent_numbers_2 #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_2(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x + (number_img_size + circ_number_spacing)*2),
  //   .y_in(circ_number_y),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(number[4][2]),
  //   .draw_out(draw_number[2])
  // );

  // // logic draw_number_3;
  // image_sprite_transparent_numbers_3 #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_3(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x + (number_img_size + circ_number_spacing)*3),
  //   .y_in(circ_number_y),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(number[4][3]),
  //   .draw_out(draw_number[3])
  // );



  // image_sprite_transparent_numbers_4 #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_4(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x),
  //   .y_in(circ_number_y + (number_img_size + circ_number_spacing)*1),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(a_number[4][0]),
  //   .draw_out(draw_number[4])
  // );

  // image_sprite_transparent_numbers_5 #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_5(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x + (number_img_size + circ_number_spacing)*1),
  //   .y_in(circ_number_y + (number_img_size + circ_number_spacing)*1),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(a_number[4][1]),
  //   .draw_out(draw_number[5])
  // );

  // image_sprite_transparent_numbers_6 #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_6(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x + (number_img_size + circ_number_spacing)*2),
  //   .y_in(circ_number_y + (number_img_size + circ_number_spacing)*1),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(a_number[4][2]),
  //   .draw_out(draw_number[6])
  // );

  // image_sprite_transparent_numbers_7 #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_7(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x + (number_img_size + circ_number_spacing)*3),
  //   .y_in(circ_number_y + (number_img_size + circ_number_spacing)*1),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(a_number[4][3]),
  //   .draw_out(draw_number[7])
  // );




  // image_sprite_transparent_numbers_8 #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_8(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x),
  //   .y_in(circ_number_y + (number_img_size + circ_number_spacing)*2),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(p_number[4][0]),
  //   .draw_out(draw_number[8])
  // );

  // image_sprite_transparent_numbers_9 #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_9(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x + (number_img_size + circ_number_spacing)*1),
  //   .y_in(circ_number_y + (number_img_size + circ_number_spacing)*2),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(p_number[4][1]),
  //   .draw_out(draw_number[9])
  // );

  // image_sprite_transparent_numbers_10 #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_10(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x + (number_img_size + circ_number_spacing)*2),
  //   .y_in(circ_number_y + (number_img_size + circ_number_spacing)*2),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(p_number[4][2]),
  //   .draw_out(draw_number[10])
  // );

  // image_sprite_transparent_numbers_11 #(
  //   .WIDTH(24),
  //   .HEIGHT(24),
  //   .NUM_IMGS(10)
  // ) sprite_number_11(
  //   .pixel_clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .x_in(circ_number_x + (number_img_size + circ_number_spacing)*3),
  //   .y_in(circ_number_y + (number_img_size + circ_number_spacing)*2),
  //   .hcount_in(hcount_hdmi),
  //   .vcount_in(vcount_hdmi),
  //   .number(p_number[4][3]),
  //   .draw_out(draw_number[11])
  // );



  


  // NEW MODULES
  // CONNECTED COMPONENTS LABELLING MODULE
  //  * Takes in a binary mask, labels k connected components, finds center of mass of each component
  // MOORE NEIGHBORHOOD MODULE
  //  * Takes in a binary mask and returns perimeter of connected component
  // CIRCULARITY MODULE
  //  * Takes in a perimater and area and returns circularity of connected component
  // SHAPE DETECTOR LOGIC
  //  * could be purely combinational?
  // SPRITE OVERLAY LOGIC 

  


  //crosshair output:
  logic [7:0] ch_red, ch_green, ch_blue;

  //Create Crosshair patter on center of mass:
  //0 cycle latency
  //: Should be using output of (PS3)
  always_comb begin
    ch_red   = ((vcount_hdmi==y_com_0) || (hcount_hdmi==x_com_0))?8'hFF:8'h00;
    ch_green = ((vcount_hdmi==y_com_0) || (hcount_hdmi==x_com_0))?8'hFF:8'h00;
    ch_blue  = ((vcount_hdmi==y_com_0) || (hcount_hdmi==x_com_0))?8'hFF:8'h00;
  end


  // HDMI video signal generator
   video_sig_gen vsg
     (
      .pixel_clk_in(clk_pixel),
      .rst_in(sys_rst_pixel),
      .hcount_out(hcount_hdmi),
      .vcount_out(vcount_hdmi),
      .vs_out(vsync_hdmi),
      .hs_out(hsync_hdmi),
      .nf_out(nf_hdmi),
      .ad_out(active_draw_hdmi),
      .fc_out(frame_count_hdmi)
      );


  // Video Mux: select from the different display modes based on switch values
  //used with switches for display selections
  logic [1:0] display_choice;
  logic [1:0] target_choice;

  assign display_choice = sw[6:5]; //was [5:4]; not anymore
  assign target_choice =  {sw[7],1'b0}; //was [7:6]; not anymore

  //choose what to display from the camera:
  // * 'b00:  normal camera out
  // * 'b01:  selected channel image in grayscale
  // * 'b10:  masked pixel (all on if 1, all off if 0)
  // * 'b11:  chroma channel with mask overtop as magenta
  //
  //then choose what to use with center of mass:
  // * 'b00: nothing
  // * 'b01: crosshair
  // * 'b10: sprite on top
  // * 'b11: nothing

  
  // MASK PIXEL LOGIC
  logic mask_tot;
  always_comb begin
    mask_tot = 0;

    // independently put the other mask pixels in based on if we have those switches flipped
    if(sw[0]) begin
      mask_tot = mask_tot || mask_fb_0;
    end
    if(sw[1]) begin
      mask_tot = mask_tot || mask_fb_1;
    end
    // if(sw[2]) begin
    //   mask_tot = mask_tot || mask_fb_2;
    // end

    // if sw[3], we get the original mask
    if(sw[2]) begin
      mask_tot = mask_tot || frame_buff_raw; // --changed from mask
    end
  end


  // TODO: EDIT THE MASK SO THAT THE MASK IS RED!!!!!!!
  video_mux mvm(
    .bg_in(display_choice), //choose background
    .target_in(target_choice), //choose target
    .camera_pixel_in((frame_buff_raw == 1) ? 16'hFFFF : 0), //: needs (PS2) // CHANGED FROM {fb_red, fb_green, fb_blue}
    .camera_y_in((frame_buff_raw == 1) ? 8'hFF : 0), //luminance : needs (PS6)
    .channel_in(0), //current channel being drawn : needs (PS5)
    .thresholded_pixel_in(mask_tot), //one bit mask signal : needs (PS4)
    .crosshair_in({ch_red, ch_green, ch_blue}), //: needs (PS8)
    .com_sprite_pixel_in({img_red, img_green, img_blue}), //: needs (PS9) maybe?
    .draw_sprite(draw_sprite), //draw sprite signal
    .pixel_out({red,green,blue}) //output to tmds
  );

   // HDMI Output: just like before!

   logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
   logic       tmds_signal [2:0]; //output of each TMDS serializer!

   //three tmds_encoders (blue, green, red)
   //note green should have no control signal like red
   //the blue channel DOES carry the two sync signals:
   //  * control_in[0] = horizontal sync signal
   //  * control_in[1] = vertical sync signal

   tmds_encoder tmds_red(
       .clk_in(clk_pixel),
       .rst_in(sys_rst_pixel),
       .data_in(red),
       .control_in(2'b0),
       .ve_in(active_draw_hdmi),
       .tmds_out(tmds_10b[2]));

   tmds_encoder tmds_green(
         .clk_in(clk_pixel),
         .rst_in(sys_rst_pixel),
         .data_in(green),
         .control_in(2'b0),
         .ve_in(active_draw_hdmi),
         .tmds_out(tmds_10b[1]));

   tmds_encoder tmds_blue(
        .clk_in(clk_pixel),
        .rst_in(sys_rst_pixel),
        .data_in(blue),
        .control_in({vsync_hdmi,hsync_hdmi}),
        .ve_in(active_draw_hdmi),
        .tmds_out(tmds_10b[0]));


   //three tmds_serializers (blue, green, red):
   //MISSING: two more serializers for the green and blue tmds signals.
   tmds_serializer red_ser(
         .clk_pixel_in(clk_pixel),
         .clk_5x_in(clk_5x),
         .rst_in(sys_rst_pixel),
         .tmds_in(tmds_10b[2]),
         .tmds_out(tmds_signal[2]));
   tmds_serializer green_ser(
         .clk_pixel_in(clk_pixel),
         .clk_5x_in(clk_5x),
         .rst_in(sys_rst_pixel),
         .tmds_in(tmds_10b[1]),
         .tmds_out(tmds_signal[1]));
   tmds_serializer blue_ser(
         .clk_pixel_in(clk_pixel),
         .clk_5x_in(clk_5x),
         .rst_in(sys_rst_pixel),
         .tmds_in(tmds_10b[0]),
         .tmds_out(tmds_signal[0]));

   //output buffers generating differential signals:
   //three for the r,g,b signals and one that is at the pixel clock rate
   //the HDMI receivers use recover logic coupled with the control signals asserted
   //during blanking and sync periods to synchronize their faster bit clocks off
   //of the slower pixel clock (so they can recover a clock of about 742.5 MHz from
   //the slower 74.25 MHz clock)
   OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
   OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
   OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
   OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));


   // Nothing To Touch Down Here:
   // register writes to the camera

   // The OV5640 has an I2C bus connected to the board, which is used
   // for setting all the hardware settings (gain, white balance,
   // compression, image quality, etc) needed to start the camera up.
   // We've taken care of setting these all these values for you:
   // "rom.mem" holds a sequence of bytes to be sent over I2C to get
   // the camera up and running, and we've written a design that sends
   // them just after a reset completes.

   // If the camera is not giving data, press your reset button.

   logic  busy, bus_active;
   logic  cr_init_valid, cr_init_ready;

   logic  recent_reset;
   always_ff @(posedge clk_camera) begin
      if (sys_rst_camera) begin
         recent_reset <= 1'b1;
         cr_init_valid <= 1'b0;
      end
      else if (recent_reset) begin
         cr_init_valid <= 1'b1;
         recent_reset <= 1'b0;
      end else if (cr_init_valid && cr_init_ready) begin
         cr_init_valid <= 1'b0;
      end
   end

   logic [23:0] bram_dout;
   logic [7:0]  bram_addr;

   // ROM holding pre-built camera settings to send
   xilinx_single_port_ram_read_first
     #(
       .RAM_WIDTH(24),
       .RAM_DEPTH(256),
       .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
       .INIT_FILE("rom.mem")
       ) registers
       (
        .addra(bram_addr),     // Address bus, width determined from RAM_DEPTH
        .dina(24'b0),          // RAM input data, width determined from RAM_WIDTH
        .clka(clk_camera),     // Clock
        .wea(1'b0),            // Write enable
        .ena(1'b1),            // RAM Enable, for additional power savings, disable port when not in use
        .rsta(sys_rst_camera), // Output reset (does not affect memory contents)
        .regcea(1'b1),         // Output register enable
        .douta(bram_dout)      // RAM output data, width determined from RAM_WIDTH
        );

   logic [23:0] registers_dout;
   logic [7:0]  registers_addr;
   assign registers_dout = bram_dout;
   assign bram_addr = registers_addr;

   logic       con_scl_i, con_scl_o, con_scl_t;
   logic       con_sda_i, con_sda_o, con_sda_t;

   // NOTE these also have pullup specified in the xdc file!
   // access our inouts properly as tri-state pins
   IOBUF IOBUF_scl (.I(con_scl_o), .IO(i2c_scl), .O(con_scl_i), .T(con_scl_t) );
   IOBUF IOBUF_sda (.I(con_sda_o), .IO(i2c_sda), .O(con_sda_i), .T(con_sda_t) );

   // provided module to send data BRAM -> I2C
   camera_registers crw
     (.clk_in(clk_camera),
      .rst_in(sys_rst_camera),
      .init_valid(cr_init_valid),
      .init_ready(cr_init_ready),
      .scl_i(con_scl_i),
      .scl_o(con_scl_o),
      .scl_t(con_scl_t),
      .sda_i(con_sda_i),
      .sda_o(con_sda_o),
      .sda_t(con_sda_t),
      .bram_dout(registers_dout),
      .bram_addr(registers_addr));

   // a handful of debug signals for writing to registers
  //  assign led[0] = crw.bus_active;
  //  assign led[1] = cr_init_valid;
  //  assign led[2] = cr_init_ready;
  //  assign led[15:3] = 0;
  
  // set the LEDs that do stuff to the corresponding switches
  assign led[2:0] = sw[3:0];
  assign led[4:3] = sw[4:3];
  assign led[7:5] = sw[7:5];
  assign led[15:8] = sw[15:8];

endmodule // top_level


`default_nettype wire