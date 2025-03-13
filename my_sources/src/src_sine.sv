
module sine_lut #(
    parameter int LUT_SIZE = 64
) (
    output shortint lut[LUT_SIZE]
);

  // Constants for sine wave generation
  localparam real PI = 3.14159265358979323846;
  localparam int MAX_VALUE = 32767;  // Max value for 16-bit signed integer
  localparam int MIN_VALUE = -32768;  // Min value for 16-bit signed integer

  // Generate the LUT values
  initial begin
    for (int i = 0; i < LUT_SIZE; i++) begin
      // Calculate sine value (scaled to 16-bit signed integer range)
      lut[i] = $rtoi(MAX_VALUE * $sin(2 * PI * i / LUT_SIZE));
    end
  end
endmodule

////////
//
module src_sine #(
    parameter int CLIP_LEN = 64,
    parameter int VOLUME_BITS,
    parameter int FREQ_RES_BITS
) (

    input mclk,   // Master Clock (256x sample rate)
    input pblrc,  // sample rate
    input rst,


    output shortint p_sample_buffer,
    output valid,

    input [VOLUME_BITS-1 : 0] volume,
    input [FREQ_RES_BITS-1 : 0] p_frequency,
    input sw
);

  shortint sine_lut[CLIP_LEN];
  sine_lut #(.LUT_SIZE(CLIP_LEN)) sine_lut_i (.lut(sine_lut));

  shortint current_sample_novol;
  player_module #(
      .CLIP_LEN(CLIP_LEN),
      .FREQ_RES_BITS(FREQ_RES_BITS)
  ) player_module_sine_i (
      .mclk(mclk),
      .rst(rst),
      .p_frequency(p_frequency),
      .data_buffer(sine_lut),
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
      .volume(volume)
  );

  shortint current_sample_filt;
  fir_lowpass #() lp_filter (
      .clk(pblrc),
      .rst(rst),
      .sample_in(current_sample_nofilt),
      .sample_out(current_sample_filt)
  );

  assign p_sample_buffer = sw ? current_sample_filt : current_sample_nofilt;

endmodule

