/*
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
*/

/*
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
*/

/*
module fir_lowpass #(
    parameter int N = 16  // Number of filter taps (Adjust as needed)
) (
    input           clk,  // 256× Clock B
    input           rst,  // Reset
    input  shortint din,  // Input sample
    output shortint dout  // Filtered output
);

  // FIR Filter Coefficients (Placeholder values, replace with actual LPF coefficients)
  shortint coeffs[N] = '{
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
  shortint shift_reg[N];

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
*/

/*
// the newest one

// assumes 48khz sample rate
// 1000hz hp filter
module fir_highpass (
    input  shortint sample_in,   // 16-bit signed input sample
    output shortint sample_out,  // 16-bit signed output sample
    input  logic    sample_clk,  // Clock signal
    input  logic    mclk,
    input  logic    rst          // Reset signal
);

  localparam int NUM_COEF = 33;

  // coefficients for a 1000hz hp filter
  shortint h[NUM_COEF] = '{
      -46,
      -58,
      -84,
      -126,
      -187,
      -266,
      -364,
      -477,
      -602,
      -733,
      -865,
      -991,
      -1105,
      -1202,
      -1274,
      -1320,
      31477,
      -1320,
      -1274,
      -1202,
      -1105,
      -991,
      -865,
      -733,
      -602,
      -477,
      -364,
      -266,
      -187,
      -126,
      -84,
      -58,
      -46
  };

  generic_fir_filter #(
      .NUM_COEF(NUM_COEF)
  ) fir_highpass_i (
      .sample_in(sample_in),
      .sample_out(sample_out),
      .sample_clk(sample_clk),
      .clk_fast(mclk),
      .rst(rst),
      .coef(h)
  );

endmodule
*/

// the newest one
// assumes 48khz sample rate
module fir_lowpass (
    input  shortint sample_in,   // 16-bit signed input sample
    output shortint sample_out,  // 16-bit signed output sample
    input  logic    sample_clk,  // Clock signal
    input  logic    mclk,
    input  logic    rst          // Reset signal
);

  localparam int NUM_COEF = 24;

  // py set to 20khz
  shortint h[NUM_COEF] = '{
      -70,
      68,
      -42,
      -72,
      324,
      -693,
      1049,
      -1140,
      622,
      971,
      -4740,
      20108,
      20108,
      -4740,
      971,
      622,
      -1140,
      1049,
      -693,
      324,
      -72,
      -42,
      68,
      -70
  };

  /*
  generic_fir_filter #(
      .NUM_COEF(NUM_COEF)
  ) fir_lowpass_i (
      .sample_in(sample_in),
      .sample_out(sample_out),
      .sample_clk(sample_clk),
      .clk_fast(mclk),
      .rst(rst),
      .coef(h)
  );
*/

  pipelined_fir_filter #(
      .NUM_COEF(NUM_COEF)
  ) firstrd_lowpass_i (
      .sample_in(sample_in),
      .sample_out(sample_out),
      .sample_clk(sample_clk),
      .clk_fast(mclk),
      .rst(rst),
      .coef(h)
  );

endmodule

module pipelined_fir_filter #(
    parameter int NUM_COEF  // this should be 32 or 33
) (
    input  shortint sample_in,             // 16-bit signed input sample
    output shortint sample_out,            // 16-bit signed output sample
    input  logic    sample_clk,            // Clock signal
    input  logic    rst,                   // Reset signal
    input  shortint coef      [NUM_COEF],
    input  logic    clk_fast               // 256x faster clock
);

  // tasks per sample clock
  // shift new sample in, and shift all the others along
  // move accumulation to output (after shifting)
  // sum all h*x

  // Define the shift register for the FIR filter
  shortint x[NUM_COEF];  // Input shift register (delay line)
  int accumulator;  // To hold the intermediate results

  always_ff @(posedge sample_clk) begin
    if (rst) begin
      x <= '{default: 16'sd0};
      sample_out <= 0;
    end else begin

      for (int i = 1; i < NUM_COEF; i++) begin
        x[i] <= x[i-1];  // Shift all previous samples
      end

      x[0] <= sample_in;


      // use the result of the FSM and set it up again
      sample_out <= accumulator >>> 15;

    end
  end

  // handle accumulation
  typedef enum logic [1:0] {
    IDLE,
    ACCUMULATE,
    DONE
  } state_t;
  state_t state;
  int ia;
  reg last_trigger;

  always_ff @(posedge clk_fast) begin
    if (rst) begin
      ia <= 0;
      state <= ACCUMULATE;
      accumulator <= 0;
      last_trigger <= 0;
    end else begin

      unique case (state)

        IDLE: begin
          if (sample_clk != last_trigger) begin
            last_trigger <= sample_clk;  // save state

            ia <= 0;
            state <= ACCUMULATE;
            accumulator <= 0;
          end
        end

        ACCUMULATE: begin
          accumulator <= accumulator + (coef[ia] * x[ia]);

          ia <= ia + 1;
          if (ia + 1 == NUM_COEF) begin
            state <= IDLE;
          end
        end

      endcase

    end
  end

endmodule

/*
module generic_fir_filter #(
    parameter int NUM_COEF  // this should be 32 or 33
) (
    input  shortint sample_in,             // 16-bit signed input sample
    output shortint sample_out,            // 16-bit signed output sample
    input  logic    sample_clk,            // Clock signal
    input  logic    rst,                   // Reset signal
    input  shortint coef      [NUM_COEF],
    input  logic    clk_fast               // 256x faster clock
);

  // Define the shift register for the FIR filter
  shortint x[NUM_COEF];  // Input shift register (delay line)
  int accumulator;  // To hold the intermediate results

  always_ff @(posedge sample_clk or posedge rst) begin
    if (rst) begin
      // Reset the shift register and accumulator
      accumulator <= 32'sd0;
      sample_out  <= 16'sd0;
    end else begin

      // Shift the input values into the delay line
      x[0] <= sample_in;  // New sample enters the shift register
      for (int i = 1; i < NUM_COEF; i++) begin
        x[i] <= x[i-1];  // Shift all previous samples
      end

      // Apply the FIR filter: accumulator = sum of h[i] * x[i]
      accumulator <= 32'sd0;  // Reset accumulator for each new sample
      for (int i = 0; i < NUM_COEF; i++) begin
        accumulator = accumulator + (coef[i] * x[i]);
      end

      sample_out <= accumulator >>> 15;
    end
  end

endmodule
*/
