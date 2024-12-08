module crc32_mpeg2(
            input wire clk_in,
            input wire rst_in,
            input wire data_valid_in,
            input wire data_in,
            output logic [31:0] data_out);


	always_ff @(posedge clk_in) begin
		
		if(rst_in) begin
			
			// outputs
			data_out <= 32'hFFFF_FFFF;	// reset lfsr to contain all 1s

		end else begin

			if(data_valid_in) begin

				for(int idx = 31; idx >= 0; idx = idx - 1) begin

					// set the value in the polynomial based on the index
					case(idx)

						26: data_out[26] <= data_out[25] ^ data_out[31] ^ data_in;
						23: data_out[23] <= data_out[22] ^ data_out[31] ^ data_in;
						22: data_out[22] <= data_out[21] ^ data_out[31] ^ data_in;
						16: data_out[16] <= data_out[15] ^ data_out[31] ^ data_in;
						12: data_out[12] <= data_out[11] ^ data_out[31] ^ data_in;
						11: data_out[11] <= data_out[10] ^ data_out[31] ^ data_in;
						10: data_out[10] <= data_out[9] ^ data_out[31] ^ data_in;
						8: data_out[8] <= data_out[7] ^ data_out[31] ^ data_in;
						7: data_out[7] <= data_out[6] ^ data_out[31] ^ data_in;
						5: data_out[5] <= data_out[4] ^ data_out[31] ^ data_in;
						4: data_out[4] <= data_out[3] ^ data_out[31] ^ data_in;
						2: data_out[2] <= data_out[1] ^ data_out[31] ^ data_in;
						1: data_out[1] <= data_out[0] ^ data_out[31] ^ data_in;
						0: data_out[0] <= data_out[31] ^ data_in;
						default: data_out[idx] <= data_out[idx-1];

					endcase

				end // for

			end // if(data_valid_in)

		end // end else begin (from if(rst_in))

	end // always_ff

endmodule