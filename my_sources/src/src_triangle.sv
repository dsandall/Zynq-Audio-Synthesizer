module triangle_lut #(
    parameter int LUT_SIZE = 64
) (
    output shortint lut[LUT_SIZE]
);

  // 16-bit signed triangle wave LUT
  localparam int M = 65536 / LUT_SIZE;
  localparam int B = -32768;
  // Generate the LUT values
  initial begin
    for (int i = 0; i < LUT_SIZE; i++) begin
      lut[i] = (i) * M + B;
    end
  end
endmodule

////////
//
module src_triangle #(
    parameter int CLIP_LEN = 64,
    parameter int VOLUME_BITS,
    parameter int FREQ_RES_BITS
) (

    input mclk,   // Master Clock (256x sample rate)
    input pblrc,  // sample rate
    input rst,

    output shortint p_sample_buffer,

    input [7:0] overdrive,
    input [VOLUME_BITS-1 : 0] volume,
    input [FREQ_RES_BITS-1 : 0] p_frequency
);

  shortint triangle_lut[CLIP_LEN];
  triangle_lut #(.LUT_SIZE(CLIP_LEN)) triangle_lut_mod_inst (.lut(triangle_lut));

  shortint current_sample;
  enveloped_oscillator_module #(
      .CLIP_LEN(CLIP_LEN),
      .VOLUME_BITS(VOLUME_BITS),
      .FREQ_RES_BITS(FREQ_RES_BITS),
      .ATTACK(150),
      .DECAY(300)
  ) sine_i (
      .mclk(mclk),
      .pblrc(pblrc),
      .rst(rst),
      .p_sample_buffer(current_sample),
      .valid(),
      .volume(volume),
      .p_frequency(p_frequency),
      .sample_buffer(triangle_lut)
  );


  // overdrive amp
  shortint current_sample_overdriven;
  overdrive overdrive_i (
      .sample_in(current_sample),
      .gain(overdrive),
      .sample_out(current_sample_overdriven)
  );

  assign p_sample_buffer = current_sample_overdriven;
endmodule


/*

module button_debouncer_fsm (
    input  logic clk,        // System clock
    input  logic btn_raw,    // Raw button input
    output logic btn_stable  // Debounced button output
);

  typedef enum logic [1:0] {
    IDLE,
    WAIT,
    STABLE
  } state_t;
  state_t state = IDLE;

  parameter integer DEBOUNCE_COUNT = 500;  // Adjust as needed
  logic [$clog2(DEBOUNCE_COUNT)-1:0] counter = 0;

  always_ff @(posedge clk) begin
    unique case (state)
      IDLE:   if (btn_raw) state <= WAIT;  // Detect button press
      WAIT: begin
        // wait for set period to let the bouncing finish
        if (counter < DEBOUNCE_COUNT) counter <= counter + 1;
        else begin
          state   <= STABLE;
          counter <= 0;
        end
      end
      STABLE: if (!btn_raw) state <= IDLE;  // Wait for release
    endcase
  end

  assign btn_stable = (state == STABLE);
endmodule



//
// button activated volume envelope with attack and release
//
module button_activated_attack_release #(
    parameter int CLIP_LEN = 32,
    parameter int VOLUME_BITS = 8,
    parameter int FREQ_RES_BITS = 8
) (
    input logic mclk,
    input logic rst,

    input logic button_raw,

    output logic [VOLUME_BITS-1:0] volume
);

  // Debounced button signal
  logic button_stable;
  button_debouncer_fsm debounce_i (
      .clk(mclk),
      .btn_raw(button_raw),
      .btn_stable(button_stable)
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

  always_ff @(posedge mclk or posedge rst) begin
    if (rst) begin
      state  <= IDLE;
      volume <= 0;
    end else begin
      unique case (state)
        // Wait for button press, keep volume at 0
        IDLE: begin
          volume <= 0;
          if (button_stable) begin
            state <= ATTACK;
            attack_counter <= 0;
          end
        end

        // Slowly ramp up to volume 7 over ~50ms
        ATTACK: begin
          if (attack_counter < 50_000) begin
            attack_counter <= attack_counter + 1;
            volume <= attack_counter >> 13;  // Smooth ramp up (50k / 8)
          end else begin
            volume <= 7;
            state  <= SUSTAIN;
          end
        end

        // Maintain max volume while button is pressed
        SUSTAIN: begin
          volume <= 7;
          if (!button_stable) begin
            state <= RELEASE;
            release_counter <= 0;
          end
        end

        // Slowly lower volume to 0 over ~500ms
        RELEASE: begin
          if (release_counter < 500_000) begin
            release_counter <= release_counter + 1;
            volume <= 7 - (release_counter >> 16);  // Smooth ramp down
          end else begin
            volume <= 0;
            state  <= IDLE;
          end
        end
      endcase
    end
  end

endmodule
*/
