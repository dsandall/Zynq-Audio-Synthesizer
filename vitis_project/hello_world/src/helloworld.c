// // /******************************************************************************
// // * Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
// // * SPDX-License-Identifier: MIT
// // ******************************************************************************/
// // /*
// //  * helloworld.c: simple test application
// //  *
// //  * This application configures UART 16550 to baud rate 9600.
// //  * PS7 UART (Zynq) is not initialized by this application, since
// //  * bootrom/bsp configures it to baud rate 115200
// //  *
// //  * ------------------------------------------------
// //  * | UART TYPE   BAUD RATE                        |
// //  * ------------------------------------------------
// //  *   uartns550   9600
// //  *   uartlite    Configurable only in HW design
// //  *   ps7_uart    115200 (configured by bootrom/bsp)
// //  */

// // #include <stdio.h>
// // #include "platform.h"
// // #include "xil_printf.h"


// // int main()
// // {
// //     init_platform();

// //     print("Hello World\n\r");
// //     print("Successfully ran Hello World application");
// //     cleanup_platform();
// //     return 0;
// // }

#include "platform.h"


#include "xil_printf.h"
#include <stdint.h>
#include <stdio.h>
#include <xil_types.h>
#include "xbram.h"
#include "xgpio.h"

#define LED_CHANNEL 1
#define SWITCH_CHANNEL 2
#define LEDS_MASK 0x0F     // 4 leds
#define SWITCHES_MASK 0x0F // 4 switches
#include "xparameters.h"

volatile uint32_t  *AudioCrtlReg = (uint32_t *) XPAR_AUDIO_CONTROL_GPIO_BASEADDR;  

 // // From Arm Cores
 // wire [FREQ_RES_BITS -1:0] player_source_freq = gpio_ctrl_o_32b_tri_o[FREQ_RES_BITS-1:0];
 // wire refresh = gpio_ctrl_o_32b_tri_o[4];
 // wire [VOLUME_BITS-1:0] volume_master = gpio_ctrl_o_32b_tri_o[15 : 8];

 // logic [VOLUME_BITS-1:0] player_source_vol = gpio_ctrl_o_32b_tri_o[23 : 16];
 // logic [VOLUME_BITS-1:0] bram_source_vol = gpio_ctrl_o_32b_tri_o[31 : 24];
//
void writePlayerFreq(uint8_t freq){
    *AudioCrtlReg = (*AudioCrtlReg & 0xFFFFFFF0) | (freq & 0x000F);
};

void writeBramFreq(uint8_t freq){
    *AudioCrtlReg = (*AudioCrtlReg & 0xFFFFFF0F) | (freq & 0x000F) << 4;
};
void writeRefresh(uint8_t bool){
 // if (bool){
 //   *AudioCrtlReg = (*AudioCrtlReg & 0xFFEF) | (0x1 << 4);
 // } else {
 //   *AudioCrtlReg = (*AudioCrtlReg & 0xFFEF);
 // }
};

void writeMasterVol(uint8_t vol){
    *AudioCrtlReg = (*AudioCrtlReg & 0xFFFF00FF) | ((vol & 0x00FF) << 8);
};

void writePlayerVol(uint8_t vol){
  *(AudioCrtlReg) = (*(AudioCrtlReg) & 0xFF00FFFF) | ((vol & 0x00FF) << 16);
};

void writeBramVol(uint8_t vol){
  *(AudioCrtlReg) = (*(AudioCrtlReg)  & 0x00FFFFFF) | ((vol & 0x00FF) << 24);
};

void flickBit(int bit){
    *AudioCrtlReg ^= 0x1 << bit;
};

int main() {

  init_platform();

  XGpio Gpio; /* The Instance of the GPIO Driver */
  XBram Bram; /* The Instance of the BRAM Driver */

  XBram_Config *ConfigPtr;


  int Status;

  /* Initialize the GPIO driver */
  Status = XGpio_Initialize(&Gpio, XPAR_ZYBO_BOARD_GPIO_BASEADDR );
  if (Status != XST_SUCCESS) {
    xil_printf("Gpio Initialization Failed\r\n");
    return XST_FAILURE;
  }

  ConfigPtr = XBram_LookupConfig(XPAR_AXI_BRAM_CTRL_0_BASEADDR);
  if (ConfigPtr == (XBram_Config *)NULL) {
    return XST_FAILURE;
  }

  Status = XBram_CfgInitialize(&Bram, ConfigPtr, ConfigPtr->CtrlBaseAddress);
  if (Status != XST_SUCCESS) {
    return XST_FAILURE;
  }

  /* Set the direction for all signals  */
  XGpio_SetDataDirection(&Gpio, LED_CHANNEL, ~LEDS_MASK);       // output
  XGpio_SetDataDirection(&Gpio, SWITCH_CHANNEL, SWITCHES_MASK); // input

  print("Hello World\n\r");
  print("Successfully ran Hello World application");

//   for (int i = 0; i < 16 * 4; i = i + 4) {
//     XBram_WriteReg(XPAR_AXI_BRAM_CTRL_0_BASEADDR, i, i);
//   }

  int out_data;
  int loop_count = 0;


  *AudioCrtlReg = 0xFFFFFFFF;
  xil_printf("reg is %d\n\r", *AudioCrtlReg);
  uint8_t f = 0;
  *AudioCrtlReg = 0x00000000;
  while (1) {

    //XBram_WriteReg(XPAR_AXI_BRAM_CTRL_0_BASEADDR, 0, loop_count++);

    u32 switches = XGpio_DiscreteRead(&Gpio, SWITCH_CHANNEL);
    XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, switches);
    xil_printf("checkeddddd! %x\n\r", switches);

    for (int i = 0; i < 16 * 4; i = i + 4) {
      out_data = *(volatile u32 *) ((XPAR_AXI_BRAM_CTRL_0_BASEADDR) + (i));

      xil_printf("%d: %X\n\r", i, out_data);
    }

    if (f == 15) {
        f = 0;
    } else {
        f = f+1;
    }

    xil_printf("sizof int %d\n", sizeof(unsigned int));
    //writeMasterVol(0xF);
    
    writePlayerVol(0x2);
    writePlayerFreq(f); // samples 
    
    writeBramVol(0x0);
    writeBramFreq(f); //9, 12, 15 introduce glitching (but only at some vols) (and other freqs glitch at other vols..)
    //writeRefresh();

    xil_printf("bit flicked: %d\n", f);
    xil_printf("reg is 0x%08X\n\r", *AudioCrtlReg);
    //xil_printf("reg is %x\n\r", *(AudioCrtlReg+sizeof(uint32_t)));
    sleep(1);
  }
  
  cleanup_platform();
  return 0;
}


