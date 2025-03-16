`timescale 1ns / 1ps

// WARN: this is currently inefficient, as the bram reads in chunks of
// 32, but the samples are stored in only the first 16 bits. If this
// becomes a constraint, pack the samples into words, or increase the
// frequency.

module I2S_bram_DMA #(
    parameter int NUM_WORDS = 256,
    parameter int CLIP_LEN = NUM_WORDS,
    parameter int VOLUME_BITS = 8,
    parameter int FREQ_RES_BITS = 8
) (
    input wire clk,  // Clock input
    input wire rst,  // Reset input

    output reg  [31:0] BRAM_addr,  // Address for BRAM
    output wire        BRAM_clk,   // Clock for BRAM
    output reg  [31:0] BRAM_din,   // Data to write to BRAM
    input  wire [31:0] BRAM_dout,  // Data read from BRAM
    output reg         BRAM_en,    // Enable BRAM
    output reg         BRAM_rst,   // Reset BRAM
    output reg  [ 3:0] BRAM_we,    // Write enable for BRAM_we

    input wire refresh,

    ////////////

    input wire mclk,  // mclk input
    input [VOLUME_BITS-1 : 0] volume,
    input [FREQ_RES_BITS-1 : 0] p_frequency,

    output valid,
    output shortint current_sample
);

  //
  // for the purposes of the player, we assume the BRAM to be static during
  // playback
  //

  shortint shortint_buffer[NUM_WORDS];

  shortint player_out;
  player_module #(
      .CLIP_LEN(CLIP_LEN),
      .FREQ_RES_BITS(FREQ_RES_BITS)
  ) player_module_i (
      .mclk(mclk),
      .rst(rst),
      .p_frequency(p_frequency),
      .data_buffer(shortint_buffer),
      .player_sample(player_out),
      .valid(valid)
  );

  // assign the output
  volume_adjust #(
      .VOLUME_BITS(8)
  ) volume_adjust_i (
      .sample_in(player_out),
      .sample_out(current_sample),
      .volume(volume)
  );


  //
  // end of player
  //

  //
  //
  ////
  // BRAM
  ////
  //
  //


  // State encoding
  typedef enum logic [2:0] {
    IDLE,
    READ,
    DONE
  } state_t;

  state_t state;

  // Connect BRAM clock to the system clock
  assign BRAM_clk = clk;

  localparam int BRAM_DELAY = 2;  // bram read delay
  localparam int BRAM_ADDR_INCREMENT = 4;


  reg [15:0] index;  // Index for accessing bram_data_buffer

  // Control logic for BRAM operations
  always_ff @(posedge clk) begin

    if (rst) begin
      BRAM_addr <= 0;
      BRAM_en <= 0;
      BRAM_rst <= 1;
      BRAM_we <= 0;
      index <= 0;
      state <= IDLE;
    end else begin

      BRAM_rst <= 0;  // De-assert BRAM reset after initialization

      unique case (state)
        IDLE: begin
          BRAM_en <= 1;
          BRAM_we <= 0;
          BRAM_addr <= 0;
          index <= 0;

          if (!rst) begin
            state <= READ;
          end

        end

        READ: begin

          BRAM_en <= 1;
          BRAM_we <= 0;

          index   <= index + 1;  // increment index

          if (index < NUM_WORDS) begin
            BRAM_addr <= BRAM_addr + BRAM_ADDR_INCREMENT;  // Increment address
          end

          if (index >= BRAM_DELAY) begin  //ie, not the first one
            // Store data in buffer, at correct index
            // also recall the bram is 32 bits, with samples stored in first
            // 16 bits of each word

            //bram_data_buffer[index-BRAM_DELAY] <= BRAM_dout;
            shortint_buffer[index-BRAM_DELAY] <= BRAM_dout[15:0]; // only using bottom 2 bytes of BRAM words
          end

          if (index == (NUM_WORDS + BRAM_DELAY)) begin
            state <= DONE;
          end

        end

        DONE: begin
          BRAM_en <= 0;
          BRAM_we <= 0;
          if (refresh) begin
            state <= IDLE;
          end

        end

        default: begin

        end
      endcase
    end
  end
endmodule
