`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/22/2025 09:00:32 PM
// Module Name: pain_and_suffering
// Additional Comments: // I2S Transciever
//////////////////////////////////////////////////////////////////////////////////


localparam int CLIP_LEN = 64;

module pain_and_suffering (
  // I2S
    output reg audio_I2S_bclk,   // Bit Clock
    output reg audio_I2S_pbdat,  // Playback Data
    output reg audio_I2S_pblrc,  // Word Select (LR Clock)
    input      mclk,              // Master Clock (256x sample rate)

// BRAM
    // input clk, // we're gonna try using MCLK
    input rst,

    output [31:0] BRAM_addr,
    output BRAM_clk,
    output [31:0] BRAM_din,
    input [31:0] BRAM_dout,
    output BRAM_en,
    output BRAM_rst,
    output [3:0] BRAM_we
);



  localparam int BRAM_DEPTH = 2048;
  localparam int SEQ_BITS = 32;
  localparam int CLK_MHZ = 100;

  logic [SEQ_BITS-1:0] seq_num;
  logic seq_valid;

  logic [31:0] address;
  logic [31:0] counter;

  logic get_next_number;
  assign get_next_number = (counter == 1) ? 1 : 0; // triggers the Fibonacci module when counter == 1

  localparam int COUNTER_MAX = CLK_MHZ * 500000;

  fibonacci #(
      .SEQ_BITS(SEQ_BITS)
  ) fibonacci_i (
      .clk(clk),
      .rst(rst | address == BRAM_DEPTH-1), // reset on external reset, or when reaching the end of the bram

      .get_next_number(get_next_number),
      .seq(seq_num),
      .seq_valid(seq_valid)

  );



  // at each clock,
  always_ff @(posedge clk) begin
    if (rst) begin
      address <= 0;
      counter <= 0;
    end else begin

      // if the fib has completed, increment the BRAM address (post-write)
      if (seq_valid) begin
        if (address < BRAM_DEPTH - 1) begin
          address <= address + 1;
        end else begin
          address <= 0;
        end
      end

      //if
      if (counter < COUNTER_MAX - 1) begin
        counter <= counter + 1;
      end else begin
        counter <= 0;
      end

    end
  end


  assign BRAM_addr = address << 2;
  assign BRAM_clk  = clk;
  assign BRAM_din  = seq_num;
  assign BRAM_en   = 1;
  assign BRAM_rst  = rst;  //BRAM reset by external
  assign BRAM_we   = {4{seq_valid}};  // 4 bit write enable signal? why not just one bit tho











////// I2C Begin





















  // Parameters
  //localparam int SAMPLE_RATE = 44100;  // Sample rate in Hz
  localparam int MCLK_DIV = 256;  // MCLK to SAMPLE_RATE divider
  localparam int BCLK_DIV = 32;  // must send 16 bits per cycle, per channel

  // Registers
  int        bclk_divider = 0;  // Toggles to generate BCLK
  int        lr_divider = 0;  // Toggles to generate LRCLK

  // The Data
  // playback frequency = sample_freq / sample_freq_divider
  int        sample_index = 0;
  reg [15:0] sample                    [CLIP_LEN - 1];

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
    if (lr_divider >= (16 - 1)) begin
      lr_divider <= 0;
      audio_I2S_pblrc <= ~audio_I2S_pblrc;
    end

    // manage the sample data
    audio_I2S_pbdat <= sample[(16-1)-lr_divider][sample_index];
  end

  // change the sample being played (the magnitude of the square wave)
  always @(negedge audio_I2S_pblrc) begin

    sample_index++;

    if (sample_index == CLIP_LEN) begin
      sample_index = 0;
    end

  end

endmodule
