`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: bram_general_interface
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Generalized BRAM Interface Template
//              Reads the first 5 words from BRAM and writes them back in reverse.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////





module I2S_bram_DMA #(
    parameter int NUM_WORDS
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

    output reg [31:0] bram_data_buffer[0:NUM_WORDS-1],  // Buffer for data read from BRAM

    input wire refresh

    //    //switches
    //    input      [ 3:0] switches,
    //    output     [31:0] gpio_ctrl_i_32b_tri_i,
    //    input      [31:0] gpio_ctrl_o_32b_tri_o,
    //    output            ip2intc_irpt_0,
    //    // I2S
    //    output reg        audio_I2S_bclk,         // Bit Clock (32x the sample rate)
    //    output reg        audio_I2S_pbdat,        // Playback Data
    //    output reg        audio_I2S_pblrc,        // Word Select (LR Clock)
    //    input             mclk                    // Master Clock (256x sample rate) 12.346 MHz

);









  ////
  // BRAM
  ////

  // State encoding
  typedef enum logic [2:0] {
    IDLE,
    READ,
    WAIT,
    REVERSE_WRITE,
    DONE
  } state_t;

  state_t state;

  // Connect BRAM clock to the system clock
  assign BRAM_clk = clk;

  localparam BRAM_DELAY = 2;  // bram read delay
  localparam BRAM_ADDR_INCREMENT = 4;


  reg [15:0] index;  // Index for accessing bram_data_buffer

  // Control logic for BRAM operations
  always_ff @(posedge clk or posedge rst) begin

    if (rst) begin
      BRAM_addr <= 0;
      BRAM_en <= 0;
      BRAM_rst <= 1;
      BRAM_we <= 0;
      index <= 0;
      state <= IDLE;
    end else begin

      BRAM_rst <= 0;  // De-assert BRAM reset after initialization

      case (state)
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

            //bram_data_buffer[index-BRAM_DELAY] <= (BRAM_dout >> volume);
            bram_data_buffer[index-BRAM_DELAY] <= BRAM_dout;
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
