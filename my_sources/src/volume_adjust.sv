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

  int extended_sample;
  assign extended_sample = sample_in;

  logic signed [(15 + VOLUME_BITS):0] scaled_sample;

  always_comb begin
    scaled_sample = extended_sample * volume;
    sample_out = scaled_sample >>> VOLUME_BITS;  // Right shift to fit into 16-bit output
  end

endmodule




module pitch_shift_lut (
    input  logic [ 3:0] n,           // n is the semitone offset (0 to 11)
    output logic [31:0] period_mult  // LUT value (output as a 32-bit fixed-point value)
);

  // Declare the LUT as a constant array. Each entry corresponds to 2^(-n/12).
  // Use a 32-bit fixed-point representation to maintain precision, but scaled by 2^12.
  // The array is indexed by 'n', which will be between 0 and 11.
  // The values represent 2^(-n/12) * 2^12 for fixed-point scaling.
  localparam int semitonesPerOctave = 12;

  const
  logic [31:0]
  lut[semitonesPerOctave] = {
    32'h1000,  // 2^0/12 (n=0)
    32'hF1A,  // 2^(-1/12) (n=1)
    32'hE41,  // 2^(-2/12) (n=2)
    32'hd74,  // 2^(-3/12) (n=3)
    32'hcb3,  // 2^(-4/12) (n=4)
    32'hbfd,  // 2^(-5/12) (n=5)
    32'hb50,  // 2^(-6/12) (n=6)
    32'haae,  // 2^(-7/12) (n=7)
    32'ha14,  // 2^(-8/12) (n=8)
    32'h983,  // 2^(-9/12) (n=9)
    32'h8fb,  // 2^(-10/12) (n=10)
    32'h87a  // 2^(-11/12) (n=11)
  };

  // Always block to read the LUT value based on 'n'
  always_comb begin
    period_mult = lut[n];  // Access the LUT value corresponding to the semitone offset 'n'
  end

endmodule


