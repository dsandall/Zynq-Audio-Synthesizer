module player_module #(
    parameter int CLIP_LEN,
    parameter int FREQ_RES_BITS,
    parameter int FREQ_PRESCALE = 256
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,
    output valid,
    input [FREQ_RES_BITS-1 : 0] p_frequency,
    output reg [$clog2(CLIP_LEN)-1:0] player_sample_index
);

  // playing the sample
  // mclk only (no rotating writes yet)

  int freq_counter;

  always @(negedge mclk or posedge rst) begin

    if (rst) begin
      player_sample_index = 0;
      freq_counter = 0;
    end else begin

      // increment the player index
      if (freq_counter == 0) begin
        freq_counter <= (FREQ_PRESCALE * (p_frequency));
        player_sample_index <= player_sample_index + 1;
      end else begin
        freq_counter <= freq_counter - 1;
      end

    end

  end

  assign valid = 1;
endmodule
