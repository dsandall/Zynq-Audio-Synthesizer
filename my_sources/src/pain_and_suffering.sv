`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/22/2025 09:00:32 PM
// Module Name: pain_and_suffering
// Additional Comments: // I2S Transciever
//////////////////////////////////////////////////////////////////////////////////

module pain_and_suffering #(
    parameter int SAMPLE_BITS,
    parameter int CLIP_LEN,
    //parameter int FREQ_RES_BITS,
    parameter int VOLUME_BITS
) (
    // I2S
    output reg audio_I2S_bclk,  // Bit Clock
    output reg audio_I2S_pbdat,  // Playback Data
    output reg audio_I2S_pblrc,  // Word Select (LR Clock) (equal to the sample rate)
    input mclk,  // Master Clock (256x sample rate)

    // input  [3:0]switches, 
    // SAMPLE_REGISTERS
    shortint sample[CLIP_LEN],
    // input [FREQ_RES_BITS - 1:0] frequency,
    input [VOLUME_BITS-1:0] volume,
    output reg [7:0] sample_index
    // pointer to the current audio buffer
);

  ////// I2C Begin
  // Parameters
  // localparam int SAMPLE_RATE = 44100;  // Sample rate in Hz
  localparam int MCLK_DIV = 256;  // MCLK to SAMPLE_RATE divider
  localparam int BCLK_DIV = 32;  // must send 16 bits per cycle, per channel

  // Registers
  int bclk_divider = 0;  // Toggles to generate BCLK
  int lr_divider = 0;  // Toggles to generate LRCLK
  shortint volume_adjusted_sample;
  shortint novol_sample;
  assign novol_sample = sample[sample_index];


  ////TODO: calculate sine frequency based on divider, clip length, mclk
  //wire [FREQ_RES_BITS - 1: 0] playback_frequency_divider = frequency; //how many times should the same sample play befor the sample_index is incremented?

  // The Data
  // playback frequency = sample_freq / sample_freq_divider
  //
  initial begin
    sample_index = 0;
    audio_I2S_bclk = 0;
    audio_I2S_pblrc = 0;
    audio_I2S_pbdat = 0;
  end

  volume_shift volume_shift_i (
      .sample_in(sample[sample_index]),
      .sample_out(volume_adjusted_sample),
      .volume(volume)
  );

  ////// MCLK
  //clock divider to create BCLK
  always @(negedge mclk) begin
    bclk_divider <= bclk_divider + 1;

    if (bclk_divider >= (MCLK_DIV / BCLK_DIV) - 1) begin
      bclk_divider   <= 0;
      audio_I2S_bclk <= ~audio_I2S_bclk;
    end
  end

  /////// BCLK
  // generate pblrclk
  // generate pbdata
  always @(negedge audio_I2S_bclk) begin

    // clock divide PBLRC from BCLK (this denotes the begin and end of
    // a sample, offset by one bit. refer to I2S spec)
    lr_divider <= lr_divider + 1;
    if (lr_divider >= (SAMPLE_BITS - 1)) begin
      lr_divider <= 0;
      audio_I2S_pblrc <= ~audio_I2S_pblrc;
    end


    // manage the sample data
    //audio_I2S_pbdat <= volume_adjusted_sample[(SAMPLE_BITS-1)-lr_divider];
    audio_I2S_pbdat <= novol_sample[(SAMPLE_BITS-1)-lr_divider];
  end

  ////// negedge PBLRC
  // increment sample index on start of each left sample transmission (or
  // right, i dont remember at the moment, check the spec)
  always @(negedge audio_I2S_pblrc) begin

    if (sample_index == 0) begin
      sample_index = (CLIP_LEN - 1);
    end else begin
      sample_index--;
    end

  end

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
