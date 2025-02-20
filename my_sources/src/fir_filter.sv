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
  assign coeff[0] = 2;  // WARN: these were hastily made
  assign coeff[1] = 6;
  assign coeff[2] = 10;
  assign coeff[3] = 6;
  assign coeff[4] = 2;

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

module fir_filter_adjustable (
    input  logic          clk,        // Clock signal
    input  logic          rst,        // Reset signal
    input  shortint       sample_in,  // 16-bit signed audio sample
    input  logic    [3:0] S,          // 4-bit scaling factor
    output shortint       sample_out  // 16-bit signed filtered output
);

  // Delay line to store previous samples (5-tap FIR filter)
  shortint delay_line[4:0];

  // Coefficients memory (5 sets of coefficients for different scaling factors)
  shortint coeff[5:0][4:0];

  // Example coefficients for different cutoffs (adjust these based on Fs_in)
  initial begin
    coeff[0] = '{2, 6, 10, 6, 2};  // Low cutoff (S = min)
    coeff[1] = '{3, 8, 12, 8, 3};  // Slightly higher cutoff
    coeff[2] = '{4, 10, 14, 10, 4};
    coeff[3] = '{5, 12, 16, 12, 5};
    coeff[4] = '{6, 14, 18, 14, 6};  // Higher cutoff
    coeff[5] = '{8, 16, 20, 16, 8};  // Highest cutoff (S = max)
  end

  // Selected coefficient bank
  shortint selected_coeff[4:0];

  // Select the coefficient set based on S
  always_comb begin
    case (S)
      4'b0000: selected_coeff = coeff[0];
      4'b0001: selected_coeff = coeff[1];
      4'b0010: selected_coeff = coeff[2];
      4'b0011: selected_coeff = coeff[3];
      4'b0100: selected_coeff = coeff[4];
      default: selected_coeff = coeff[5];  // Use highest cutoff for S > 4
    endcase
  end

  // FIR filtering operation
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      delay_line[0] <= 0;
      delay_line[1] <= 0;
      delay_line[2] <= 0;
      delay_line[3] <= 0;
      delay_line[4] <= 0;
      sample_out <= 0;
    end else begin
      // Shift samples through the delay line
      delay_line[4] <= delay_line[3];
      delay_line[3] <= delay_line[2];
      delay_line[2] <= delay_line[1];
      delay_line[1] <= delay_line[0];
      delay_line[0] <= sample_in;

      // Compute filtered output
      sample_out <= (delay_line[0] * selected_coeff[0] +
                     delay_line[1] * selected_coeff[1] +
                     delay_line[2] * selected_coeff[2] +
                     delay_line[3] * selected_coeff[3] +
                     delay_line[4] * selected_coeff[4]) >>> 5; // Normalize output
    end
  end

endmodule

module fir_lowpass #(
    parameter N = 16  // Number of filter taps (Adjust as needed)
) (
    input                    clk,  // 256× Clock B
    input                    rst,  // Reset
    input  signed     [15:0] din,  // Input sample
    output reg signed [15:0] dout  // Filtered output
);

  // FIR Filter Coefficients (Placeholder values, replace with actual LPF coefficients)
  reg signed [15:0] coeffs[0:15] = '{
      -79,
      -136,
      312,
      654,
      -1244,
      -2280,
      4501,
      14655,
      14655,
      4501,
      -2280,
      -1244,
      654,
      312,
      -136,
      -79
  };

  // Shift Register for storing past inputs
  reg signed [15:0] shift_reg[0:N-1];

  // Multiply-Accumulate (MAC) Output
  reg signed [31:0] mac_result;

  integer i;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      // Reset shift registers and output
      for (i = 0; i < N; i = i + 1) begin
        shift_reg[i] <= 16'd0;
      end
      dout <= 16'd0;
    end else begin
      // Shift in new sample
      for (i = N - 1; i > 0; i = i - 1) begin
        shift_reg[i] <= shift_reg[i-1];
      end
      shift_reg[0] <= din;

      // FIR Convolution (MAC Operation)
      mac_result = 32'd0;
      for (i = 0; i < N; i = i + 1) begin
        mac_result = mac_result + (shift_reg[i] * coeffs[i]);
      end

      // Output result (truncated to 16-bit)
      dout <= mac_result >>> 8;  // Adjust bit shift based on coefficient scaling
    end
  end
endmodule
