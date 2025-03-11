#Audio Codec, from digital audio example
#set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports { audio_I2S_bclk }]; #IO_0_34 Sch=ac_bclk
#set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { audio_cons_mclk }]; #IO_L19N_T3_VREF_34 Sch=ac_mclk
#set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { audio_cons_muten }]; #IO_L23N_T3_34 Sch=ac_muten
#set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { audio_I2S_pbdat }]; #IO_L20N_T3_34 Sch=ac_pbdat
#set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33 } [get_ports { audio_I2S_pblrc }]; #IO_25_34 Sch=ac_pblrc
##set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { audio_I2S_recdat }]; #IO_L19P_T3_34 Sch=ac_recdat
##set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { audio_I2S_reclrc }]; #IO_L17P_T2_34 Sch=ac_reclrc
#set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { IIC_0_scl }]; #IO_L13P_T2_MRCC_34 Sch=ac_scl
#set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { IIC_0_sda }]; #IO_L23P_T3_34 Sch=ac_sda


#
## Define MCLK and BCLK as an external clock
#create_clock -name audio_mclk -period 81.38 [get_ports audio_cons_mclk]
## 12.288 MHz
#create_clock -name audio_bclk -period 325.52 [get_ports audio_I2S_bclk]
## 3.072 MHz
#
## inherent Input delay for I2S data
#set_input_delay -max 5 -clock [get_ports audio_I2S_bclk] [get_ports audio_I2S_pbdat]
## inherent Output delay for I2S Left/Right Clock (Word Clock)
#set_output_delay -max 5 -clock [get_ports audio_I2S_bclk] [get_ports audio_I2S_pblrc]
#
## ignore these paths
#set_false_path -from [get_ports audio_cons_mclk] -to [get_ports audio_I2S_bclk]
#set_false_path -from [get_ports audio_I2S_bclk] -to [get_ports audio_cons_mclk]
#
# shouldn't be necessary 
# set_multicycle_path -setup 32 -from [get_ports audio_I2S_pblrc] -to [get_ports audio_I2S_pbdat]

create_clock -name mclk -period 81.38 [get_ports audio_cons_mclk]
create_generated_clock -name bclk -source [get_ports audio_cons_mclk] -divide_by 8 [get_ports audio_I2S_bclk]
create_generated_clock -name pblrc -source [get_ports audio_cons_mclk] -divide_by 256 [get_ports audio_I2S_pblrc]

set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { audio_I2S_bclk }]; 
#IO_0_34 Sch=ac_bclk
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { audio_cons_mclk }]; 
#IO_L19N_T3_VREF_34 Sch=ac_mclk
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { audio_cons_muten }]; 
#IO_L23N_T3_34 Sch=ac_muten
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { audio_I2S_pbdat }]; 
#IO_L20N_T3_34 Sch=ac_pbdat

set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33 } [get_ports { audio_I2S_pblrc }]; 
#IO_25_34 Sch=ac_pblrc
#set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { audio_I2S_recdat }]; #IO_L19P_T3_34 Sch=ac_recdat
#set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { audio_I2S_reclrc }]; #IO_L17P_T2_34 Sch=ac_reclrc
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { IIC_0_scl }]; 
#IO_L13P_T2_MRCC_34 Sch=ac_scl
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { IIC_0_sda }]; 
#IO_L23P_T3_34 Sch=ac_sda



##LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
#IO_L23P_T3_35 Sch=led[0]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
#IO_L23N_T3_35 Sch=led[1]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
#IO_0_35 Sch=led[2]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];
#IO_L3N_T0_DQS_AD1N_35 Sch=led[3]


#Switches
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; #IO_L19N_T3_VREF_35 Sch=sw[0]
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]; #IO_L24P_T3_34 Sch=sw[1]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]; #IO_L4N_T0_34 Sch=sw[2]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]; #IO_L9P_T1_DQS_34 Sch=sw[3]

#Buttons
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]; #IO_L12N_T1_MRCC_35 Sch=btn[0]
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]; #IO_L24N_T3_34 Sch=btn[1]
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]; #IO_L10P_T1_AD11P_35 Sch=btn[2]
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]; #IO_L7P_T1_34 Sch=btn[3]
