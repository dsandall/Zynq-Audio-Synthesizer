// jungle drum loop
// https://youtu.be/Hal5TuhjNDE

// TODO: use this to create hihat - feed in high passed noise, and make
// no attack with fast decay
// https://www.youtube.com/watch?v=lycuJKFHJFw&pp=ygUqaG93IHRvIG1ha2Ugc3ludGhlc2l6ZXIgaGloYXQgZnJvbSBzY3JhdGNo

// TODO: make snare - start with kick drum, but high-low pitch at begin, and
// add white noise spike/fade at begin https://youtu.be/Ky3yg8ghpo8


module src_oneshot_snare #(
    parameter int CLIP_LEN = 64,
    parameter int VOLUME_BITS = 8,
    parameter int FREQ_RES_BITS = 8
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,

    output shortint p_sample_buffer,
    input trig
);
  shortint sine_lut[CLIP_LEN];
  sine_lut #(.LUT_SIZE(CLIP_LEN)) sine_lut_mod_inst (.lut(sine_lut));

  // WARN: same as the 808 vol env right now
  logic [VOLUME_BITS-1:0] volume_env;
  oneshot_enveloper envelope_i (
      .mclk(mclk),
      .rst(rst),
      .trigger(trig),
      .volume_out(volume_env)
  );

  static reg [FREQ_RES_BITS-1:0] freq = 12 * 4;  // WARN: middle C
  shortint current_sample_novol;
  player_module #(
      .CLIP_LEN(CLIP_LEN),
      .FREQ_RES_BITS(FREQ_RES_BITS)
  ) player_module_i (
      .mclk(mclk),
      .rst(rst),
      .data_buffer(sine_lut),
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
      .sample_out(p_sample_buffer),
      .volume(volume_env)
  );

endmodule


// TODO: another option for producing random samples, could be lighter on hardware
module lfsr_random_noise (
    input             clk,       // Clock signal
    input             rst,       // Reset signal
    output reg [15:0] noise_out  // 16-bit signed random noise output
);

  // LFSR state register (16-bit)
  reg [15:0] lfsr_reg;

  // Define the feedback polynomial: x^16 + x^14 + x^13 + x^11 + 1
  wire feedback = lfsr_reg[15] ^ lfsr_reg[13] ^ lfsr_reg[12] ^ lfsr_reg[10];

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      // Reset the LFSR to a non-zero value (you can choose any non-zero value)
      lfsr_reg  <= 16'hACE1;  // Some non-zero value
      noise_out <= 16'sd0;  // Reset the output to zero
    end else begin
      // Shift the LFSR and apply feedback
      lfsr_reg <= {lfsr_reg[14:0], feedback};

      // Convert the LFSR value to signed 16-bit noise (signed interpretation)
      // Assuming that the most significant bit is the sign bit
      noise_out <= (lfsr_reg[15]) ? -lfsr_reg : lfsr_reg;  // Apply 2's complement for signed output
    end
  end

endmodule




//// TEST:
// WARN: From Chat
module my_module (
    input  logic       clk,               // Clock input
    input  logic       reset,             // Reset signal
    input  logic       start,             // External input to trigger the process
    input  logic [7:0] freq_add,          // Starting frequency
    input  logic [7:0] pitchRise,         // Number of frequency steps
    input  logic [7:0] pitchFall_delay,   // Delay (in clock cycles) for pitch fall
    input  logic [7:0] volStart,          // Starting volume
    input  logic [7:0] volumeFall_delay,  // Delay (in clock cycles) for volume fall
    input  logic [7:0] scale,             // Scale factor
    output logic [7:0] bram_freq,         // Output to frequency BRAM
    output logic [7:0] bram_vol           // Output to volume BRAM
);

  // Internal registers to hold loop counters
  reg [7:0] freq_counter;
  reg [7:0] vol_counter;
  reg [7:0] pitchFall_counter;
  reg [7:0] volumeFall_counter;

  // State machine for controlling the process
  typedef enum logic [1:0] {
    IDLE = 2'b00,
    PITCH_RISE = 2'b01,
    VOLUME_FALL = 2'b10
  } state_t;

  state_t state, next_state;

  // Sequential logic to handle state transitions and counter updates
  always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
      state <= IDLE;
      freq_counter <= 0;
      vol_counter <= 0;
      pitchFall_counter <= 0;
      volumeFall_counter <= 0;
    end else begin
      state <= next_state;
      if (state == PITCH_RISE) begin
        if (freq_counter < pitchRise) begin
          freq_counter <= freq_counter + 1;
        end
      end else if (state == VOLUME_FALL) begin
        if (vol_counter > 0) begin
          vol_counter <= vol_counter - 1;
        end
      end
    end
  end

  // Determine next state
  always_ff @(posedge clk) begin
    case (state)
      IDLE: begin
        if (start) begin
          next_state <= PITCH_RISE;
        end else begin
          next_state <= IDLE;
        end
      end

      PITCH_RISE: begin
        if (freq_counter < pitchRise) begin
          next_state <= PITCH_RISE;
        end else begin
          next_state <= VOLUME_FALL;
        end
      end

      VOLUME_FALL: begin
        if (vol_counter > 0) begin
          next_state <= VOLUME_FALL;
        end else begin
          next_state <= IDLE;
        end
      end

      default: next_state <= IDLE;
    endcase
  end

  // Output logic: Assign to BRAM outputs based on current state and counters
  always_ff @(posedge clk) begin
    case (state)
      PITCH_RISE: begin
        bram_freq <= freq_add + freq_counter;
        pitchFall_counter <= pitchFall_counter + 1;
        if (pitchFall_counter >= pitchFall_delay * scale) begin
          pitchFall_counter <= 0;
        end
      end
      VOLUME_FALL: begin
        bram_vol <= vol_counter;
        volumeFall_counter <= volumeFall_counter + 1;
        if (volumeFall_counter >= volumeFall_delay * scale) begin
          volumeFall_counter <= 0;
        end
      end
      default: begin
        bram_freq <= 0;
        bram_vol  <= 0;
      end
    endcase
  end

endmodule
