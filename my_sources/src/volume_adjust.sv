//module volume_adjust #(
//    parameter int VOLUME_BITS = 4
//) (
//    input  shortint                     sample_in,  // 16-bit audio sample
//    input  logic    [VOLUME_BITS-1 : 0] volume,     // 4-bit volume index (0 to 8)
//    output shortint                     sample_out  // Scaled 16-bit sample
//);
//
//  logic signed [(15+VOLUME_BITS):0] extended_sample;
//  assign extended_sample[15+VOLUME_BITS : 15] = {(VOLUME_BITS + 1) {sample_in[15]}};
//  assign extended_sample[14:0] = sample_in[14:0];
//
//  logic signed [(15+VOLUME_BITS):0] scaled_sample;
//
//  always_comb begin
//    scaled_sample = {{(VOLUME_BITS + 1) {sample_in[15]}}, sample_in[14:0]} * volume;
//    sample_out = scaled_sample >>> VOLUME_BITS;
//  end
//
//endmodule


module volume_adjust #(
    parameter int VOLUME_BITS = 8  // Default to 8 bits for better resolution
) (
    input  shortint                     sample_in,  // 16-bit audio sample
    input  logic    [VOLUME_BITS-1 : 0] volume,     // Volume index (0 to 255 for 8-bit)
    output shortint                     sample_out  // Scaled 16-bit sample
);

  // Extend the sample to match the full resolution (with extra bits for scaling)
  logic signed [(15 + VOLUME_BITS):0] extended_sample;

  // Extend the sample to be signed and include VOLUME_BITS extra bits
  assign extended_sample[15+VOLUME_BITS : 15] = {(VOLUME_BITS + 1) {sample_in[15]}};
  assign extended_sample[14:0] = sample_in[14:0];

  // Declare the scaled sample
  logic signed [(15 + VOLUME_BITS):0] scaled_sample;

  // Scale the sample according to the volume control, accounting for higher resolution
  always_comb begin
    scaled_sample = extended_sample * volume;  // Multiply by volume value

    // Scale back by shifting according to the volume resolution
    // VOLUME_BITS represents the scaling factor for the increased resolution.
    sample_out = scaled_sample >>> VOLUME_BITS;  // Right shift to fit into 16-bit output
  end

endmodule
