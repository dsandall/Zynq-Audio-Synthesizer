module src_oneshot_hihat #(
    parameter int CLIP_LEN = 256,
    parameter int VOLUME_BITS = 8,
    parameter int FREQ_RES_BITS = 8
) (
    input mclk,   // Master Clock (256x sample rate)
    input pblrc,
    input rst,

    output shortint p_sample_buffer,
    input trig,
    input sw
);

  shortint noise_lut[CLIP_LEN];
  noise_lut #(.LUT_SIZE(CLIP_LEN)) noise_lut_mod_inst (.lut(noise_lut));


  //WARN: This is sloppy
  //
  // Trigger debounce logic
  logic trigger_prev = 0;  // Previous state of trigger signal
  logic trigger_rising_edge = 0;  // Flag for rising edge detection

  // Debouncing the trigger to detect rising edge
  always_ff @(posedge pblrc) begin
    trigger_prev <= trig;
    trigger_rising_edge <= trig && !trigger_prev;  // Detect rising edge (trigger asserted)
  end
  //WARN: This is sloppy


  logic [VOLUME_BITS-1:0] volume_env;
  oneshot_enveloper #(
      .ATTACK_TIME(200),
      .DECAY_TIME (500)
  ) envelope_i (
      .mclk(mclk),
      .rst(rst),
      .trigger(trigger_rising_edge),
      .volume_out(volume_env)
  );

  static reg [FREQ_RES_BITS-1:0] freq = 12 * 2;
  shortint current_sample_novol;
  player_module #(
      .CLIP_LEN(CLIP_LEN),
      .FREQ_RES_BITS(FREQ_RES_BITS)
  ) player_module_i (
      .mclk(mclk),
      .rst(rst),
      .data_buffer(noise_lut),
      .p_frequency(freq),
      .player_sample(current_sample_novol),
      .valid()
  );

  shortint current_sample_nofilt;
  // assign the output
  volume_adjust #(
      .VOLUME_BITS(VOLUME_BITS)
  ) volume_adjust_tri (
      .sample_in(current_sample_novol),
      .sample_out(current_sample_nofilt),
      .volume(volume_env)
  );

  // AA LP filter
  shortint current_sample_aafilt;
  fir_lowpass #() aa_filt_i (
      .clk(pblrc),
      .rst(rst),
      .sample_in(current_sample_nofilt),
      .sample_out(current_sample_aafilt)
  );

  // hp filter to bring out the hihat-ness
  shortint current_sample_final;
  hihat_highpass_filter hihat_filt_i (
      .sample_in(current_sample_aafilt),
      .sample_out(current_sample_final),
      .clk(pblrc),
      .rst(rst)
  );

  assign p_sample_buffer = sw ? current_sample_final : current_sample_aafilt;
endmodule


module hihat_highpass_filter (
    input  shortint sample_in,   // 16-bit signed input sample
    output shortint sample_out,  // 16-bit signed output sample
    input  logic    clk,         // Clock signal
    input  logic    rst          // Reset signal
);

  localparam int NUM_COEF = 7;
  shortint h[NUM_COEF] = '{256, -461, -8051, 18101, -8051, -461, 256};

  generic_fir_filter #(
      .NUM_COEF(NUM_COEF)
  ) fir_lowpass_i (
      .sample_in(sample_in),
      .sample_out(sample_out),
      .clk(clk),
      .rst(rst),
      .coef(h)
  );

endmodule




module noise_lut #(
    parameter int LUT_SIZE = 256
) (
    output shortint lut[LUT_SIZE]
);

  /*
  // Constants for white noise generation
  localparam int MAX_VALUE = 32767;  // Max value for 16-bit signed integer
  localparam int MIN_VALUE = -32768;  // Min value for 16-bit signed integer

  // Generate the LUT values
  initial begin
    for (int i = 0; i < LUT_SIZE; i++) begin
      // Generate a random value between -32768 and 32767 (16-bit signed range)
      lut[i] = $signed($urandom)
          ;  // $random generates a 32-bit value, so we use $signed to ensure it's a signed value
    end
  end
*/

  shortint lut[NUM_COEF] = '{
      12671,
      16388,
      -26906,
      -24529,
      15197,
      -22902,
      -21482,
      11964,
      -18054,
      -16097,
      8842,
      3063,
      15688,
      -22855,
      9255,
      -16416,
      -21566,
      -561,
      29235,
      9877,
      -12656,
      -8681,
      28041,
      -235,
      -28320,
      -19316,
      28507,
      -31342,
      32062,
      -4744,
      -5888,
      7196,
      26416,
      -6332,
      -4363,
      -19161,
      -10477,
      -26283,
      -6735,
      -30255,
      15504,
      -26716,
      -9229,
      -32670,
      29861,
      -271,
      -26718,
      -21187,
      24164,
      -26444,
      -24530,
      -31613,
      -10876,
      8990,
      8954,
      -28020,
      23909,
      -13478,
      21230,
      -5233,
      -32391,
      -7223,
      21862,
      21606,
      -20040,
      -32159,
      -6352,
      -2437,
      67,
      -18674,
      -32610,
      32382,
      30491,
      2089,
      7975,
      -10052,
      21708,
      3901,
      -28267,
      11629,
      -29874,
      -12577,
      -30230,
      18484,
      -1586,
      11584,
      -7268,
      19466,
      -28842,
      -28639,
      -12181,
      5738,
      -17489,
      -5282,
      7066,
      7162,
      13089,
      17164,
      -11928,
      -23705,
      -29832,
      -5893,
      -12520,
      -4436,
      -4456,
      16132,
      16256,
      29867,
      -12114,
      -22711,
      -19296,
      -5303,
      -5586,
      24341,
      1319,
      -25087,
      -10226,
      -8987,
      8375,
      -13952,
      -16401,
      31316,
      -15634,
      -6509,
      31766,
      -8641,
      -2862,
      -8998,
      13275,
      -8799,
      24892,
      12145,
      -13535,
      703,
      21962,
      31273,
      -29060,
      356,
      -12,
      13629,
      -13143,
      -11055,
      15839,
      -3138,
      -27141,
      29303,
      7417,
      -28709,
      -6460,
      -13392,
      15376,
      -28548,
      28528,
      9462,
      -17571,
      -27810,
      207,
      -9775,
      -5896,
      -23000,
      2135,
      -20925,
      -3169,
      2064,
      -27818,
      16052,
      9310,
      16847,
      -30191,
      -19601,
      26004,
      7032,
      10590,
      -22993,
      24841,
      -30795,
      32616,
      5148,
      -25109,
      -17850,
      7097,
      -24278,
      28372,
      28816,
      29654,
      -31607,
      -27050,
      -9617,
      -9388,
      1698,
      -14852,
      17695,
      -19019,
      -23495,
      -22726,
      4442,
      29464,
      13640,
      32402,
      -30520,
      1767,
      30585,
      22398,
      -32167,
      23041,
      -21808,
      8662,
      18618,
      -18215,
      28588,
      -26373,
      24029,
      -26352,
      14181,
      -21329,
      10588,
      6866,
      -8195,
      17152,
      -30212,
      -26415,
      -4108,
      -4342,
      32723,
      -32440,
      5611,
      23316,
      19963,
      -8699,
      -24046,
      -28460,
      -14499,
      -32715,
      18880,
      29340,
      -16188,
      -7044,
      -26071,
      -28980,
      1923,
      -4823,
      -4595,
      18041,
      -9122,
      24365,
      -2146,
      -14913,
      -16984,
      -1289,
      -54,
      19408,
      12007,
      -12573,
      -4436,
      10904,
      5781
  };

endmodule

