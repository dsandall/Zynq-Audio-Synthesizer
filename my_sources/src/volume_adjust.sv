module volume_adjust_old (
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


module volume_adjust (
    input  shortint       sample_in,  // 16-bit audio sample
    input  logic    [7:0] volume,     // 4-bit volume index (0 to 8)
    output shortint       sample_out  // Scaled 16-bit sample
);

  wire [3:0] volume_4bit = volume[3:0];

  // LUT for volume scaling (precomputed values, scaled to 8-bit fixed-point)
  shortint volume_lut[0:8] = {
    8'd1,  // 0.00398 (~ -48 dB)
    8'd2,  // 0.00794 (~ -42 dB)
    8'd4,  // 0.01585 (~ -36 dB)
    8'd8,  // 0.03162 (~ -30 dB)
    8'd16,  // 0.06310 (~ -24 dB)
    8'd32,  // 0.12589 (~ -18 dB)
    8'd64,  // 0.25119 (~ -12 dB)
    8'd128,  // 0.50119 (~ -6 dB)
    8'd255  // 1.00000 (~ 0 dB, full volume)
  };

  int scaled_sample;

  always_comb begin
    scaled_sample = (sample_in * volume_lut[volume_4bit]) >>> 8;  // Apply scaling
  end

  assign sample_out = {scaled_sample[31], scaled_sample[(16-2):0]};  // Clip to 16-bit output

endmodule
