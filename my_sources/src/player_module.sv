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

module player_module #(
    parameter int SAMPLE_BITS = 16,
    parameter int CLIP_LEN,
    parameter int VOLUME_BITS = 4
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,

    input [7:0] m_sample_index,
    output [SAMPLE_BITS-1 : 0] p_sample_buffer,
    output valid,

    input [VOLUME_BITS-1 : 0] volume
);

  //shortint sample[CLIP_LEN],

  assign p_sample_buffer = 0;

endmodule
