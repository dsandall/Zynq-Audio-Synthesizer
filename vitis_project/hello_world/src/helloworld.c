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


// /******************************************************************************
// *
// * Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
// *
// * Permission is hereby granted, free of charge, to any person obtaining a copy
// * of this software and associated documentation files (the "Software"), to deal
// * in the Software without restriction, including without limitation the rights
// * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// * copies of the Software, and to permit persons to whom the Software is
// * furnished to do so, subject to the following conditions:
// *
// * The above copyright notice and this permission notice shall be included in
// * all copies or substantial portions of the Software.
// *
// * Use of the Software is limited solely to applications:
// * (a) running on a Xilinx device, or
// * (b) that interact with a Xilinx device through a bus or interconnect.
// *
// * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// * XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
// * OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// * SOFTWARE.
// *
// * Except as contained in this notice, the name of the Xilinx shall not be used
// * in advertising or otherwise to promote the sale, use or other dealings in
// * this Software without prior written authorization from Xilinx.
// *
// ******************************************************************************/

// /*
//  * helloworld.c: simple test application
//  *
//  * This application configures UART 16550 to baud rate 9600.
//  * PS7 UART (Zynq) is not initialized by this application, since
//  * bootrom/bsp configures it to baud rate 115200
//  *
//  * ------------------------------------------------
//  * | UART TYPE   BAUD RATE                        |
//  * ------------------------------------------------
//  *   uartns550   9600
//  *   uartlite    Configurable only in HW design
//  *   ps7_uart    115200 (configured by bootrom/bsp)
//  */

// #include <stdio.h>
// #include "platform.h"
// #include "xil_printf.h"
// #include "xgpio.h"
// #include "xbram.h"
// #include "xparameters.h"

// #define LED_CHANNEL 1
// #define SWITCH_CHANNEL 2
// #define LEDS_MASK 0x0F   // 4 leds
// #define SWITCHES_MASK 0x0F   // 4 switches
// #define XPAR_BRAM_0_BASEADDR  XPAR_AXI_BRAM_CTRL_0_BASEADDR


// int main()
// {


//     init_platform();

// 	XGpio Gpio; /* The Instance of the GPIO Driver */
// 	XBram Bram;	/* The Instance of the BRAM Driver */

// 	XBram_Config *ConfigPtr;

// 	int Status;

// 	/* Initialize the GPIO driver */
// 	Status = XGpio_Initialize(&Gpio, XPAR_AXI_GPIO_0_BASEADDR);
// 	if (Status != XST_SUCCESS) {
// 		xil_printf("Gpio Initialization Failed\r\n");
// 		return XST_FAILURE;
// 	}


// 	ConfigPtr = XBram_LookupConfig(XPAR_BRAM_0_BASEADDR);
// 	if (ConfigPtr == (XBram_Config *) NULL) {
// 		return XST_FAILURE;
// 	}

// 	Status = XBram_CfgInitialize(&Bram, ConfigPtr,
// 				     ConfigPtr->CtrlBaseAddress);
// 	if (Status != XST_SUCCESS) {
// 		return XST_FAILURE;
// 	}


// 	/* Set the direction for all signals  */
// 	XGpio_SetDataDirection(&Gpio, LED_CHANNEL, ~LEDS_MASK); // output
// 	XGpio_SetDataDirection(&Gpio, SWITCH_CHANNEL, SWITCHES_MASK); // input

//     print("Hello World\n\r");
//     print("Successfully ran Hello World application");

//     //for (int i = 0; i < 16*4; i=i+4){
//     //	XBram_WriteReg(XPAR_BRAM_0_BASEADDR,i,i);
//     //}



//     while(1){

//         int out_data;
        
//         for (int i = 0; i < 16*4; i=i+4){
//     	    out_data = XBram_ReadReg(XPAR_BRAM_0_BASEADDR,i);
// 		    xil_printf("%d: %d\n\r",i, out_data);
//         }

//         u32 switches = XGpio_DiscreteRead(&Gpio,SWITCH_CHANNEL);
//         XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, switches);
        
// 		xil_printf("checked! %x\n\r",switches);
// 		sleep(1);
//     }


//     cleanup_platform();
//     return 0;
// }


// /******************************************************************************
// * Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
// * SPDX-License-Identifier: MIT
// ******************************************************************************/
// /*
//  * helloworld.c: simple test application
//  *
//  * This application configures UART 16550 to baud rate 9600.
//  * PS7 UART (Zynq) is not initialized by this application, since
//  * bootrom/bsp configures it to baud rate 115200
//  *
//  * ------------------------------------------------
//  * | UART TYPE   BAUD RATE                        |
//  * ------------------------------------------------
//  *   uartns550   9600
//  *   uartlite    Configurable only in HW design
//  *   ps7_uart    115200 (configured by bootrom/bsp)
//  */

// #include <stdio.h>
// #include "platform.h"
// #include "xil_printf.h"

// int main()
// {
//     init_platform();

//     print("Hello World\n\r");
//     print("Successfully ran Hello World application");
//     cleanup_platform();
//     return 0;
// }

#include "platform.h"
#include "xgpio.h"
#include "xbram.h"
#include "xil_printf.h"
#include <stdint.h>
#include <stdio.h>

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

  int Status;

  /* Initialize the GPIO driver */
  Status = XGpio_Initialize(&Gpio, XPAR_AXI_GPIO_0_BASEADDR);
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

  for (int i = 0; i < 16 * 4; i = i + 4) {
    XBram_WriteReg(XPAR_AXI_BRAM_CTRL_0_BASEADDR, i, i);
  }

  int out_data;
  int loop_count = 0;

//   volatile u32 *i2s_ctrl = (u32 *)XPAR_I2S_TRANSMITTER_0_BASEADDR;
//   i2s_ctrl[2] = 0x00000001; // set enable core bit

  while (1) {

    XBram_WriteReg(XPAR_AXI_BRAM_CTRL_0_BASEADDR, 0, loop_count++);

    u32 switches = XGpio_DiscreteRead(&Gpio, SWITCH_CHANNEL);
    XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, switches);
    xil_printf("checkeddddd! %x\n\r", switches);
    //sleep(1);

    for (int i = 0; i < 16 * 4; i = i + 4) {
      out_data = XBram_ReadReg(XPAR_AXI_BRAM_CTRL_0_BASEADDR, i);
      xil_printf("%d: %d\n\r", i, out_data);
    }

    // // Accessing the I2S transmitter control registers
    // for (int i = 0; i < 6; i++) {
    //   xil_printf("%02x== %x\n\r", i * sizeof(u32), i2s_ctrl[i]);
    // }
    // xil_printf("%02x== %x\n\r", 8 * sizeof(u32), i2s_ctrl[8]);
    // xil_printf("%02x== %x\n\r", 12 * sizeof(u32), i2s_ctrl[12]);
    // xil_printf("%02x== %x\n\r", 13 * sizeof(u32), i2s_ctrl[13]);
    // xil_printf("%02x== %x\n\r", 14 * sizeof(u32), i2s_ctrl[14]);
    // xil_printf("%02x== %x\n\r", 15 * sizeof(u32), i2s_ctrl[15]);

    // i2s_ctrl[0x14 / 4] = 0x00000002; // clear interrupt flag?
  }

  cleanup_platform();
  return 0;
}
