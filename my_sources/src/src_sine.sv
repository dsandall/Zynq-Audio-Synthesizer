
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
    parameter int VOLUME_BITS = 8,
    parameter int FREQ_RES_BITS = 8
) (

    input mclk,   // Master Clock (256x sample rate)
    input pblrc,  // sample rate
    input rst,

    output shortint p_sample_buffer,

    input [7:0] overdrive,
    input [VOLUME_BITS-1 : 0] volume,
    input [FREQ_RES_BITS-1 : 0] p_frequency
);

  shortint sine_lut[CLIP_LEN];
  sine_lut #(.LUT_SIZE(CLIP_LEN)) sine_lut_i (.lut(sine_lut));

  shortint current_sample;
  enveloped_oscillator_module #(
      .CLIP_LEN(CLIP_LEN),
      .VOLUME_BITS(VOLUME_BITS),
      .FREQ_RES_BITS(FREQ_RES_BITS),
      .ATTACK(150),
      .DECAY(300)
  ) sine_i (
      .mclk(mclk),
      .pblrc(pblrc),
      .rst(rst),
      .p_sample_buffer(current_sample),
      .valid(),
      .volume(volume),
      .p_frequency(p_frequency),
      .sample_buffer(sine_lut)
  );

  // overdrive amp
  shortint current_sample_overdriven;
  overdrive overdrive_i (
      .sample_in(current_sample),
      .gain(overdrive),
      .sample_out(current_sample_overdriven)
  );

  assign p_sample_buffer = current_sample_overdriven;
endmodule

