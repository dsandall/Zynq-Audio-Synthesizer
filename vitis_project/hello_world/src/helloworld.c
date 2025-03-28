// //
// /******************************************************************************
// // * Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
// // * SPDX-License-Identifier: MIT
// //
// ******************************************************************************/
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

// #include "ff.h"
#include "platform.h"
#include "xbram.h"
#include "xgpio.h"
#include "xil_printf.h"
#include "xsdps.h" // SD card library
#include <stdint.h>
#include <stdio.h>
#include <xil_types.h>

#define LED_CHANNEL 1
#define SWITCH_CHANNEL 2
#define LEDS_MASK 0x0F     // 4 leds
#define SWITCHES_MASK 0x0F // 4 switches

#include "sd_card.h"
#include "sleep.h"
#include "xparameters.h"

typedef struct __attribute__((packed)) {
  volatile uint8_t vol;
  volatile uint8_t freq;
} SourceControl_t;

typedef struct __attribute__((packed)) {
  volatile SourceControl_t triangle;
  volatile SourceControl_t sine;
} OscillatorControlReg_t;

typedef struct __attribute__((packed)) {
  uint16_t control;
  SourceControl_t source;
} OscillatorBRAMReg_t;

typedef struct __attribute__((packed)) {
  volatile uint32_t fill : 21;
  volatile uint32_t overdrive : 8;
  volatile uint32_t hihat : 1;
  volatile uint32_t snare : 1;
  volatile uint32_t kick : 1;
} DrumControlReg_t;

typedef struct __attribute__((packed)) {
  uint16_t fill;
  uint8_t overdrive;
  uint8_t vol;
} MainControlReg_t;

volatile DrumControlReg_t *DrumReg =
    (DrumControlReg_t *)XPAR_DRUM_CONTROL_REG_BASEADDR;
volatile MainControlReg_t *MainReg =
    (MainControlReg_t *)XPAR_MAIN_CONTROL_REG_BASEADDR;
volatile OscillatorControlReg_t *OscReg =
    (OscillatorControlReg_t *)XPAR_OSCILLATOR_CONTROL_REG_BASEADDR;
volatile OscillatorBRAMReg_t *BRAMReg =
    (OscillatorBRAMReg_t *)XPAR_XGPIO_2_BASEADDR;

void debug_printHex(const unsigned char *dataBuffer, size_t length) {
  for (size_t i = 0; i < length; i++) {
    if (isprint(dataBuffer[i])) {
      xil_printf("[x%1X \033[1;32m%c\033[0m] ", dataBuffer[i],
                 dataBuffer[i]); // Green for printable
    } else {
      xil_printf("[x%2X  ] ", dataBuffer[i]); // Default color for non-printable
    }

    // Line break every 16 bytes for readability
    if ((i + 1) % 8 == 0) {
      xil_printf("\n");
    }
  }
  xil_printf("\n");
}

int my_init() {

  init_platform();

  XGpio Gpio; /* The Instance of the GPIO Driver */
  XBram Bram; /* The Instance of the BRAM Driver */
  XBram_Config *ConfigPtr;

  int Status;

  /* Initialize the GPIO driver */
  Status = XGpio_Initialize(&Gpio, XPAR_ZYBO_BOARD_GPIO_BASEADDR);
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

  return XST_SUCCESS;
}

uint32_t usec_per_beat;
float dut;
void triangle_note(uint8_t f, uint8_t dur, uint8_t vol) {

  uint32_t total_duration = usec_per_beat * dur;
  *((uint32_t *)OscReg) =
      (*((uint32_t *)OscReg) & 0xFFFF00FF) | (f << 8); // write freq
  *((uint32_t *)OscReg) =
      (*((uint32_t *)OscReg) & 0xFFFFFF00) | (vol << 0); // write vol

  usleep(total_duration * dut);

if (dut != 1.0) {
  *((uint32_t *)OscReg) =
      (*((uint32_t *)OscReg) & 0xFFFFFF00) | (0 << 0); // write vol

  usleep(total_duration * (1.0 - dut));
}  

};
void sine_note(uint8_t f, uint8_t dur, uint8_t vol) {


  uint32_t total_duration = usec_per_beat * dur;
  *((uint32_t *)OscReg) =
      (*((uint32_t *)OscReg) & 0x00FFFFFF) | (f << 24); // write freq
  *((uint32_t *)OscReg) =
      (*((uint32_t *)OscReg) & 0xFF00FFFF) | (vol << 16); // write vol

  usleep(total_duration * dut);

  if (dut != 1.0) {

  *((uint32_t *)OscReg) =
      (*((uint32_t *)OscReg) & 0xFF00FFFF) | (0 << 16); // write vol

  usleep(total_duration * (1.0 - dut));
}};

void clearDrum() {
  usleep(200); // give the hardware a second to register the deassertion
  DrumReg->kick = 0;
  DrumReg->snare = 0;
  DrumReg->hihat = 0;
  usleep(200); // give the hardware a second to register the deassertion
}

void drums() {
  DrumReg->kick = 1;
  DrumReg->hihat = 1;
  clearDrum();
  usleep(200000);

  DrumReg->hihat = 1;
  clearDrum();
  usleep(200000);

  DrumReg->snare = 1;
  DrumReg->hihat = 1;
  clearDrum();
  usleep(200000);

  DrumReg->hihat = 1;
  clearDrum();
  usleep(200000);
}
static uint8_t volly = 0;

void demo() {
dut = 1.0;

  const uint32_t bpm = 440;
  usec_per_beat = (700000 * 60) / bpm;

    for ( int i = 0; i < 100; i++){
        sine_note(i, 1, volly);
        xil_printf("%d\n\r", i);
    }

}

void e1m1() {

dut = 0.8;

  const uint32_t bpm = 220;
  usec_per_beat = (700000 * 60) / bpm;

  // bar 1
  DrumReg->kick = 1;
  DrumReg->hihat = 1;
  sine_note(2 * 12 + 4, 1, volly);
  DrumReg->kick = 0;
  DrumReg->hihat = 0;
  sine_note(2 * 12 + 4, 1, volly);
  sine_note(3 * 12 + 4, 1, volly);

  sine_note(2 * 12 + 4, 1, volly);
  sine_note(2 * 12 + 4, 1, volly);
  sine_note(3 * 12 + 2, 1, volly);

  sine_note(2 * 12 + 4, 1, volly);
  sine_note(2 * 12 + 4, 1, volly);
  sine_note(3 * 12 + 0, 1, volly);

  sine_note(2 * 12 + 4, 1, volly);
  sine_note(2 * 12 + 4, 1, volly);
  sine_note(3 * 12 - 2, 1, volly);

  sine_note(2 * 12 + 4, 1, volly);
  sine_note(2 * 12 + 4, 1, volly);
  sine_note(3 * 12 - 1, 1, volly);
  sine_note(3 * 12 - 0, 1, volly);

  // bar 1 ends
  //
  // bar 2

  DrumReg->kick = 1;
  DrumReg->hihat = 1;
  sine_note(2 * 12 + 4, 1, volly);
  DrumReg->kick = 0;
  DrumReg->hihat = 0;
  sine_note(2 * 12 + 4, 1, volly);
  sine_note(3 * 12 + 4, 1, volly);

  sine_note(2 * 12 + 4, 1, volly);
  sine_note(2 * 12 + 4, 1, volly);
  sine_note(3 * 12 + 2, 1, volly);

  sine_note(2 * 12 + 4, 1, volly);
  sine_note(2 * 12 + 4, 1, volly);
  sine_note(3 * 12 + 0, 1, volly);

  sine_note(2 * 12 + 4, 1, volly);
  sine_note(2 * 12 + 4, 1, volly);
  sine_note(3 * 12 - 2, 5, volly);
}


int main() {

  if (my_init() == XST_SUCCESS) {
    print("Hello World\n\r");
  } else {
    return XST_FAILURE;
  }

  //  // write to the bram
  //   for (int i = 0; i < 16 * 4; i = i + 4) {
  //     XBram_WriteReg(XPAR_AXI_BRAM_CTRL_0_BASEADDR, i, i);
  //   }

  // writeReg_RefreshBram(1);

  while (1) {

    xil_printf("mainreg is %X\n\r", *MainReg);
    debug_printHex((const unsigned char *)MainReg, 4);

    // // write loop iteration to bram
    // XBram_WriteReg(XPAR_AXI_BRAM_CTRL_0_BASEADDR, 0, loop_count++);
    /*
        // Read gpio switches
        u32 switches = XGpio_DiscreteRead(&Gpio, SWITCH_CHANNEL);
        XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, switches);

        // read bram contents
        for (int i = 0; i < 16 * 4; i = i + 4) {
          int out_data;
          out_data = *(volatile u32 *) ((XPAR_AXI_BRAM_CTRL_0_BASEADDR) + (i));

          xil_printf("%d: %X\n\r", i, out_data);
        }
    */
    xil_printf("drum reg %X d\n\r", *DrumReg);

    char c = inbyte();


    static uint8_t main_od = 0;

    if (c == 'z') {
        sine_note(2 * 12 + 4, 1, volly);

    } else if (c == '+') {
      MainReg->vol++;

    } else if (c == '-') {
      MainReg->vol--;
    } else if (c == ' ') {
      // freq up
      DrumReg->kick = 1;
      usleep(500);
      DrumReg->kick = 0;
    } else if (c == 'y') {
        volly++;
    xil_printf("v: %d\n\r",  volly);

    } else if (c == 'w') {
        volly--;
    xil_printf("v: %d\n\r",  volly);

    } else if (c == 'v') {
      DrumReg->hihat = 1;
      usleep(500);
      DrumReg->hihat = 0;

    } else if (c == 'm') {
      e1m1();
    } else if (c == 'l') {
      drums();
    } else if (c == 'h') {
      demo();
    } else if (c == 'o') {
    
        main_od++;

      *((uint32_t *)MainReg) = (*((uint32_t *)MainReg) & 0xFF00FFFF) | (main_od << 16);
    } else if (c == 'p') {

      *((uint32_t *)DrumReg) =
          (*((uint32_t *)DrumReg) & 0xE01FFFFF) | (2 << 21);
      
    } else if (c == 'n') {
      OscReg->sine.freq = 0;
      OscReg->sine.vol = 0;
      OscReg->triangle.freq = 0;
      OscReg->triangle.vol = 0;
      DrumReg->overdrive = 0;
        *((uint32_t *)MainReg) = (uint32_t) 0;
        main_od = 0;

    }

    continue;

    uint8_t f = 0;
    uint8_t v = 0;
    const int tri_octave = f / 12;
    const int tri_semitone = f % 12;

    xil_printf("f: %d, v: %d\n\r", f, v);
    xil_printf("octave %d, semitone %d\n\r", tri_octave, tri_semitone);
  }

  cleanup_platform();
  return 0;
}

/*
FIL fil;
    // interface with SD card
        int Status;
        xil_printf("SD Polled File System Example Test \r\n");

        Status = FfsSdPolledExample();
        if (Status != XST_SUCCESS) {
                xil_printf("SD Polled File System Example Test failed
   \r\n"); return XST_FAILURE;
        }
        xil_printf("Successfully ran SD Polled File System Example Test
   \r\n");


        // Status = dostuff(&fil);
        // if (Status != XST_SUCCESS) {
        // 	xil_printf("SD Polled File System Example Test failed \r\n");
        // 	return XST_FAILURE;
        // }
        // xil_printf("Successfully ran SD Polled File System Example Test
   \r\n");
*/

// jungle drum loop
// https://youtu.be/Hal5TuhjNDE

// TODO: use this to create hihat - feed in high passed noise, and make
// no attack with fast decay
// https://www.youtube.com/watch?v=lycuJKFHJFw&pp=ygUqaG93IHRvIG1ha2Ugc3ludGhlc2l6ZXIgaGloYXQgZnJvbSBzY3JhdGNo

// TODO: make snare - start with kick drum, but high-low pitch at begin, and
// add white noise spike/fade at begin https://youtu.be/Ky3yg8ghpo8
