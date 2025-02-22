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
#include "xsdps.h" // SD card library
#include "ff.h"

#define LED_CHANNEL 1
#define SWITCH_CHANNEL 2
#define LEDS_MASK 0x0F     // 4 leds
#define SWITCHES_MASK 0x0F // 4 switches
#include "xparameters.h"

#include "sleep.h"

#include "sd_card.h"

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
    *AudioCrtlReg = (*AudioCrtlReg & 0xFFFFFEFF) | ((bool & 0x0001) << 8);
    // bit 0 of the second byte in the reg.
};
void writeReg_RefreshBram(uint8_t bool){
    *AudioCrtlReg = (*AudioCrtlReg & 0xFFFFFDFF) | ((bool & 0x0001) << 9);
    // bit 0 of the second byte in the reg.
};
/*
void writeMasterVol(uint8_t vol){
    *AudioCrtlReg = (*AudioCrtlReg & 0xFFFF00FF) | ((vol & 0x00FF) << 8);
};
*/

void writePlayerVol(uint8_t vol){
  *(AudioCrtlReg) = (*(AudioCrtlReg) & 0xFF00FFFF) | ((vol & 0x00FF) << 16);
};

void writeBramVol(uint8_t vol){
  *(AudioCrtlReg) = (*(AudioCrtlReg)  & 0x00FFFFFF) | ((vol & 0x00FF) << 24);
};

void flickBit(int bit){
    *AudioCrtlReg ^= 0x1 << bit;
};

void playKick(uint8_t freq_add) {
  int scale = 5000;
  int pitchFall_delay = 3;
  int volumeFall_delay = 9;
    // high pitch for a sec
    // low pitch for remainder
    // long fadeout
    //
    writeBramVol(7);
    writeBramFreq(1 + freq_add);
    usleep(pitchFall_delay *scale);
    writeBramFreq(2 + freq_add);
    usleep(pitchFall_delay *scale);
    writeBramFreq(3 + freq_add);
    usleep(pitchFall_delay *scale);
    writeBramFreq(4 + freq_add);
    usleep(pitchFall_delay *scale);
    writeBramVol(6);
    usleep(volumeFall_delay*scale);
    writeBramVol(5);
    usleep(volumeFall_delay*scale);
    writeBramVol(4);
    usleep(volumeFall_delay*scale);
    writeBramVol(3);
    usleep(volumeFall_delay*scale);
    writeBramVol(2);
    usleep(volumeFall_delay*scale);
    writeBramVol(0);
    writeBramFreq(0);
};

int my_init() {

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

  return XST_SUCCESS;
}

int main() {

  if (my_init() == XST_SUCCESS){
    print("Hello World\n\r");
  } else {
    return XST_FAILURE;
  }

//  // write to the bram
//   for (int i = 0; i < 16 * 4; i = i + 4) {
//     XBram_WriteReg(XPAR_AXI_BRAM_CTRL_0_BASEADDR, i, i);
//   }


  uint8_t f = 0;
  *AudioCrtlReg = 0x00000000;
  uint8_t refresh_en = 1;
  writeRefresh(refresh_en);
  uint8_t refresh_bram = 1;
  writeReg_RefreshBram(refresh_bram);
    writePlayerVol(0x0);
    writeBramVol(0x7);
    writePlayerFreq(f); // samples 
    writeBramFreq(f); //9, 12, 15 introduce glitching (but only at some vols) (and other freqs glitch at other vols..)

  while (1) {

    // // write loop iteration to bram
    //XBram_WriteReg(XPAR_AXI_BRAM_CTRL_0_BASEADDR, 0, loop_count++);

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
    //xil_printf("f is: %d\n", f);



	int Status;
	xil_printf("SD Polled File System Example Test \r\n");
	Status = FfsSdPolledExample();
	if (Status != XST_SUCCESS) {
		xil_printf("SD Polled File System Example Test failed \r\n");
		return XST_FAILURE;
	}
	xil_printf("Successfully ran SD Polled File System Example Test \r\n");



    xil_printf("reg is 0x%08X\n\r", *AudioCrtlReg);

    char c = inbyte();
    if (c == '\r') {
        refresh_en = refresh_en ? 0 : 1; 
        xil_printf("refresh_main_buffer is %d\n", refresh_en);
        writeRefresh(refresh_en);
    } else if (c == 'x') {
        refresh_bram = refresh_bram ? 0 : 1;
        xil_printf("refresh_bram is %d\n", refresh_bram);
        writeReg_RefreshBram(refresh_bram);  
    } else {
        playKick(c % 8);
    }

    //writeRefresh(0);
    //sleep(2);
/*    writeRefresh(1);
    sleep(1);
    writeRefresh(0);
    sleep(1);
 */
  }
  
  cleanup_platform();
  return 0;
}

///
///
///
///
///
///
///
///
///
///
///
///
/************************** Variable Definitions *****************************/
static FIL fil;		/* File object */
static FATFS fatfs;
/*
 * To test logical drive 0, FileName should be "0:/<File name>" or
 * "<file_name>". For logical drive 1, FileName should be "1:/<file_name>"
 */
static char FileName[32] = "Test.bin";
static char *SD_File;

#ifdef __ICCARM__
#pragma data_alignment = 32
u8 DestinationAddress[10*1024];
#pragma data_alignment = 32
u8 SourceAddress[10*1024];
#else
u8 DestinationAddress[10*1024] __attribute__ ((aligned(32)));
u8 SourceAddress[10*1024] __attribute__ ((aligned(32)));
#endif

#define TEST 7
MKFS_PARM mkfs_parm;


int FfsSdPolledExample(void)
{
	FRESULT Res; 
	UINT NumBytesRead;
	UINT NumBytesWritten;
	u32 BuffCnt;
	BYTE work[FF_MAX_SS];
	u32 FileSize = (8*1024);

	/*
	 * To test logical drive 0, Path should be "0:/"
	 * For logical drive 1, Path should be "1:/"
	 */
	TCHAR *Path = "0:/";

	for(BuffCnt = 0; BuffCnt < FileSize; BuffCnt++){
		SourceAddress[BuffCnt] = TEST + BuffCnt;
	}

	/*
	 * Register volume work area, initialize device
	 */
	Res = f_mount(&fatfs, Path, 0);

	if (Res != FR_OK) {
		return XST_FAILURE;
	}

	 mkfs_parm.fmt = FM_FAT32;
	/*
	 * Path - Path to logical driver, 0 - FDISK format.
	 * 0 - Cluster size is automatically determined based on Vol size.
	 */
	Res = f_mkfs(Path, &mkfs_parm , work, sizeof work);
	if (Res != FR_OK) {
		return XST_FAILURE;
	}

	/*
	 * Open file with required permissions.
	 * Here - Creating new file with read/write permissions. .
	 * To open file with write permissions, file system should not
	 * be in Read Only mode.
	 */
	SD_File = (char *)FileName;

	Res = f_open(&fil, SD_File, FA_CREATE_ALWAYS | FA_WRITE | FA_READ);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Pointer to beginning of file .
	 */
	Res = f_lseek(&fil, 0);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Write data to file.
	 */
	Res = f_write(&fil, (const void*)SourceAddress, FileSize,
			&NumBytesWritten);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Pointer to beginning of file .
	 */
	Res = f_lseek(&fil, 0);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Read data from file.
	 */
	Res = f_read(&fil, (void*)DestinationAddress, FileSize,
			&NumBytesRead);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Data verification
	 */
	for(BuffCnt = 0; BuffCnt < FileSize; BuffCnt++){
		if(SourceAddress[BuffCnt] != DestinationAddress[BuffCnt]){
			return XST_FAILURE;
		}
	}

	/*
	 * Close file.
	 */
	Res = f_close(&fil);
	if (Res) {
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}
