module src_oneshot_808 #(
    parameter int CLIP_LEN,
    parameter int VOLUME_BITS,
    parameter int FREQ_RES_BITS
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,

    output shortint p_sample_buffer,
    input enable
);
  // WARN:
  // TODO:
  shortint triangle_lut[CLIP_LEN];
  triangle_lut #(.LUT_SIZE(CLIP_LEN)) triangle_lut_mod_inst (.lut(triangle_lut));

  logic [VOLUME_BITS-1:0] volume_env;
  oneshot_enveloper envelope_i (
      .mclk(mclk),
      .rst(rst),
      .trigger(enable),
      .volume_out(volume_env)
  );

  player_module #(
      .CLIP_LEN(CLIP_LEN),
      .FREQ_RES_BITS(FREQ_RES_BITS)
  ) player_module_i (
      .mclk(mclk),
      .rst(rst),
      .data_buffer(triangle_lut),
      .p_frequency(12 * 4),  // WARN: middle C
      .player_sample(current_sample_novol),
      .valid(valid)
  );

  shortint current_sample_nofilt;
  // assign the output
  volume_adjust #(
      .VOLUME_BITS(VOLUME_BITS)
  ) volume_adjust_tri (
      .sample_in(current_sample_novol),
      .sample_out(p_sample_buffer),
      .volume(volume_env * 3)  // WARN: sloppy volume scalar
  );

endmodule


module oneshot_enveloper #(
    parameter int VOLUME_BITS   = 8,
    parameter int FREQ_RES_BITS = 8
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
      volume_out <= 0;
      attack_counter <= 0;
      release_counter <= 0;
    end else if (trigger_rising_edge) begin
      // If trigger is asserted, reset state to ATTACK and reset counters
      state <= ATTACK;
      attack_counter <= 0;
      volume_out <= 0;
    end else begin
      // Main state machine logic
      unique case (state)
        // Slowly ramp up to volume 7 over ~50ms
        ATTACK: begin
          if (attack_counter < 50_000) begin
            attack_counter <= attack_counter + 1;
            volume_out <= attack_counter >> 13;  // Smooth ramp up (50k / 8)
          end else begin
            volume_out <= 7;
            state <= SUSTAIN;
          end
        end

        // Maintain max volume while trigger is high
        SUSTAIN: begin
          volume_out <= 7;
          if (!trigger) begin
            state <= RELEASE;
            release_counter <= 0;
          end
        end

        // Slowly lower volume to 0 over ~500ms
        RELEASE: begin
          if (release_counter < 500_000) begin
            release_counter <= release_counter + 1;
            volume_out <= 7 - (release_counter >> 16);  // Smooth ramp down
          end else begin
            volume_out <= 0;
            state <= IDLE;
          end
        end

        // Wait for trigger, keep volume at 0
        IDLE: begin
          volume_out <= 0;
          attack_counter <= 0;
        end
      endcase
    end
  end

endmodule
