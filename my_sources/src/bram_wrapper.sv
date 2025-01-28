`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2023 10:01:25 PM
// Design Name: 
// Module Name: fibonacci_bram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module bram_wrapper (

    input clk,
    input rst,

    output [31:0] BRAM_addr,
    output BRAM_clk,
    output [31:0] BRAM_din,
    input [31:0] BRAM_dout,
    output BRAM_en,
    output BRAM_rst,
    output [3:0] BRAM_we

);

  localparam int BRAM_DEPTH = 2048;
  localparam int SEQ_BITS = 32;
  localparam int CLK_MHZ = 100;

  logic [SEQ_BITS-1:0] seq_num;
  logic seq_valid;

  logic [31:0] address;
  logic [31:0] counter;

  logic get_next_number;
  assign get_next_number = (counter == 1) ? 1 : 0; // triggers the Fibonacci module when counter == 1

  localparam int COUNTER_MAX = CLK_MHZ * 500000;

  fibonacci #(
      .SEQ_BITS(SEQ_BITS)
  ) fibonacci_i (
      .clk(clk),
      .rst(rst | address == BRAM_DEPTH-1), // reset on external reset, or when reaching the end of the bram

      .get_next_number(get_next_number),
      .seq(seq_num),
      .seq_valid(seq_valid)

  );



  // at each clock,
  always_ff @(posedge clk) begin
    if (rst) begin
      address <= 0;
      counter <= 0;
    end else begin

      // if the fib has completed, increment the BRAM address (post-write)
      if (seq_valid) begin
        if (address < BRAM_DEPTH - 1) begin
          address <= address + 1;
        end else begin
          address <= 0;
        end
      end

      //if
      if (counter < COUNTER_MAX - 1) begin
        counter <= counter + 1;
      end else begin
        counter <= 0;
      end

    end
  end


  assign BRAM_addr = address << 2;
  assign BRAM_clk  = clk;
  assign BRAM_din  = seq_num;
  assign BRAM_en   = 1;
  assign BRAM_rst  = rst;  //BRAM reset by external
  assign BRAM_we   = {4{seq_valid}};  // 4 bit write enable signal? why not just one bit tho

endmodule
