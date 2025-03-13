module src_oneshot_hihat #(
    parameter int CLIP_LEN = 256,
    parameter int VOLUME_BITS = 8,
    parameter int FREQ_RES_BITS = 8
) (
    input mclk,  // Master Clock (256x sample rate)
    input rst,

    output shortint p_sample_buffer,
    input trig
);

  shortint noise_lut[CLIP_LEN];
  noise_lut #(.LUT_SIZE(CLIP_LEN)) noise_lut_mod_inst (.lut(noise_lut));

  logic [VOLUME_BITS-1:0] volume_env;
  oneshot_enveloper #(
      .ATTACK_TIME(200),
      .DECAY_TIME (500)
  ) envelope_i (
      .mclk(mclk),
      .rst(rst),
      .trigger(trig),
      .volume_out(volume_env)
  );

  static reg [FREQ_RES_BITS-1:0] freq = 12 * 4;  // WARN: middle C
  shortint current_sample_novol;
  player_module #(
      .CLIP_LEN(CLIP_LEN),
      .FREQ_RES_BITS(FREQ_RES_BITS)
  ) player_module_i (
      .mclk(mclk),
      .rst(rst),
      .data_buffer(noise_lut),
      .p_frequency(freq),
      .player_sample(current_sample_novol),
      .valid()
  );

  shortint current_sample_nofilt;
  // assign the output
  volume_adjust #(
      .VOLUME_BITS(VOLUME_BITS)
  ) volume_adjust_tri (
      .sample_in(current_sample_novol),
      .sample_out(p_sample_buffer),
      .volume(volume_env)
  );

endmodule

module noise_lut #(
    parameter int LUT_SIZE = 256
) (
    output shortint lut[LUT_SIZE]
);

  // Constants for white noise generation
  localparam int MAX_VALUE = 32767;  // Max value for 16-bit signed integer
  localparam int MIN_VALUE = -32768;  // Min value for 16-bit signed integer

  // Generate the LUT values
  initial begin
    for (int i = 0; i < LUT_SIZE; i++) begin
      // Generate a random value between -32768 and 32767 (16-bit signed range)
      lut[i] = $signed($urandom)
          ;  // $random generates a 32-bit value, so we use $signed to ensure it's a signed value
    end
  end
endmodule

