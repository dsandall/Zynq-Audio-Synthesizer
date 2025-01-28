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

module bram_general_interface (
    input wire clk,               // Clock input
    input wire rst,               // Reset input
    
    output reg [31:0] BRAM_addr,  // Address for BRAM
    output wire BRAM_clk,         // Clock for BRAM
    output reg [31:0] BRAM_din,   // Data to write to BRAM
    input wire [31:0] BRAM_dout,  // Data read from BRAM
    output reg BRAM_en,           // Enable BRAM
    output reg BRAM_rst,          // Reset BRAM
    output reg [3:0] BRAM_we      // Write enable for BRAM
);

    // State encoding
    typedef enum logic [2:0] {
        IDLE,
        READ,
        WAIT,
        REVERSE_WRITE,
        DONE
    } state_t;
    
    state_t state;

    localparam NUM_WORDS = 5; // Number of words to process
    localparam WAIT_LEN = 4; 
    localparam BRAM_DELAY = 2; // bram read delay
    localparam BRAM_ADDR_INCREMENT = 1;
 
    int wait_cnt = WAIT_LEN; 

    reg [31:0] data_buffer [0:NUM_WORDS-1]; // Buffer for data read from BRAM
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
                        state <= REVERSE_WRITE;
                    end 

                end
                WAIT: begin

                    wait_cnt--;

                    if (wait_cnt == 0) begin
                      state <= REVERSE_WRITE; 
                      BRAM_addr <= 0; //reset index for writeback
                      wait_cnt <= WAIT_LEN;
                    end

                end
                REVERSE_WRITE: begin
                    BRAM_en <= 1;
                    BRAM_we <= 4'hF;            // Enable write for all bytes
                    BRAM_din <= data_buffer[NUM_WORDS - reverse_index - 1]; // Write reversed data
                    BRAM_addr <= BRAM_addr + BRAM_ADDR_INCREMENT;    // Increment address
                    reverse_index <= reverse_index + 1;

                    if (reverse_index == NUM_WORDS) begin
                        state <= DONE;
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
