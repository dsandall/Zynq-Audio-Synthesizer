
// very simple sample buffer player. 
// allows for upsampling and downsampling at varying frequencies

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

  int semi_mult;
  pitch_shift_lut pitch_i (
      .n(semitone),
      .period_mult(semi_mult)
  );
  int oct = p_frequency / 12;
  int semitone = p_frequency % 12;

  // 2^(10-oct) * 2^(-n/12) * base_p = new_p
  //
  // extend period for semitones
  localparam int base_p = 10 * 61 * 20;
  reg signed [63:0] a = (base_p * semi_mult);

  // shift up for high octaves, then shift back down to:
  // account for semitone LUT fixed pt math
  // and to account for varying clip lengths
  localparam int highest_oct = 10;
  reg signed [63:0] freq_counter_reload = (a << (highest_oct - oct)) >> (16 + $clog2(
      CLIP_LEN
  ));  // thats a mouthful

  reg signed [63:0] freq_counter;
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




// an improvement on the player module, for notes that you hold

////////
//
module enveloped_oscillator_module #(
    parameter int CLIP_LEN = 64,
    parameter int VOLUME_BITS = 8,
    parameter int FREQ_RES_BITS = 8,
    parameter int ATTACK,
    parameter int DECAY
) (

    input mclk,   // Master Clock (256x sample rate)
    input pblrc,  // sample rate
    input rst,

    output shortint p_sample_buffer,
    output valid,

    input [VOLUME_BITS-1 : 0] volume,
    input [FREQ_RES_BITS-1 : 0] p_frequency,
    input shortint sample_buffer[CLIP_LEN]
);

  logic activate;
  assign activate = (volume != 0);

  // preserves the volume setting during deassertion of a note.
  // allows for decay after vol is set to 0
  logic [VOLUME_BITS-1:0] vol_saved;
  always_ff @(posedge pblrc) begin
    if (activate) begin
      vol_saved <= volume;
    end
  end

  logic [VOLUME_BITS-1:0] volume_env;
  logic [VOLUME_BITS-1:0] volume_final;
  assign volume_final = (volume_env * vol_saved) / (2 ** 7);
  oneshot_enveloper #(
      .ATTACK_TIME(ATTACK),
      .DECAY_TIME(DECAY),
      .MAX_VOL(2 ** 7)
  ) envelope_i (
      .mclk(mclk),
      .rst(rst),
      .trigger(activate),
      .volume_out(volume_env)
  );

  shortint current_sample_novol;
  player_module #(
      .CLIP_LEN(CLIP_LEN),
      .FREQ_RES_BITS(FREQ_RES_BITS)
  ) player_module_sine_i (
      .mclk(mclk),
      .rst(rst),
      .p_frequency(p_frequency),
      .data_buffer(sample_buffer),
      .player_sample(current_sample_novol),
      .valid(valid)
  );

  shortint current_sample_nofilt;
  // assign the output
  volume_adjust #(
      .VOLUME_BITS(VOLUME_BITS)
  ) volume_adjust_sine_i (
      .sample_in(current_sample_novol),
      .sample_out(current_sample_nofilt),
      .volume(volume_final)
  );

  shortint current_sample_filt;
  fir_lowpass #() lp_filter (
      .sample_clk(pblrc),
      .rst(rst),
      .mclk(mclk),
      .sample_in(current_sample_nofilt),
      .sample_out(p_sample_buffer)
  );

endmodule

