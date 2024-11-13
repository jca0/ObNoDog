module video_sig_gen
#(
  parameter ACTIVE_H_PIXELS = 1280,
  parameter H_FRONT_PORCH = 110,
  parameter H_SYNC_WIDTH = 40,
  parameter H_BACK_PORCH = 220,
  parameter ACTIVE_LINES = 720,
  parameter V_FRONT_PORCH = 5,
  parameter V_SYNC_WIDTH = 5,
  parameter V_BACK_PORCH = 20,
  parameter FPS = 60)
(
  input wire pixel_clk_in,
  input wire rst_in,
  output logic [$clog2(TOTAL_PIXELS)-1:0] hcount_out,
  output logic [$clog2(TOTAL_LINES)-1:0] vcount_out,
  output logic vs_out, //vertical sync out
  output logic hs_out, //horizontal sync out
  output logic ad_out,
  output logic nf_out, //single cycle enable signal
  output logic [5:0] fc_out); //frame

  localparam TOTAL_PIXELS = ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH; //figure this out // *** DONE ***
  localparam TOTAL_LINES = ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH; //figure this out // *** DONE ***

  always_comb begin
    if(!rst_in) begin
      if(hcount_out < ACTIVE_H_PIXELS && vcount_out < ACTIVE_LINES) begin
        ad_out = 1;
      end else begin
        ad_out = 0;
      end

      if((hcount_out >= ACTIVE_H_PIXELS + H_FRONT_PORCH) && (hcount_out <= ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH - 1)) begin
        hs_out = 1;
      end else begin
        hs_out = 0;
      end

      if((vcount_out >= ACTIVE_LINES + V_FRONT_PORCH) && (vcount_out <= ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH - 1)) begin
        vs_out = 1;
      end else begin
        vs_out = 0;
      end
    end else begin
      ad_out = 0;
      vs_out = 0;
      hs_out = 0;
    end
  end

  always_ff @(posedge pixel_clk_in) begin

    if(rst_in) begin
      // outputs
      hcount_out <= 0;
      vcount_out <= 0;
      //vs_out <= 0;
      //hs_out <= 0;
      nf_out <= 0;
      fc_out <= 0;
      //ad_out <= 0;

      // logics

    end else begin
      // hcount_out and vcount_out
      hcount_out <= (hcount_out == TOTAL_PIXELS-1)? 0 : hcount_out + 1; // increment x cursor with wrap around
      vcount_out <= (hcount_out == TOTAL_PIXELS-1)? ((vcount_out == TOTAL_LINES-1)? 0 : vcount_out + 1) : vcount_out; // increment y cursor with wrap around, only when x wraps around


      // nf_out and fc_out
      if(vcount_out == ACTIVE_LINES && hcount_out == ACTIVE_H_PIXELS - 1) begin // if, on the next cycle we will be on the change frame indicator:
        nf_out <= 1;
        fc_out <= (fc_out == FPS-1)? 0 : fc_out + 1;
      end else begin
        nf_out <= 0;
      end


      // ad_out
      //if(((hcount_out <= ACTIVE_H_PIXELS-2 || (hcount_out == TOTAL_PIXELS-1 && vcount_out != ACTIVE_LINES-1)) && (vcount_out <= ACTIVE_LINES-1)) || (hcount_out == TOTAL_PIXELS-1 && vcount_out == TOTAL_LINES-1)) begin // are we currently within the rectangle or are we at the end of the line (but not the end of the last active line) or are we on the last pixel
      //  ad_out <= 1;
      //end else begin
      //  ad_out <= 0;
      //end


      // hs_out         // 1389 (on next we're 1390)                               // 1428 (on next we're 1429)
      // if((hcount_out >= ACTIVE_H_PIXELS + H_FRONT_PORCH-1) && (hcount_out <= ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH - 2)) begin
      //   hs_out <= 1;
      // end else begin
      //   hs_out <= 0;
      // end

      // if we are on the pixel right before the sync line                                    or if we're currently on or above the start     and we're currently on or before the end                            and we're not on the last pixel in the sync line
      // if((hcount_out == TOTAL_PIXELS-1 && vcount_out == ACTIVE_LINES + V_FRONT_PORCH - 1) || ((vcount_out >= ACTIVE_LINES + V_FRONT_PORCH) && (vcount_out <= ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH - 1) && !(hcount_out == TOTAL_PIXELS-1 && vcount_out == ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH - 1))) begin
      //   vs_out <= 1;
      // end else begin
      //   vs_out <= 0;
      // end

    end // else (for if(rst_in))

  end // always_ff



endmodule