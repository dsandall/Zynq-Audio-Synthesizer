module src_oneshot_808 #(
    parameter int CLIP_LEN = 32,
    parameter int VOLUME_BITS = 8,
    parameter int FREQ_RES_BITS = 8
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,

    output shortint p_sample_buffer,
    input trig
);

  shortint sine_lut[CLIP_LEN];
  sine_lut #(.LUT_SIZE(CLIP_LEN)) sine_lut_i (.lut(sine_lut));

  logic [VOLUME_BITS-1:0] volume_env;
  oneshot_enveloper envelope_i (
      .mclk(mclk),
      .rst(rst),
      .trigger(trig),
      .volume_out(volume_env)
  );

  static reg [FREQ_RES_BITS-1:0] freq = 12 * 1;
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


// implements rise, sustain, and fall
// will play indefinitely if not deasserted
// can be interrupted by reassertion of trigger
//
module oneshot_enveloper #(
    parameter int VOLUME_BITS = 8,
    parameter int FREQ_RES_BITS = 8,
    parameter int TIMESCALE = 1024,
    parameter int MAX_VOL = 2 ** 6,
    parameter int ATTACK_TIME = 500,
    parameter int DECAY_TIME = 5000
) (
    input logic mclk,
    input logic rst,
    input logic trigger,  // state machine resets volume envelope on posedge of trigger
    output logic [VOLUME_BITS-1:0] volume_out
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

        // Slowly ramp up
        ATTACK: begin
          if (attack_counter < (ATTACK_TIME * TIMESCALE)) begin
            attack_counter <= attack_counter + 1;
            volume_out <= (MAX_VOL * attack_counter / ATTACK_TIME) >> $clog2(TIMESCALE);
          end else begin
            volume_out <= MAX_VOL;
            state <= SUSTAIN;
          end
        end

        // Maintain max while trigger is high
        SUSTAIN: begin
          volume_out <= MAX_VOL;
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
          end else begin
            volume_out <= 0;
            state <= IDLE;
          end
        end

        // Wait for trigger, keep volume at 0
        IDLE: begin
          volume_out <= 0;
          attack_counter <= 0;
          release_counter <= 0;
        end
      endcase
    end
  end

endmodule
