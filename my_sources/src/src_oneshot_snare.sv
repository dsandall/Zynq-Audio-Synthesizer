module src_oneshot_snare #(
    parameter int CLIP_LEN = 64,
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

  reg debounced;
  debounce debouncer_i (
      .trig(trig),
      .clk (pblrc),
      .out (debounced)
  );

  logic [  VOLUME_BITS-1:0] volume_env;
  logic [FREQ_RES_BITS-1:0] freq_add;
  oneshot_enveloper_withpitch #(
      .ATTACK_TIME (800),
      .DECAY_TIME  (2000),
      .SEMITONE_ADD(0)
  ) envelope_i (
      .mclk(mclk),
      .rst(rst),
      .trigger(debounced),
      .volume_out(volume_env),
      .freq_add_out(freq_add)
  );

  shortint sine_lut[CLIP_LEN];
  sine_lut #(.LUT_SIZE(CLIP_LEN)) sine_lut_mod_inst (.lut(sine_lut));

  logic [FREQ_RES_BITS-1:0] base_freq = 12 * 3;
  logic [FREQ_RES_BITS-1:0] final_freq = base_freq + freq_add;
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
      .sample_out(current_sample_nofilt),
      .volume(volume_env)
  );

  // AA LP filter
  shortint current_sample_aafilt;
  fir_lowpass #() aa_filt_i (
      .sample_in(current_sample_nofilt),
      .sample_out(current_sample_aafilt),
      .sample_clk(pblrc),
      .mclk(mclk),
      .rst(rst)
  );

  assign p_sample_buffer = sw ? current_sample_nofilt : current_sample_aafilt;
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



module oneshot_enveloper_withpitch #(
    parameter int VOLUME_BITS = 8,
    parameter int FREQ_RES_BITS = 8,
    parameter int TIMESCALE = 1024,
    parameter int MAX_VOL = 2 ** 6,
    parameter int ATTACK_TIME = 500,
    parameter int DECAY_TIME = 5000,
    parameter int SEMITONE_ADD = 6
) (
    input logic mclk,
    input logic rst,
    input logic trigger,  // state machine resets volume envelope on posedge of trigger
    output logic [VOLUME_BITS-1:0] volume_out,
    output logic [FREQ_RES_BITS-1:0] freq_add_out
);

  // FSM States
  typedef enum logic [1:0] {
    IDLE,
    ATTACK,
    SUSTAIN,
    RELEASE
  } state_t;

  state_t state = IDLE;

  // Volume ramp control
  logic [$clog2(600_000)-1:0] attack_counter = 0;  // ~50ms at high freq
  logic [$clog2(6_000_000)-1:0] release_counter = 0;  // ~500ms

  // Trigger debounce logic
  logic trigger_prev = 0;  // Previous state of trigger signal
  logic trigger_rising_edge = 0;  // Flag for rising edge detection

  // Debouncing the trigger to detect rising edge
  always_ff @(posedge mclk) begin
    trigger_prev <= trigger;
    trigger_rising_edge <= trigger && !trigger_prev;  // Detect rising edge (trigger asserted)
  end

  // Main state machine control with trigger interrupt
  always_ff @(posedge mclk or posedge rst) begin
    if (rst) begin
      // Reset condition
      state <= IDLE;
    end else if (trigger_rising_edge) begin
      // If trigger is asserted, reset state to ATTACK and reset counters
      state <= ATTACK;
      attack_counter <= 0;
    end else begin

      // Main state machine logic
      unique case (state)

        // Note: I implemented the volume_out math with a mixture of
        // bitshifting and integer division. Selection of exclusively pow2
        // ATTACK_TIMEs could make this a single operation

        // Slowly ramp up vol
        // freq add starts at max and decays during fall
        ATTACK: begin
          if (attack_counter < (ATTACK_TIME * TIMESCALE)) begin
            attack_counter <= attack_counter + 1;
            volume_out <= (MAX_VOL * attack_counter / ATTACK_TIME) >> $clog2(TIMESCALE);
            freq_add_out <= SEMITONE_ADD;
          end else begin
            volume_out <= MAX_VOL;
            freq_add_out <= SEMITONE_ADD;
            state <= SUSTAIN;
          end
        end

        // Maintain max while trigger is high
        SUSTAIN: begin
          volume_out   <= MAX_VOL;
          freq_add_out <= SEMITONE_ADD;
          if (!trigger) begin
            state <= RELEASE;
            release_counter <= 0;
          end
        end

        // Slowly lower volume to 0
        RELEASE: begin
          if (release_counter < (DECAY_TIME * TIMESCALE)) begin
            release_counter <= release_counter + 1;
            //volume_out <= MAX_VOL - (release_counter >> 16);  // Smooth ramp down
            volume_out <= MAX_VOL - ((MAX_VOL * release_counter / DECAY_TIME) >> $clog2(TIMESCALE));
            freq_add_out <= SEMITONE_ADD - ((SEMITONE_ADD * release_counter / DECAY_TIME) >> $clog2(
                TIMESCALE
            ));
          end else begin
            volume_out <= 0;
            freq_add_out <= 0;
            state <= IDLE;
          end
        end

        // Wait for trigger, keep volume at 0
        IDLE: begin
          volume_out <= 0;
          freq_add_out <= 0;
          attack_counter <= 0;
          release_counter <= 0;
        end
      endcase
    end
  end

endmodule
