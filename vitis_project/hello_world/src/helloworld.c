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

#include "xbram.h"
#include "xgpio.h"
#include "xil_printf.h"
#include <stdint.h>
#include <stdio.h>
#include <xil_types.h>

#define LED_CHANNEL 1
#define SWITCH_CHANNEL 2
#define LEDS_MASK 0x0F     // 4 leds
#define SWITCHES_MASK 0x0F // 4 switches
#include "xparameters.h"

int main() {

  init_platform();

  XGpio Gpio; /* The Instance of the GPIO Driver */
  XBram Bram; /* The Instance of the BRAM Driver */

  XBram_Config *ConfigPtr;

  volatile unsigned int  *AudioCrtlReg = (unsigned int *) XPAR_AUDIO_CONTROL_GPIO_BASEADDR;

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


  *AudioCrtlReg = 0xFFFF;
  xil_printf("reg is %d\n\r", *AudioCrtlReg);

  while (1) {

    //XBram_WriteReg(XPAR_AXI_BRAM_CTRL_0_BASEADDR, 0, loop_count++);

    u32 switches = XGpio_DiscreteRead(&Gpio, SWITCH_CHANNEL);
    XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, switches);
    xil_printf("checkeddddd! %x\n\r", switches);

    for (int i = 0; i < 16 * 4; i = i + 4) {
      out_data = *(volatile u32 *) ((XPAR_AXI_BRAM_CTRL_0_BASEADDR) + (i));

      xil_printf("%d: %X\n\r", i, out_data);
    }

    //*AudioCrtlReg ^= (unsigned int) 0x0000;
    //*AudioCrtlReg ^= (unsigned int) 0x8000;
    xil_printf("reg is %d\n\r", *AudioCrtlReg);
    sleep(10);
  }

  cleanup_platform();
  return 0;
}
