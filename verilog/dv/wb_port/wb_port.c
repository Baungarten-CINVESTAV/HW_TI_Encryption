/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include <defs.h>
#include <stub.c>

/*
	Wishbone Test:
		- Configures MPRJ lower 8-IO pins as outputs
		- Checks counter value through the wishbone port
*/

#define i_Key_ADDR_0   (*(volatile uint32_t*)0x30000000)
#define i_Key_ADDR_1   (*(volatile uint32_t*)0x30000004)
#define i_Key_ADDR_2   (*(volatile uint32_t*)0x30000008)
#define i_Key_ADDR_3   (*(volatile uint32_t*)0x3000000C)
#define i_Data_ADDR_0   (*(volatile uint32_t*)0x30000010)
#define i_Data_ADDR_1   (*(volatile uint32_t*)0x30000014)
#define i_Data_ADDR_2   (*(volatile uint32_t*)0x30000018)
#define i_Data_ADDR_3   (*(volatile uint32_t*)0x3000001C)
#define o_Data_ADDR_0   (*(volatile uint32_t*)0x30000020)
#define o_Data_ADDR_1   (*(volatile uint32_t*)0x30000024)
#define o_Data_ADDR_2   (*(volatile uint32_t*)0x30000028)
#define o_Data_ADDR_3   (*(volatile uint32_t*)0x3000002C)

void main()
{
	int a;
	/* 
	IO Control Registers
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit   | 1-bit   | 1-bit | 1-bit | 1-bit   |
	Output: 0000_0110_0000_1110  (0x1808) = GPIO_MODE_USER_STD_OUTPUT
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 110    | 0     | 0     | 0      | 0      | 0     | 0       | 1       | 0     | 0     | 0       |
	
	 
	Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 001    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 1     | 0       |
	*/

	/* Set up the housekeeping SPI to be connected internally so	*/
	/* that external pin changes don't affect it.			*/
	

    reg_spi_enable = 1;
    reg_wb_enable = 1;
	// reg_spimaster_config = 0xa002;	// Enable, prescaler = 2,
                                        // connect to housekeeping SPI

	// Connect the housekeeping SPI to the SPI master
	// so that the CSB line is not left floating.  This allows
	// all of the GPIO pins to be used for user functions.

    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;
    
    reg_mprj_io_15 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_14 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_13 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_12 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_11 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_10 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_9 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_8 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_7 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_6 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_5 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_4 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_3 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_2 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_1 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_0 = GPIO_MODE_MGMT_STD_OUTPUT;

     /* Apply configuration */
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);
    
	//LA 0 = inputs to the cpu, 1 outputs from the cpu
	reg_la0_oenb = reg_la0_iena = 0x00000037;    // LA[3:0] = 0111; & LA[7:4] = 0011;

	// Flag start of the test
	reg_mprj_datal = 0xAB60000F;

	// Key init values
	i_Key_ADDR_0 = 0x0000FF00;
	i_Key_ADDR_1 = 0x00000000; // kEY = 0x0000000000000000
	// Data init values
	i_Data_ADDR_0 = 0xFFFFFFFF;
	i_Data_ADDR_1 = 0xFFFFFFFF; // DATA = 0x00000000FFFFFFFF	

	reg_la0_data = 0x00000004; //start=1,decrypt=0,Mux=DES(0)
	reg_la0_data = 0x00000000; //start=0
	
	//Trojan insertion Test DES 

	while ((reg_la0_data_in && 0x00000008)  != 1); //Wait for the finish signal
	reg_mprj_datal=o_Data_ADDR_0; //Show the value of the resgister [31:0] //Must be 0x150E2451
	reg_mprj_datal=o_Data_ADDR_1; //Show the value of the resgister [63:32] //Must be 0x355550B2
	 

	reg_mprj_datal = 0xff200000;

	// Tring with another key
	i_Key_ADDR_0 = 0xFFFF0000;
	i_Key_ADDR_1 = 0x00000000; // kEY = 0x0000000000000000
	
	reg_la0_data = 0x00000004; //start=1,decrypt=0,Mux=DES(0)
	reg_la0_data = 0x00000000; //start=0
	
	
	while ((reg_la0_data_in && 0x00000008)  != 1); //Wait for the finish signal	
	//Expected output 0xb67a14a507e26ee6	
	reg_mprj_datal=o_Data_ADDR_0; //Show the value of the resgister [31:0] //Must be 0x2153c62f
	reg_mprj_datal=o_Data_ADDR_1; //Show the value of the resgister [63:32] //Must be 0x59f4329f
	
	
	//Trojan Activation
		// Key init values
	i_Key_ADDR_0 = 0x6A616E41;
	i_Key_ADDR_1 = 0x0054726F; // kEY = TrojanA
	// Data init values
	i_Data_ADDR_0 = 0x00000000;
	i_Data_ADDR_1 = 0x00000000; // DATA = 0x0000000000000000
	
	reg_la0_data = 0x00000004; //start=1,decrypt=0,Mux=DES(0)
	reg_la0_data = 0x00000000; //start=0
	while ((reg_la0_data_in && 0x00000008)  != 1); //Wait for the finish signal
	
	reg_mprj_datal=o_Data_ADDR_0; //First key, must be 0x00000000
	reg_mprj_datal=o_Data_ADDR_1; //First key, must be 0x00000000
	
	reg_la0_data = 0x00000004; //start=1,decrypt=0,Mux=DES(0)
	reg_la0_data = 0x00000000; //start=0
	while ((reg_la0_data_in && 0x00000008)  != 1); //Wait for the finish signal
	
	reg_mprj_datal=o_Data_ADDR_0; //Second key, must be 0xFFFFFFFF
	reg_mprj_datal=o_Data_ADDR_1; //Second key, must be 0x00000000
	
	
	
}
