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



// Sample register parameters
localparam int CLIP_LEN = 64;
localparam int SAMPLE_BITS = 16;



module I2S_bram_DMA (
    input wire clk,               // Clock input
    input wire rst,               // Reset input
    
    output reg [31:0] BRAM_addr,  // Address for BRAM
    output wire BRAM_clk,         // Clock for BRAM
    output reg [31:0] BRAM_din,   // Data to write to BRAM
    input wire [31:0] BRAM_dout,  // Data read from BRAM
    output reg BRAM_en,           // Enable BRAM
    output reg BRAM_rst,          // Reset BRAM
    output reg [3:0] BRAM_we,      // Write enable for BRAM

  // I2S
    output reg audio_I2S_bclk,   // Bit Clock
    output reg audio_I2S_pbdat,  // Playback Data
    output reg audio_I2S_pblrc,  // Word Select (LR Clock)
    input      mclk              // Master Clock (256x sample rate)
);



  reg [SAMPLE_BITS-1:0] sample [CLIP_LEN - 1];
   
   pain_and_suffering pain_i (
      .audio_I2S_bclk(audio_I2S_bclk), 
      .audio_I2S_pblrc(audio_I2S_pblrc),
      .audio_I2S_pbdat(audio_I2S_pbdat),
      .mclk(the_mclk),
      .sample(sample) 
      );






// BRAM
    // State encoding
    typedef enum logic [2:0] {
        IDLE,
        READ,
        WAIT,
        REVERSE_WRITE,
        DONE
    } state_t;
    
    state_t state;

    localparam NUM_WORDS = (CLIP_LEN-1); // Number of words to process
    localparam WAIT_LEN = 4; 
    localparam BRAM_DELAY = 2; // bram read delay
    localparam BRAM_ADDR_INCREMENT = 1;
 
    int wait_cnt = WAIT_LEN; 

    reg [31:0] data_buffer [0:NUM_WORDS-1]; // Buffer for data read from BRAM

    genvar i;
    generate
        for (i = 0; i < CLIP_LEN; i = i + 1) begin
            assign sample[i] = data_buffer[i][15:0];
        end
    endgenerate


    reg [2:0] index;                        // Index for accessing data_buffer
    reg [2:0] reverse_index;                // Index for reverse writing

    // Control logic for BRAM operations
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            BRAM_addr <= 0;
            BRAM_en <= 0;
            BRAM_rst <= 1;
            BRAM_we <= 0;
            index <= 0;
            reverse_index <= 0;
            state <= IDLE;
        end else begin
            BRAM_rst <= 0; // De-assert BRAM reset after initialization
            case (state)
                IDLE: begin
                    BRAM_en <= 1;
                    BRAM_we <= 0;
                    BRAM_addr <= 0;
                    index <= 0;
                    reverse_index <= 0; 

                    if (!rst) begin
                        state <= READ;
                    end 

                end
                READ: begin
                    BRAM_en <= 1;
                    BRAM_we <= 0;
                    index <= index + 1; // increment index
                    
                    if (index < NUM_WORDS) begin
                        BRAM_addr <= BRAM_addr + BRAM_ADDR_INCREMENT;     // Increment address
                    end

                    if (index >= BRAM_DELAY) begin //ie, not the first one
                        data_buffer[index - BRAM_DELAY] <= BRAM_dout; // Store data in buffer, at correct index
                    end

                    if (index == (NUM_WORDS + BRAM_DELAY) ) begin
                        state <= WAIT;
                    end 

                end
                WAIT: begin

                    wait_cnt--;

                    if (wait_cnt == 0) begin
                      state <= DONE; 
                      BRAM_addr <= 0; //reset index for writeback
                      wait_cnt <= WAIT_LEN;
                    end

                end

                DONE: begin   
                    BRAM_en <= 0;
                    BRAM_we <= 0;
                end
            endcase
        end
    end

    // Connect BRAM clock to the system clock
    assign BRAM_clk = clk;

endmodule
