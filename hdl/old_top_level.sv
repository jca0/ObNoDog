`timescale 1ns / 1ps
`default_nettype none

module old_top_level
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

  //clock domain cross (from clk_camera to clk_pixel)
  //switching from camera clock domain to pixel clock domain early
  //this lets us do convolution on the 74.25 MHz clock rather than the
  //200 MHz clock domain that the camera lives on.
  logic empty;
  logic cdc_valid;
  logic [15:0] cdc_pixel;
  logic [10:0] cdc_hcount;
  logic [9:0] cdc_vcount;

  //cdc fifo (AXI IP). Remember to include that IP folder.
  fifo cdc_fifo
    (.wr_clk(clk_camera),
     .full(),
     .din({camera_hcount, camera_vcount, camera_pixel}),
     .wr_en(camera_valid),

     .rd_clk(clk_pixel),
     .empty(empty),
     .dout({cdc_hcount, cdc_vcount, cdc_pixel}),
     .rd_en(1) //always read
    );
  assign cdc_valid = ~empty; //watch when empty. Ready immediately if something there

  //----
  //Filter 0: 1280x720 convolution of gaussian blur
  logic [10:0] f0_hcount;  //hcount from filter0 module
  logic [9:0] f0_vcount; //vcount from filter0 module
  logic [15:0] f0_pixel; //pixel data from filter0 module
  logic f0_valid; //valid signals for filter0 module
  //full resolution filter
  filter #(.K_SELECT(1),.HRES(1280),.VRES(720))
    filtern(
    .clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .data_valid_in(cdc_valid),
    .pixel_data_in(cdc_pixel),
    .hcount_in(cdc_hcount),
    .vcount_in(cdc_vcount),
    .data_valid_out(f0_valid),
    .pixel_data_out(f0_pixel),
    .hcount_out(f0_hcount),
    .vcount_out(f0_vcount)
  );

  //----
  logic [10:0] lb_hcount;  //hcount to filter modules
  logic [9:0] lb_vcount; //vcount to filter modules
  logic [15:0] lb_pixel; //pixel data to filter modules
  logic lb_valid; //valid signals to filter modules

  //selection logic to either go through (btn[1]=1)
  //or bypass (btn[1]==0) the first filter
  //in the first part of lab as you develop line buffer, you'll want to bypass
  //since your filter won't be working, but it would be good to test the
  //downsampling line buffer below on its own
  always_ff @(posedge clk_pixel) begin
    if (btn[1])begin
      ds_hcount = cdc_hcount;
      ds_vcount = cdc_vcount;
      ds_pixel = cdc_pixel;
      ds_valid = cdc_valid;
    end else begin
      ds_hcount = f0_hcount;
      ds_vcount = f0_vcount;
      ds_pixel = f0_pixel;
      ds_valid = f0_valid;
    end
  end

  //----
  //A line buffer that, in conjunction with the control signal will down sample
  //the camera (or f0 filter) values from 1280x720 to 320x180
  //in reality we could get by without this, but it does make things a little easier
  //and we've also added it since it gives us a means of testing the line buffer
  //design outside of the filter.
  logic [2:0][15:0] lb_buffs; //grab output of down sample line buffer
  logic ds_control; //controlling when to write (every fourth pixel and line)
  logic [10:0] ds_hcount;  //hcount to downsample line buffer
  logic [9:0] ds_vcount; //vcount to downsample line buffer
  logic [15:0] ds_pixel; //pixel data to downsample line buffer
  logic ds_valid; //valid signals to downsample line buffer
  assign ds_control = ds_valid&&(ds_hcount[1:0]==2'b0)&&(ds_vcount[1:0]==2'b0);
  line_buffer #(.HRES(320),
                .VRES(180))
    ds_lbuff (
    .clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .data_valid_in(ds_control),
    .pixel_data_in(ds_pixel),
    .hcount_in(ds_hcount[10:2]),
    .vcount_in(ds_vcount[9:2]),
    .data_valid_out(lb_valid),
    .line_buffer_out(lb_buffs),
    .hcount_out(lb_hcount),
    .vcount_out(lb_vcount)
  );

  assign lb_pixel = lb_buffs[1]; //pass on only the middle one.

  //----
  //Create six different filters that all exist in parallel
  //The outputs of all six filters are fed into the unpacked arrays below:
  logic [10:0] f_hcount [5:0];  //hcount from filter modules
  logic [9:0] f_vcount [5:0]; //vcount from filter modules
  logic [15:0] f_pixel [5:0]; //pixel data from filter modules
  logic f_valid [5:0]; //valid signals for filter modules

  //using generate/genvar, create five *Different* instances of the
  //filter module (you'll write that).  Each filter will implement a different
  //kernel
  generate
    genvar i;
    for (i=0; i<6; i=i+1)begin
      filter #(.K_SELECT(i),.HRES(320),.VRES(180))
        filterm(
        .clk_in(clk_pixel),
        .rst_in(sys_rst_pixel),
        .data_valid_in(lb_valid),
        .pixel_data_in(lb_pixel),
        .hcount_in(lb_hcount),
        .vcount_in(lb_vcount),
        .data_valid_out(f_valid[i]),
        .pixel_data_out(f_pixel[i]),
        .hcount_out(f_hcount[i]),
        .vcount_out(f_vcount[i])
      );
    end
  endgenerate

  //combine hor and vert signals from filters 4 and 5 for special signal:
  logic [7:0] fcomb_r, fcomb_g, fcomb_b;
  assign fcomb_r = (f_pixel[4][15:11]+f_pixel[5][15:11])>>1;
  assign fcomb_g = (f_pixel[4][10:5]+f_pixel[5][10:5])>>1;
  assign fcomb_b = (f_pixel[4][4:0]+f_pixel[5][4:0])>>1;

  //------
  //Choose which filter to use
  //based on values of sw[2:0] select which filter output gets handed on to the
  //next module. We must make sure to route hcount, vcount, pixels and valid signal
  // for each module.  Could have done this with a for loop as well!  Think
  // about it!
  logic [10:0] fmux_hcount; //hcount from filter mux
  logic [9:0]  fmux_vcount; //vcount from filter mux
  logic [15:0] fmux_pixel; //pixel data from filter mux
  logic fmux_valid; //data valid from filter mux

  //000 Identity Kernel
  //001 Gaussian Blur
  //010 Sharpen
  //011 Ridge Detection
  //100 Sobel Y-axis Edge Detection
  //101 Sobel X-axis Edge Detection
  //110 Total Sobel Edge Detection
  //111 Output of Line Buffer Directly (Helpful for debugging line buffer in first part)
  always_ff @(posedge clk_pixel)begin
    case (sw[2:0])
      3'b000: begin
        fmux_hcount <= f_hcount[0];
        fmux_vcount <= f_vcount[0];
        fmux_pixel <= f_pixel[0];
        fmux_valid <= f_valid[0];
      end
      3'b001: begin
        fmux_hcount <= f_hcount[1];
        fmux_vcount <= f_vcount[1];
        fmux_pixel <= f_pixel[1];
        fmux_valid <= f_valid[1];
      end
      3'b010: begin
        fmux_hcount <= f_hcount[2];
        fmux_vcount <= f_vcount[2];
        fmux_pixel <= f_pixel[2];
        fmux_valid <= f_valid[2];
      end
      3'b011: begin
        fmux_hcount <= f_hcount[3];
        fmux_vcount <= f_vcount[3];
        fmux_pixel <= f_pixel[3];
        fmux_valid <= f_valid[3];
      end
      3'b100: begin
        fmux_hcount <= f_hcount[4];
        fmux_vcount <= f_vcount[4];
        fmux_pixel <= f_pixel[4];
        fmux_valid <= f_valid[4];
      end
      3'b101: begin
        fmux_hcount <= f_hcount[5];
        fmux_vcount <= f_vcount[5];
        fmux_pixel <= f_pixel[5];
        fmux_valid <= f_valid[5];
      end
      3'b110: begin
        fmux_hcount <= f_hcount[4];
        fmux_vcount <= f_vcount[4];
        fmux_pixel <= {fcomb_r[4:0],fcomb_g[5:0],fcomb_b[4:0]};
        fmux_valid <= f_valid[4]&&f_valid[5];
      end
      default: begin
        fmux_hcount <= lb_hcount;
        fmux_vcount <= lb_vcount;
        fmux_pixel <= lb_pixel;
        fmux_valid <= lb_valid;
      end
    endcase
  end

  localparam FB_DEPTH = 320*180;
  localparam FB_SIZE = $clog2(FB_DEPTH);
  logic [FB_SIZE-1:0] addra; //used to specify address to write to in frame buffer
  logic valid_camera_mem; //used to enable writing pixel data to frame buffer
  logic [15:0] camera_mem; //used to pass pixel data into frame buffer

  //because the down sampling already happened upstream, there's no need to do here.
  always_ff @(posedge clk_pixel) begin
    if(fmux_valid) begin
      addra <= fmux_hcount + fmux_vcount * 320;
      camera_mem <= fmux_pixel;
      valid_camera_mem <= 1;
    end else begin
      valid_camera_mem <= 0;
    end
  end

  //frame buffer from IP
  blk_mem_gen_0 frame_buffer (
    .addra(addra), //pixels are stored using this math
    .clka(clk_pixel),
    .wea(valid_camera_mem),
    .dina(camera_mem),
    .ena(1'b1),
    .douta(), //never read from this side
    .addrb(addrb),//transformed lookup pixel
    .dinb(16'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(frame_buff_raw)
  );
  logic [15:0] frame_buff_raw; //data out of frame buffer (565)
  logic [FB_SIZE-1:0] addrb; //used to lookup address in memory for reading from buffer
  logic good_addrb; //used to indicate within valid frame for scaling
  //brought in from lab 5...just do 4X upscale
  always_ff @(posedge clk_pixel)begin
    if(!btn[2]) begin // 4x upsampling
      addrb <= (319-(hcount_hdmi >> 2)) + 320*(vcount_hdmi >> 2);
      good_addrb <= (hcount_hdmi<1280)&&(vcount_hdmi<720);
    end else begin //1X scaling from frame buffer
      addrb <= (319-hcount_hdmi) + 320*vcount_hdmi;
      good_addrb <= (hcount_hdmi<320) && (vcount_hdmi<180);
    end
  end

  //--------------------------END NEW STUFF-------------------

  //split fame_buff into 3 8 bit color channels (5:6:5 adjusted accordingly)
  //remapped frame_buffer outputs with 8 bits for r, g, b
  logic [7:0] fb_red, fb_green, fb_blue;
  always_ff @(posedge clk_pixel)begin
    fb_red <= good_addrb?{frame_buff_raw[15:11],3'b0}:8'b0;
    fb_green <= good_addrb?{frame_buff_raw[10:5], 2'b0}:8'b0;
    fb_blue <= good_addrb?{frame_buff_raw[4:0],3'b0}:8'b0;
  end
  // Pixel Processing pre-HDMI output

  // RGB to YCrCb

  //output of rgb to ycrcb conversion (10 bits due to module):
  logic [9:0] y_full, cr_full, cb_full; //ycrcb conversion of full pixel
  //bottom 8 of y, cr, cb conversions:
  logic [7:0] y, cr, cb; //ycrcb conversion of full pixel
  //Convert RGB of full pixel to YCrCb
  //See lecture 07 for YCrCb discussion.
  //Module has a 3 cycle latency
  rgb_to_ycrcb rgbtoycrcb_m(
    .clk_in(clk_pixel),
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
  logic [10:0] x_com, x_com_calc; //long term x_com and output from module, resp
  logic [9:0] y_com, y_com_calc; //long term y_com and output from module, resp
  logic new_com; //used to know when to update x_com and y_com ...

  //take lower 8 of full outputs.
  // treat cr and cb as signed numbers, invert the MSB to get an unsigned equivalent ( [-128,128) maps to [0,256) )
  assign y = y_full[7:0];
  assign cr = {!cr_full[7],cr_full[6:0]};
  assign cb = {!cb_full[7],cb_full[6:0]};

  assign channel_sel = {1'b1, sw[4:3]}; //[3:1];
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
     .r_in(fb_red),    //TODO: needs to use pipelined signal (PS1)
     .g_in(fb_green),  //TODO: needs to use pipelined signal (PS1)
     .b_in(fb_blue),   //TODO: needs to use pipelined signal (PS1)
     .y_in(y),
     .cr_in(cr),
     .cb_in(cb),
     .channel_out(selected_channel)
  );

  //threshold values used to determine what value  passes:
  assign lower_threshold = {sw[11:8],4'b0};
  assign upper_threshold = {sw[15:12],4'b0};

  //Thresholder: Takes in the full selected channedl and
  //based on upper and lower bounds provides a binary mask bit
  // * 1 if selected channel is within the bounds (inclusive)
  // * 0 if selected channel is not within the bounds
  threshold mt(
     .clk_in(clk_pixel),
     .rst_in(sys_rst_pixel),
     .pixel_in(selected_channel),
     .lower_bound_in(lower_threshold),
     .upper_bound_in(upper_threshold),
     .mask_out(mask) //single bit if pixel within mask.
  );


  logic [6:0] ss_c;
  //modified version of seven segment display for showing
  // thresholds and selected channel
  // special customized version
  lab05_ssc mssc(.clk_in(clk_pixel),
                 .rst_in(sys_rst_pixel),
                 .lt_in(lower_threshold),
                 .ut_in(upper_threshold),
                 .channel_sel_in(channel_sel),
                 .cat_out(ss_c),
                 .an_out({ss0_an, ss1_an})
  );
  assign ss0_c = ss_c; //control upper four digit's cathodes!
  assign ss1_c = ss_c; //same as above but for lower four digits!

  logic [15:0] perimeter;
  logic [15:0] perimeter_temp;
  logic [19:0] area_raw;
  logic [15:0] area;
  logic [15:0] circularity;
  logic [1:0] shape;
  logic both_valid;
  logic ccl_valid;
  logic ccl_temp;
  logic moore_busy;
  logic moore_valid;
  logic moore_temp;
  logic circularity_busy;
  logic circularity_valid;

  // // dont use this for now
  // always_ff @(posedge clk_pixel)begin
  //   if (ccl_valid) begin
  //     ccl_temp <= 1;
  //   end
  //   if (moore_valid) begin
  //     moore_temp <= 1;
  //     perimeter_temp <= perimeter;
  //   end
  //   if (moore_temp && ccl_temp) begin
  //     both_valid <= 1;
  //     ccl_temp <= 0;
  //     moore_temp <= 0;
  //   end
  //   if (both_valid) begin
  //     both_valid <= 0;
  //   end
  // end
  

  // connected_components #(
  //   .HRES(320),
  //   .VRES(180),
  //   .MAX_LABELS(20),
  //   .MIN_AREA(40)
  // ) cc(
  //   .clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .hcount_in(fmux_hcount),
  //   .vcount_in(fmux_vcount),
  //   .mask_in(mask),
  //   .valid_in(fmux_valid),
  //   .label_out(),
  //   .hcount_out(),
  //   .vcount_out(),
  //   .valid_out()
  // );

  //Center of Mass Calculation: (you need to do)
  //using x_com_calc and y_com_calc values
  //Center of Mass:
  center_of_mass com_m(
    .clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(hcount_hdmi),  //TODO: needs to use pipelined signal! (PS3)
    .y_in(vcount_hdmi), //TODO: needs to use pipelined signal! (PS3)
    .valid_in(mask), //aka threshold
    .tabulate_in((nf_hdmi)),
    .x_out(x_com_calc),
    .y_out(y_com_calc),
    .area_out(area_raw),
    .valid_out(new_com)
  );

  always_comb begin
    area <= (area_raw >> 4);
  end

  moore_neighbor_tracing mnt (
    .clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(hcount_hdmi >> 2),
    .y_in(vcount_hdmi >> 2),
    .valid_in(active_draw_hdmi),
    .masked_in(mask),
    .new_frame_in(nf_hdmi),
    .perimeter(perimeter),
    .busy_out(moore_busy),
    .valid_out(moore_valid)
  );

  // circularity circularity_m (
  //   .clk_in(clk_pixel),
  //   .rst_in(sys_rst_pixel),
  //   .area(area),
  //   .perimeter(perimeter),
  //   .data_valid_in(moore_valid && new_com),
  //   .circularity(circularity),
  //   .busy_out(circularity_busy),
  //   .valid_out(circularity_valid)
  // );



  logic com_waiting;
  logic [31:0] area_stored;
  logic moore_waiting;
  logic [31:0] perimeter_stored;

  logic [15:0] area_saved;
  logic [15:0] perimeter_saved;

  // dont use this for now
  always_ff @(posedge clk_pixel)begin
    if (new_com && !both_valid && !circularity_busy) begin
      com_waiting <= 1;
      area_stored <= area;
    end
    if (moore_valid && !both_valid && !circularity_busy) begin
      moore_waiting <= 1;
      perimeter_stored <= perimeter;
    end
    if (com_waiting && moore_waiting) begin
      both_valid <= 1;
      com_waiting <= 0;
      moore_waiting <= 0;
    end
    if (both_valid && !circularity_busy) begin
      both_valid <= 0;
      area_saved <= area_stored;
      perimeter_saved <= perimeter_stored;
    end
  end


  logic [31:0] dividend;
  logic [31:0] divisor;
  logic [31:0] circularity_raw;
  assign dividend = 4 * area_stored * 314;
  assign divisor = perimeter_stored * perimeter_stored; // area is 16* what it should be --> divide out without losing information

  divider
    #(.WIDTH(32)
    ) my_divider
    (.clk_in(clk_pixel),
        .rst_in(sys_rst_pixel),
        .dividend_in(dividend),
        .divisor_in(divisor),
        .data_valid_in(both_valid && !circularity_busy),
        .quotient_out(circularity_raw), // outputs
        .remainder_out(),
        .data_valid_out(circularity_valid),
        .error_out(),
        .busy_out(circularity_busy)
    );


  // shape detector stuff
  // always_ff @(posedge clk_pixel)begin
  //   if (circularity_valid)begin
  //     if (circularity > 80)begin
  //       shape <= 0; // circle
  //     end else if (circularity > 60)begin
  //       shape <= 1; // square
  //     end else if (circularity > 40)begin
  //       shape <= 2; // triangle
  //     end else begin
  //       shape <= 3; // plus
  //     end
  //   end
  // end

  logic [31:0] circularity;

  logic [15:0] circ_temp [4:0];     // 2D array for circ_temp[stage]
  logic [15:0] area_temp [4:0];
  logic [15:0] perim_temp [4:0];

  always_ff @(posedge clk_pixel) begin
    if(circularity_valid && circularity_raw < 200) begin // throw out obviously garbage circularity values --> should be in the 0-100 range (but circle can be a bit bigger)
      circularity <= circularity_raw;
      circ_temp[0] <= circularity_raw;
      area_temp[0] <= area_saved; // area is 16* what it should be because the screen is 4x larger in both directions
      perim_temp[0] <= perimeter_saved;
    end
  end

  always_comb begin
    //if (circularity_valid) begin
    if (circularity > 95)begin
      shape = 0; // circle
    end else if (circularity > 82)begin
      shape = 1; // square
    end else if (circularity > 50)begin
      shape = 2; // triangle
    end else begin
      shape = 3; // plus
    end
    //end
  end



  //image_sprite output:
  logic [7:0] img_red, img_green, img_blue;
  assign img_red =0;
  assign img_green =0;
  assign img_blue =0;
  logic draw_sprite;
  //image sprite removed to keep builds focused.

  //if any of the draw_outs from any of the sprite modules are true, then set draw_out to be true
  always_comb begin
    if ((draw_classifier && !(perim_temp[0] == 0)) || draw_number[0] || draw_number[1] || draw_number[2] || draw_number[3] || draw_number[4] || draw_number[5] || draw_number[6] || draw_number[7] || draw_number[8] || draw_number[9] || draw_number[10] || draw_number[11]) begin
      draw_sprite = 1;
    end else begin
      draw_sprite = 0;
    end
  end

  logic draw_classifier;
  image_sprite_transparent #(
    .WIDTH(256),
    .HEIGHT(256),
    .NUM_IMGS(4)
  ) classifier(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(x_com>128 ? x_com-128 : 0),
    .y_in(y_com>128 ? y_com-128 : 0),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .shape(shape),
    .draw_out(draw_classifier)
  );



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






  // logic [3:0] number_0;
  // logic [3:0] number_1;
  // logic [3:0] number_2;
  // logic [3:0] number_3;

  // // pulling the numbers from circularity
  // always_comb begin

  //   //circ_temp[0] <= circularity;

  //   if (circ_temp >= 10000) begin
  //     number_0 = 9;
  //     number_1 = 9;
  //     number_2 = 9;
  //     number_3 = 9;
  //   end else begin
  //     // THOUSANDS
  //     if (circ_temp >= 9000) begin
  //       number_0 = 9;
  //       circ_temp = circ_temp - 9000;
  //     end else if (circ_temp >= 8000) begin
  //       number_0 = 8;
  //       circ_temp = circ_temp - 8000;
  //     end else if (circ_temp >= 7000) begin
  //       number_0 = 7;
  //       circ_temp = circ_temp - 7000;
  //     end else if (circ_temp >= 6000) begin
  //       number_0 = 6;
  //       circ_temp = circ_temp - 6000;
  //     end else if (circ_temp >= 5000) begin
  //       number_0 = 5;
  //       circ_temp = circ_temp - 5000;
  //     end else if (circ_temp >= 4000) begin
  //       number_0 = 4;
  //       circ_temp = circ_temp - 4000;
  //     end else if (circ_temp >= 3000) begin
  //       number_0 = 3;
  //       circ_temp = circ_temp - 3000;
  //     end else if (circ_temp >= 2000) begin
  //       number_0 = 2;
  //       circ_temp = circ_temp - 2000;
  //     end else if (circ_temp >= 1000) begin
  //       number_0 = 1;
  //       circ_temp = circ_temp - 1000;
  //     end else begin
  //       number_0 = 0;
  //     end

  //     // HUNDREDS
  //     if (circ_temp >= 900) begin
  //       number_1 = 9;
  //       circ_temp = circ_temp - 900;
  //     end else if (circ_temp >= 800) begin
  //       number_1 = 8;
  //       circ_temp = circ_temp - 800;
  //     end else if (circ_temp >= 700) begin
  //       number_1 = 7;
  //       circ_temp = circ_temp - 700;
  //     end else if (circ_temp >= 600) begin
  //       number_1 = 6;
  //       circ_temp = circ_temp - 600;
  //     end else if (circ_temp >= 500) begin
  //       number_1 = 5;
  //       circ_temp = circ_temp - 500;
  //     end else if (circ_temp >= 400) begin
  //       number_1 = 4;
  //       circ_temp = circ_temp - 400;
  //     end else if (circ_temp >= 300) begin
  //       number_1 = 3;
  //       circ_temp = circ_temp - 300;
  //     end else if (circ_temp >= 200) begin
  //       number_1 = 2;
  //       circ_temp = circ_temp - 200;
  //     end else if (circ_temp >= 100) begin
  //       number_1 = 1;
  //       circ_temp = circ_temp - 100;
  //     end else begin
  //       number_1 = 0;
  //     end
      
  //     // TENS
  //     if (circ_temp >= 90) begin
  //       number_2 = 9;
  //       circ_temp = circ_temp - 90;
  //     end else if (circ_temp >= 80) begin
  //       number_2 = 8;
  //       circ_temp = circ_temp - 80;
  //     end else if (circ_temp >= 70) begin
  //       number_2 = 7;
  //       circ_temp = circ_temp - 70;
  //     end else if (circ_temp >= 60) begin
  //       number_2 = 6;
  //       circ_temp = circ_temp - 60;
  //     end else if (circ_temp >= 50) begin
  //       number_2 = 5;
  //       circ_temp = circ_temp - 50;
  //     end else if (circ_temp >= 40) begin
  //       number_2 = 4;
  //       circ_temp = circ_temp - 40;
  //     end else if (circ_temp >= 30) begin
  //       number_2 = 3;
  //       circ_temp = circ_temp - 30;
  //     end else if (circ_temp >= 20) begin
  //       number_2 = 2;
  //       circ_temp = circ_temp - 20;
  //     end else if (circ_temp >= 10) begin
  //       number_2 = 1;
  //       circ_temp = circ_temp - 10;
  //     end else begin
  //       number_2 = 0;
  //     end

  //     // ONES
  //     if (circ_temp <= 9) begin
  //       number_3 = circ_temp;
  //     end else begin
  //       number_3 = 0;
  //     end

  //   end

  // end




  // logic [15:0] area_temp;
  // logic [3:0] a_number_0;
  // logic [3:0] a_number_1;
  // logic [3:0] a_number_2;
  // logic [3:0] a_number_3;

  // // pulling the numbers from area
  // always_comb begin

  //   area_temp = area_stored;

  //   if (area_temp >= 10000) begin
  //     a_number_0 = 9;
  //     a_number_1 = 9;
  //     a_number_2 = 9;
  //     a_number_3 = 9;
  //   end else begin
  //     // THOUSANDS
  //     if (area_temp >= 9000) begin
  //       a_number_0 = 9;
  //       area_temp = area_temp - 9000;
  //     end else if (area_temp >= 8000) begin
  //       a_number_0 = 8;
  //       area_temp = area_temp - 8000;
  //     end else if (area_temp >= 7000) begin
  //       a_number_0 = 7;
  //       area_temp = area_temp - 7000;
  //     end else if (area_temp >= 6000) begin
  //       a_number_0 = 6;
  //       area_temp = area_temp - 6000;
  //     end else if (area_temp >= 5000) begin
  //       a_number_0 = 5;
  //       area_temp = area_temp - 5000;
  //     end else if (area_temp >= 4000) begin
  //       a_number_0 = 4;
  //       area_temp = area_temp - 4000;
  //     end else if (area_temp >= 3000) begin
  //       a_number_0 = 3;
  //       area_temp = area_temp - 3000;
  //     end else if (area_temp >= 2000) begin
  //       a_number_0 = 2;
  //       area_temp = area_temp - 2000;
  //     end else if (area_temp >= 1000) begin
  //       a_number_0 = 1;
  //       area_temp = area_temp - 1000;
  //     end else begin
  //       a_number_0 = 0;
  //     end

  //     // HUNDREDS
  //     if (area_temp >= 900) begin
  //       a_number_1 = 9;
  //       area_temp = area_temp - 900;
  //     end else if (area_temp >= 800) begin
  //       a_number_1 = 8;
  //       area_temp = area_temp - 800;
  //     end else if (area_temp >= 700) begin
  //       a_number_1 = 7;
  //       area_temp = area_temp - 700;
  //     end else if (area_temp >= 600) begin
  //       a_number_1 = 6;
  //       area_temp = area_temp - 600;
  //     end else if (area_temp >= 500) begin
  //       a_number_1 = 5;
  //       area_temp = area_temp - 500;
  //     end else if (area_temp >= 400) begin
  //       a_number_1 = 4;
  //       area_temp = area_temp - 400;
  //     end else if (area_temp >= 300) begin
  //       a_number_1 = 3;
  //       area_temp = area_temp - 300;
  //     end else if (area_temp >= 200) begin
  //       a_number_1 = 2;
  //       area_temp = area_temp - 200;
  //     end else if (area_temp >= 100) begin
  //       a_number_1 = 1;
  //       area_temp = area_temp - 100;
  //     end else begin
  //       a_number_1 = 0;
  //     end
      
  //     // TENS
  //     if (area_temp >= 90) begin
  //       a_number_2 = 9;
  //       area_temp = area_temp - 90;
  //     end else if (area_temp >= 80) begin
  //       a_number_2 = 8;
  //       area_temp = area_temp - 80;
  //     end else if (area_temp >= 70) begin
  //       a_number_2 = 7;
  //       area_temp = area_temp - 70;
  //     end else if (area_temp >= 60) begin
  //       a_number_2 = 6;
  //       area_temp = area_temp - 60;
  //     end else if (area_temp >= 50) begin
  //       a_number_2 = 5;
  //       area_temp = area_temp - 50;
  //     end else if (area_temp >= 40) begin
  //       a_number_2 = 4;
  //       area_temp = area_temp - 40;
  //     end else if (area_temp >= 30) begin
  //       a_number_2 = 3;
  //       area_temp = area_temp - 30;
  //     end else if (area_temp >= 20) begin
  //       a_number_2 = 2;
  //       area_temp = area_temp - 20;
  //     end else if (area_temp >= 10) begin
  //       a_number_2 = 1;
  //       area_temp = area_temp - 10;
  //     end else begin
  //       a_number_2 = 0;
  //     end

  //     // ONES
  //     if (area_temp <= 9) begin
  //       a_number_3 = area_temp;
  //     end else begin
  //       a_number_3 = 0;
  //     end

  //   end

  // end


  // logic [15:0] perim_temp;
  // logic [3:0] p_number_0;
  // logic [3:0] p_number_1;
  // logic [3:0] p_number_2;
  // logic [3:0] p_number_3;

  // always_comb begin

  //     perim_temp = area_stored;

  //     if (perim_temp >= 10000) begin
  //       p_number_0 = 9;
  //       p_number_1 = 9;
  //       p_number_2 = 9;
  //       p_number_3 = 9;
  //     end else begin
  //       // THOUSANDS
  //       if (perim_temp >= 9000) begin
  //         p_number_0 = 9;
  //         perim_temp = perim_temp - 9000;
  //       end else if (perim_temp >= 8000) begin
  //         p_number_0 = 8;
  //         perim_temp = perim_temp - 8000;
  //       end else if (perim_temp >= 7000) begin
  //         p_number_0 = 7;
  //         perim_temp = perim_temp - 7000;
  //       end else if (perim_temp >= 6000) begin
  //         p_number_0 = 6;
  //         perim_temp = perim_temp - 6000;
  //       end else if (perim_temp >= 5000) begin
  //         p_number_0 = 5;
  //         perim_temp = perim_temp - 5000;
  //       end else if (perim_temp >= 4000) begin
  //         p_number_0 = 4;
  //         perim_temp = perim_temp - 4000;
  //       end else if (perim_temp >= 3000) begin
  //         p_number_0 = 3;
  //         perim_temp = perim_temp - 3000;
  //       end else if (perim_temp >= 2000) begin
  //         p_number_0 = 2;
  //         perim_temp = perim_temp - 2000;
  //       end else if (perim_temp >= 1000) begin
  //         p_number_0 = 1;
  //         perim_temp = perim_temp - 1000;
  //       end else begin
  //         p_number_0 = 0;
  //       end

  //       // HUNDREDS
  //       if (perim_temp >= 900) begin
  //         p_number_1 = 9;
  //         perim_temp = perim_temp - 900;
  //       end else if (perim_temp >= 800) begin
  //         p_number_1 = 8;
  //         perim_temp = perim_temp - 800;
  //       end else if (perim_temp >= 700) begin
  //         p_number_1 = 7;
  //         perim_temp = perim_temp - 700;
  //       end else if (perim_temp >= 600) begin
  //         p_number_1 = 6;
  //         perim_temp = perim_temp - 600;
  //       end else if (perim_temp >= 500) begin
  //         p_number_1 = 5;
  //         perim_temp = perim_temp - 500;
  //       end else if (perim_temp >= 400) begin
  //         p_number_1 = 4;
  //         perim_temp = perim_temp - 400;
  //       end else if (perim_temp >= 300) begin
  //         p_number_1 = 3;
  //         perim_temp = perim_temp - 300;
  //       end else if (perim_temp >= 200) begin
  //         p_number_1 = 2;
  //         perim_temp = perim_temp - 200;
  //       end else if (perim_temp >= 100) begin
  //         p_number_1 = 1;
  //         perim_temp = perim_temp - 100;
  //       end else begin
  //         p_number_1 = 0;
  //       end
        
  //       // TENS
  //       if (perim_temp >= 90) begin
  //         p_number_2 = 9;
  //         perim_temp = perim_temp - 90;
  //       end else if (perim_temp >= 80) begin
  //         p_number_2 = 8;
  //         perim_temp = perim_temp - 80;
  //       end else if (perim_temp >= 70) begin
  //         p_number_2 = 7;
  //         perim_temp = perim_temp - 70;
  //       end else if (perim_temp >= 60) begin
  //         p_number_2 = 6;
  //         perim_temp = perim_temp - 60;
  //       end else if (perim_temp >= 50) begin
  //         p_number_2 = 5;
  //         perim_temp = perim_temp - 50;
  //       end else if (perim_temp >= 40) begin
  //         p_number_2 = 4;
  //         perim_temp = perim_temp - 40;
  //       end else if (perim_temp >= 30) begin
  //         p_number_2 = 3;
  //         perim_temp = perim_temp - 30;
  //       end else if (perim_temp >= 20) begin
  //         p_number_2 = 2;
  //         perim_temp = perim_temp - 20;
  //       end else if (perim_temp >= 10) begin
  //         p_number_2 = 1;
  //         perim_temp = perim_temp - 10;
  //       end else begin
  //         p_number_2 = 0;
  //       end

  //       // ONES
  //       if (perim_temp <= 9) begin
  //         p_number_3 = perim_temp;
  //       end else begin
  //         p_number_3 = 0;
  //       end

  //     end

  //   end




  // for placing the numbers easier
  logic [15:0] circ_number_x = 6;
  logic [15:0] circ_number_y = 4;
  logic [15:0] circ_number_spacing = 4;
  logic [4:0] number_img_size = 24; // doesnt change
  logic [11:0] draw_number;


  // logic draw_number_0;
  image_sprite_transparent_numbers #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_0(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x),
    .y_in(circ_number_y),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(number[4][0]),
    .draw_out(draw_number[0])
  );

  // logic draw_number_1;
  image_sprite_transparent_numbers_1 #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_1(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x + (number_img_size + circ_number_spacing)*1),
    .y_in(circ_number_y),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(number[4][1]),
    .draw_out(draw_number[1])
  );

  // logic draw_number_2;
  image_sprite_transparent_numbers_2 #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_2(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x + (number_img_size + circ_number_spacing)*2),
    .y_in(circ_number_y),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(number[4][2]),
    .draw_out(draw_number[2])
  );

  // logic draw_number_3;
  image_sprite_transparent_numbers_3 #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_3(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x + (number_img_size + circ_number_spacing)*3),
    .y_in(circ_number_y),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(number[4][3]),
    .draw_out(draw_number[3])
  );



  image_sprite_transparent_numbers_4 #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_4(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x),
    .y_in(circ_number_y + (number_img_size + circ_number_spacing)*1),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(a_number[4][0]),
    .draw_out(draw_number[4])
  );

  image_sprite_transparent_numbers_5 #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_5(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x + (number_img_size + circ_number_spacing)*1),
    .y_in(circ_number_y + (number_img_size + circ_number_spacing)*1),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(a_number[4][1]),
    .draw_out(draw_number[5])
  );

  image_sprite_transparent_numbers_6 #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_6(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x + (number_img_size + circ_number_spacing)*2),
    .y_in(circ_number_y + (number_img_size + circ_number_spacing)*1),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(a_number[4][2]),
    .draw_out(draw_number[6])
  );

  image_sprite_transparent_numbers_7 #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_7(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x + (number_img_size + circ_number_spacing)*3),
    .y_in(circ_number_y + (number_img_size + circ_number_spacing)*1),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(a_number[4][3]),
    .draw_out(draw_number[7])
  );







  image_sprite_transparent_numbers_8 #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_8(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x),
    .y_in(circ_number_y + (number_img_size + circ_number_spacing)*2),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(p_number[4][0]),
    .draw_out(draw_number[8])
  );

  image_sprite_transparent_numbers_9 #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_9(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x + (number_img_size + circ_number_spacing)*1),
    .y_in(circ_number_y + (number_img_size + circ_number_spacing)*2),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(p_number[4][1]),
    .draw_out(draw_number[9])
  );

  image_sprite_transparent_numbers_10 #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_10(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x + (number_img_size + circ_number_spacing)*2),
    .y_in(circ_number_y + (number_img_size + circ_number_spacing)*2),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(p_number[4][2]),
    .draw_out(draw_number[10])
  );

  image_sprite_transparent_numbers_11 #(
    .WIDTH(24),
    .HEIGHT(24),
    .NUM_IMGS(10)
  ) sprite_number_11(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(circ_number_x + (number_img_size + circ_number_spacing)*3),
    .y_in(circ_number_y + (number_img_size + circ_number_spacing)*2),
    .hcount_in(hcount_hdmi),
    .vcount_in(vcount_hdmi),
    .number(p_number[4][3]),
    .draw_out(draw_number[11])
  );



  


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

  //grab logic for above
  //update center of mass x_com, y_com based on new_com signal
  always_ff @(posedge clk_pixel)begin
    if (sys_rst_pixel)begin
      x_com <= 0;
      y_com <= 0;
    end if(new_com)begin
      x_com <= x_com_calc;
      y_com <= y_com_calc;
    end
  end


  //crosshair output:
  logic [7:0] ch_red, ch_green, ch_blue;

  //Create Crosshair patter on center of mass:
  //0 cycle latency
  //TODO: Should be using output of (PS3)
  always_comb begin
    ch_red   = ((vcount_hdmi==y_com) || (hcount_hdmi==x_com))?8'hFF:8'h00;
    ch_green = ((vcount_hdmi==y_com) || (hcount_hdmi==x_com))?8'hFF:8'h00;
    ch_blue  = ((vcount_hdmi==y_com) || (hcount_hdmi==x_com))?8'hFF:8'h00;
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
  assign target_choice =  {1'b1,sw[7]}; //was [7:6]; not anymore

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

  video_mux mvm(
    .bg_in(display_choice), //choose background
    .target_in(target_choice), //choose target
    .camera_pixel_in({fb_red, fb_green, fb_blue}), //TODO: needs (PS2)
    .camera_y_in(y), //luminance TODO: needs (PS6)
    .channel_in(selected_channel), //current channel being drawn TODO: needs (PS5)
    .thresholded_pixel_in(mask), //one bit mask signal TODO: needs (PS4)
    .crosshair_in({ch_red, ch_green, ch_blue}), //TODO: needs (PS8)
    .com_sprite_pixel_in({img_red, img_green, img_blue}), //TODO: needs (PS9) maybe?
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
   assign led[0] = crw.bus_active;
   assign led[1] = cr_init_valid;
   assign led[2] = cr_init_ready;
   assign led[15:3] = 0;

endmodule // top_level


`default_nettype wire
