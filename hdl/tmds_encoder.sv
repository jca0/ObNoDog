`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
 
  logic [8:0] q_m;
  logic [4:0] tally;            // keep the tally of 1s and 0s
  logic [3:0] n_1;              // number of 1s in q_m's lower 8 bits (assigned combinationally)
  logic [3:0] n_0;              // number of 0s in q_m's lower 8 bits (assigned combinationally)


  //logic [9:0] tmds_out_t;      // all 3 possible tmds_out outputs, which we assign combinationally
  //logic [9:0] tmds_out_ft;
  //logic [9:0] tmds_out_ff;
 
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));
 
 
  always_comb begin
    n_1 = q_m[0]+q_m[1]+q_m[2]+q_m[3]+q_m[4]+q_m[5]+q_m[6]+q_m[7]; // get the number of 1s in q_m
    n_0 = 8-n_1;

    //tmds_out_t = {~q_m[8], q_m[8], (q_m[8])? q_m[7:0] : ~q_m[7:0]};
    //tmds_out_ft = {1'b1, q_m[8], ~q_m[7:0]};
    //tmds_out_ff = {1'b0, q_m[8], q_m[7:0]};
  end



  
  
  always_ff @(posedge clk_in) begin

    if(rst_in) begin
      //outputs
      tmds_out <= 0;

      //logics
      tally <= 0;

    end else if(!ve_in) begin
      tally <= 0;

      case (control_in)
        2'b00: tmds_out <= 10'b11010_10100;
        2'b01: tmds_out <= 10'b00101_01011;
        2'b10: tmds_out <= 10'b01010_10100;
        2'b11: tmds_out <= 10'b10101_01011;
        default: tmds_out <= 0;
      endcase

    end else begin

      if(tally == 0 || n_1 == n_0) begin // t_
        tmds_out[9] <= ~q_m[8];
        tmds_out[8] <= q_m[8];
        tmds_out[7:0] <= (q_m[8])? q_m[7:0] : ~q_m[7:0];

        //tmds_out <= tmds_out_t;

        if(q_m[8] == 0) begin // tt
          tally <= tally + (n_0 - n_1); // n_0 = 8-n_1
        end else begin // tf
          tally <= tally + (n_1 - n_0);
        end

      end else begin // f_
        if((tally[4] == 0 && n_1 > n_0) || (tally[4] == 1 && n_0 > n_1)) begin //ft  // if tally[4] is equivalent to is tally positive
          tmds_out[9] <= 1'b1;
          tmds_out[8] <= q_m[8];
          tmds_out[7:0] <= ~q_m[7:0];
          //tmds_out <= tmds_out_ft;

          tally <= tally + q_m[8] + q_m[8] + (n_0 - n_1);
        end else begin // ff
          tmds_out[9] <= 1'b0;
          tmds_out[8] <= q_m[8];
          tmds_out[7:0] <= q_m[7:0];
          //tmds_out <= tmds_out_ff;

          //tally <= tally - (2'd2)*(!q_m[8]) + (n_1 - n_0);
          tally <= tally - ((q_m[8])? 2'd0 : 2'd2) + (n_1 - n_0);
        end

      end // else (for if(tally == 0 || n_1 == n_0))

    end // else (for if(rst_in) else if(!ve_in))

  end // always_ff
 
endmodule


`default_nettype wire