`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/12/2023 10:50:04 AM
// Design Name: 
// Module Name: zynq_example_top
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

module zynq_example_top (
    inout [14:0] DDR_addr,
    inout [2:0] DDR_ba,
    inout DDR_cas_n,
    inout DDR_ck_n,
    inout DDR_ck_p,
    inout DDR_cke,
    inout DDR_cs_n,
    inout [3:0] DDR_dm,
    inout [31:0] DDR_dq,
    inout [3:0] DDR_dqs_n,
    inout [3:0] DDR_dqs_p,
    inout DDR_odt,
    inout DDR_ras_n,
    inout DDR_reset_n,
    inout DDR_we_n,
    inout FIXED_IO_ddr_vrn,
    inout FIXED_IO_ddr_vrp,
    inout [53:0] FIXED_IO_mio,
    inout FIXED_IO_ps_clk,
    inout FIXED_IO_ps_porb,
    inout FIXED_IO_ps_srstb,
    output [3:0] led,
    input [3:0] sws_4bits_tri_i,

    inout  IIC_0_sda,
    IIC_0_scl,
    output audio_cons_muten,
    audio_cons_mclk,
    output audio_I2S_bclk,
    audio_I2S_pbdat,
    audio_I2S_pblrc

);
  localparam int SAMPLE_BITS = 16;
  localparam int CLIP_LEN = 256;
  localparam int FREQ_RES_BITS = 4;
  localparam int VOLUME_BITS = 4;

  // instantiate clock and reset
  logic clk;
  logic rst;
  logic rstn;
  assign rst = ~rstn;

  // bram interface instantiation a
  logic [31:0] BRAM_addr;
  logic BRAM_clk;
  logic [31:0] BRAM_din;
  logic [31:0] BRAM_dout;
  logic BRAM_en;
  logic BRAM_rst;
  logic [3:0] BRAM_we;

  // instantiate gpio control registers
  wire [31:0] gpio_ctrl_i_32b_tri_i;
  wire [31:0] gpio_ctrl_o_32b_tri_o;

  //// assign the bits to the associated controls
  // From Arm Cores
  wire [FREQ_RES_BITS -1:0] frequency = gpio_ctrl_o_32b_tri_o[FREQ_RES_BITS-1:0];
  wire refresh = gpio_ctrl_o_32b_tri_o[31];
  wire [VOLUME_BITS-1: 0] volume_master = gpio_ctrl_o_32b_tri_o [(VOLUME_BITS-1 + FREQ_RES_BITS) : (0 + FREQ_RES_BITS)];
  // From Board
  //wire [VOLUME_BITS-1:0] volume_master = sws_4bits_tri_i;  // volume == switches
  // To Arm Cores
  // To Board


  //   logic [31:0]	BRAM_SynthBuffer_addr;
  //   logic	BRAM_SynthBuffer_clk;
  //   logic [31:0]	BRAM_SynthBuffer_din;
  //   logic [31:0]	BRAM_SynthBuffer_dout;
  //   logic	BRAM_SynthBuffer_en;
  //   logic	BRAM_SynthBuffer_rst;
  //   logic [3:0]	BRAM_SynthBuffer_we;

  //assign led[0] = audio_I2S_pblrc;
  //assign led[1] = audio_I2S_pbdat;
  //assign audio_cons_muten = 1'b1;

  shortint m_sample_buffer[CLIP_LEN];
  wire [7:0] m_sample_index;

  pain_and_suffering #(
      .SAMPLE_BITS(SAMPLE_BITS),
      .CLIP_LEN(CLIP_LEN),
      .VOLUME_BITS(VOLUME_BITS)
  ) pain_i (
      .audio_I2S_bclk(audio_I2S_bclk),
      .audio_I2S_pblrc(audio_I2S_pblrc),
      .audio_I2S_pbdat(audio_I2S_pbdat),
      .mclk(audio_cons_mclk),

      .volume(volume_master),

      .sample(m_sample_buffer),
      .sample_index(m_sample_index)
  );

  wire [31:0] bram_data_buffer[0:CLIP_LEN -1];  // Buffer for data read from BRAM

  I2S_bram_DMA #(
      .NUM_WORDS(CLIP_LEN)
  ) I2S_bram_DMA_i (
      .clk(clk),  // System clock
      .rst(rst),  // System reset

      .BRAM_addr(BRAM_addr),  // BRAM address
      .BRAM_clk (BRAM_clk),   // BRAM clock
      .BRAM_din (BRAM_din),   // BRAM data input
      .BRAM_dout(BRAM_dout),  // BRAM data output
      .BRAM_en  (BRAM_en),    // BRAM enable
      .BRAM_rst (BRAM_rst),   // BRAM reset
      .BRAM_we  (BRAM_we),    // BRAM write enable

      .bram_data_buffer(bram_data_buffer),
      .refresh(refresh)

      //// control sources
      //.switches(sws_4bits_tri_i),
      //
      //.gpio_ctrl_i_32b_tri_i(gpio_ctrl_i_32b_tri_i),
      //.gpio_ctrl_o_32b_tri_o(gpio_ctrl_o_32b_tri_o),
      //.ip2intc_irpt_0(ip2intc_irpt_0),
      //
      //// audio output bus
      //.audio_I2S_bclk(audio_I2S_bclk),
      //.audio_I2S_pblrc(audio_I2S_pblrc),
      //.audio_I2S_pbdat(audio_I2S_pbdat),
      //.mclk(audio_cons_mclk)
  );

  //TODO:
  localparam PLAYER_CLIP_LEN = 32;
  int player_vol = 4;
  shortint player_sample_buffer;  // Buffer for data read from BRAM
  player_module #(
      .SAMPLE_BITS(SAMPLE_BITS),
      .CLIP_LEN(PLAYER_CLIP_LEN)
  ) player_module_i (
      .mclk(audio_cons_mclk),
      .rst (rst),

      .m_sample_index(m_sample_index),
      .p_sample_buffer(player_sample_buffer),
      .valid(player_valid),

      .volume(player_vol)
  );


  // Audio Combinator prototype
  // Bram data buffer at set frequency matching the m sample buffer
  // player
  genvar i;
  generate
    for (i = 0; i < CLIP_LEN; i = i + 1) begin
      assign m_sample_buffer[i] = bram_data_buffer[i][SAMPLE_BITS-1:0] + player_sample_buffer;

      // WARN: this is currently inefficient, as the bram reads in chunks of
      // 32, but the samples are stored in only the first 16 bits. If this
      // becomes a constraint, pack the samples into words, or increase the
      // frequency.
    end
  endgenerate

  //------------------

  design_1_wrapper design_1_wrapper_i (

      //// MCU reset, MCU clk
      .peripheral_aresetn_0(rstn),
      .FCLK_CLK0_0(clk),

      //// external (leaves the FPGA, interfaces with the rest of the on board peripherals)
      .DDR_addr(DDR_addr),
      .DDR_ba(DDR_ba),
      .DDR_cas_n(DDR_cas_n),
      .DDR_ck_n(DDR_ck_n),
      .DDR_ck_p(DDR_ck_p),
      .DDR_cke(DDR_cke),
      .DDR_cs_n(DDR_cs_n),
      .DDR_dm(DDR_dm),
      .DDR_dq(DDR_dq),
      .DDR_dqs_n(DDR_dqs_n),
      .DDR_dqs_p(DDR_dqs_p),
      .DDR_odt(DDR_odt),
      .DDR_ras_n(DDR_ras_n),
      .DDR_reset_n(DDR_reset_n),
      .DDR_we_n(DDR_we_n),
      .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
      .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
      .FIXED_IO_mio(FIXED_IO_mio),
      .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
      .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
      .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),


      //// on board LEDs and switches
      .leds_4bits_tri_o(led),
      .sws_4bits_tri_i (sws_4bits_tri_i),


      //// audio control gpio
      .gpio_ctrl_i_32b_tri_i(gpio_ctrl_i_32b_tri_i),
      .gpio_ctrl_o_32b_tri_o(gpio_ctrl_o_32b_tri_o),
      .ip2intc_irpt_0(ip2intc_irpt_0),  // and interrupt

      .MCLK(audio_cons_mclk),  //WARN: this is a terrible name, very easily confused with the master clock

      // internal (stays within the FPGA chip, to let the ARM core IP communicate with the soft logic)
      .BRAM_PORTB_0_addr(BRAM_addr),
      .BRAM_PORTB_0_clk (BRAM_clk),
      .BRAM_PORTB_0_din (BRAM_din),
      .BRAM_PORTB_0_dout(BRAM_dout),
      .BRAM_PORTB_0_en  (BRAM_en),
      .BRAM_PORTB_0_rst (BRAM_rst),
      .BRAM_PORTB_0_we  (BRAM_we)

      //.BRAM_SynthBuffer_PORTA_1_addr(BRAM_SynthBuffer_addr),
      //.BRAM_SynthBuffer_PORTA_1_clk(BRAM_SynthBuffer_clk),
      //.BRAM_SynthBuffer_PORTA_1_din(BRAM_SynthBuffer_din),
      //.BRAM_SynthBuffer_PORTA_1_dout(BRAM_SynthBuffer_dout),
      //.BRAM_SynthBuffer_PORTA_1_en(BRAM_SynthBuffer_en),
      //.BRAM_SynthBuffer_PORTA_1_we(BRAM_SynthBuffer_we),



      //// adding my own stuff for audio

      // These stay on this module
      //      .s_axis_aud_0_tdata(s_axis_aud_0_tdata), // AXI-S generator > I2S Converter
      //      .s_axis_aud_0_tid(s_axis_aud_0_tid),
      //      .s_axis_aud_0_tready(s_axis_aud_0_tready),
      //      .s_axis_aud_0_tvalid(s_axis_aud_0_tvalid),

      // these leave the chip (constraints file)
      //.IIC_0_scl_io(IIC_0_scl), // to I2C audio registers
      //.IIC_0_sda_io(IIC_0_sda), 

      /*
      .sdata_0_out_0(audio_I2S_pbdat), // I2S Converter > I2S chip off board
      .lrclk_out_0(audio_I2S_pblrc),
      .bclk_out_0(audio_I2S_bclk)

      */
  );
endmodule
