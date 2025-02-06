module volume_adjust #(
    parameter int VOLUME_BITS
) (
    input  shortint                     sample_in,  // 16-bit audio sample
    input  logic    [VOLUME_BITS-1 : 0] volume,     // 4-bit volume index (0 to 8)
    output shortint                     sample_out  // Scaled 16-bit sample
);

  logic signed [(15+VOLUME_BITS):0] extended_sample;
  assign extended_sample[15+VOLUME_BITS : 15] = {(VOLUME_BITS + 1) {sample_in[15]}};
  assign extended_sample[14:0] = sample_in[14:0];

  logic signed [(15+VOLUME_BITS):0] scaled_sample;

  always_comb begin
    scaled_sample = {{(VOLUME_BITS + 1) {sample_in[15]}}, sample_in[14:0]} * volume;
    sample_out = scaled_sample >>> VOLUME_BITS;
  end

endmodule
