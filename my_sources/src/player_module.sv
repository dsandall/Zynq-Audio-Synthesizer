module player_module #(
    parameter int CLIP_LEN,
    parameter int FREQ_RES_BITS,
    parameter int FREQ_PRESCALE
    // 256: update after 256 mclks (1 to 1 samples)
    // higher: lower frequencies
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,
    input [FREQ_RES_BITS-1 : 0] p_frequency,
    input shortint data_buffer[0:CLIP_LEN-1],
    output shortint player_sample,  // the linearly interpolated sample
    output valid
);

  // playing the sample
  // mclk only (no rotating writes yet)

  reg [$clog2(CLIP_LEN)-1:0] player_sample_index;

  int freq_counter;
  int freq_counter_reload;
  assign freq_counter_reload = (FREQ_PRESCALE * (p_frequency + 1));
  assign and_a_bit = freq_counter / freq_counter_reload;
  always @(negedge mclk or posedge rst) begin

    if (rst) begin
      player_sample_index = 0;
      freq_counter = 0;
    end else begin

      // increment the player index
      if (freq_counter >= freq_counter_reload) begin
        freq_counter <= 0;
        player_sample_index++;
      end else begin
        freq_counter++;
      end

    end

  end

  shortint raw_sample;
  assign raw_sample = data_buffer[player_sample_index];
  shortint raw_next_sample;
  assign raw_next_sample = data_buffer[player_sample_index+1];

  shortint this_sample;
  assign this_sample = (raw_sample * (freq_counter_reload - freq_counter)) / freq_counter_reload;
  shortint next_sample;
  assign next_sample = (raw_next_sample * freq_counter) / freq_counter_reload;

  assign player_sample = this_sample + next_sample;

  assign valid = 1;
endmodule

//WARN: not done
module once_player_module #(
    parameter int CLIP_LEN,
    parameter int FREQ_RES_BITS,
    parameter int FREQ_PRESCALE
    // 256: update after 256 mclks (1 to 1 samples)
    // higher: lower frequencies
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,
    output valid,
    input [FREQ_RES_BITS-1 : 0] p_frequency,
    output reg [$clog2(CLIP_LEN)-1:0] player_sample_index,

    // new for once player
    input shortint duration
);



endmodule
