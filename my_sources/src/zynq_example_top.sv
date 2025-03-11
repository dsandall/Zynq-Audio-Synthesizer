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
// Define a struct to group related audio control signals

localparam int SAMPLE_BITS = 16;
localparam int M_BUF_LEN = 256;
localparam int FREQ_RES_BITS = 8;
localparam int VOLUME_BITS = 8;

// 16 bits
typedef struct {
  logic [FREQ_RES_BITS-1:0] freq;
  logic [VOLUME_BITS-1:0]   vol;
} SourceControlReg_t;


//typedef struct {
//  logic [3:0]             player_source_freq;  // Player frequency
//  logic [3:0]             bram_source_freq;    // BRAM frequency
//  logic                   refresh;             // Refresh signal
//  logic                   refresh_bram;        // Refresh signal for BRAM
//  logic [VOLUME_BITS-1:0] player_source_vol;   // Player volume
//  logic [VOLUME_BITS-1:0] bram_source_vol;     // BRAM volume
//} AudioControlReg_t;


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
    input [3:0] sw,
    input [3:0] btn,

    inout  IIC_0_sda,
    IIC_0_scl,
    output audio_cons_muten,
    audio_cons_mclk,
    output audio_I2S_bclk,
    audio_I2S_pbdat,
    audio_I2S_pblrc
);


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

  // instantiate gpio control registers (audio control reg)
  wire [31:0] PS_32b_AudioControlReg_In;
  wire [31:0] PS_32b_AudioControlReg_Out;

  // and the general board inputs can be accessed by the arm cores
  wire [31:0] PS_32bIn_AxiReg;
  assign PS_32bIn_AxiReg[3:0] = sw;
  assign PS_32bIn_AxiReg[7:4] = btn;

  //// assign the bits to the associated controls
  // From Arm Cores
  //  wire [FREQ_RES_BITS -1:0] player_source_freq = PS_32b_AudioControlReg_Out[FREQ_RES_BITS-1:0];
  //  wire [FREQ_RES_BITS -1:0] bram_source_freq = PS_32b_AudioControlReg_Out[(FREQ_RES_BITS-1)+4:4];
  //
  //  wire refresh = PS_32b_AudioControlReg_Out[8];
  //  wire refresh_bram = PS_32b_AudioControlReg_Out[9];
  //  //logic [VOLUME_BITS-1:0] volume_master = gpio_ctrl_o_32b_tri_o[15 : 8];
  //  logic [VOLUME_BITS-1:0] player_source_vol = PS_32b_AudioControlReg_Out[23 : 16];
  //  logic [VOLUME_BITS-1:0] bram_source_vol = PS_32b_AudioControlReg_Out[31 : 24];

  ////////////////

  // audio control

  // Declare an instance of the struct
  SourceControlReg_t player;
  SourceControlReg_t bram;
  // Assign values to the struct fields
  //always_comb begin
  //end

  assign player.freq = PS_32b_AudioControlReg_Out[7:0];
  assign bram.freq = PS_32b_AudioControlReg_Out[15:8];
  assign player.vol = PS_32b_AudioControlReg_Out[23:16];
  assign bram.vol = PS_32b_AudioControlReg_Out[31:24];

  //assign player.refresh = PS_32b_AudioControlReg_Out[8]; // TODO: map this to something not in this struct
  //assign bram.refresh = PS_32b_AudioControlReg_Out[9];

  /////////////
  //
  // MASTER PLAYBACK, TO I2S OUT
  //

  logic [7:0] m_sample_index;  // 2^8 master sample indexes
  shortint m_sample_buffer[M_BUF_LEN];

  pain_and_suffering #(
      .SAMPLE_BITS(SAMPLE_BITS),
      .CLIP_LEN(M_BUF_LEN),
      .VOLUME_BITS(VOLUME_BITS)
  ) pain_i (
      .audio_I2S_bclk(audio_I2S_bclk),
      .audio_I2S_pblrc(audio_I2S_pblrc),
      .audio_I2S_pbdat(audio_I2S_pbdat),
      .mclk(audio_cons_mclk),

      .volume(sw),  // master vol = switches

      .sample(m_sample_buffer),
      .sample_index(m_sample_index)
  );

  /////////////
  //
  // AUDIO SOURCES
  //

  localparam int BRAM_CLIP_LEN = 256;
  shortint bram_sample_buffer;  // Buffer for data read from BRAM
  wire bram_source_valid;
  I2S_bram_DMA #(
      .NUM_WORDS(BRAM_CLIP_LEN),
      .VOLUME_BITS(VOLUME_BITS),
      .FREQ_RES_BITS(FREQ_RES_BITS)
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

      //.bram_data_buffer(bram_data_buffer),
      .refresh(1),

      // Player connections
      .mclk(audio_cons_mclk),
      .volume(bram.vol),
      .p_frequency(bram.freq),

      .valid(bram_source_valid),
      .current_sample(bram_sample_buffer)

  );

  shortint triangle_sample_buffer;  // Buffer for data read from BRAM
  src_triangle #(
      .CLIP_LEN(64),
      .VOLUME_BITS(VOLUME_BITS),
      .FREQ_RES_BITS(FREQ_RES_BITS)
  ) src_triangle_i (
      .mclk(audio_cons_mclk),
      .rst (rst),

      .valid(),

      .p_sample_buffer(triangle_sample_buffer),

      .volume(player.vol),
      .p_frequency(player.freq)
  );

  shortint oneshot_sample_buffer;  // Buffer for data read from BRAM
  src_oneshot_808 #(
      .CLIP_LEN(64),
      .VOLUME_BITS(VOLUME_BITS),
      .FREQ_RES_BITS(FREQ_RES_BITS)
  ) src_oneshot_808_i (
      .mclk(audio_cons_mclk),
      .rst (rst),

      .p_sample_buffer(oneshot_sample_buffer),

      .trig(sw[0])  // WARN: Fuck it no debouncer, it might work anyway
  );

  // button debouncer module test
  //  (debouncer not working yet)
  logic stab;
  logic flip;
  assign led[0] = flip;
  button_debouncer_fsm instreanstrd (
      .clk(mclk),
      .btn_raw(sw[1]),
      .btn_stable(stab)
  );
  always_ff @(posedge stab) begin
    flip <= ~flip;
  end

  assign led[1] = ~flip;
  assign led[2] = 0;
  assign led[3] = btn[1] | btn[2];

  //
  // END OF SOURCES
  //
  /////////////

  /*
  logic [3:0] button_volume;
  button_activated_attack_release #() button_activated_i (
      .mclk(mclk),
      .rst(rst),
      .button_ra
      w(btn[0]),
      .volume(button_volume)
  );
  */

  /////////////
  //
  // Audio Combinator prototype
  //

  // Bram data buffer at set frequency matching the m sample buffer
  shortint output_filtered, output_filter_input;
  int before_index;

  int refresh = 1;
  always_ff @(negedge audio_I2S_pblrc) begin

    if (refresh) begin
      if (m_sample_index < 1) begin
        before_index <= (M_BUF_LEN - 1);  // arbitrary lag amount
      end else begin
        before_index <= m_sample_index - 1;
      end

      //output_filter_input <= bram_sample_buffer + triangle_sample_buffer;  // Store in buffer
      //m_sample_buffer[before_index] <= output_filtered;
      m_sample_buffer[before_index] <= bram_sample_buffer + triangle_sample_buffer + oneshot_sample_buffer;
    end

  end

  /*
  fir_lowpass #() lp_filter (
      .clk (m_sample_index),
      .rst (rst),
      .din (output_filter_input),
      .dout(output_filtered)
  );
  */

  //assign bram_sample_buffer[i] = bram_data_buffer[i][SAMPLE_BITS-1:0]; //WARN: TEMPORARY GAIN SHIFT FOR BRAM SOURCE
  //assign m_sample_buffer[i] = (bram_sample_buffer[i] >>> bram_source_vol) + (player_sample_buffer);  // Store in buffer


  //------------------

  /////////////
  //
  // Arm Cores (Programming System)
  //

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
      .leds_4bits_tri_o(),
      .GPIO_In_32bits_tri_i(PS_32bIn_AxiReg),  // allows the arm chip to read the state of gpio


      //// audio control gpio
      .gpio_ctrl_i_32b_tri_i(PS_32b_AudioControlReg_In),
      .gpio_ctrl_o_32b_tri_o(PS_32b_AudioControlReg_Out),
      .ip2intc_irpt_0(ip2intc_irpt_0),  // and interrupt

      .MCLK(audio_cons_mclk),

      .slowest_sync_clk_0(audio_I2S_pblrc),  // WARN: be careful with this one

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
