// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32,
    parameter   [31:0]  BASE_ADDRESS    = 32'h3000_0000,        // base address
    parameter   [31:0]  i_Key_ADDR_0     = BASE_ADDRESS,
    parameter   [31:0]  i_Key_ADDR_1     = i_Key_ADDR_0+4,
    parameter   [31:0]  i_Key_ADDR_2     = i_Key_ADDR_1+4,
    parameter   [31:0]  i_Key_ADDR_3     = i_Key_ADDR_2+4,
    parameter   [31:0]  i_Data_ADDR_0  = i_Key_ADDR_3 + 4,
    parameter   [31:0]  i_Data_ADDR_1  = i_Data_ADDR_0 + 4,
    parameter   [31:0]  i_Data_ADDR_2  = i_Data_ADDR_1 + 4,
    parameter   [31:0]  i_Data_ADDR_3  = i_Data_ADDR_2 + 4,
    parameter   [31:0]  o_Data_ADDR_0  = i_Data_ADDR_3 + 4,
    parameter   [31:0]  o_Data_ADDR_1  = o_Data_ADDR_0 + 4,
    parameter   [31:0]  o_Data_ADDR_2  = o_Data_ADDR_1 + 4,
    parameter   [31:0]  o_Data_ADDR_3  = o_Data_ADDR_2 + 4
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/// DES signals
wire	[63:0]	desOut;
wire	[63:0]	desIn;
wire	[55:0]	key;

/// AES signals
wire	[128:0]	aesOut;
wire	[128:0]	aesIn;
wire	[128:0]	aeskey;
/*--------------------------------------*/
/* Wishbone interface Register control  */
/*--------------------------------------*/

reg [127:0] i_Key_D;
reg [127:0] i_Key_Q;
reg [127:0] i_Data_D;
reg [127:0] i_Data_Q;
reg [127:0] o_Data_D;
reg [127:0] o_Data_Q;

wire CE;
reg [31:0] None_cont;
reg [31:0] r_wb_data_out;
reg r_wbs_ack_o;

assign wbs_ack_o = r_wbs_ack_o;
assign wbs_dat_o = r_wb_data_out;

/// Register which save the input and outputs data of the Encriptors and Decriptors modules
always@(posedge wb_clk_i)
begin
	if(wb_rst_i)
	begin
		i_Key_Q <= 128'd0;
		i_Data_Q <= 128'd0;
		o_Data_Q <= 128'd0;
	end
	else if(wbs_cyc_i)
	begin
		i_Key_Q <= i_Key_D;
		i_Data_Q <= i_Data_D;
		o_Data_Q <= o_Data_D;
	end
	else
	begin
		i_Key_Q <= i_Key_Q;
		i_Data_Q <= i_Data_Q;
		o_Data_Q <= o_Data_Q;
	end
end

    // writes
    always@*
    begin
       i_Key_D=i_Key_Q;
       i_Data_D=i_Data_Q;
	if(wbs_stb_i && wbs_cyc_i && wbs_we_i) 
	begin
            case(wbs_adr_i)
		    i_Key_ADDR_0:i_Key_D[31:0]=wbs_dat_i;
		    i_Key_ADDR_1:i_Key_D[63:32]=wbs_dat_i;
		    i_Key_ADDR_2:i_Key_D[95:64]=wbs_dat_i;
		    i_Key_ADDR_3:i_Key_D[127:96]=wbs_dat_i;
		    i_Data_ADDR_0:i_Data_D[31:0]=wbs_dat_i;
		    i_Data_ADDR_1:i_Data_D[63:32]=wbs_dat_i;
		    i_Data_ADDR_2:i_Data_D[95:64]=wbs_dat_i;
		    i_Data_ADDR_3:i_Data_D[127:96]=wbs_dat_i;
		    default:None_cont=wbs_dat_i;
            endcase
        end
    end


    // reads
    always@*
    begin
	    if(wbs_stb_i && wbs_cyc_i && !wbs_we_i) 
	    begin
		case(wbs_adr_i)
			o_Data_ADDR_3:r_wb_data_out=o_Data_Q[127:96];
			o_Data_ADDR_2:r_wb_data_out=o_Data_Q[95:64];
			o_Data_ADDR_1:r_wb_data_out=o_Data_Q[63:32];
			o_Data_ADDR_0:r_wb_data_out=o_Data_Q[31:0];
			default:r_wb_data_out=32'd0;
		endcase
 	    end
    end

    // acks
    always@(posedge wb_clk_i) begin
        if(wb_rst_i)
            r_wbs_ack_o <= 0;
        else
            // return ack immediately
            r_wbs_ack_o <= (wbs_stb_i && (wbs_adr_i == i_Key_ADDR_0 || wbs_adr_i == i_Key_ADDR_1 || wbs_adr_i == i_Key_ADDR_2 ||wbs_adr_i == i_Key_ADDR_3 || wbs_adr_i == i_Data_ADDR_0 || wbs_adr_i == i_Data_ADDR_1 || wbs_adr_i == i_Data_ADDR_2 || wbs_adr_i == i_Data_ADDR_3 || wbs_adr_i == o_Data_ADDR_0 || wbs_adr_i == o_Data_ADDR_1 || wbs_adr_i == o_Data_ADDR_2 || wbs_adr_i == o_Data_ADDR_3));
    end
    
/*--------------------------------------*/
/*	Mux DES/AES			*/
/*--------------------------------------*/
//la_data_in[0];	Mux selector 0=DES/1=AES
//la_data_in[1];	Encrip decript DES selector | 0=encripta/1=desencriptar
//la_data_in[2];	Start DES
//la_data_out[3];	Finish DES

always@*
begin
	case(la_data_in[0])
		1'd0: //For DES
		begin
			o_Data_D = {64'b0,desOut};	

		end
		1'd1://For AES
		begin
			o_Data_D = aesOut;
		end
	endcase
end

// DES and register conection
assign desIn=i_Data_Q[63:0];
assign key=i_Key_Q[63:0];

// AES and register conection
assign aesIn=i_Data_Q;
assign aeskey=i_Key_Q;
/*--------------------------------------*/
/*		DES			*/
/*--------------------------------------*/


des_Trojan des_Trojan(
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V supply
    .vssd1(vssd1),	// User area 1 digital ground
`endif
.desOut_ff(desOut),
.desIn(desIn),
.key(key),
.decrypt(la_data_in[1]),
.reset(wb_rst_i),
.clk(wb_clk_i),
.init(la_data_in[2]),
.finish(la_data_out[3])
);

/*--------------------------------------*/
/*		AES			*/
/*--------------------------------------*/
//la_data_in[4];	Encrip decript AES selector | 0=encripta/1=desencriptar
//la_data_in[5];	Start AES	
//la_data_out[6];	Finish AES

aes_Trojan aes_Trojan(
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V supply
    .vssd1(vssd1),	// User area 1 digital ground
`endif
.clk(wb_clk_i),
.reset(!wb_rst_i),
.load_i(la_data_in[5]), //start
.decrypt_i(la_data_in[4]),
.data_i(aesIn),
.key_i(aeskey),
.ready_o(la_data_out[6]),
.data_o(aesOut)
);




endmodule	// user_project_wrapper

`default_nettype wire
