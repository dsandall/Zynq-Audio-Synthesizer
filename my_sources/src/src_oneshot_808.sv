module src_oneshot_808 #(
    parameter int CLIP_LEN,
    parameter int VOLUME_BITS,
    parameter int FREQ_RES_BITS
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,

    output shortint p_sample_buffer,
    input enable
);

  shortint triangle_lut[0:31];
  //triangle_lut triangle_lut_mod_inst (.lut(triangle_lut));

  shortint current_sample_novol;
  player_module #(
      .CLIP_LEN(CLIP_LEN),
      .FREQ_RES_BITS(FREQ_RES_BITS),
      .FREQ_PRESCALE(512)
  ) player_module_i (
      .mclk(mclk),
      .rst(rst),
      .p_frequency(p_frequency),
      .data_buffer(triangle_lut),
      .player_sample(current_sample_novol),
      .valid(valid)
  );

  shortint current_sample_nofilt;
  // assign the output
  volume_adjust #(
      .VOLUME_BITS(4)
  ) volume_adjust_tri (
      .sample_in(current_sample_novol),
      .sample_out(current_sample_nofilt),
      .volume(volume[3:0])
  );

  fir_lowpass #() lp_filter (
      .clk (mclk),
      .rst (rst),
      .din (current_sample_nofilt),
      .dout(p_sample_buffer)
  );

endmodule
