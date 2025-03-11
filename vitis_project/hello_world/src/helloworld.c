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

#include "ff.h"
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
#include "xparameters.h"

#include "sleep.h"

#include "sd_card.h"

volatile uint32_t *AudioCrtlReg = (uint32_t *)XPAR_AUDIO_CONTROL_GPIO_BASEADDR;

// // From Arm Cores
// wire [FREQ_RES_BITS -1:0] player_source_freq =
// gpio_ctrl_o_32b_tri_o[FREQ_RES_BITS-1:0]; wire refresh =
// gpio_ctrl_o_32b_tri_o[4]; wire [VOLUME_BITS-1:0] volume_master =
// gpio_ctrl_o_32b_tri_o[15 : 8];

// logic [VOLUME_BITS-1:0] player_source_vol = gpio_ctrl_o_32b_tri_o[23 : 16];
// logic [VOLUME_BITS-1:0] bram_source_vol = gpio_ctrl_o_32b_tri_o[31 : 24];
//
void writePlayerFreq(uint8_t freq) {
  //*AudioCrtlReg = (*AudioCrtlReg & 0xFFFFFFF0) | (freq & 0x000F);
  *AudioCrtlReg = (*AudioCrtlReg & 0xFFFFFF00) | (freq & 0x00FF);
};

void writeBramFreq(uint8_t freq) {
  *AudioCrtlReg = (*AudioCrtlReg & 0xFFFFF00FF) | (freq & 0x00FF) << 8;
};

/*
void writeRefresh(uint8_t bool) {
  *AudioCrtlReg = (*AudioCrtlReg & 0xFFFFFEFF) | ((bool & 0x0001) << 8);
  // bit 0 of the second byte in the reg.
};
void writeReg_RefreshBram(uint8_t bool) {
  *AudioCrtlReg = (*AudioCrtlReg & 0xFFFFFDFF) | ((bool & 0x0001) << 9);
  // bit 0 of the second byte in the reg.
};
void writeMasterVol(uint8_t vol){
    *AudioCrtlReg = (*AudioCrtlReg & 0xFFFF00FF) | ((vol & 0x00FF) << 8);
};
*/
//  assign player.freq = PS_32b_AudioControlReg_Out[7:0];
//  assign bram.freq = PS_32b_AudioControlReg_Out[15:8];
//  assign player.vol = PS_32b_AudioControlReg_Out[23:16];
//  assign bram.vol = PS_32b_AudioControlReg_Out[31:24];

void writePlayerVol(uint8_t vol) {
  *(AudioCrtlReg) = (*(AudioCrtlReg) & 0xFF00FFFF) | ((vol & 0x00FF) << 16);
};

void writeBramVol(uint8_t vol) {
  *(AudioCrtlReg) = (*(AudioCrtlReg) & 0x00FFFFFF) | ((vol & 0x00FF) << 24);
};

void flickBit(int bit) { *AudioCrtlReg ^= 0x1 << bit; };

void playBass(uint8_t freq) {
  int scale = 1000;
  int pitchFall_delay = 3;
  int volumeFall_delay = 9;
  // high pitch for a sec
  // low pitch for remainder
  // long fadeout
  //

  writePlayerVol(0);
  writePlayerFreq(freq);
  writePlayerVol(7);
  writePlayerFreq(1 + freq);
  usleep(pitchFall_delay * scale);
  writePlayerFreq(2 + freq);
  usleep(pitchFall_delay * scale);
  writePlayerFreq(3 + freq);
  usleep(pitchFall_delay * scale);
  writePlayerFreq(4 + freq);
  usleep(pitchFall_delay * scale);
  writePlayerVol(6);
  usleep(volumeFall_delay * scale);
  writePlayerVol(5);
  usleep(volumeFall_delay * scale);
  usleep(volumeFall_delay * scale);
  writePlayerVol(4);
  usleep(volumeFall_delay * scale);
  usleep(volumeFall_delay * scale);
  writePlayerVol(3);
  usleep(volumeFall_delay * scale);
  usleep(volumeFall_delay * scale);
  writePlayerVol(2);
  usleep(volumeFall_delay * scale);
  usleep(volumeFall_delay * scale);
  writePlayerVol(1);
  usleep(volumeFall_delay * scale);
  usleep(volumeFall_delay * scale);
  writePlayerVol(0);
  writePlayerFreq(0);
};

void playKick(uint8_t freq_add) {
  int scale = 2500;
  int pitchFall_delay = 3;
  const int pitchRise = 8;
  int volumeFall_delay = 8;
  // high pitch for a sec
  // low pitch for remainder
  // long fadeout

  // hw implementations:
  // oneshot triggering (register write 1, becomes 0 when "handled", can be
  // interrupted)
  //
  // simple time controllers for linear/constant freq and volume changes
  //
  // filters with coefficients that make sense
  //

  // jungle drum loop
  // https://youtu.be/Hal5TuhjNDE

  // TODO: use this to create hihat - feed in high passed noise, and make
  // no attack with fast decay
  // https://www.youtube.com/watch?v=lycuJKFHJFw&pp=ygUqaG93IHRvIG1ha2Ugc3ludGhlc2l6ZXIgaGloYXQgZnJvbSBzY3JhdGNo

  // TODO: make snare - start with kick drum, but high-low pitch at begin, and
  // add white noise spike/fade at begin https://youtu.be/Ky3yg8ghpo8

  const uint8_t volStart = 64;

  writeBramVol(volStart);

  for (uint8_t f = freq_add; f < freq_add + pitchRise; f++) {
    writeBramFreq(f);
    usleep(pitchFall_delay * scale);
  }

  for (uint8_t v = volStart; v > 0; v--) {
    writeBramVol(v);
    usleep(volumeFall_delay * scale);
  }

  writeBramVol(0);
  writeBramFreq(0);

  //   writeBramVol(7);
  //   writeBramFreq(1 + freq_add);
  //   usleep(pitchFall_delay * scale);
  //   writeBramFreq(2 + freq_add);
  //   usleep(pitchFall_delay * scale);
  //   writeBramFreq(3 + freq_add);
  //   usleep(pitchFall_delay * scale);
  //   writeBramFreq(4 + freq_add);
  //   usleep(pitchFall_delay * scale);
  //   writeBramVol(6);
  //   usleep(volumeFall_delay * scale);
  //   writeBramVol(5);
  //   usleep(volumeFall_delay * scale);
  //   writeBramVol(4);
  //   usleep(volumeFall_delay * scale);
  //   writeBramVol(3);
  //   usleep(volumeFall_delay * scale);
  //   writeBramVol(2);
  //   usleep(volumeFall_delay * scale);
  //   writeBramVol(0);
  //   writeBramFreq(0);
};

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

  *AudioCrtlReg = 0x00000000;
  // uint8_t refresh_en = 1;
  // writeRefresh(refresh_en);
  // uint8_t refresh_bram = 1;
  // writeReg_RefreshBram(refresh_bram);
  writePlayerVol(0);
  writeBramVol(0);
  writePlayerFreq(0); // samples
  writeBramFreq(0);   // 9, 12, 15 introduce glitching (but only at some vols)
                      // (and other freqs glitch at other vols..)

  while (1) {

    // // write loop iteration to bram
    // XBram_WriteReg(XPAR_AXI_BRAM_CTRL_0_BASEADDR, 0, loop_count++);

    /*
        // Read gpio switches
        u32 switches = XGpio_DiscreteRead(&Gpio, SWITCH_CHANNEL);
        XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, switches);
        xil_printf("checkeddddd! %x\n\r", switches);
    */

    /*
        // read bram contents
        for (int i = 0; i < 16 * 4; i = i + 4) {
          int out_data;
          out_data = *(volatile u32 *) ((XPAR_AXI_BRAM_CTRL_0_BASEADDR) + (i));

          xil_printf("%d: %X\n\r", i, out_data);
        }
    */
    // xil_printf("f is: %d\n", f);

    char c = inbyte();

    static uint8_t f = 0;
    static uint8_t player_v = 0;

    if (c == '\r') {

      writePlayerVol(player_v++);

      //      refresh_en = refresh_en ? 0 : 1;
      //      xil_printf("refresh_main_buffer is %d\n", refresh_en);
      //      writeRefresh(refresh_en);
      //
      //    } else if (c == 'x') {
      //      refresh_bram = refresh_bram ? 0 : 1;
      //      xil_printf("refresh_bram is %d\n", refresh_bram);
      //      writeReg_RefreshBram(refresh_bram);

    } else if (c == '+') {
      f++;
      writePlayerFreq(f);

    } else if (c == '-') {
      f--;
      writePlayerFreq(f);

    } else if (c == ' ') {
      xil_printf("%d\n", f);
      // writePlayerFreq(f);
      // playBass(f);

    } else {
      xil_printf("%d\n", c);
      playKick(c % 8);
    }

    const int tri_octave = f / 12;
    const int tri_semitone = f % 12;

    xil_printf("triangle octave %d, semitone %d\n\r", tri_octave, tri_semitone);
    xil_printf("reg is 0x%08X\n\r", *AudioCrtlReg);
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
