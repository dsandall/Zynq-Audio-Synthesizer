// localparam PLAYER_CLIP_LEN = 32;
//  int player_vol = 4;
//  shortint player_sample_buffer;  // Buffer for data read from BRAM
//  player_module #(
//      .SAMPLE_BITS(SAMPLE_BITS),
//      .CLIP_LEN(PLAYER_CLIP_LEN),
//  ) player_module_i (
//      .mclk(audio_cons_mclk),
//      .rst (rst),
//
//      .m_sample_index(m_sample_index),
//      .p_sample_buffer(player_sample_buffer),
//      .valid(player_valid),
//
//      .volume(player_vol)
//  );

parameter int LUT_SIZE = 32;
module triangle_lut (
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
    parameter int CLIP_LEN = 32,
    parameter int VOLUME_BITS,
    parameter int FREQ_RES_BITS
) (

    input mclk,  // Master Clock (256x sample rate)
    input rst,

    output shortint p_sample_buffer,
    output valid,

    input [  VOLUME_BITS-1 : 0] volume,
    input [FREQ_RES_BITS-1 : 0] p_frequency
);

  shortint triangle_lut[32];
  triangle_lut triangle_lut_mod_inst (.lut(triangle_lut));

  shortint current_sample_novol;
  player_module #(
      .CLIP_LEN(CLIP_LEN),
      .FREQ_RES_BITS(FREQ_RES_BITS),
      .FREQ_PRESCALE(512)
  ) player_module_i (
      .mclk(mclk),
      .rst(rst),
      .p_frequency(p_frequency),
      .data_buffer(triangle_lut),
      .player_sample(current_sample_novol),
      .valid(valid)
  );

  shortint current_sample_nofilt;
  // assign the output
  volume_adjust #(
      .VOLUME_BITS(VOLUME_BITS)
  ) volume_adjust_tri (
      .sample_in(current_sample_novol),
      .sample_out(current_sample_nofilt),
      .volume(volume)
  );

  fir_lowpass #() lp_filter (
      .clk (mclk),
      .rst (rst),
      .din (current_sample_nofilt),
      .dout(p_sample_buffer)
  );

endmodule


//
//
//
// WARN: untested vvv
//
//
//

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

  parameter integer DEBOUNCE_COUNT = 50_000;  // Adjust as needed
  logic [$clog2(DEBOUNCE_COUNT)-1:0] counter = 0;

  always_ff @(posedge clk) begin
    case (state)
      IDLE:   if (btn_raw) state <= WAIT;  // Detect button press
      WAIT: begin
        if (counter < DEBOUNCE_COUNT) counter <= counter + 1;
        else state <= STABLE;  // Confirm stable button press
      end
      STABLE: if (!btn_raw) state <= IDLE;  // Wait for release
    endcase
  end

  assign btn_stable = (state == STABLE);
endmodule





module button_activated_attack_release #(
    parameter int CLIP_LEN = 32,
    parameter int VOLUME_BITS = 4,  // Volume range: 0 to 7 (3-bit value)
    parameter int FREQ_RES_BITS = 4  // Frequency resolution bits
) (
    input logic mclk,  // Master Clock (256x sample rate)
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
      case (state)
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

