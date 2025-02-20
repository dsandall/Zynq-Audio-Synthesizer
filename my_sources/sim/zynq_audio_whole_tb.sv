

module zynq_audio_whole_tb (
    output reg a
);

  reg [3:0] master_vol = 4'h7;

  //reg [31:0] audio_ctrl_reg = 32'h0;
  zynq_example_top zynq_example_top_i (.sws_4bits_tri_i(master_vol));


  initial begin
    #2000;
  end
endmodule

/*
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

endmodule

*/
