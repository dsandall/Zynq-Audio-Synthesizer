`timescale 1ns / 1ps

localparam int M_BUF_LEN = 32;
localparam int FREQ_BITS = 8;
localparam int VOLUME_BITS = 8;

typedef struct packed {
  logic [FREQ_BITS-1:0]   freq;
  logic [VOLUME_BITS-1:0] vol;
} SourceControl_t;

typedef struct packed {
  SourceControl_t sine;
  SourceControl_t triangle;
} OscillatorControlReg_t;

typedef struct packed {
  SourceControl_t source;
  reg [15:0] control;
} OscillatorBRAMReg_t;

typedef struct packed {
  reg kick;
  reg snare;
  reg hihat;
  reg [7:0] overdrive;
  reg [20:0] fill;
} DrumControlReg_t;

typedef struct packed {
  reg [7:0]  vol;
  reg [7:0]  overdrive;
  reg [15:0] fill;
} MainControlReg_t;

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
  assign clk = BRAM_clk;
  logic rst;
  logic rstn;
  assign rst = ~rstn;

  // bram interface instantiation
  logic [31:0] BRAM_addr;
  logic [31:0] BRAM_din;
  logic [31:0] BRAM_dout;
  logic BRAM_clk;
  logic BRAM_en;
  logic BRAM_rst;
  logic [3:0] BRAM_we;

  ////////////////
  // audio control

  // Declare an instance of the struct
  MainControlReg_t main;
  OscillatorControlReg_t osc;
  OscillatorBRAMReg_t bram;
  DrumControlReg_t drum;

  //----------------------------------------------------------

  /////////////
  //
  // AUDIO (OSCILLATOR) SOURCES
  //

  shortint bram_sample_buffer;  // Buffer for data read from BRAM
  shortint triangle_sample_buffer;
  shortint sine_sample_buffer;

  src_bram #(
      .NUM_WORDS(256),
      .VOLUME_BITS(VOLUME_BITS),
      .FREQ_RES_BITS(FREQ_BITS)
  ) src_bram_i (
      .rst(rst),  // System reset

      .BRAM_addr(BRAM_addr),  // BRAM address
      .BRAM_clk(BRAM_clk),  // BRAM clock
      .BRAM_din(BRAM_din),  // BRAM data input
      .BRAM_dout(BRAM_dout),  // BRAM data output
      .BRAM_en(BRAM_en),  // BRAM enable
      .BRAM_rst(BRAM_rst),  // BRAM reset
      .BRAM_we(BRAM_we),  // BRAM write enable
      .refresh(1),  // TODO:

      // Player connections
      .mclk(audio_cons_mclk),
      .pblrc(audio_I2S_pblrc),
      .volume(bram.source.vol),
      .p_frequency(bram.source.freq),
      .p_sample_buffer(bram_sample_buffer)
  );

  src_triangle #(
      .CLIP_LEN(256),
      .VOLUME_BITS(VOLUME_BITS),
      .FREQ_RES_BITS(FREQ_BITS)
  ) src_triangle_i (
      .rst(rst),
      .mclk(audio_cons_mclk),
      .pblrc(audio_I2S_pblrc),
      .overdrive(main.overdrive),
      .volume(osc.triangle.vol),
      .p_frequency(osc.triangle.freq),
      .p_sample_buffer(triangle_sample_buffer)
  );

  src_sine #(
      .CLIP_LEN(256),
      .VOLUME_BITS(VOLUME_BITS),
      .FREQ_RES_BITS(FREQ_BITS)
  ) src_sine_i (
      .rst(rst),
      .mclk(audio_cons_mclk),
      .pblrc(audio_I2S_pblrc),
      .overdrive(main.overdrive),
      .volume(osc.sine.vol),
      .p_frequency(osc.sine.freq),
      .p_sample_buffer(sine_sample_buffer)
  );

  //----------------------------------------------------------

  ////////////
  //
  // ONESHOT SOURCES
  //

  shortint oneshot_808_sample_buffer;
  shortint oneshot_snare_sample_buffer;
  shortint oneshot_hihat_sample_buffer;
  src_oneshot_808 #(
      .CLIP_LEN(256),
      .VOLUME_BITS(VOLUME_BITS),
      .FREQ_RES_BITS(FREQ_BITS)
  ) src_oneshot_808_i (
      .mclk(audio_cons_mclk),
      .pblrc(audio_I2S_pblrc),
      .rst(rst),
      .overdrive(drum.overdrive),
      .p_sample_buffer(oneshot_808_sample_buffer),
      .trig(btn[0] | drum.kick),
      .sw(sw[0])
  );

  src_oneshot_snare #(
      .CLIP_LEN(256),
      .VOLUME_BITS(VOLUME_BITS),
      .FREQ_RES_BITS(FREQ_BITS)
  ) src_oneshot_snare_i (
      .mclk(audio_cons_mclk),
      .pblrc(audio_I2S_pblrc),
      .rst(rst),
      .p_sample_buffer(oneshot_snare_sample_buffer),
      .trig(btn[1] | drum.snare),
      .sw(sw[1])
  );

  src_oneshot_hihat #(
      .CLIP_LEN(256),
      .VOLUME_BITS(VOLUME_BITS),
      .FREQ_RES_BITS(FREQ_BITS)
  ) hihat_i (
      .mclk(audio_cons_mclk),
      .pblrc(audio_I2S_pblrc),
      .rst(rst),
      .p_sample_buffer(oneshot_hihat_sample_buffer),
      .trig(btn[2] | drum.hihat),
      .sw(sw[2])
  );

  //
  // END OF SOURCES
  //
  /////////////


  //----------------------------------------------------------

  /////////////
  //
  // Audio Combinator
  //

  // master playback buffer
  logic [7:0] m_sample_index;
  shortint m_sample_buffer[M_BUF_LEN];

  // Bram data buffer at set frequency matching the m sample buffer
  shortint output_filtered, output_filter_input;
  int before_index;

  always_ff @(negedge audio_I2S_pblrc) begin

    if (m_sample_index < 1) begin
      before_index <= (M_BUF_LEN - 1);  // arbitrary lag amount
    end else begin
      before_index <= m_sample_index - 1;
    end

    m_sample_buffer[before_index] <=
      oneshot_hihat_sample_buffer +
      oneshot_snare_sample_buffer +
      oneshot_808_sample_buffer +

      sine_sample_buffer +
      triangle_sample_buffer +
      bram_sample_buffer;
  end

  //----------------------------------------------------------

  /////////////
  //
  // MASTER PLAYBACK, TO I2S OUT
  //

  I2S_output_driver #(
      .SAMPLE_BITS(16),
      .CLIP_LEN(M_BUF_LEN),
      .VOLUME_BITS(VOLUME_BITS)
  ) pain_i (
      .audio_I2S_bclk(audio_I2S_bclk),
      .audio_I2S_pblrc(audio_I2S_pblrc),
      .audio_I2S_pbdat(audio_I2S_pbdat),
      .mclk(audio_cons_mclk),
      .volume(main.vol),
      .sample(m_sample_buffer),
      .sample_index(m_sample_index)
  );

  //----------------------------------------------------------

  /////////////
  //
  // Arm Cores (Programming System)
  //

  design_1_wrapper design_1_wrapper_i (
      .BRAM_PORTB_0_addr(BRAM_addr),
      .BRAM_PORTB_0_clk(BRAM_clk),
      .BRAM_PORTB_0_din(BRAM_din),
      .BRAM_PORTB_0_dout(BRAM_dout),
      .BRAM_PORTB_0_en(BRAM_en),
      .BRAM_PORTB_0_rst(BRAM_rst),
      .BRAM_PORTB_0_we(BRAM_we),
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

      .drum_control_0_tri_o(drum),
      .drum_control_1_tri_o(),

      .osc_control_0_tri_o(osc),
      .osc_control_1_tri_o(bram),

      .main_control_in_tri_i (),
      .main_control_interrupt(),
      .main_control_out_tri_o(main),

      .FCLK_CLK0_0(clk),
      .MCLK(audio_cons_mclk),

      //// on board LEDs and switches
      .leds_4bits_tri_o(),
      .GPIO_In_32bits_tri_i(PS_32bIn_AxiReg),
      .peripheral_aresetn_0(rstn),
      .slowest_sync_clk_0(audio_I2S_pblrc)
  );
endmodule
