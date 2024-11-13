module tm_choice (
    input wire [7:0] data_in,
    output logic [8:0] qm_out
    );

    // your code here, friend
    // count 1s
    logic [3:0] count;
    always_comb begin
        count = 0;
        for (int i = 0; i < 8; i++) begin
            count += data_in[i];
        end
    end

    always_comb begin
        if (count > 4 || (count == 4 && data_in[0] == 0))begin
            qm_out[0] = data_in[0];
            for (int i = 1; i < 8; i++)begin
                qm_out[i] = ~(data_in[i] ^ qm_out[i-1]);
            end
            qm_out[8] = 0;
        end else begin
            qm_out[0] = data_in[0];
            for (int i = 1; i < 8; i++)begin
                qm_out[i] = data_in[i] ^ qm_out[i-1];
            end
            qm_out[8] = 1;
        end
    end



endmodule //end tm_choice