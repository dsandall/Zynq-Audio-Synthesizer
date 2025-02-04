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
    parameter int CLIP_LEN = 32,
    parameter int VOLUME_BITS = 8,
    parameter int FREQ_RES_BITS = 4
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,

    input [7:0] m_sample_index,
    output shortint p_sample_buffer,
    output valid,

    input [  VOLUME_BITS-1 : 0] volume,
    input [FREQ_RES_BITS-1 : 0] p_frequency
);

  logic [5-1:0] player_sample_index;

  // 16-bit signed triangle wave LUT
  localparam int LUT_SIZE = 32;
  localparam int M = 65536 / LUT_SIZE;
  localparam int B = -32768;
  shortint triangle_lut[0:LUT_SIZE-1];
  // Generate the LUT values
  initial begin
    for (int i = 0; i < LUT_SIZE; i++) begin
      triangle_lut[i] = (i) * M + B;
    end
  end



  shortint current_sample_novol;
  assign current_sample_novol = triangle_lut[player_sample_index];
  // assign the output
  //assign p_sample_buffer = triangle_lut[player_sample_index] <<< volume;
  volume_shift volume_shift_i (
      .sample_in(current_sample_novol),
      .sample_out(p_sample_buffer),
      .volume(volume)
  );

  // playing the sample
  // mclk only (no rotating writes yet)
  int freq_counter;
  always @(negedge mclk) begin

    if (rst) begin
      player_sample_index = 0;
      freq_counter = 0;
    end else begin

      // increment the player index
      if (freq_counter == 0) begin
        freq_counter <= (256 * (p_frequency));
        player_sample_index <= player_sample_index + 1;

      end else begin
        freq_counter <= freq_counter - 1;
      end
    end
  end

  assign valid = 1;
endmodule


module volume_shift (
    input  logic signed [15:0] sample_in,  // 16-bit audio sample
    input  logic        [ 7:0] volume,     // 8-bit volume (0 to 255)
    output logic signed [15:0] sample_out  // Scaled 16-bit sample
);

  logic signed [15:0] temp;
  always_comb begin
    case (volume[7:5])  // Use upper 3 bits for coarse scaling
      3'b000: temp = sample_in >>> 8;  // ~ 0.0039 (1/256)
      3'b001: temp = (sample_in >>> 7) + (sample_in >>> 8);  // ~ 0.0117 (3/256)
      3'b010: temp = sample_in >>> 6;  // ~ 0.0156 (4/256)
      3'b011: temp = (sample_in >>> 5) + (sample_in >>> 7);  // ~ 0.0468 (12/256)
      3'b100: temp = sample_in >>> 4;  // ~ 0.0625 (16/256)
      3'b101: temp = (sample_in >>> 3) + (sample_in >>> 5);  // ~ 0.1406 (36/256)
      3'b110: temp = sample_in >>> 2;  // ~ 0.25 (64/256)
      3'b111: temp = (sample_in >>> 1) + (sample_in >>> 3);  // ~ 0.625 (160/256)
    endcase

    // Fine adjustment using lower bits
    if (volume[4]) temp = temp + (temp >>> 3);  // Adjust for midpoints
    if (volume[3]) temp = temp + (temp >>> 4);
    if (volume[2]) temp = temp + (temp >>> 5);
    if (volume[1]) temp = temp + (temp >>> 6);
    if (volume[0]) temp = temp + (temp >>> 7);
  end

  assign sample_out = temp;
endmodule
