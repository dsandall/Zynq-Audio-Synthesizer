module player_module #(
    parameter int CLIP_LEN,
    parameter int FREQ_RES_BITS
    // 256: update after 256 mclks (1 to 1 samples)
    // higher: lower frequencies
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,
    input [FREQ_RES_BITS-1:0] p_frequency,
    input shortint data_buffer[CLIP_LEN],
    output shortint player_sample,  // the linearly interpolated sample
    output valid
);

  // TODO: relate freq prescale to clip_len?
  // this would... normalize each clip to be the same period? that would be good
  // for playing consistent frequencies across sources

  // playing the sample
  // mclk only (no rotating writes yet)

  reg [$clog2(CLIP_LEN)-1:0] player_sample_index;

  int freq_counter;
  int freq_counter_reload;


  //assign freq_counter_reload = (FREQ_PRESCALE * (p_frequency + 1));
  int semi_mult;
  pitch_shift_lut pitch_i (
      .n(semitone),
      .period_mult(semi_mult)
  );
  int oct = p_frequency / 12;
  int semitone = p_frequency % 12;
  localparam int base_p = 10 * 61;
  localparam int highest_oct = 10;
  assign freq_counter_reload = base_p * semi_mult << (highest_oct - oct) >> (16 + $clog2(
          CLIP_LEN
      ));  // thats a mouthful
  // 2^(8-oct) * 2^(-n/12) * base_p = new_p

  always @(posedge mclk or posedge rst) begin

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
  /*
  ///// Linear interpolation!
  shortint raw_sample;
  assign raw_sample = data_buffer[player_sample_index];
  shortint raw_next_sample;
  assign raw_next_sample = data_buffer[player_sample_index+1];

  shortint this_sample;
  assign this_sample = (raw_sample * (freq_counter_reload - freq_counter)) / freq_counter_reload;
  shortint next_sample;
  assign next_sample = (raw_next_sample * freq_counter) / freq_counter_reload;

  assign player_sample = this_sample + next_sample;
*/

  // alternatively, use no linear interpolation:
  assign player_sample = data_buffer[player_sample_index];

  assign valid = 1;
endmodule
