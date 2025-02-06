// localparam PLAYER_CLIP_LEN = 32;
//  int player_vol = 4;
//  shortint player_sample_buffer;  // Buffer for data read from BRAM
//  player_module #(
//      .SAMPLE_BITS(SAMPLE_BITS),
//      .CLIP_LEN(PLAYER_CLIP_LEN),
//  ) player_module_i (
//      .mclk(audio_cons_mclk),
//      .rst (rst),
//
//      .m_sample_index(m_sample_index),
//      .p_sample_buffer(player_sample_buffer),
//      .valid(player_valid),
//
//      .volume(player_vol)
//  );

module triangle_lut #(
    parameter int LUT_SIZE = 32
) (
    output shortint lut[0:LUT_SIZE-1]
);

  // 16-bit signed triangle wave LUT
  localparam int M = 65536 / LUT_SIZE;
  localparam int B = -32768;
  // Generate the LUT values
  initial begin
    for (int i = 0; i < LUT_SIZE; i++) begin
      lut[i] = (i) * M + B;
    end
  end
endmodule

////////
//
module src_triangle #(
    parameter int CLIP_LEN,
    parameter int VOLUME_BITS,
    parameter int FREQ_RES_BITS
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,

    output shortint p_sample_buffer,
    output valid,

    input [  VOLUME_BITS-1 : 0] volume,
    input [FREQ_RES_BITS-1 : 0] p_frequency
);

  shortint triangle_lut[0:31];
  triangle_lut triangle_lut_mod_inst (.lut(triangle_lut));

  logic [$clog2(CLIP_LEN)-1:0] player_sample_index;
  player_module #(
      .CLIP_LEN(CLIP_LEN),
      .FREQ_RES_BITS(FREQ_RES_BITS)
  ) player_module_i (
      .mclk(mclk),
      .rst(rst),
      .valid(valid),
      .p_frequency(p_frequency),
      .player_sample_index(player_sample_index)
  );

  shortint current_sample_novol;
  shortint current_sample_vol;
  assign current_sample_novol = triangle_lut[player_sample_index];

  // assign the output
  volume_adjust #(
      .VOLUME_BITS(4)
  ) volume_adjust_tri (
      .sample_in(current_sample_novol),
      .sample_out(current_sample_vol),
      .volume(volume[3:0])
  );

  fir_filter fir_filter_i (
      .clk(player_sample_index[0]),
      .rst(rst),
      .sample_in(current_sample_vol),
      .sample_out(p_sample_buffer)
  );

endmodule
