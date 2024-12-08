module tm_choice (
  input wire [7:0] data_in,
  output logic [8:0] qm_out
  );

  logic [3:0] N_1;
  logic [8:0] store_qm_out;

  always_comb begin
    N_1 = data_in[0]+data_in[1]+data_in[2]+data_in[3]+data_in[4]+data_in[5]+data_in[6]+data_in[7]; // get the number of 1s

    if(N_1 > 4 || (N_1 == 4 && data_in[0] == 0)) begin // option 2
      store_qm_out[0] = data_in[0];
      store_qm_out[1] = ~(data_in[1] ^ store_qm_out[0]);
      store_qm_out[2] = ~(data_in[2] ^ store_qm_out[1]);
      store_qm_out[3] = ~(data_in[3] ^ store_qm_out[2]);
      store_qm_out[4] = ~(data_in[4] ^ store_qm_out[3]);
      store_qm_out[5] = ~(data_in[5] ^ store_qm_out[4]);
      store_qm_out[6] = ~(data_in[6] ^ store_qm_out[5]);
      store_qm_out[7] = ~(data_in[7] ^ store_qm_out[6]);
      store_qm_out[8] = 1'b0;

    end else begin  // option 1
      store_qm_out[0] = data_in[0];
      store_qm_out[1] = data_in[1] ^ store_qm_out[0];
      store_qm_out[2] = data_in[2] ^ store_qm_out[1];
      store_qm_out[3] = data_in[3] ^ store_qm_out[2];
      store_qm_out[4] = data_in[4] ^ store_qm_out[3];
      store_qm_out[5] = data_in[5] ^ store_qm_out[4];
      store_qm_out[6] = data_in[6] ^ store_qm_out[5];
      store_qm_out[7] = data_in[7] ^ store_qm_out[6];
      store_qm_out[8] = 1'b1;
    end

    qm_out = store_qm_out; // set value
  end

 
endmodule