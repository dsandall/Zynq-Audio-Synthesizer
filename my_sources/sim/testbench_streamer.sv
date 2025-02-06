`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2025 09:32:52 PM
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench_streamer;

  // Testbench signals
  reg   mclk;  // Master Clock
  logic audio_I2S_bclk;  // Bit Clock
  logic audio_I2S_pbdat;  // Playback Data
  logic audio_I2S_pblrc;  // Word Select (LR Clock)

  // Instantiate the I2S controller
  pain_and_suffering pain_inst (
      .audio_I2S_bclk(audio_I2S_bclk),
      .audio_I2S_pbdat(audio_I2S_pbdat),
      .audio_I2S_pblrc(audio_I2S_pblrc),
      .mclk(mclk)
  );


  localparam CLIP_LEN = 32;
  reg [15:0] sample[CLIP_LEN - 1];

  initial begin
    $readmemh("unsigned_sine_wave_64_samples.coe", sample);  // Load the data from the .coe file
  end

  // Clock generation (mclk is 256 times the sample rate, 44kHz)
  initial begin
    mclk = 0;
    forever #45.5 mclk = ~mclk;  // 11.3 MHz clock (~256 times 44.1kHz)
  end

  // Monitoring output signals
  initial begin
    // Display the signal values
    $monitor("Time = %0t, BCLK = %b, PB_DAT = %b, LRCLK = %b", $time, audio_I2S_bclk,
             audio_I2S_pbdat, audio_I2S_pblrc);

    #100000;
  end

  // Simulation duration
  //    initial begin
  //        // Run the simulation for a while to observe the behavior
  //        #100000;
  //        $finish;
  //    end

endmodule
