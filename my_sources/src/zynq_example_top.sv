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

module zynq_example_top
  (
   inout [14:0]	DDR_addr,
   inout [2:0]	DDR_ba,
   inout	DDR_cas_n,
   inout	DDR_ck_n,
   inout	DDR_ck_p,
   inout	DDR_cke,
   inout	DDR_cs_n,
   inout [3:0]	DDR_dm,
   inout [31:0]	DDR_dq,
   inout [3:0]	DDR_dqs_n,
   inout [3:0]	DDR_dqs_p,
   inout	DDR_odt,
   inout	DDR_ras_n,
   inout	DDR_reset_n,
   inout	DDR_we_n,
   inout	FIXED_IO_ddr_vrn,
   inout	FIXED_IO_ddr_vrp,
   inout [53:0]	FIXED_IO_mio,
   inout	FIXED_IO_ps_clk,
   inout	FIXED_IO_ps_porb,
   inout	FIXED_IO_ps_srstb,
   output [3:0]	led,
   input [3:0]	sws_4bits_tri_i,

   inout IIC_0_sda, IIC_0_scl,
   output audio_cons_muten, audio_cons_mclk,
   output audio_I2S_bclk, audio_I2S_pbdat, audio_I2S_pblrc 

   );
   
   

   
   
   logic	clk;
   logic	rst;
   logic	rstn;
   assign rst = ~rstn;
   
   logic [31:0]	BRAM_addr;
   logic	BRAM_clk;
   logic [31:0]	BRAM_din;
   logic [31:0]	BRAM_dout;
   logic	BRAM_en;
   logic	BRAM_rst;
   logic [3:0]	BRAM_we;

      logic [31:0]	BRAM_SynthBuffer_addr;
   logic	BRAM_SynthBuffer_clk;
   logic [31:0]	BRAM_SynthBuffer_din;
   logic [31:0]	BRAM_SynthBuffer_dout;
   logic	BRAM_SynthBuffer_en;
   logic	BRAM_SynthBuffer_rst;
   logic [3:0]	BRAM_SynthBuffer_we;
   
   logic [3:0] dummy;
   
   assign led[0] = audio_I2S_pblrc;
   assign led[1] = audio_I2S_pbdat;

    wire the_mclk;
    assign audio_cons_mclk = the_mclk;
   
   
    assign audio_cons_muten = 1'b1;
         
         
   fibonacci_bram fibonacci_bram_i
     (
      
      .clk(clk), 
      .rst(rst), 
      
      .BRAM_addr(BRAM_addr),
      .BRAM_clk(BRAM_clk),
      .BRAM_din(BRAM_din),
      .BRAM_dout(BRAM_dout),
      .BRAM_en(BRAM_en),
      .BRAM_rst(BRAM_rst),
      .BRAM_we(BRAM_we)
      
      );
      
      
      pain_and_suffering pain_i (
      .audio_I2S_bclk(audio_I2S_bclk), 
      .audio_I2S_pblrc(audio_I2S_pblrc),
      .audio_I2S_pbdat(audio_I2S_pbdat),
      .mclk(the_mclk)
      );
      
      
      
       // Instantiate the BRAM interface module
    bram_general_interface bram_interface_instance (
        .clk(clk),               // System clock
        .rst(rst),               // System reset
        .BRAM_addr(BRAM_SynthBuffer_addr),   // BRAM address
        .BRAM_clk(BRAM_SynthBuffer_clk),     // BRAM clock
        .BRAM_din(BRAM_SynthBuffer_din),     // BRAM data input
        .BRAM_dout(BRAM_SynthBuffer_dout),   // BRAM data output
        .BRAM_en(BRAM_SynthBuffer_en),       // BRAM enable
        .BRAM_rst(BRAM_SynthBuffer_rst),     // BRAM reset
        .BRAM_we(BRAM_SynthBuffer_we)        // BRAM write enable
    );

//------------------
   
   design_1_wrapper design_1_wrapper_i
     (
      // internal (stays within the FPGA chip, to let the ARM core IP communicate with the soft logic)
      .BRAM_PORTB_0_addr(BRAM_addr),
      .BRAM_PORTB_0_clk(BRAM_clk),
      .BRAM_PORTB_0_din(BRAM_din),
      .BRAM_PORTB_0_dout(BRAM_dout),
      .BRAM_PORTB_0_en(BRAM_en),
      .BRAM_PORTB_0_rst(BRAM_rst),
      .BRAM_PORTB_0_we(BRAM_we),
      
      .BRAM_SynthBuffer_PORTA_1_addr(BRAM_SynthBuffer_addr),
      .BRAM_SynthBuffer_PORTA_1_clk(BRAM_SynthBuffer_clk),
      .BRAM_SynthBuffer_PORTA_1_din(BRAM_SynthBuffer_din),
      .BRAM_SynthBuffer_PORTA_1_dout(BRAM_SynthBuffer_dout),
      .BRAM_SynthBuffer_PORTA_1_en(BRAM_SynthBuffer_en),
      .BRAM_SynthBuffer_PORTA_1_we(BRAM_SynthBuffer_we),
    
      .peripheral_aresetn(rstn),
      .FCLK_CLK0(clk),
      
      // external (leaves the FPGA, interfaces with the rest of the on board peripherals)
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
      .leds_4bits_tri_o(dummy),
      .sws_4bits_tri_i(sws_4bits_tri_i),
      
      //// adding my own stuff for audio
      
      // These stay on this module
//      .s_axis_aud_0_tdata(s_axis_aud_0_tdata), // AXI-S generator > I2S Converter
//      .s_axis_aud_0_tid(s_axis_aud_0_tid),
//      .s_axis_aud_0_tready(s_axis_aud_0_tready),
//      .s_axis_aud_0_tvalid(s_axis_aud_0_tvalid),
      
      // these leave the chip (constraints file)
      //.IIC_0_scl_io(IIC_0_scl), // to I2C audio registers
      //.IIC_0_sda_io(IIC_0_sda), 
      .MCLK(the_mclk) //WARN: this is a terrible name, very easily confused with the master clock
/*      .sdata_0_out_0(audio_I2S_pbdat), // I2S Converter > I2S chip off board
      .lrclk_out_0(audio_I2S_pblrc),
      .bclk_out_0(audio_I2S_bclk)*/
      );      
      

 
     
endmodule
