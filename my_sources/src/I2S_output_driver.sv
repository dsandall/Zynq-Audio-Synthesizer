`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/22/2025 09:00:32 PM
// Module Name: pain_and_suffering
// Additional Comments: // I2S Transciever
//////////////////////////////////////////////////////////////////////////////////

module I2S_output_driver #(
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

  volume_adjust #(
      .VOLUME_BITS(8)
  ) volume_adjust_i (
      .sample_in(sample[sample_index]),
      .sample_out(volume_adjusted_sample),
      .volume(volume)
  );

  ////// MCLK
  //clock divider to create BCLK
  always_ff @(negedge mclk) begin
    bclk_divider <= bclk_divider + 1;

    if (bclk_divider >= (MCLK_DIV / BCLK_DIV) - 1) begin
      bclk_divider   <= 0;
      audio_I2S_bclk <= ~audio_I2S_bclk;
    end
  end

  /////// BCLK
  // generate pblrclk
  // generate pbdata
  always_ff @(negedge audio_I2S_bclk) begin

    // clock divide PBLRC from BCLK (this denotes the begin and end of
    // a sample, offset by one bit. refer to I2S spec)
    lr_divider <= lr_divider + 1;
    if (lr_divider >= (SAMPLE_BITS - 1)) begin
      lr_divider <= 0;
      audio_I2S_pblrc <= ~audio_I2S_pblrc;
    end

    // manage the sample data
    audio_I2S_pbdat <= volume_adjusted_sample[(SAMPLE_BITS-1)-lr_divider];
    //audio_I2S_pbdat <= novol_sample[(SAMPLE_BITS-1)-lr_divider];  //WARN: NOVOL used
  end

  ////// negedge PBLRC
  // increment sample index on start of each left sample transmission (or
  // right, i dont remember at the moment, check the spec)
  always_ff @(negedge audio_I2S_pblrc) begin

    if (sample_index == (CLIP_LEN - 1)) begin
      sample_index <= 0;
    end else begin
      sample_index <= sample_index + 1;
    end

  end

endmodule
