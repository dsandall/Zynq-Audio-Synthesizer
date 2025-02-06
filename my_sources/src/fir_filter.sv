module fir_filter (
    input  logic    clk,        // Clock signal
    input  logic    rst,        // Reset signal
    input  shortint sample_in,  // 16-bit signed audio sample (shortint)
    output shortint sample_out  // 16-bit signed filtered output (shortint)
);

  // Delay line to store previous samples (5 taps for a simple FIR filter)
  shortint delay_line[4:0];

  // FIR filter coefficients (for a simple low-pass filter, you can adjust these)
  shortint coeff[4:0];
  assign coeff[0] = 4;  // WARN: these were hastily made
  assign coeff[1] = 10;
  assign coeff[2] = 14;
  assign coeff[3] = 10;
  assign coeff[4] = 4;

  // Always block for filter operation
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      // Clear delay line and output on reset
      delay_line[0] <= 0;
      delay_line[1] <= 0;
      delay_line[2] <= 0;
      delay_line[3] <= 0;
      delay_line[4] <= 0;
      sample_out <= 0;
    end else begin
      // Shift input samples through the delay line
      delay_line[4] <= delay_line[3];
      delay_line[3] <= delay_line[2];
      delay_line[2] <= delay_line[1];
      delay_line[1] <= delay_line[0];
      delay_line[0] <= sample_in;

      // Apply FIR filter (convolution of input with coefficients)
      sample_out <= (delay_line[0] * coeff[0] +
                     delay_line[1] * coeff[1] +
                     delay_line[2] * coeff[2] +
                     delay_line[3] * coeff[3] +
                     delay_line[4] * coeff[4]) >>> 5; // Normalize by shifting down
    end
  end

endmodule
