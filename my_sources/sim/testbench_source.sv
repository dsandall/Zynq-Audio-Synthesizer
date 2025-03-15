
`timescale 1ns / 1ps

typedef struct {
  logic [7:0] freq;
  logic [7:0] vol;
} SourceControlReg_t;

module testbench_source;

  reg mclk, pblrc, rst, sw;

  SourceControlReg_t sine;
  assign sine.vol = 63;
  assign sine.freq = 02;

  assign sw = 1;

  initial begin
    mclk = 0;
    forever #45.5 mclk = ~mclk;  // 11.3 MHz clock (~256 times 44.1kHz)
  end

  initial begin
    rst = 1;
    #180 rst = 0;
  end

  reg [5:0] div;
  always_ff @(mclk) begin
    if (rst) begin
      pblrc <= 0;
      div   <= 0;
    end else begin
      div <= div + 1;
      if (div == 0) begin
        pblrc <= ~pblrc;
      end
    end
  end

  shortint sine_sample_buffer;
  src_sine #(
      .CLIP_LEN(256),
      .VOLUME_BITS(8),
      .FREQ_RES_BITS(8)
  ) src_sine_i (
      .mclk(mclk),
      .pblrc(pblrc),
      .rst(rst),
      .p_sample_buffer(sine_sample_buffer),
      .valid(),
      .volume(sine.vol),
      .p_frequency(sine.freq),
      .sw(sw)
  );

endmodule
;
