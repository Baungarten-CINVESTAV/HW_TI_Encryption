module top(
    input clk,
    input rst,
    input start,
    input [1:0] mode,
    input [255:0] random_coin,

    input [255:0] m_in,
    input [6399:0]pk_in,// 12*256*2 + 256
    input [6143:0]sk_in,// 12*256*2
    input [6143:0]c_in, // 10*256*2 + 4*256

    output [255:0] m_out,
    output [6399:0]pk_out,// 12*256*2 + 256
    output [6143:0]sk_out,// 12*256*2
    output [6143:0]c_out, // 10*256*2 + 4*256

    output finish
);

//controller
wire ntt_start, ntt_is_add_or_sub;
wire [1:0] ntt_mode;
wire [7:0]  ntt_ram_r_start_offset_A, ntt_ram_r_start_offset_B, ntt_ram_w_start_offset;

wire G_active, G_rst;

wire CBD_rst, CBD_active;
wire [1:0] CBD_num;
wire [7:0] CBD_ram_w_start_offset, CBD_diff;

wire A_gen_rst, A_gen_active;
wire [7:0] A_gen_ram_w_start_offset;
wire [15:0] A_gen_diff;

wire coder_active, coder_load_input_Enc, coder_load_input_Dec;
wire [3:0] coder_mode;

wire CBD_in_sel, rho_sel, ram_r_sel;
wire [1:0] ram_w_sel;

//G
wire [255:0] G_rho, G_sigma;

//A_gen
wire A_wen;
wire [7:0] A_waddr;
wire [95:0] A_wdata;

reg [255:0] rho_temp;

//CBD
wire CBD_wen;
wire [7:0] CBD_waddr;
wire [95:0] CBD_wdata; 

reg [255:0] CBD_input;

//ntt
wire ntt_wen, ntt_last_cycle;
wire [7:0] ntt_raddr, ntt_waddr;
wire [95:0] ntt_wdata;

//coder
wire [255:0] rho_from_pk;
wire coder_wen;
wire [7:0] coder_raddr, coder_waddr;
wire [95:0] coder_wdata;

//ram
wire [95:0] RAM_rdata;

reg wen_temp;
reg [7:0] raddr_temp, waddr_temp;
reg [95:0] wdata_temp;

controller control(
    .clk(clk),
    .rst(rst),
    .start(start),
    .mode(mode),
    .finish(finish),

    .ntt_start(ntt_start),
    .ntt_mode(ntt_mode),
    .ntt_is_add_or_sub(ntt_is_add_or_sub),
    .ntt_ram_r_start_offset_A(ntt_ram_r_start_offset_A),
    .ntt_ram_r_start_offset_B(ntt_ram_r_start_offset_B),
    .ntt_ram_w_start_offset(ntt_ram_w_start_offset),

    .G_active(G_active),
    .G_rst(G_rst),

    .CBD_rst(CBD_rst),
    .CBD_active(CBD_active),
    .CBD_num(CBD_num),
    .CBD_ram_w_start_offset(CBD_ram_w_start_offset),
    .CBD_diff(CBD_diff),

    .A_gen_rst(A_gen_rst),
    .A_gen_active(A_gen_active),
    .A_gen_ram_w_start_offset(A_gen_ram_w_start_offset),
    .A_gen_diff(A_gen_diff),

    .coder_active(coder_active),
    .coder_load_input_Enc(coder_load_input_Enc),
    .coder_load_input_Dec(coder_load_input_Dec),
    .coder_mode(coder_mode),

    .CBD_in_sel(CBD_in_sel),
    .rho_sel(rho_sel),
    .ram_r_sel(ram_r_sel),
    .ram_w_sel(ram_w_sel)
);

SHA3_512 G( .M(random_coin),
            .active(G_active),
            .clk(clk),.rst(G_rst),
            .Z({G_rho,G_sigma}));


A_generator A_gen(  .M({rho_temp,A_gen_diff}),
                    .ram_w_start_offset(A_gen_ram_w_start_offset), 
                    .clk(clk),.rst(A_gen_rst), .active(A_gen_active),
                    .enw(A_wen),
                    .waddr(A_waddr),
                    .dout(A_wdata));

                    
small_poly_generator CBD(   .M({CBD_input,CBD_diff}), 
                            .ram_w_start_offset(CBD_ram_w_start_offset),
                            .n_num(CBD_num), 
                            .clk(clk),.rst(CBD_rst), .active(CBD_active),
                            .enw(CBD_wen),
                            .waddr(CBD_waddr),
                            .dout(CBD_wdata)); 


ntt_processer ntt(
    .clk(clk),
    .rst(rst),
    .start(ntt_start),
    .mode(ntt_mode),
    .is_add_or_sub(ntt_is_add_or_sub),
    .ram_r_start_offset_A(ntt_ram_r_start_offset_A),
    .ram_r_start_offset_B(ntt_ram_r_start_offset_B),
    .ram_w_start_offset(ntt_ram_w_start_offset),
    .ram_rdata(RAM_rdata),
    .last_cycle(ntt_last_cycle),
    .ram_wen(ntt_wen),
    .ram_raddr(ntt_raddr),
    .ram_waddr(ntt_waddr),
    .ram_wdata(ntt_wdata)
);

coder code(
    .clk(clk),
    .rst(rst),
    .active(coder_active),
    .load_input_Enc(coder_load_input_Enc),
    .load_input_Dec(coder_load_input_Dec),
    .mode(coder_mode), 
   
    .pk_in(pk_in), 
    .m_in(m_in), 
    .sk_in(sk_in),
    .c_in(c_in), 
    
    .pk_out(pk_out), 
    .m_out(m_out), 
    .sk_out(sk_out), 
    .c_out(c_out), 

    .rho_from_G(G_rho),
    .rho_from_pk(rho_from_pk),
    .ram_wen(coder_wen),
    .ram_raddr(coder_raddr),
    .ram_waddr(coder_waddr), 
    .ram_rdata(RAM_rdata),
    .ram_wdata(coder_wdata)

);

ram_96x256 ram(
    .clk(clk),
    .rst(rst),
    .wen(wen_temp),
    .raddr(raddr_temp),
    .waddr(waddr_temp),
    .din(wdata_temp),
    .dout(RAM_rdata)
);

always@(*)begin
    case(rho_sel)
        1'b0:begin
            rho_temp = G_rho;
        end
        1'b1:begin
            rho_temp = rho_from_pk;
        end
    endcase

    case(CBD_in_sel)
        1'b0:begin
            CBD_input = G_sigma;
        end
        1'b1:begin
            CBD_input = random_coin;
        end
    endcase

    case(ram_r_sel)
        1'b0:begin
            raddr_temp = coder_raddr;
        end
        1'b1:begin
            raddr_temp = ntt_raddr;
        end
    endcase

    case(ram_w_sel)
        2'd0:begin
            wen_temp = coder_wen;
            waddr_temp = coder_waddr;
            wdata_temp = coder_wdata;
        end
        2'd1:begin
            wen_temp = ntt_wen;
            waddr_temp = ntt_waddr;
            wdata_temp = ntt_wdata;
        end
        2'd2:begin
            wen_temp = A_wen;
            waddr_temp = A_waddr;
            wdata_temp = A_wdata;
        end
        2'd3:begin
            wen_temp = CBD_wen;
            waddr_temp = CBD_waddr;
            wdata_temp = CBD_wdata;        
        end
    endcase
end


endmodule


//////////////////////////////////////////////////////////////

module ram_96x256 (
    input clk,
    input rst,
    input wen,
    input [7:0] raddr,
    input [7:0] waddr,
    input [95:0] din,
    output reg [95:0] dout
);

reg [95:0] data [0:255];

always @(*) begin
    dout = data[raddr];
end

integer i;
always@(posedge clk) begin
    if(rst) begin
        for(i=0; i<256; i=i+1) data[i] <= 0;
    end
    else begin
        if(wen) data[waddr] <= din;
    end
end

endmodule

//////////////////////////////////////////////

module controller (
    input clk,
    input rst,
    input start,
    input [1:0] mode, // 0:KeyGen, 1:Enc, 2:Dec
    output finish,
    
    output reg ntt_start,
    output reg [1:0] ntt_mode,
    output reg ntt_is_add_or_sub,
    output reg [7:0] ntt_ram_r_start_offset_A,
    output reg [7:0] ntt_ram_r_start_offset_B,
    output reg [7:0] ntt_ram_w_start_offset,

    output G_active,
    output G_rst,

    output reg CBD_rst, 
    output reg CBD_active,
    output reg [1:0] CBD_num, //1 => n1; 2 => n2
    output reg [7:0] CBD_ram_w_start_offset,
    output reg [7:0] CBD_diff,
    
    output reg A_gen_rst, 
    output reg A_gen_active,
    output reg [7:0] A_gen_ram_w_start_offset,
    output reg [15:0] A_gen_diff,
    
    output reg coder_active,
    output reg coder_load_input_Enc,
    output reg coder_load_input_Dec,
    output reg [3:0] coder_mode, 

    output CBD_in_sel, // 0:from G, 1:from random coin
    output rho_sel, // 0:from G, 1:from pk
    output reg ram_r_sel, // 0:from coder, 1:from ntt
    output reg [1:0] ram_w_sel // 0:from coder, 1:from ntt, 2:from A_gen, 3:from CBD
);

reg [1:0] state_reg;
reg [11:0] cycle_cnt, ncnt;
reg [1:0] A_gen_state;
reg [2:0] CBD_state;
reg [4:0] ntt_state;
reg [1:0] coder_state;

// mode define
parameter KeyGen = 2'd0;
parameter Enc = 2'd1;
parameter Dec = 2'd2;
parameter FINISH = 2'd3;

// A_gen_state define
parameter A_gen_st_A00 = 2'd0;
parameter A_gen_st_A01 = 2'd1;
parameter A_gen_st_A10 = 2'd2;
parameter A_gen_st_A11 = 2'd3;

// CBD_state define
parameter CBD_st_s0 = 3'd0; // KeyGen
parameter CBD_st_s1 = 3'd1; // KeyGen
parameter CBD_st_e0 = 3'd2; // KeyGen
parameter CBD_st_e1 = 3'd3; // KeyGen
parameter CBD_st_r0 = 3'd0; // Enc
parameter CBD_st_r1 = 3'd1; // Enc
parameter CBD_st_e10 = 3'd2; // Enc
parameter CBD_st_e11 = 3'd3; // Enc
parameter CBD_st_e2 = 3'd4; // Enc

// coder_state define
parameter coder_st_encode_pk = 2'd0; // KeyGen
parameter coder_st_encode_sk = 2'd1; // KeyGen
parameter coder_st_decode_pk = 2'd0; // Enc
parameter coder_st_decode_m = 2'd1; // Enc
parameter coder_st_encode_c = 2'd2; // Enc
parameter coder_st_decode_c = 2'd0; // Dec
parameter coder_st_decode_sk = 2'd1; // Dec
parameter coder_st_encode_m = 2'd2; // Dec

// ntt_state define
parameter NTT_st_NTT_s0        = 5'd0; // KeyGen
parameter NTT_st_NTT_s1        = 5'd1; // KeyGen
parameter NTT_st_MUL_A00_s0    = 5'd2; // KeyGen
parameter NTT_st_MUL_A01_s1    = 5'd3; // KeyGen
parameter NTT_st_NTT_e0        = 5'd4; // KeyGen
parameter NTT_st_ADD_t0        = 5'd5; // KeyGen
parameter NTT_st_ADD_e0        = 5'd6; // KeyGen
parameter NTT_st_MUL_A10_s0    = 5'd7; // KeyGen
parameter NTT_st_MUL_A11_s1    = 5'd8; // KeyGen
parameter NTT_st_NTT_e1        = 5'd9; // KeyGen
parameter NTT_st_ADD_t1        = 5'd10; // KeyGen
parameter NTT_st_ADD_e1        = 5'd11; // KeyGen

parameter NTT_st_NTT_r0        = 5'd0; // Enc
parameter NTT_st_NTT_r1        = 5'd1; // Enc
parameter NTT_st_MUL_A00_r0    = 5'd2; // Enc
parameter NTT_st_MUL_A10_r1    = 5'd3; // Enc
parameter NTT_st_ADD_u0        = 5'd4; // Enc
parameter NTT_st_INVNTT_u0     = 5'd5; // Enc
parameter NTT_st_ADD_e10       = 5'd6; // Enc
parameter NTT_st_MUL_A01_r0    = 5'd7; // Enc
parameter NTT_st_MUL_A11_r1    = 5'd8; // Enc
parameter NTT_st_ADD_u1        = 5'd9; // Enc
parameter NTT_st_INVNTT_u1     = 5'd10; // Enc
parameter NTT_st_ADD_e11       = 5'd11; // Enc
parameter NTT_st_MUL_t0_r0     = 5'd12; // Enc
parameter NTT_st_MUL_t1_r1     = 5'd13; // Enc
parameter NTT_st_ADD_v         = 5'd14; // Enc
parameter NTT_st_INVNTT_v      = 5'd15; // Enc
parameter NTT_st_ADD_e2        = 5'd16; // Enc
parameter NTT_st_ADD_m         = 5'd17; // Enc

parameter NTT_st_NTT_u0        = 5'd0; // Dec
parameter NTT_st_NTT_u1        = 5'd1; // Dec
parameter NTT_st_MUL_s0_u0     = 5'd2; // Dec
parameter NTT_st_MUL_s1_u1     = 5'd3; // Dec
parameter NTT_st_ADD_su        = 5'd4; // Dec
parameter NTT_st_INVNTT_su     = 5'd5; // Dec
parameter NTT_st_SUB_v_su      = 5'd6; // Dec

// ram offset define
parameter ram_0_offset = 8'd0;
parameter ram_1_offset = 8'd32;
parameter ram_2_offset = 8'd64;
parameter ram_3_offset = 8'd96;
parameter ram_4_offset = 8'd128;
parameter ram_5_offset = 8'd160;
parameter ram_6_offset = 8'd192;
parameter ram_7_offset = 8'd224;

// coder mode define
parameter coder_mode_KeyGen_encode_sk = 4'd1;
parameter coder_mode_KeyGen_encode_pk = 4'd2;
parameter coder_mode_Enc_decode_pk = 4'd3;
parameter coder_mode_Enc_decode_m = 4'd4;
parameter coder_mode_Enc_encode_c = 4'd5;
parameter coder_mode_Dec_decode_sk = 4'd6;
parameter coder_mode_Dec_decode_c = 4'd7;
parameter coder_mode_Dec_encode_m = 4'd8;

// ram_w_sel define
parameter ram_w_from_coder = 2'd0;
parameter ram_w_from_ntt = 2'd1;
parameter ram_w_from_A_gen = 2'd2;
parameter ram_w_from_CBD = 2'd3;

// cycle_cnt logic
always @(posedge clk or posedge rst) begin
    if(rst) begin
        state_reg <= FINISH;
        cycle_cnt <= 12'd0;
    end
    else begin
        cycle_cnt <= ncnt;
        if (state_reg == FINISH && start) state_reg <= mode;
        else if ( (state_reg == KeyGen && cycle_cnt == 12'd2001) || 
                  (state_reg == Enc && cycle_cnt == 12'd2654)    || 
                  (state_reg == Dec && cycle_cnt == 12'd1174)    ) state_reg <= FINISH;
    end
end
always @(*) begin
    ncnt = state_reg == FINISH ? 12'd0 : cycle_cnt + 12'd1;
end

// ntt logic
always @(*) begin
    case(cycle_cnt)
    12'd119, 12'd349, 12'd579, 12'd719,
    12'd859, 12'd1089, 12'd1157, 12'd1225,
    12'd1365, 12'd1505, 12'd1735, 12'd1803 : ntt_start = state_reg == KeyGen;
    12'd90, 12'd320, 12'd550, 12'd690,
    12'd830, 12'd898, 12'd1128, 12'd1196,
    12'd1336, 12'd1476, 12'd1544, 12'd1774,
    12'd1842, 12'd1982, 12'd2122, 12'd2190,
    12'd2420, 12'd2488 : ntt_start = state_reg == Enc;
    12'd34, 12'd264, 12'd494, 12'd634,
    12'd774, 12'd842, 12'd1072 : ntt_start = state_reg == Dec;
    default : ntt_start = 1'b0;
    endcase
end
always @(posedge clk or posedge rst) begin
    if(rst) CBD_state <= 5'd0;
    else begin
        case(state_reg)
        KeyGen: begin
        case(cycle_cnt)
        12'd0: ntt_state <= NTT_st_NTT_s0;
        12'd348: ntt_state <= NTT_st_NTT_s1;
        12'd578: ntt_state <= NTT_st_MUL_A00_s0;
        12'd718: ntt_state <= NTT_st_MUL_A01_s1;
        12'd858: ntt_state <= NTT_st_NTT_e0;
        12'd1088: ntt_state <= NTT_st_ADD_t0;
        12'd1156: ntt_state <= NTT_st_ADD_e0;
        12'd1224: ntt_state <= NTT_st_MUL_A10_s0;
        12'd1364: ntt_state <= NTT_st_MUL_A11_s1;
        12'd1504: ntt_state <= NTT_st_NTT_e1;
        12'd1734: ntt_state <= NTT_st_ADD_t1;
        12'd1802: ntt_state <= NTT_st_ADD_e1;
        endcase
        end
        Enc: begin
        case(cycle_cnt)
        12'd0: ntt_state <= NTT_st_NTT_r0;
        12'd319: ntt_state <= NTT_st_NTT_r1;
        12'd549: ntt_state <= NTT_st_MUL_A00_r0;
        12'd689: ntt_state <= NTT_st_MUL_A10_r1;
        12'd829: ntt_state <= NTT_st_ADD_u0;
        12'd897: ntt_state <= NTT_st_INVNTT_u0;
        12'd1127: ntt_state <= NTT_st_ADD_e10;
        12'd1195: ntt_state <= NTT_st_MUL_A01_r0;
        12'd1335: ntt_state <= NTT_st_MUL_A11_r1;
        12'd1475: ntt_state <= NTT_st_ADD_u1;
        12'd1543: ntt_state <= NTT_st_INVNTT_u1;
        12'd1773: ntt_state <= NTT_st_ADD_e11;
        12'd1841: ntt_state <= NTT_st_MUL_t0_r0;
        12'd1981: ntt_state <= NTT_st_MUL_t1_r1;
        12'd2121: ntt_state <= NTT_st_ADD_v;
        12'd2189: ntt_state <= NTT_st_INVNTT_v;
        12'd2419: ntt_state <= NTT_st_ADD_e2;
        12'd2487: ntt_state <= NTT_st_ADD_m;
        endcase
        end
        Dec: begin
        case(cycle_cnt)
        12'd0: ntt_state <= NTT_st_NTT_u0;
        12'd263: ntt_state <= NTT_st_NTT_u1;
        12'd493: ntt_state <= NTT_st_MUL_s0_u0;
        12'd633: ntt_state <= NTT_st_MUL_s1_u1;
        12'd773: ntt_state <= NTT_st_ADD_su;
        12'd841: ntt_state <= NTT_st_INVNTT_su;
        12'd1071: ntt_state <= NTT_st_SUB_v_su;
        endcase
        end
        default: ntt_state <= 5'd0;
        endcase
    end
end
always @(*) begin
    case(state_reg)
    KeyGen: begin
        ntt_is_add_or_sub = 1'b0;
        case(ntt_state)
        NTT_st_NTT_s0: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_4_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_4_offset;
        end
        NTT_st_NTT_s1: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_5_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_5_offset;
        end
        NTT_st_MUL_A00_s0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_MUL_A01_s1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_1_offset;
        end
        NTT_st_NTT_e0: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_6_offset;
            ntt_ram_r_start_offset_B = ram_6_offset;
            ntt_ram_w_start_offset = ram_6_offset;
        end
        NTT_st_ADD_t0: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_1_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_ADD_e0: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_6_offset;
            ntt_ram_w_start_offset = ram_6_offset;
        end
        NTT_st_MUL_A10_s0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_2_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_2_offset;
        end
        NTT_st_MUL_A11_s1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_3_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_3_offset;
        end
        NTT_st_NTT_e1: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_7_offset;
            ntt_ram_r_start_offset_B = ram_7_offset;
            ntt_ram_w_start_offset = ram_7_offset;
        end
        NTT_st_ADD_t1: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_2_offset;
            ntt_ram_r_start_offset_B = ram_3_offset;
            ntt_ram_w_start_offset = ram_2_offset;
        end
        NTT_st_ADD_e1: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_2_offset;
            ntt_ram_r_start_offset_B = ram_7_offset;
            ntt_ram_w_start_offset = ram_7_offset;
        end
        default: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        endcase
    end
    Enc: begin
        ntt_is_add_or_sub = 1'b0;
        case(ntt_state)
        NTT_st_NTT_r0: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_4_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_4_offset;
        end
        NTT_st_NTT_r1: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_5_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_5_offset;
        end
        NTT_st_MUL_A00_r0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_MUL_A10_r1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_2_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_2_offset;
        end
        NTT_st_ADD_u0: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_2_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_INVNTT_u0: begin
            ntt_mode = 2'd1;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_ADD_e10: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_6_offset;
            ntt_ram_w_start_offset = ram_6_offset;
        end
        NTT_st_MUL_A01_r0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_1_offset;
        end
        NTT_st_MUL_A11_r1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_3_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_3_offset;
        end
        NTT_st_ADD_u1: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_3_offset;
            ntt_ram_w_start_offset = ram_3_offset;
        end
        NTT_st_INVNTT_u1: begin
            ntt_mode = 2'd1;
            ntt_ram_r_start_offset_A = ram_3_offset;
            ntt_ram_r_start_offset_B = ram_3_offset;
            ntt_ram_w_start_offset = ram_3_offset;
        end
        NTT_st_ADD_e11: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_3_offset;
            ntt_ram_r_start_offset_B = ram_7_offset;
            ntt_ram_w_start_offset = ram_7_offset;
        end
        NTT_st_MUL_t0_r0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_MUL_t1_r1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_1_offset;
        end
        NTT_st_ADD_v: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_1_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_INVNTT_v: begin
            ntt_mode = 2'd1;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_ADD_e2: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_2_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_ADD_m: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_3_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        default: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        endcase
    end
    Dec: begin
        ntt_is_add_or_sub = 1'b0;
        case(ntt_state)
        NTT_st_NTT_u0: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_NTT_u1: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_1_offset;
            ntt_ram_w_start_offset = ram_1_offset;
        end
        NTT_st_MUL_s0_u0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_3_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_MUL_s1_u1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_1_offset;
        end
        NTT_st_ADD_su: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_1_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_INVNTT_su: begin
            ntt_mode = 2'd1;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_SUB_v_su: begin
            ntt_is_add_or_sub = 1'b1;
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_2_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        default: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        endcase
    end
    default: begin
        ntt_is_add_or_sub = 1'b0;
        ntt_mode = 2'd0;
        ntt_ram_r_start_offset_A = ram_0_offset;
        ntt_ram_r_start_offset_B = ram_0_offset;
        ntt_ram_w_start_offset = ram_0_offset;
    end
    endcase
end

// G logic
assign G_active = state_reg == KeyGen && cycle_cnt == 12'd0;
assign G_rst = rst || state_reg == FINISH;

// CBD logic
always @(*) begin
    if(rst) CBD_rst = 1'b1;
    else begin
        case(state_reg)
        KeyGen: begin
            if(cycle_cnt == 12'd119 || cycle_cnt == 12'd578 || cycle_cnt == 12'd718 || cycle_cnt == 12'd809) CBD_rst = 1'b1;
            else CBD_rst = 1'b0;
        end
        Enc: begin
            if(cycle_cnt == 12'd90 || cycle_cnt == 12'd360 || cycle_cnt == 12'd549 || cycle_cnt == 12'd897 || cycle_cnt == 12'd960) CBD_rst = 1'b1;
            else CBD_rst = 1'b0;
        end
        default: CBD_rst = 1'b1;
        endcase
    end
end
always @(*) begin
    case(state_reg)
    KeyGen: begin
        CBD_active = cycle_cnt == 12'd29 || cycle_cnt == 12'd120 || cycle_cnt == 12'd579 || cycle_cnt == 12'd719;
    end
    Enc: begin
        CBD_active = cycle_cnt == 12'd0 || cycle_cnt == 12'd91 || cycle_cnt == 12'd361 || cycle_cnt == 12'd550 || cycle_cnt == 12'd898;
    end
    default: CBD_active = 1'b0;
    endcase
end
always @(posedge clk or posedge rst) begin
    if(rst) CBD_state <= 3'd0;
    else begin
        case(state_reg)
        KeyGen: begin
            if(cycle_cnt == 12'd0) CBD_state <= CBD_st_s0;
            else if(cycle_cnt == 12'd119) CBD_state <= CBD_st_s1;
            else if(cycle_cnt == 12'd578) CBD_state <= CBD_st_e0;
            else if(cycle_cnt == 12'd718) CBD_state <= CBD_st_e1;
            else if(cycle_cnt == 12'd809) CBD_state <= 3'd0;
        end
        Enc: begin
            if(cycle_cnt == 12'd0) CBD_state <= CBD_st_r0;
            else if(cycle_cnt == 12'd90) CBD_state <= CBD_st_r1;
            else if(cycle_cnt == 12'd360) CBD_state <= CBD_st_e10;
            else if(cycle_cnt == 12'd549) CBD_state <= CBD_st_e11;
            else if(cycle_cnt == 12'd897) CBD_state <= CBD_st_e2;
            else if(cycle_cnt == 12'd960) CBD_state <= CBD_st_r0;
        end
        default: CBD_state <= 3'd0;
        endcase
    end
end
always @(*) begin
    case(state_reg)
    KeyGen: begin
        CBD_num = 2'd1;
        case(CBD_state)       
        CBD_st_s0 : begin
            CBD_ram_w_start_offset = ram_4_offset;
            CBD_diff = 8'd0;
        end
        CBD_st_s1 : begin
            CBD_ram_w_start_offset = ram_5_offset;
            CBD_diff = 8'd1;            
        end
        CBD_st_e0 : begin
            CBD_ram_w_start_offset = ram_6_offset;
            CBD_diff = 8'd2;
        end
        CBD_st_e1 : begin
            CBD_ram_w_start_offset = ram_7_offset;
            CBD_diff = 8'd3;
        end
        default: begin
            CBD_ram_w_start_offset = 8'd0;
            CBD_diff = 8'd0;
        end
        endcase
    end
    Enc: begin
        case(CBD_state)     
        CBD_st_r0: begin
            CBD_num = 2'd1;
            CBD_ram_w_start_offset = ram_4_offset;
            CBD_diff = 8'd0;
        end
        CBD_st_r1: begin
            CBD_num = 2'd1;
            CBD_ram_w_start_offset = ram_5_offset;
            CBD_diff = 8'd1;
        end
        CBD_st_e10: begin
            CBD_num = 2'd2;
            CBD_ram_w_start_offset = ram_6_offset;
            CBD_diff = 8'd2;
        end
        CBD_st_e11: begin
            CBD_num = 2'd2;
            CBD_ram_w_start_offset = ram_7_offset;
            CBD_diff = 8'd3;
        end
        CBD_st_e2: begin
            CBD_num = 2'd2;
            CBD_ram_w_start_offset = ram_2_offset;
            CBD_diff = 8'd4;
        end
        default: begin
            CBD_num = 2'd1;
            CBD_ram_w_start_offset = 8'd0;
            CBD_diff = 8'd0;
        end
        endcase
    end
    default: begin
        CBD_num = 2'd1;
        CBD_ram_w_start_offset = 8'd0;
        CBD_diff = 8'd0;
    end
    endcase
end

// A_gen logic
always @(*) begin
    if(rst) A_gen_rst = 1'b1;
    else begin
        case(state_reg)
        KeyGen: begin
            if(cycle_cnt == 12'd151 || cycle_cnt == 12'd348 || cycle_cnt == 12'd492 || cycle_cnt == 12'd611) A_gen_rst = 1'b1;
            else A_gen_rst = 1'b0;
        end
        Enc: begin
            if(cycle_cnt == 12'd122 || cycle_cnt == 12'd241 || cycle_cnt == 12'd360 || cycle_cnt == 12'd479) A_gen_rst = 1'b1;
            else A_gen_rst = 1'b0;
        end
        default: A_gen_rst = 1'b1;
        endcase
    end
end
always @(*) begin
    case(state_reg)
    KeyGen: begin
        A_gen_active = cycle_cnt == 12'd33 || cycle_cnt == 12'd152 || cycle_cnt == 12'd349 || cycle_cnt == 12'd493;
    end
    Enc: begin
        A_gen_active = cycle_cnt == 12'd4 || cycle_cnt == 12'd123 || cycle_cnt == 12'd242 || cycle_cnt == 12'd361;
    end
    default: A_gen_active = 1'b0;
    endcase
end
always @(posedge clk or posedge rst) begin
    if(rst) A_gen_state <= A_gen_st_A00;
    else begin
        case(state_reg)
        KeyGen: begin
            if(cycle_cnt == 12'd0) A_gen_state <= A_gen_st_A00;
            else if(cycle_cnt == 12'd151) A_gen_state <= A_gen_st_A01;
            else if(cycle_cnt == 12'd348) A_gen_state <= A_gen_st_A10;
            else if(cycle_cnt == 12'd492) A_gen_state <= A_gen_st_A11;
        end
        Enc: begin
            if(cycle_cnt == 12'd0) A_gen_state <= A_gen_st_A00;
            else if(cycle_cnt == 12'd122) A_gen_state <= A_gen_st_A01;
            else if(cycle_cnt == 12'd241) A_gen_state <= A_gen_st_A10;
            else if(cycle_cnt == 12'd360) A_gen_state <= A_gen_st_A11;
        end
        default: A_gen_state <= A_gen_st_A00;
        endcase
    end
end
always @(*) begin
    case(A_gen_state)
    A_gen_st_A00: begin
        A_gen_ram_w_start_offset = ram_0_offset;
        A_gen_diff = { 8'd0, 8'd0 };
    end
    A_gen_st_A01: begin
        A_gen_ram_w_start_offset = ram_1_offset;
        A_gen_diff = { 8'd0, 8'd1 };
    end
    A_gen_st_A10: begin
        A_gen_ram_w_start_offset = ram_2_offset;
        A_gen_diff = { 8'd1, 8'd0 };
    end
    A_gen_st_A11: begin
        A_gen_ram_w_start_offset = ram_3_offset;
        A_gen_diff = { 8'd1, 8'd1 };
    end
    endcase
end

// coder logic
always @(*) begin
    coder_load_input_Dec = 1'b0;
    coder_load_input_Enc = 1'b0;
    case(state_reg)
    KeyGen: begin
        coder_active = cycle_cnt == 12'd1871 || cycle_cnt == 12'd1936;
    end
    Enc: begin
        coder_load_input_Enc = cycle_cnt == 12'd0;
        coder_active = cycle_cnt == 12'd1544 || cycle_cnt == 12'd1842 || cycle_cnt == 12'd2556;
    end
    Dec: begin
        coder_load_input_Dec = cycle_cnt == 12'd0;
        coder_active = cycle_cnt == 12'd0 || cycle_cnt == 12'd98 || cycle_cnt == 12'd1140;
    end
    default: coder_active = 1'b0;
    endcase
end
always @(posedge clk or posedge rst) begin
    if(rst) coder_state <= 2'd0;
    else begin
        case(state_reg)
        KeyGen: begin
            if(cycle_cnt == 12'd0) coder_state <= coder_st_encode_pk;
            else if(cycle_cnt == 12'd1935) coder_state <= coder_st_encode_sk;
        end
        Enc: begin
            if(cycle_cnt == 12'd0) coder_state <= coder_st_decode_pk;
            else if(cycle_cnt == 12'd1841) coder_state <= coder_st_decode_m;
            else if(cycle_cnt == 12'd2555) coder_state <= coder_st_encode_c;
        end
        Dec: begin
            if(cycle_cnt == 12'd0) coder_state <= coder_st_decode_c;
            else if(cycle_cnt == 12'd97) coder_state <= coder_st_decode_sk;
            else if(cycle_cnt == 12'd1139) coder_state <= coder_st_encode_m;
        end
        default: coder_state <= 2'd0;
        endcase
    end
end
always @(*) begin
    case(state_reg)
    KeyGen: begin
        case(coder_state)
        coder_st_encode_pk: coder_mode = coder_mode_KeyGen_encode_pk;
        coder_st_encode_sk: coder_mode = coder_mode_KeyGen_encode_sk;
        default: coder_mode = 4'd0;
        endcase
    end
    Enc: begin
        case(coder_state)
        coder_st_decode_pk: coder_mode = coder_mode_Enc_decode_pk;
        coder_st_decode_m: coder_mode = coder_mode_Enc_decode_m;
        coder_st_encode_c: coder_mode = coder_mode_Enc_encode_c;
        default: coder_mode = 4'd0;
        endcase
    end
    Dec: begin
        case(coder_state)
        coder_st_decode_c: coder_mode = coder_mode_Dec_decode_c;
        coder_st_decode_sk: coder_mode = coder_mode_Dec_decode_sk;
        coder_st_encode_m: coder_mode = coder_mode_Dec_encode_m;
        default: coder_mode = 4'd0;
        endcase
    end
    default: coder_mode = 4'd0;
    endcase
end

// multiplexer sel logic
assign CBD_in_sel = state_reg != KeyGen;
assign rho_sel = state_reg != KeyGen;

always @(*) begin
    case(state_reg)
    KeyGen: ram_r_sel = cycle_cnt < 12'd1871;
    Enc: ram_r_sel = cycle_cnt < 12'd2556;
    Dec: ram_r_sel = cycle_cnt < 12'd1140;
    default: ram_r_sel = 1'b0;
    endcase
end

always @(*) begin
    case(state_reg)
    KeyGen: begin
        if(cycle_cnt < 12'd119) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd151) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd210) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd270) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd349) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd467) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd579) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd611) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd669) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd719) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd809) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd1871) ram_w_sel = ram_w_from_ntt;
        else ram_w_sel = ram_w_from_coder;
    end
    Enc: begin
        if(cycle_cnt < 12'd90) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd122) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd181) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd241) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd320) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd360) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd423) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd479) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd550) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd612) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd898) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd960) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd1544) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd1609) ram_w_sel = ram_w_from_coder;
        else if(cycle_cnt < 12'd1842) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd1876) ram_w_sel = ram_w_from_coder;
        else if(cycle_cnt < 12'd2556) ram_w_sel = ram_w_from_ntt;
        else ram_w_sel = ram_w_from_coder;
    end
    Dec: begin
        if(cycle_cnt < 12'd163) ram_w_sel = ram_w_from_coder;
        else if(cycle_cnt < 12'd1140) ram_w_sel = ram_w_from_ntt;
        else ram_w_sel = ram_w_from_coder;
    end
    default: ram_w_sel = 1'b0;
    endcase
end

assign finish = state_reg == FINISH;
   
endmodule

//////////////////////////////////////////////////////

module decompress (
    input clk,
    input rst,
    input [3:0] d,     
    input [7:0] in_data_d1,
    input [31:0] in_data_d4,
    input [79:0] in_data_d10,
    output [95:0] out_data
);

// input reg
integer i;
reg [11:0] in_reg [0:7];
reg [21:0] mul_out [0:7];
reg [3:0] d_reg;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        for(i=0; i<8; i=i+1) in_reg[i] <= 12'd0;
        d_reg <= 0;
    end
    else begin
        d_reg <= d;
        if(d == 4'd1) begin
            in_reg[0] <= in_data_d1[0];
            in_reg[1] <= in_data_d1[1];
            in_reg[2] <= in_data_d1[2];
            in_reg[3] <= in_data_d1[3];
            in_reg[4] <= in_data_d1[4];
            in_reg[5] <= in_data_d1[5];
            in_reg[6] <= in_data_d1[6];
            in_reg[7] <= in_data_d1[7];
        end
        else if(d == 4'd4) begin
            in_reg[0] <= in_data_d4[03:00];
            in_reg[1] <= in_data_d4[07:04];
            in_reg[2] <= in_data_d4[11:08];
            in_reg[3] <= in_data_d4[15:12];
            in_reg[4] <= in_data_d4[19:16];
            in_reg[5] <= in_data_d4[23:20];
            in_reg[6] <= in_data_d4[27:24];
            in_reg[7] <= in_data_d4[31:28];
        end
        else begin // d == 10
            in_reg[0] <= in_data_d10[09:00];
            in_reg[1] <= in_data_d10[19:10];
            in_reg[2] <= in_data_d10[29:20];
            in_reg[3] <= in_data_d10[39:30];
            in_reg[4] <= in_data_d10[49:40];
            in_reg[5] <= in_data_d10[59:50];
            in_reg[6] <= in_data_d10[69:60];
            in_reg[7] <= in_data_d10[79:70];
        end
    end
end

always @(*) begin
    for(i=0; i<8; i=i+1) mul_out[i] = (in_reg[i] * 12'd3329) >> d_reg;
end

assign out_data = {  mul_out[7][11:0], mul_out[6][11:0], mul_out[5][11:0], mul_out[4][11:0], 
                     mul_out[3][11:0], mul_out[2][11:0], mul_out[1][11:0], mul_out[0][11:0] } ;

endmodule
////////////////////////////////////////////////////

module compress (
    input clk,
    input rst,
    input [3:0] d,     
    input [95:0] in_data,
    output [7:0] out_data_d1,
    output [31:0] out_data_d4,
    output [79:0] out_data_d10
);

// input reg
integer i;
reg [11:0] in_reg [0:7];
reg [23:0] mul_out [0:7];

always @(posedge clk or posedge rst) begin
    if(rst) for(i=0; i<8; i=i+1) in_reg[i] <= 12'd0;
    else begin
        in_reg[0] <= in_data[11:00];
        in_reg[1] <= in_data[23:12];
        in_reg[2] <= in_data[35:24];
        in_reg[3] <= in_data[47:36];
        in_reg[4] <= in_data[59:48];
        in_reg[5] <= in_data[71:60];
        in_reg[6] <= in_data[83:72];
        in_reg[7] <= in_data[95:84];
    end
end

always @(*) begin
    for(i=0; i<8; i=i+1) mul_out[i] = in_reg[i] * 12'd2519; // 2519 = (2<<22)/3329 = (16<<19)/3329 = (1024<<13)/3329
end

//assign out_data_d1 = {  mul_out[7][22], mul_out[6][22], mul_out[5][22], mul_out[4][22], 
//                        mul_out[3][22], mul_out[2][22], mul_out[1][22], mul_out[0][22] } ; // mul_out >> 22
//
assign out_data_d1[7] = in_reg[7] > 12'd832 && in_reg[7] < 12'd2496;
assign out_data_d1[6] = in_reg[6] > 12'd832 && in_reg[6] < 12'd2496;
assign out_data_d1[5] = in_reg[5] > 12'd832 && in_reg[5] < 12'd2496;
assign out_data_d1[4] = in_reg[4] > 12'd832 && in_reg[4] < 12'd2496;
assign out_data_d1[3] = in_reg[3] > 12'd832 && in_reg[3] < 12'd2496;
assign out_data_d1[2] = in_reg[2] > 12'd832 && in_reg[2] < 12'd2496;
assign out_data_d1[1] = in_reg[1] > 12'd832 && in_reg[1] < 12'd2496;
assign out_data_d1[0] = in_reg[0] > 12'd832 && in_reg[0] < 12'd2496;

assign out_data_d4 = {  mul_out[7][22:19], mul_out[6][22:19], mul_out[5][22:19], mul_out[4][22:19], 
                        mul_out[3][22:19], mul_out[2][22:19], mul_out[1][22:19], mul_out[0][22:19] } ; // mul_out >> 19

assign out_data_d10 = { mul_out[7][22:13], mul_out[6][22:13], mul_out[5][22:13], mul_out[4][22:13], 
                        mul_out[3][22:13], mul_out[2][22:13], mul_out[1][22:13], mul_out[0][22:13] } ; // mul_out >> 13

endmodule

/////////////////////////////////////////////////

module coder (
    input clk,
    input rst,
    input active,
    input load_input_Enc,
    input load_input_Dec,
    input [3:0] mode, 
   
    input [6399:0] pk_in, // 12*256*2 + 256
    input [255:0] m_in, 
    input [6143:0] sk_in, // 12*256*2
    input [6143:0] c_in, // 10*256*2 + 4*256
    
    output [6399:0] pk_out, // 12*256*2 + 256
    output [255:0] m_out, 
    output [6143:0] sk_out, // 12*256*2
    output [6143:0] c_out, // 10*256*2 + 4*256

    input [255:0] rho_from_G,
    output [255:0] rho_from_pk,
    output reg ram_wen,
    output reg [7:0] ram_raddr,
    output reg [7:0] ram_waddr, 
    input [95:0] ram_rdata,
    output reg [95:0] ram_wdata

);

// ram offset
parameter ram_0_offset = 8'd0;
parameter ram_1_offset = 8'd32;
parameter ram_2_offset = 8'd64;
parameter ram_3_offset = 8'd96;
parameter ram_4_offset = 8'd128;
parameter ram_5_offset = 8'd160;
parameter ram_6_offset = 8'd192;
parameter ram_7_offset = 8'd224;

// mode define
parameter WAIT = 4'd0;
parameter KeyGen_encode_sk = 4'd1; // 65 cycle (active 1 + working 64)
parameter KeyGen_encode_pk = 4'd2; // 65 cycle (active 1 + working 64)
parameter Enc_decode_pk = 4'd3; // 65 cycle (active 1 + working 64)
parameter Enc_decode_m = 4'd4; // 34 cycle (active 1 + working 33)
parameter Enc_encode_c = 4'd5; // 98 cycle (active 1 + working 97)
parameter Dec_decode_sk = 4'd6; // 65 cycle (active 1 + working 64)
parameter Dec_decode_c = 4'd7; // 98 cycle (active 1 + working 97)
parameter Dec_encode_m = 4'd8; // 34 cycle (active 1 + working 33)

// registers
reg [3:0] mode_reg;
reg [6:0] cnt;
reg [6143:0] t_c_reg; // store t at Key_gen, store t/c at Enc, store  c  at Dec
reg [6143:0] s_m_reg; // store s at Key_gen, store  m  at Enc, store s/m at Dec
reg [255:0] rho_reg;

// 
reg [3:0] d;
wire [7:0] comp_out_d1;
wire [31:0] comp_out_d4;
wire [79:0] comp_out_d10;
reg [7:0] decomp_in_d1;
reg [31:0] decomp_in_d4;
reg [79:0] decomp_in_d10;
wire [95:0] decomp_out_data;
reg last_cycle;

compress comp (
    .clk(clk),
    .rst(rst),
    .d(d), 
    .in_data(ram_rdata),
    .out_data_d1(comp_out_d1),
    .out_data_d4(comp_out_d4),
    .out_data_d10(comp_out_d10)
);

decompress decomp (
    .clk(clk),
    .rst(rst),
    .d(d),
    .in_data_d1(decomp_in_d1),
    .in_data_d4(decomp_in_d4),
    .in_data_d10(decomp_in_d10),
    .out_data(decomp_out_data)
);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        mode_reg <= WAIT;
        cnt <= 7'd0;
    end
    else begin
        if(active) begin
            mode_reg <= mode;
            cnt <= 7'd0;
        end
        else if(last_cycle) begin
            mode_reg <= WAIT;
            cnt <= 7'd0;
        end
        else if(mode_reg != WAIT) begin
            cnt <= cnt + 7'd1;
        end
    end
end

// output wires
assign pk_out = { t_c_reg, rho_reg };
assign m_out = s_m_reg[255:0];
assign sk_out = s_m_reg;
assign c_out = t_c_reg;
assign rho_from_pk = rho_reg[255:0];

// register wires
reg [95:0] t_c_reg_t_in [0:63];
wire [95:0] t_c_reg_t [0:63];

reg [79:0] t_c_reg_u_in [0:63];
wire [79:0] t_c_reg_u [0:63];

reg [31:0] t_c_reg_v_in [0:31];
wire [31:0] t_c_reg_v [0:31];

reg [95:0] s_m_reg_s_in [0:63];
wire [95:0] s_m_reg_s [0:63];

reg [7:0] s_m_reg_m_in [0:31];
wire [7:0] s_m_reg_m [0:31];

genvar i1;
generate
    for(i1=0; i1<64; i1=i1+1) begin
        assign t_c_reg_t[i1] = t_c_reg[(i1*96+95):(i1*96)];
        assign t_c_reg_u[i1] = t_c_reg[(i1*80+79):(i1*80)];
        assign s_m_reg_s[i1] = s_m_reg[(i1*96+95):(i1*96)];
    end
    for(i1=0; i1<32; i1=i1+1) begin
        assign t_c_reg_v[i1] = t_c_reg[(i1*32+80*64+31):(i1*32+80*64)];
        assign s_m_reg_m[i1] = s_m_reg[(i1*8+7):(i1*8)];
    end
endgenerate

integer i2;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        t_c_reg <= 6144'd0;
        s_m_reg <= 6144'd0;
        rho_reg <= 256'd0;
    end
    else if(load_input_Enc) begin
        rho_reg <= pk_in[255:0];
        t_c_reg <= pk_in[6399:256];
        s_m_reg <= m_in;
    end
    else if(load_input_Dec) begin
        t_c_reg <= c_in;
        s_m_reg <= sk_in;
    end
    else begin
        case(mode_reg)
        KeyGen_encode_sk: 
            for(i2=0; i2<64; i2=i2+1)
                s_m_reg[i2*96 +: 96] <= s_m_reg_s_in[i2];
        KeyGen_encode_pk: begin
            if(cnt == 4'd0) rho_reg <= rho_from_G;
            for(i2=0; i2<64; i2=i2+1)
                t_c_reg[i2*96 +: 96] <= t_c_reg_t_in[i2];
        end
        Enc_encode_c: begin
            for(i2=0; i2<64; i2=i2+1)
                t_c_reg[i2*80 +: 80] <= t_c_reg_u_in[i2];
            for(i2=0; i2<32; i2=i2+1)
                t_c_reg[(i2*32+80*64) +: 32] <= t_c_reg_v_in[i2];
        end
        Dec_encode_m:
            for(i2=0; i2<32; i2=i2+1)
                s_m_reg[i2*8 +: 8] <= s_m_reg_m_in[i2];
        endcase
    end
end

always @(*) begin
    ram_wen = 1'b0;
    ram_raddr = 7'd0;
    ram_waddr = 7'd0;
    ram_wdata = 8'd0;
    d = 4'd1;
    decomp_in_d1 = 8'd0;
    decomp_in_d4 = 32'd0;
    decomp_in_d10 = 80'd0;
    last_cycle = 1'b0;
    for(i2=0; i2<64; i2=i2+1) begin
        t_c_reg_t_in[i2] = t_c_reg_t[i2];
        t_c_reg_u_in[i2] = t_c_reg_u[i2];
        s_m_reg_s_in[i2] = s_m_reg_s[i2];
    end
    for(i2=0; i2<32; i2=i2+1) begin
        t_c_reg_v_in[i2] = t_c_reg_v[i2];
        s_m_reg_m_in[i2] = s_m_reg_m[i2];
    end
    case(mode_reg)
        KeyGen_encode_sk: begin
            ram_raddr = ram_4_offset + cnt;
            s_m_reg_s_in[cnt] = ram_rdata;
            last_cycle = cnt == 7'd63;
        end
        KeyGen_encode_pk: begin
            ram_raddr = ram_6_offset + cnt;
            t_c_reg_t_in[cnt] = ram_rdata;
            last_cycle = cnt == 7'd63;
        end
        Enc_decode_pk: begin
            ram_wen = 1'b1;
            ram_waddr = ram_0_offset + cnt;
            ram_wdata = t_c_reg_t[cnt];
            last_cycle = cnt == 7'd63;
        end
        Enc_decode_m: begin
            ram_wen = cnt != 7'd0 ? 1'b1 : 1'b0;
            ram_waddr = ram_3_offset + cnt - 8'd1;
            ram_wdata = decomp_out_data;
            d = 4'd1;
            decomp_in_d1 = s_m_reg_m[cnt];
            last_cycle = cnt == 7'd32;
        end
        Enc_encode_c: begin
            if(cnt == 7'd0) begin
                d = 4'd10;
                ram_raddr = ram_6_offset + cnt;
            end
            else if(cnt < 7'd64) begin
                d = 4'd10;
                ram_raddr = ram_6_offset + cnt;
                t_c_reg_u_in[cnt-1] = comp_out_d10;
            end
            else if(cnt == 7'd64) begin
                d = 4'd4;
                ram_raddr = ram_0_offset + cnt - 7'd64;
                t_c_reg_u_in[cnt-1] = comp_out_d10;
            end
            else begin
                d = 4'd4;
                ram_raddr = ram_0_offset + cnt - 7'd64;
                t_c_reg_v_in[cnt-65] = comp_out_d4;
            end
            last_cycle = cnt == 7'd96;
        end
        Dec_decode_sk: begin
            ram_wen = 1'b1;
            ram_waddr = ram_3_offset + cnt;
            ram_wdata = s_m_reg_s[cnt];
            last_cycle = cnt == 7'd63;
        end
        Dec_decode_c: begin
            ram_wen = cnt != 7'd0 ? 1'b1 : 1'b0;
            ram_waddr = ram_0_offset + cnt - 8'd1;
            ram_wdata = decomp_out_data;
            d = cnt < 7'd64 ? 4'd10 : 4'd4;
            decomp_in_d10 = t_c_reg_u[cnt];
            decomp_in_d4 = t_c_reg_v[cnt-64];
            last_cycle = cnt == 7'd96;
        end
        Dec_encode_m: begin
            ram_raddr = ram_0_offset + cnt;
            s_m_reg_m_in[cnt-1] = comp_out_d1;
            last_cycle = cnt == 7'd32;
        end
    endcase
end

endmodule

/////////////////////////////////////////////////////

module twiddle_factor(
    input clk,
    input [6:0] addr,
    output [23:0] dout
);

reg [11:0] data [0:127];

assign dout = {data[addr + 1], data[addr]};

initial begin
    data[0] <= 12'h001;
    data[1] <= 12'h6c1;
    data[2] <= 12'ha14;
    data[3] <= 12'hcd9;
    data[4] <= 12'ha52;
    data[5] <= 12'h276;
    data[6] <= 12'h769;
    data[7] <= 12'h350;
    data[8] <= 12'h426;
    data[9] <= 12'h77f;
    data[10] <= 12'h0c1;
    data[11] <= 12'h31d;
    data[12] <= 12'hae2;
    data[13] <= 12'hcbc;
    data[14] <= 12'h239;
    data[15] <= 12'h6d2;
    data[16] <= 12'h128;
    data[17] <= 12'h98f;
    data[18] <= 12'h53b;
    data[19] <= 12'h5c4;
    data[20] <= 12'hbe6;
    data[21] <= 12'h038;
    data[22] <= 12'h8c0;
    data[23] <= 12'h535;
    data[24] <= 12'h592;
    data[25] <= 12'h82e;
    data[26] <= 12'h217;
    data[27] <= 12'hb42;
    data[28] <= 12'h959;
    data[29] <= 12'hb3f;
    data[30] <= 12'h7b6;
    data[31] <= 12'h335;
    data[32] <= 12'h121;
    data[33] <= 12'h14b;
    data[34] <= 12'hcb5;
    data[35] <= 12'h6dc;
    data[36] <= 12'h4ad;
    data[37] <= 12'h900;
    data[38] <= 12'h8e5;
    data[39] <= 12'h807;
    data[40] <= 12'h28a;
    data[41] <= 12'h7b9;
    data[42] <= 12'h9d1;
    data[43] <= 12'h278;
    data[44] <= 12'hb31;
    data[45] <= 12'h021;
    data[46] <= 12'h528;
    data[47] <= 12'h77b;
    data[48] <= 12'h90f;
    data[49] <= 12'h59b;
    data[50] <= 12'h327;
    data[51] <= 12'h1c4;
    data[52] <= 12'h59e;
    data[53] <= 12'hb34;
    data[54] <= 12'h5fe;
    data[55] <= 12'h962;
    data[56] <= 12'ha57;
    data[57] <= 12'ha39;
    data[58] <= 12'h5c9;
    data[59] <= 12'h288;
    data[60] <= 12'h9aa;
    data[61] <= 12'hc26;
    data[62] <= 12'h4cb;
    data[63] <= 12'h38e;
    data[64] <= 12'h011;
    data[65] <= 12'hac9;
    data[66] <= 12'h247;
    data[67] <= 12'ha59;
    data[68] <= 12'h665;
    data[69] <= 12'h2d3;
    data[70] <= 12'h8f0;
    data[71] <= 12'h44c;
    data[72] <= 12'h581;
    data[73] <= 12'ha66;
    data[74] <= 12'hcd1;
    data[75] <= 12'h0e9;
    data[76] <= 12'h2f4;
    data[77] <= 12'h86c;
    data[78] <= 12'hbc7;
    data[79] <= 12'hbea;
    data[80] <= 12'h6a7;
    data[81] <= 12'h673;
    data[82] <= 12'hae5;
    data[83] <= 12'h6fd;
    data[84] <= 12'h737;
    data[85] <= 12'h3b8;
    data[86] <= 12'h5b5;
    data[87] <= 12'ha7f;
    data[88] <= 12'h3ab;
    data[89] <= 12'h904;
    data[90] <= 12'h985;
    data[91] <= 12'h954;
    data[92] <= 12'h2dd;
    data[93] <= 12'h921;
    data[94] <= 12'h10c;
    data[95] <= 12'h281;
    data[96] <= 12'h630;
    data[97] <= 12'h8fa;
    data[98] <= 12'h7f5;
    data[99] <= 12'hc94;
    data[100] <= 12'h177;
    data[101] <= 12'h9f5;
    data[102] <= 12'h82a;
    data[103] <= 12'h66d;
    data[104] <= 12'h427;
    data[105] <= 12'h13f;
    data[106] <= 12'had5;
    data[107] <= 12'h2f5;
    data[108] <= 12'h833;
    data[109] <= 12'h231;
    data[110] <= 12'h9a2;
    data[111] <= 12'ha22;
    data[112] <= 12'haf4;
    data[113] <= 12'h444;
    data[114] <= 12'h193;
    data[115] <= 12'h402;
    data[116] <= 12'h477;
    data[117] <= 12'h866;
    data[118] <= 12'had7;
    data[119] <= 12'h376;
    data[120] <= 12'h6ba;
    data[121] <= 12'h4bc;
    data[122] <= 12'h752;
    data[123] <= 12'h405;
    data[124] <= 12'h83e;
    data[125] <= 12'hb77;
    data[126] <= 12'h375;
    data[127] <= 12'h86a;
end

endmodule

///////////////////////////////////////////////

module sub_div2 (
    input [11:0] in1,
    input [11:0] in2,
    input [1:0] mode,
    output [11:0] res
);

wire [12:0] sub_result;
wire [11:0] reduced_sub_result;

assign sub_result = in1 - in2;
assign reduced_sub_result = sub_result[12]/*negative?*/ ? sub_result + 12'd3329 : sub_result;
assign res = mode == 2'd1 ?  (reduced_sub_result[0]/*odd?*/ ? reduced_sub_result[11:1] + 12'd1665 : reduced_sub_result[11:1] )
           /*mode != 2'd1*/: reduced_sub_result;
endmodule

///////////////////////////

module reduce (
    input clk,
    input rst,
    input [23:0] c,
    output [11:0] r
);

// segment 1
// Calculate Q'1 (Q_1) with low-complexity division by 13.
wire [7:0] c0;
wire [15:0] c1;
wire [13:0] d_1;
wire [13:0] d1_sum;
wire [12:0] Q_1;
assign c0 = c[7:0];
assign c1 = c[23:8];
assign d_1 = c1[15:3] + c1[15:5]; 
assign d1_sum = d_1 - d_1[13:6];
assign Q_1 = d1_sum[13:1];

// stage 1 registers
reg [7:0] c0_reg;
reg [5:0] c1_reg;
reg [12:0] Q_1_reg;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        Q_1_reg <= 0;
        c1_reg <= 0;
        c0_reg <= 0;
    end
    else begin
        Q_1_reg <= Q_1;
        c1_reg <= c1[5:0];
        c0_reg <= c0;
    end
end

// segment 2
// Calculate r'1 (r_1) ~= c1 mod13 with a short width addition tree.
wire [5:0] s_1;
wire [5:0] s_2;
wire [5:0] r_1;
wire [13:0] r1c0;
assign s_1[5:3] = c1_reg[5:3] - Q_1_reg[2:0];
assign s_1[2:0] = c1_reg[2:0];
assign s_2[5:2] = Q_1_reg[5:2] + Q_1_reg[3:0];
assign s_2[1:0] = Q_1_reg[1:0];
assign r_1 = s_1 - s_2;
assign r1c0 = {r_1, c0_reg};

// segment 3
// Obtain raw remander R and calculate r = R mod 3329.
wire [13:0] R;
reg [13:0] R_reg;
assign R = r1c0 - Q_1_reg;
always @(posedge clk or posedge rst) begin
    if(rst) R_reg = 0;
    else R_reg <= R;
end
assign r = R_reg[13] | (R_reg[12:0] >= 13'd3329) ? 
                       (R_reg[11:0] + (R_reg[13] ? 12'd3329 : -12'd3329))
                     : R_reg[11:0];

    
endmodule

/////////////////////////////////////

module ntt_processer (
    input clk,
    input rst,
    input start,
    input [1:0] mode, // 0:NTT, 1:INVNTT, 2:MULT, 3:ADDSUB
    input is_add_or_sub,
    input [7:0] ram_r_start_offset_A,
    input [7:0] ram_r_start_offset_B,
    input [7:0] ram_w_start_offset,
    input [95:0] ram_rdata,
    output reg last_cycle,
    output reg ram_wen,
    output [7:0] ram_raddr,
    output [7:0] ram_waddr,
    output reg [95:0] ram_wdata
);

parameter WAIT_COMMAND_AND_FRST_CYCLE = 2'd0;
parameter PROCESSING = 2'd1;
parameter LAST_CYCLE = 2'd2;

`define NTT 2'd0
`define INVNTT 2'd1
`define MULT 2'd2
`define ADDSUB 2'd3

reg [1:0] st, nst; // state register
reg [7:0] cycle_cnt, ncnt;
reg [2:0] stage;
reg in_buf_pre_load;
reg in_buf_load;
reg type;
wire type2;
assign type2=type;
reg [7:0] ram_r_start_offset;
reg buf_wen;
reg [95:0] BP_in_data;
reg [4:0] buf_raddr;

wire [6:0] coef_addr;
wire [4:0] ag_raddr_out, ag_waddr_out;
wire [23:0] coef_rom_out;
wire [95:0] buf_rdata, buf_wdata;
wire [95:0] BP_out_data;

reg [1:0] mode_reg;
reg is_add_or_sub_reg;
reg [7:0] ram_r_start_offset_A_reg;
reg [7:0] ram_r_start_offset_B_reg;
reg [7:0] ram_w_start_offset_reg;

addr_generator AG (
    .clk(clk),
    .rst(rst),
    .mode(start ? mode : mode_reg),
    .cycle_cnt(cycle_cnt),
    .stage(stage),
    .coef_addr(coef_addr),
    .raddr(ag_raddr_out),
    .waddr(ag_waddr_out)
);

BU_processor BP (
    .clk(clk),
    .rst(rst),
    .op_mode(start ? mode : mode_reg),  
    .stage(stage), 
    .in_buf_pre_load(in_buf_pre_load),
    .in_buf_load(in_buf_load),
    .type(type2), 
    .in_data(BP_in_data),
    .in_coef(coef_rom_out),
    .out_data(BP_out_data)
);

twiddle_factor ROM (
    .clk(clk),
    .addr(coef_addr),
    .dout(coef_rom_out)
);

assign buf_wdata = BP_out_data; 
buf_96x32 ntt_buf (
    .clk(clk),
    .rst(rst),
    .wen(buf_wen),
    .raddr(buf_raddr),
    .waddr(ag_waddr_out),
    .din(buf_wdata),
    .dout(buf_rdata)
);

assign ram_raddr = ram_r_start_offset + ag_raddr_out;
assign ram_waddr = mode == `NTT || mode == `INVNTT ? ram_w_start_offset_reg + ag_waddr_out : ram_w_start_offset_reg + buf_raddr;

// control logic
always @(posedge clk or posedge rst) begin
    if(rst) begin
        st <= WAIT_COMMAND_AND_FRST_CYCLE;
        cycle_cnt <= 8'd0;
    end
    else begin
        st <= nst;
        cycle_cnt <= ncnt;
    end
end

always @(*) begin
    case (st)
        WAIT_COMMAND_AND_FRST_CYCLE : begin
            stage = 3'd0;
            if(start) begin
                nst = PROCESSING;
                ncnt = cycle_cnt + 1;
            end
            else begin
                nst = st;
                ncnt = 8'd0;
            end
        end 
        PROCESSING : begin
            ncnt = cycle_cnt + 1;
            case(mode_reg)
            `NTT, `INVNTT: begin
                nst = cycle_cnt == 8'd228 ? LAST_CYCLE : PROCESSING;
                stage = cycle_cnt[7:5];
            end
            `MULT: begin
                nst = cycle_cnt == 8'd138 ? LAST_CYCLE : PROCESSING;
                stage = { 1'b0, ~cycle_cnt[1], cycle_cnt[0] }; // 2(10) -> 0(00), 3(11) -> 1(01), 0(00) -> 2(20), 1(01) -> 3(11) 
            end
            `ADDSUB: begin
                nst = cycle_cnt == 8'd66 ? LAST_CYCLE : PROCESSING;
                stage = { 2'b0, cycle_cnt[0] };
            end
            endcase
        end 
        LAST_CYCLE : begin
            nst = WAIT_COMMAND_AND_FRST_CYCLE;
            ncnt = 8'd0;
            stage = 3'd0;
        end 
        default: begin
            nst = WAIT_COMMAND_AND_FRST_CYCLE;
            stage = 3'd0;
            ncnt = 8'd0;
        end
    endcase
end

always @(*) begin
    case (st)
        WAIT_COMMAND_AND_FRST_CYCLE : begin
            in_buf_pre_load = mode == `MULT || mode == `ADDSUB;
            in_buf_load = 1'b0;
            type = mode == `ADDSUB ? is_add_or_sub : 1'b0;
            ram_r_start_offset = ram_r_start_offset_A;
            last_cycle = 1'b0;
            ram_wen = 1'b0;
            buf_wen = 1'b0;
            BP_in_data = ram_rdata;
            ram_wdata = 0;
            buf_raddr = 0;
        end 
        PROCESSING : begin
            last_cycle = 1'b0;
            case(mode_reg)
            `NTT, `INVNTT: begin
                in_buf_pre_load = 1'b0;
                in_buf_load = 1'b0;
                type = cycle_cnt[0];
                ram_r_start_offset = ram_r_start_offset_A_reg;
                ram_wen = cycle_cnt > 8'd197;
                buf_wen = cycle_cnt > 8'd5 && cycle_cnt <= 8'd197;
                BP_in_data = stage == 3'd0 ? ram_rdata : buf_rdata;
                ram_wdata = BP_out_data;
                buf_raddr = ag_raddr_out;
            end
            `MULT: begin
                in_buf_pre_load = cycle_cnt[1:0] == 2'd0;
                in_buf_load = cycle_cnt[1:0] == 2'd1;
                type = 1'b0;
                ram_r_start_offset = cycle_cnt[0] ? ram_r_start_offset_B_reg : ram_r_start_offset_A_reg;
                ram_wen = cycle_cnt > 8'd107;
                buf_wen = cycle_cnt > 8'd12 && cycle_cnt[1:0] == 2'd3;
                BP_in_data = ram_rdata;
                ram_wdata = buf_rdata;
                buf_raddr = cycle_cnt - 8'd108;
            end
            `ADDSUB: begin
                in_buf_pre_load = ~cycle_cnt[0];
                in_buf_load = cycle_cnt[0];
                type = is_add_or_sub_reg;
                ram_r_start_offset = cycle_cnt[0] ? ram_r_start_offset_B_reg : ram_r_start_offset_A_reg;
                ram_wen = cycle_cnt > 8'd35;
                buf_wen = cycle_cnt > 8'd3 && cycle_cnt[0];
                BP_in_data = ram_rdata;
                ram_wdata = buf_rdata;
                buf_raddr = cycle_cnt - 8'd36;
            end
            endcase
        end 
        LAST_CYCLE : begin
            in_buf_pre_load = 1'b0;
            in_buf_load = 1'b0;
            type = 1'b0;
            ram_r_start_offset = ram_w_start_offset_reg;
            last_cycle = 1'b1;
            ram_wen = 1'b1;
            buf_wen = 1'b0;
            BP_in_data = ram_rdata;
            ram_wdata = BP_out_data;
            buf_raddr = 5'd31;
        end 
        default: begin
            in_buf_pre_load = 1'b0;
            in_buf_load = 1'b0;
            type = 1'b0;
            ram_r_start_offset = ram_r_start_offset_A;
            last_cycle = 1'b0;
            ram_wen = 1'b0;
            buf_wen = 1'b0;
            BP_in_data = ram_rdata;
            ram_wdata = 0;
            buf_raddr = 0;
        end
    endcase
end
// end of control logic

always @(posedge clk or posedge rst) begin
    if(rst) begin
        mode_reg <= 0;
        is_add_or_sub_reg <= 0;
        ram_r_start_offset_A_reg <= 0;
        ram_r_start_offset_B_reg <= 0;
        ram_w_start_offset_reg <= 0;
    end
    else begin
        if(start) begin
            mode_reg <= mode;
            is_add_or_sub_reg <= is_add_or_sub;
            ram_r_start_offset_A_reg <= ram_r_start_offset_A;
            ram_r_start_offset_B_reg <= ram_r_start_offset_B;
            ram_w_start_offset_reg <= ram_w_start_offset;
        end
    end
end

endmodule

//////////////////////////////////////////

module mul_reduce (
    input clk,
    input rst,
    input [11:0] in1,
    input [11:0] in2,
    output [11:0] res
);

// input_reg
reg [11:0] in1_reg;
reg [11:0] in2_reg;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        in1_reg <= 0;
        in2_reg <= 0;
    end
    else begin
        in1_reg <= in1;
        in2_reg <= in2;
    end
end

// product registers
wire [23:0] prod;
assign prod = in1_reg * in2_reg;
reg [23:0] prod_reg;
always @(posedge clk or posedge rst) begin
    if(rst) prod_reg <= 0;
    else prod_reg <= prod;
end

// reduce unit
// (2 pipeline register inside)

reduce mod (
    .clk(clk),
    .rst(rst),
    .c(prod_reg),
    .r(res)
);
    
endmodule

/////////////////////////////////////////

module buf_96x32 (
    input clk,
    input rst,
    input wen,
    input [4:0] raddr,
    input [4:0] waddr,
    input [95:0] din,
    output reg [95:0] dout
);

reg [95:0] data [0:31];

always @(*) begin
    dout = data[raddr];
end

integer i;
always@(posedge clk) begin
    if(rst) begin
        for(i=0; i<32; i=i+1) data[i] <= 0;
    end
    else begin
        if(wen) data[waddr] <= din;
    end
end

endmodule

/////////////////////////////////

module addr_generator (
    input clk,
    input rst,
    input [1:0] mode,
    input [7:0] cycle_cnt,
    input [2:0] stage,
    output reg [6:0] coef_addr,
    output reg [4:0] raddr,
    output reg [4:0] waddr
);

`define NTT 2'd0
`define INVNTT 2'd1
`define MULT 2'd2
`define ADDSUB 2'd3

reg [4:0] stage_offset;
reg [4:0] raddr_offset;
reg [6:0] coef_addr_offset;
reg [6:0] coef_addr_cnt;

wire [7:0] cycle_cnt_sub_2;
assign cycle_cnt_sub_2 = cycle_cnt - 2;

reg [4:0] waddr_shift_reg [5:0];

always @(*) begin
    case(mode)
    `NTT: begin
        case(stage)
        3'd0: stage_offset = 5'd16;
        3'd1: stage_offset = 5'd8;
        3'd2: stage_offset = 5'd4;
        3'd3: stage_offset = 5'd2;
        default: stage_offset = 5'd1;
        endcase
    end
    `INVNTT: begin
        case(stage)
        3'd5: stage_offset = 5'd16;
        3'd4: stage_offset = 5'd8;
        3'd3: stage_offset = 5'd4;
        3'd2: stage_offset = 5'd2;
        default: stage_offset = 5'd1;
        endcase
    end
    default: begin // MULT, ADDSUB
        stage_offset = 5'd0;
    end
    endcase
end


always @(*) begin
    case(mode)
    `NTT: begin
        coef_addr_offset = 7'd1 << stage;
        coef_addr_cnt = stage == 3'd6 ? {cycle_cnt[4:0], 1'b0} : (cycle_cnt[4:0] >> (3'd5-stage));
    end
    `INVNTT: begin
        coef_addr_offset = 7'd1 << (3'd7 - stage);
        coef_addr_cnt = stage == 3'd0 ? {cycle_cnt[4:0], 1'b0} + 6'd2 :
                        stage == 3'd1 || stage == 3'd6 ? (cycle_cnt[4:0] >> (stage-1)) + 6'd1 :
                        { (cycle_cnt[4:0] >> (stage)), 1'b0 } + (cycle_cnt[0] ? 6'd2 : 6'd1);
    end
    `MULT: begin
        coef_addr_offset = 7'd64;
        coef_addr_cnt = { cycle_cnt_sub_2[7:2], 1'b0 };
    end
    `ADDSUB: begin
        coef_addr_offset = 7'd0;
        coef_addr_cnt = 7'd0;
    end
    endcase
end

always @(*) begin
    case(mode)
    `NTT: begin
        case(stage)
        3'd0: raddr_offset = 5'd0;
        3'd1: raddr_offset = { 1'b0, cycle_cnt[4], 3'b0 } ; // +0(0~15), +8(16~31)
        3'd2: raddr_offset = { 1'b0, cycle_cnt[4:3], 2'b0 } ; // +0(0~7), +4(8~15), +8(16~23), +12(24~31)
        3'd3: raddr_offset = { 1'b0, cycle_cnt[4:2], 1'b0 } ; // +0(0~3), +2(4~7), +4(8~12) ......
        default: raddr_offset = { 1'd0, cycle_cnt[4:1] };
        endcase
    end
    `INVNTT: begin
        case(stage)
        3'd5: raddr_offset = 5'd0;
        3'd4: raddr_offset = { 1'b0, cycle_cnt[4], 3'b0 } ; // +0(0~15), +8(16~31)
        3'd3: raddr_offset = { 1'b0, cycle_cnt[4:3], 2'b0 } ; // +0(0~7), +4(8~15), +8(16~23), +12(24~31)
        3'd2: raddr_offset = { 1'b0, cycle_cnt[4:2], 1'b0 } ; // +0(0~3), +2(4~7), +4(8~12) ......
        default: raddr_offset = { 1'd0, cycle_cnt[4:1] };
        endcase        
    end
    `MULT: begin
        raddr_offset = cycle_cnt[7:2];
    end
    `ADDSUB: begin
        raddr_offset = cycle_cnt[6:1];
    end
    endcase
end

always @(*) begin
    case(mode)
    `NTT, 
    `INVNTT: begin
        raddr = raddr_offset + cycle_cnt[4:1] + (cycle_cnt[0] ? stage_offset : 5'd0);
    end
    default: begin // `MULT, `ADDSUB
        raddr = raddr_offset;
    end
    endcase
end

always @(*) begin
    case(mode)
    `NTT: begin
       coef_addr = coef_addr_offset + coef_addr_cnt;
    end
    `INVNTT: begin
       coef_addr = coef_addr_offset - coef_addr_cnt;
    end
    `MULT: begin
        coef_addr = coef_addr_offset + coef_addr_cnt;
    end
    `ADDSUB: begin
        coef_addr = 0;
    end
    endcase
end

integer i;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        for(i=0; i<6; i=i+1) waddr_shift_reg[i] <= 0;
    end
    else begin
        case(mode)
        `NTT, 
        `INVNTT: begin
        waddr_shift_reg[0] <= raddr;
        for(i=1; i<6; i=i+1) waddr_shift_reg[i] <= waddr_shift_reg[i-1];
        end
        endcase
    end
end


always @(*) begin
    case(mode)
    `NTT, 
    `INVNTT: begin
       waddr = waddr_shift_reg[5];
    end
    `MULT: begin
       waddr = cycle_cnt[7:2] - 3;
    end
    `ADDSUB: begin
       waddr = cycle_cnt[7:1] - 2;
    end
    endcase
end

endmodule

////////////////////////////////////

module add_div2 (
    input [11:0] in1,
    input [11:0] in2,
    input [1:0] mode,
    output [11:0] res
);

wire [12:0] add_result;
wire [11:0] reduced_add_result;

assign add_result = in1 + in2;
assign reduced_add_result = add_result >= 13'd3329 ? add_result - 12'd3329 : add_result;
assign res = mode == 2'd1 ?  (reduced_add_result[0]/*odd?*/ ? reduced_add_result[11:1] + 12'd1665 : reduced_add_result[11:1] )
           /*mode != 2'd1*/: reduced_add_result;
endmodule

//////////////////////////////////////

module BU_processor (
    input clk,
    input rst,
    input [1:0] op_mode, 
    // op_mode : ntt(0) , invntt(1), mult(2), addsub(3)    
    input [2:0] stage, 
    // stage : ntt & invntt(0~6 for output control), mult(0~3 for input control), addsub(0~1 for input control)    
    input in_buf_pre_load,
    // in_buf_preload : used in mult and add_sub, loading in_buf_a_pre_load
    input in_buf_load,
    // in_buf_load : used in mult and add_sub, loading in_buf_a & in_buf_b
    input type, 
    // type : used in ntt stage 0~4 & invntt stage 1~5 for output control// type : used in ntt stage 0~4 & invntt stage 1~5 for output control
    //        used in addsub for output control add(0) or sub(1) result 
    input [95:0] in_data,
    input [23:0] in_coef,
    output [95:0] out_data
);

`define NTT 2'd0
`define INVNTT 2'd1
`define MULT 2'd2
`define ADDSUB 2'd3


integer i;
wire [11:0] in_data_split [7:0];
wire [11:0] in_coef_split [1:0];
reg [11:0] out_data_split [7:0];
wire [11:0] in_coef_split_neg [1:0];

// some registers
reg [11:0] in_buf_a_pre [7:0]; // 12x8 input buffer, used in multiply operation
reg [11:0] in_buf_a [7:0]; // 12x8 input buffer, used in multiply operation
reg [11:0] in_buf_b [7:0]; // 12x8 input buffer, used in multiply operation
reg [11:0] out_buf [7:0]; // 12x8 output buffer
reg [2:0] stage_prop [8:0]; // stage propagation register
reg type_prop [5:0]; // type propagation register

// bu_0
reg [11:0] bu_0_in_1, bu_0_in_2, bu_0_coef;
wire [1:0] bu_0_mode;
wire [11:0] bu_0_out_1, bu_0_out_2;
BU bu_0 (
    .clk(clk),
    .rst(rst),
    .u_in(bu_0_in_1),
    .t_in(bu_0_in_2),
    .coef(bu_0_coef),
    .mode(bu_0_mode),
    .U_out(bu_0_out_1),
    .T_out(bu_0_out_2)
);

// bu_1
reg [11:0] bu_1_in_1, bu_1_in_2, bu_1_coef;
wire [1:0] bu_1_mode;
wire [11:0] bu_1_out_1, bu_1_out_2;
BU bu_1 (
    .clk(clk),
    .rst(rst),
    .u_in(bu_1_in_1),
    .t_in(bu_1_in_2),
    .coef(bu_1_coef),
    .mode(bu_1_mode),
    .U_out(bu_1_out_1),
    .T_out(bu_1_out_2)
);

// bu_2
reg [11:0] bu_2_in_1, bu_2_in_2, bu_2_coef;
wire [1:0] bu_2_mode;
wire [11:0] bu_2_out_1, bu_2_out_2;
BU bu_2 (
    .clk(clk),
    .rst(rst),
    .u_in(bu_2_in_1),
    .t_in(bu_2_in_2),
    .coef(bu_2_coef),
    .mode(bu_2_mode),
    .U_out(bu_2_out_1),
    .T_out(bu_2_out_2)
);

// bu_3
reg [11:0] bu_3_in_1, bu_3_in_2, bu_3_coef;
wire [1:0] bu_3_mode;
wire [11:0] bu_3_out_1, bu_3_out_2;
BU bu_3 (
    .clk(clk),
    .rst(rst),
    .u_in(bu_3_in_1),
    .t_in(bu_3_in_2),
    .coef(bu_3_coef),
    .mode(bu_3_mode),
    .U_out(bu_3_out_1),
    .T_out(bu_3_out_2)
);

// wires declare for multiply operation
reg [11:0] mult_a0, mult_a1, mult_b0, mult_b1, mult_coef;

// mul_reduce (used in multiply operation)
wire [11:0] mul_reduce_in_1, mul_reduce_in_2;
wire [11:0] mul_reduce_out;
mul_reduce MR (
    .clk(clk),
    .rst(rst),
    .in1(mul_reduce_in_1),
    .in2(mul_reduce_in_2),
    .res(mul_reduce_out)
);
assign mul_reduce_in_1 = op_mode == `MULT ? mult_a1 : 12'd0;
assign mul_reduce_in_2 = op_mode == `MULT ? mult_coef : 12'd0;

// in_data & out_data split assignment
assign in_data_split[0] = in_data[11:00];
assign in_data_split[1] = in_data[23:12];
assign in_data_split[2] = in_data[35:24];
assign in_data_split[3] = in_data[47:36];
assign in_data_split[4] = in_data[59:48];
assign in_data_split[5] = in_data[71:60];
assign in_data_split[6] = in_data[83:72];
assign in_data_split[7] = in_data[95:84];
assign in_coef_split[0] = in_coef[11:00];
assign in_coef_split[1] = in_coef[23:12];
assign in_coef_split_neg[0] = 12'd3329 - in_coef[11:00];
assign in_coef_split_neg[1] = 12'd3329 - in_coef[23:12];
assign out_data = { out_data_split[7], out_data_split[6], out_data_split[5], out_data_split[4],
                    out_data_split[3], out_data_split[2], out_data_split[1], out_data_split[0] };

// BU_inputs
assign bu_0_mode = op_mode;
assign bu_1_mode = op_mode;
assign bu_2_mode = op_mode == `MULT ? 2'd0 : op_mode;
assign bu_3_mode = op_mode == `MULT ? 2'd0 : op_mode;
always @(*) begin
    case(op_mode)
    `NTT : begin
        bu_0_in_1 = in_data_split[0];
        bu_0_in_2 = in_data_split[2];
        
        bu_1_in_1 = in_data_split[1];
        bu_1_in_2 = in_data_split[3];
        
        bu_2_in_1 = in_data_split[4];
        bu_2_in_2 = in_data_split[6];
        
        bu_3_in_1 = in_data_split[5];
        bu_3_in_2 = in_data_split[7];
        
        bu_0_coef = in_coef_split[0];
        bu_1_coef = in_coef_split[0];
        bu_2_coef = stage == 3'd6 ? in_coef_split[1] : in_coef_split[0];
        bu_3_coef = stage == 3'd6 ? in_coef_split[1] : in_coef_split[0];
    end
    `INVNTT: begin
        bu_0_in_1 = in_data_split[0];
        bu_0_in_2 = stage == 3'd0 ? in_data_split[2] : in_data_split[4];
        
        bu_1_in_1 = in_data_split[1];
        bu_1_in_2 = stage == 3'd0 ? in_data_split[3] : in_data_split[5];
        
        bu_2_in_1 = stage == 3'd0 ? in_data_split[4] : in_data_split[2];
        bu_2_in_2 = in_data_split[6];
        
        bu_3_in_1 = stage == 3'd0 ? in_data_split[5] : in_data_split[3];
        bu_3_in_2 = in_data_split[7];
        
        bu_0_coef = stage == 3'd0 ? in_coef_split_neg[1] : in_coef_split_neg[0];
        bu_1_coef = stage == 3'd0 ? in_coef_split_neg[1] : in_coef_split_neg[0];
        bu_2_coef = in_coef_split_neg[0];
        bu_3_coef = in_coef_split_neg[0];
    end
    `MULT: begin
        // stage 1
        bu_0_in_1 = mult_b1; // input b1 to shift reg
        bu_0_in_2 = mult_b0; // b0 * a0
        bu_0_coef = mult_a0; // b0 * a0
        bu_1_in_1 = mult_a0; // input a0 to shift reg
        bu_1_in_2 = mult_b0; // b0 * a1
        bu_1_coef = mult_a1; // b0 * a1
        // stage 2
        bu_2_in_1 = bu_0_out_2; // b0 * a1 result -> adding
        bu_2_in_2 = mul_reduce_out; // a1 * coef -> a1 * coef * b1
        bu_2_coef = bu_0_out_1; // b1 -> a1 * coef * b1
        bu_3_in_1 = bu_1_out_2; // b0 * a1 -> adding
        bu_3_in_2 = bu_0_out_1; // b1 -> b1 * a0
        bu_3_coef = bu_1_out_1; // a0 -> b1 * a0
    end
    default: begin // ADDSUB
        bu_0_in_1 = stage[0] ? in_buf_a[4] : in_buf_a[0];
        bu_0_in_2 = stage[0] ? in_buf_b[4] : in_buf_b[0];
        bu_1_in_1 = stage[0] ? in_buf_a[5] : in_buf_a[1];
        bu_1_in_2 = stage[0] ? in_buf_b[5] : in_buf_b[1];
        bu_2_in_1 = stage[0] ? in_buf_a[6] : in_buf_a[2];
        bu_2_in_2 = stage[0] ? in_buf_b[6] : in_buf_b[2];
        bu_3_in_1 = stage[0] ? in_buf_a[7] : in_buf_a[3];
        bu_3_in_2 = stage[0] ? in_buf_b[7] : in_buf_b[3];
        bu_0_coef = 12'd0;
        bu_1_coef = 12'd0;
        bu_2_coef = 12'd0;
        bu_3_coef = 12'd0;
    end
    endcase
end

// mult_a0 a1 b0 b1 coef
always @(*) begin
    if(op_mode == `MULT) begin
        case(stage[1:0])
        2'd0: begin
            mult_a0 = in_buf_a[0];
            mult_b0 = in_buf_b[0];
            mult_a1 = in_buf_a[1];
            mult_b1 = in_buf_b[1];
            mult_coef = in_coef_split[0];
        end
        2'd1: begin
            mult_a0 = in_buf_a[2];
            mult_b0 = in_buf_b[2];
            mult_a1 = in_buf_a[3];
            mult_b1 = in_buf_b[3];
            mult_coef = in_coef_split_neg[0];
        end
        2'd2: begin
            mult_a0 = in_buf_a[4];
            mult_b0 = in_buf_b[4];
            mult_a1 = in_buf_a[5];
            mult_b1 = in_buf_b[5];
            mult_coef = in_coef_split[1];
        end
        2'd3: begin
            mult_a0 = in_buf_a[6];
            mult_b0 = in_buf_b[6];
            mult_a1 = in_buf_a[7];
            mult_b1 = in_buf_b[7];
            mult_coef = in_coef_split_neg[1];
        end
        endcase 
    end
    else begin
        mult_a0 = 12'd0;
        mult_b0 = 12'd0;
        mult_a1 = 12'd0;
        mult_b1 = 12'd0;
        mult_coef = 12'd0;
    end
end

// stage_prop & type_prop
always @(posedge clk or posedge rst) begin
    if(rst) begin
        for(i=0; i<6; i=i+1) stage_prop[0] <= 0;
        for(i=0; i<9; i=i+1) type_prop[0] <= 0;
    end
    else begin
        stage_prop[0] <= stage;
        type_prop[0] <= type;
        for(i=1; i<6; i=i+1) begin
            stage_prop[i] <= stage_prop[i-1];
            type_prop[i] <= type_prop[i-1];
        end
        for(i=6; i<9; i=i+1) begin
            stage_prop[i] <= stage_prop[i-1];
        end
    end
end

// output buffer
always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<8; i=i+1) out_buf[i] <= 0;
    end
    else begin
        case(op_mode)
        `NTT: begin
            if(stage_prop[4] == 3'd5) begin
                out_buf[0] <= bu_0_out_1;
                out_buf[1] <= bu_1_out_1;
                out_buf[2] <= bu_2_out_1;
                out_buf[3] <= bu_3_out_1;
                out_buf[4] <= bu_0_out_2;
                out_buf[5] <= bu_1_out_2;
                out_buf[6] <= bu_2_out_2;
                out_buf[7] <= bu_3_out_2;
            end
            else if(stage_prop[4] == 3'd6) begin
                out_buf[0] <= bu_0_out_1;
                out_buf[1] <= bu_1_out_1;
                out_buf[2] <= bu_0_out_2;
                out_buf[3] <= bu_1_out_2;
                out_buf[4] <= bu_2_out_1;
                out_buf[5] <= bu_3_out_1;
                out_buf[6] <= bu_2_out_2;
                out_buf[7] <= bu_3_out_2;
            end
            else begin 
                if(type_prop[4] == 1'b0) begin 
                    out_buf[0] <= bu_0_out_2;
                    out_buf[1] <= bu_1_out_2;
                    out_buf[2] <= bu_2_out_2;
                    out_buf[3] <= bu_3_out_2;
                    out_buf[4] <= bu_0_out_1;
                    out_buf[5] <= bu_1_out_1;
                    out_buf[6] <= bu_2_out_1;
                    out_buf[7] <= bu_3_out_1;
                end
                else begin
                    out_buf[4] <= bu_0_out_2;
                    out_buf[5] <= bu_1_out_2;
                    out_buf[6] <= bu_2_out_2;
                    out_buf[7] <= bu_3_out_2;
                end
            end
        end
        `INVNTT: begin
            if(stage_prop[4] == 3'd0 || stage_prop[4] == 3'd6) begin
                out_buf[0] <= bu_0_out_1;
                out_buf[1] <= bu_1_out_1;
                out_buf[2] <= bu_0_out_2;
                out_buf[3] <= bu_1_out_2;
                out_buf[4] <= bu_2_out_1;
                out_buf[5] <= bu_3_out_1;
                out_buf[6] <= bu_2_out_2;
                out_buf[7] <= bu_3_out_2;
            end
            else begin 
                if(type_prop[4] == 1'b0) begin 
                    out_buf[0] <= bu_2_out_1;
                    out_buf[1] <= bu_3_out_1;
                    out_buf[2] <= bu_2_out_2;
                    out_buf[3] <= bu_3_out_2;
                    out_buf[4] <= bu_0_out_1;
                    out_buf[5] <= bu_1_out_1;
                    out_buf[6] <= bu_0_out_2;
                    out_buf[7] <= bu_1_out_2;
                end
                else begin
                    out_buf[4] <= bu_2_out_1;
                    out_buf[5] <= bu_3_out_1;
                    out_buf[6] <= bu_2_out_2;
                    out_buf[7] <= bu_3_out_2;
                end
            end
        end
        `MULT: begin
            case(stage_prop[8][1:0]) 
            2'd0: begin
                out_buf[0] <= bu_2_out_1;
                out_buf[1] <= bu_3_out_1;
            end
            2'd1: begin
                out_buf[2] <= bu_2_out_1;
                out_buf[3] <= bu_3_out_1;            
            end
            2'd2: begin
                out_buf[4] <= bu_2_out_1;
                out_buf[5] <= bu_3_out_1;            
            end
            2'd3: begin
                out_buf[6] <= bu_2_out_1;
                out_buf[7] <= bu_3_out_1;            
            end
            endcase
        end
        default: begin // ADDSUB
            if(type_prop[0]) begin // sub
                if(stage_prop[0][0]) begin
                    out_buf[4] <= bu_0_out_2;
                    out_buf[5] <= bu_1_out_2;
                    out_buf[6] <= bu_2_out_2;
                    out_buf[7] <= bu_3_out_2;    
                end
                else begin
                    out_buf[0] <= bu_0_out_2;
                    out_buf[1] <= bu_1_out_2;
                    out_buf[2] <= bu_2_out_2;
                    out_buf[3] <= bu_3_out_2;   
                end 
            end
            else begin // add
                if(stage_prop[0][0]) begin
                    out_buf[4] <= bu_0_out_1;
                    out_buf[5] <= bu_1_out_1;
                    out_buf[6] <= bu_2_out_1;
                    out_buf[7] <= bu_3_out_1;    
                end
                else begin
                    out_buf[0] <= bu_0_out_1;
                    out_buf[1] <= bu_1_out_1;
                    out_buf[2] <= bu_2_out_1;
                    out_buf[3] <= bu_3_out_1;    
                end
            end
        end
        endcase
    end
end

// output data
always @(*) begin
    case(op_mode)
    `NTT: begin
        if(stage_prop[5] == 3'd5 || stage_prop[5] == 3'd6) begin
            for(i=0; i<8; i=i+1) out_data_split[i] = out_buf[i];
        end
        else begin 
            if(type_prop[5] == 1'b0) begin 
                out_data_split[0] = out_buf[4];
                out_data_split[1] = out_buf[5];
                out_data_split[2] = out_buf[6];
                out_data_split[3] = out_buf[7];
                out_data_split[4] = bu_0_out_1;
                out_data_split[5] = bu_1_out_1;
                out_data_split[6] = bu_2_out_1;
                out_data_split[7] = bu_3_out_1;
            end
            else begin
                for(i=0; i<8; i=i+1) out_data_split[i] = out_buf[i];
            end
        end
    end
    `INVNTT: begin
        if(stage_prop[5] == 3'd0 || stage_prop[5] == 3'd6) begin
            for(i=0; i<8; i=i+1) out_data_split[i] = out_buf[i];
        end
        else begin 
            if(type_prop[5] == 1'b0) begin 
                out_data_split[0] = out_buf[4];
                out_data_split[1] = out_buf[5];
                out_data_split[2] = out_buf[6];
                out_data_split[3] = out_buf[7];
                out_data_split[4] = bu_0_out_1;
                out_data_split[5] = bu_1_out_1;
                out_data_split[6] = bu_0_out_2;
                out_data_split[7] = bu_1_out_2;
            end
            else begin
                for(i=0; i<8; i=i+1) out_data_split[i] = out_buf[i];
            end
        end        
    end
    default: begin // MULT & ADDSUB
        for(i=0; i<8; i=i+1) out_data_split[i] = out_buf[i];
    end
    endcase
end
    
// in_buf_control
always @(posedge clk or posedge rst) begin
    if(rst) begin
        for(i=0; i<8; i=i+1) in_buf_a_pre[i] <= 0;
    end
    else begin
        if(in_buf_pre_load) begin
            for(i=0; i<8; i=i+1) in_buf_a_pre[i] <= in_data_split[i];
        end
    end
end
always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<8; i=i+1) in_buf_a[i] <= 0;
        for(i=0; i<8; i=i+1) in_buf_b[i] <= 0;
    end
    else begin
        if(in_buf_load) begin
            for(i=0; i<8; i=i+1) begin
                in_buf_a[i] <= in_buf_a_pre[i];
                in_buf_b[i] <= in_data_split[i];
            end
        end
    end
end

endmodule

//////////////////////////////////////

module BU (
    input clk,
    input rst,
    input [11:0] u_in,
    input [11:0] t_in,
    input [11:0] coef,
    input [1:0] mode,
    output [11:0] U_out,
    output [11:0] T_out
);

/*
mode 0: NTT & mul_stage_2 (mul reduce -> add sub, total 5 delay)
mode 1: INVNTT (add sub -> mul reduce, total 5 delay)
mode 2: mul_stage_1 (mul reduce only, total 4 delay)
mode 3: add or sub poly (add sub only, total 1 delay)

*/

// slice A
// mult & reduce
wire [11:0] slice_A_u_in;
wire [11:0] slice_A_t_in;
wire [11:0] slice_A_coef_in;
wire [11:0] slice_A_U_out;
wire [11:0] slice_A_T_out;
reg [11:0] slice_A_shift_regs [0:3];
mul_reduce mul_red_A (
    .clk(clk),
    .rst(rst),
    .in1(slice_A_t_in),
    .in2(slice_A_coef_in),
    .res(slice_A_T_out)
);
always @(posedge clk) begin
    slice_A_shift_regs[0] <= slice_A_u_in;
    slice_A_shift_regs[1] <= slice_A_shift_regs[0];
    slice_A_shift_regs[2] <= slice_A_shift_regs[1];
    slice_A_shift_regs[3] <= slice_A_shift_regs[2];
end
assign slice_A_U_out = slice_A_shift_regs[3];

// slice B
// add & sub
wire [11:0] slice_B_u_in;
wire [11:0] slice_B_t_in;
wire [11:0] slice_B_U_out;
wire [11:0] slice_B_T_out;
reg [11:0] slice_B_u_in_reg;
reg [11:0] slice_B_t_in_reg;
add_div2 add_B (
    .in1(slice_B_u_in_reg),
    .in2(slice_B_t_in_reg),
    .mode(mode),
    .res(slice_B_U_out)
);
sub_div2 sub_B (
    .in1(slice_B_u_in_reg),
    .in2(slice_B_t_in_reg),
    .mode(mode),
    .res(slice_B_T_out)
);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        slice_B_u_in_reg <= 0;
        slice_B_t_in_reg <= 0;
    end
    else begin
        slice_B_u_in_reg <= slice_B_u_in;
        slice_B_t_in_reg <= slice_B_t_in;
    end
end

// input select multiplexers
reg [11:0] coef_reg;
always @(posedge clk) begin
    if(rst) coef_reg <= 0;
    else coef_reg <= coef;
end
assign slice_A_u_in = mode == 2'd1 || mode == 2'd3 ? slice_B_U_out : u_in;
assign slice_A_t_in = mode == 2'd1 || mode == 2'd3 ? slice_B_T_out : t_in;
assign slice_A_coef_in = mode == 2'd1 || mode == 2'd3 ? coef_reg : coef;
assign slice_B_u_in = mode == 2'd1 || mode == 2'd3 ? u_in : slice_A_U_out;
assign slice_B_t_in = mode == 2'd1 || mode == 2'd3 ? t_in : slice_A_T_out;

// output select multiplexers
assign U_out = mode == 2'd0 || mode == 2'd3 ? slice_B_U_out : slice_A_U_out;
assign T_out = mode == 2'd0 || mode == 2'd3 ? slice_B_T_out : slice_A_T_out;
    
endmodule

////////////////////////////////////////

module small_poly_generator(input [0:264-1] M, //256+8 (s||b)
                            input [7:0] ram_w_start_offset,
                            input [1:0] n_num, //1 => n1; 2 => n2
                            input clk,rst, active,
                            output reg enw,
                            output reg [7:0] waddr,
                            output reg [95:0] dout);

wire [1536-1:0] b;
wire enable;
wire [11:0] a_temp1,b_temp1 ,a_temp2,b_temp2 ,a_temp3,b_temp3;
wire [11:0] a_temp4,b_temp4 ,a_temp5,b_temp5,a_temp6,b_temp6;
wire [11:0] a_temp7,b_temp7 ,a_temp8,b_temp8;
wire [10:0] index_a,index_b;
reg [1:0] cs,ns;
reg [7:0]counter_i;
reg [7:0] counter;


parameter s0 = 2'b00,
          s1 = 2'b01,
          s2 = 2'b10;

SHAKE_256 PRF(.M(M),.active(active),.n_num(n_num),.clk(clk),.rst(rst),.finish(enable),.Z(b));

//when i=0 => f0
assign index_a = (n_num == 2'd1)?(({3'd0,counter_i})<<2) + (({3'd0,counter_i})<<1) : ({3'd0,counter_i})<<2; //2*i*n1=2*i*3; 2*i*n2=2*i*2
assign a_temp1 = (n_num == 2'd1)?{11'd0,b[index_a]} + {11'd0,b[index_a+11'd1]} + {11'd0,b[index_a+11'd2]} : {11'd0,b[index_a]} + {11'd0,b[index_a+11'd1]};
assign index_b = (n_num == 2'd1)? (({3'd0,counter_i})<<2) + (({3'd0,counter_i})<<1) + 11'd3 : (({3'd0,counter_i})<<2) + 11'd2; //2*i*n1+n1=2*i*3+3; //2*i*n2+n2=2*i*2+2
assign b_temp1 = (n_num == 2'd1)?{11'd0,b[index_b]} + {11'd0,b[index_b+11'd1]} + {11'd0,b[index_b+11'd2]} : {11'd0,b[index_b]} + {11'd0,b[index_b+11'd1]};

//when i=0 => f1,index+6*1;  f1,index+4*1
assign a_temp2 = (n_num == 2'd1)?{11'd0,b[index_a+11'd6]} + {11'd0,b[index_a+11'd7]} + {11'd0,b[index_a+11'd8]} : {11'd0,b[index_a+11'd4]} + {11'd0,b[index_a+11'd5]};
assign b_temp2 = (n_num == 2'd1)?{11'd0,b[index_b+11'd6]} + {11'd0,b[index_b+11'd7]} + {11'd0,b[index_b+11'd8]} : {11'd0,b[index_b+11'd4]} + {11'd0,b[index_b+11'd5]};

//when i=0 => f64,index+6*64; f64,index+4*64
assign a_temp3 = (n_num == 2'd1)?{11'd0,b[index_a+11'd384]} + {11'd0,b[index_a+11'd385]} + {11'd0,b[index_a+11'd386]} : {11'd0,b[index_a+11'd256]} + {11'd0,b[index_a+11'd257]};
assign b_temp3 = (n_num == 2'd1)?{11'd0,b[index_b+11'd384]} + {11'd0,b[index_b+11'd385]} + {11'd0,b[index_b+11'd386]} : {11'd0,b[index_b+11'd256]} + {11'd0,b[index_b+11'd257]};

//when i=0 => f65,index+6*65; f65,index+4*65
assign a_temp4 = (n_num == 2'd1)?{11'd0,b[index_a+11'd390]} + {11'd0,b[index_a+11'd391]} + {11'd0,b[index_a+11'd392]} : {11'd0,b[index_a+11'd260]} + {11'd0,b[index_a+11'd261]};
assign b_temp4 = (n_num == 2'd1)?{11'd0,b[index_b+11'd390]} + {11'd0,b[index_b+11'd391]} + {11'd0,b[index_b+11'd392]} : {11'd0,b[index_b+11'd260]} + {11'd0,b[index_b+11'd261]};

//when i=0 => f128,index+6*128; f128,index+4*128
assign a_temp5 = (n_num == 2'd1)?{11'd0,b[index_a+11'd768]} + {11'd0,b[index_a+11'd769]} + {11'd0,b[index_a+11'd770]} : {11'd0,b[index_a+11'd512]} + {11'd0,b[index_a+11'd513]};
assign b_temp5 = (n_num == 2'd1)?{11'd0,b[index_b+11'd768]} + {11'd0,b[index_b+11'd769]} + {11'd0,b[index_b+11'd770]} : {11'd0,b[index_b+11'd512]} + {11'd0,b[index_b+11'd513]};

//when i=0 => f129,index+6*129; f129,index+4*129
assign a_temp6 = (n_num == 2'd1)?{11'd0,b[index_a+11'd774]} + {11'd0,b[index_a+11'd775]} + {11'd0,b[index_a+11'd776]} : {11'd0,b[index_a+11'd516]} + {11'd0,b[index_a+11'd517]};
assign b_temp6 = (n_num == 2'd1)?{11'd0,b[index_b+11'd774]} + {11'd0,b[index_b+11'd775]} + {11'd0,b[index_b+11'd776]} : {11'd0,b[index_b+11'd516]} + {11'd0,b[index_b+11'd517]};

//when i=0 => f192,index+6*192; f192,index+4*192
assign a_temp7 = (n_num == 2'd1)?{11'd0,b[index_a+11'd1152]} + {11'd0,b[index_a+11'd1153]} + {11'd0,b[index_a+11'd1154]} : {11'd0,b[index_a+11'd768]} + {11'd0,b[index_a+11'd769]};
assign b_temp7 = (n_num == 2'd1)?{11'd0,b[index_b+11'd1152]} + {11'd0,b[index_b+11'd1153]} + {11'd0,b[index_b+11'd1154]} : {11'd0,b[index_b+11'd768]} + {11'd0,b[index_b+11'd769]};

//when i=0 => f193,index+6*193; f193,index+4*193
assign a_temp8 = (n_num == 2'd1)?{11'd0,b[index_a+11'd1158]} + {11'd0,b[index_a+11'd1159]} + {11'd0,b[index_a+11'd1160]} : {11'd0,b[index_a+11'd772]} + {11'd0,b[index_a+11'd773]};
assign b_temp8 = (n_num == 2'd1)?{11'd0,b[index_b+11'd1158]} + {11'd0,b[index_b+11'd1159]} + {11'd0,b[index_b+11'd1160]} : {11'd0,b[index_b+11'd772]} + {11'd0,b[index_b+11'd773]};

always@(posedge clk or posedge rst)begin
    if(rst)begin
        cs <= 2'd0;
        counter_i <= 8'd0;
        counter <= 8'd0;
        
    end
    else begin
        cs <= ns;
        counter_i <= ((ns == s1)&&(cs != s0))? counter_i + 8'd2: counter_i;//i=i+2
        counter <= ((ns == s1)&&(cs != s0))? counter + 8'd1: counter;//cnt=cnt+1
        

    end
end


always@(cs or enable or counter)begin
	//next state
	case(cs)
		s0: ns = (enable)? s1:s0;
		s1: ns = (counter < 8'd31)? s1:s2;
		s2: ns = s2;
        
		default: ns = s0;
	endcase	
end


always@(*)begin
	case(cs)
		s0: begin
            enw = 1'b0;
            waddr = 8'd0;
            dout = 96'd0;                
        end           
		s1: begin
            //next clk write 8 coeff         
            enw = 1'b1;
            waddr = ram_w_start_offset + counter;
            //addr 0 => coeff: 193 192 65 64 129 128 1 0
            //d=a-b
            dout[0 +:12]= (a_temp1 < b_temp1)? 12'd3329+a_temp1-b_temp1 :a_temp1-b_temp1;
            dout[12 +:12]= (a_temp2 < b_temp2)? 12'd3329+a_temp2-b_temp2 :a_temp2-b_temp2;
            dout[24 +:12]= (a_temp5 < b_temp5)? 12'd3329+a_temp5-b_temp5 :a_temp5-b_temp5;
            dout[36 +:12]= (a_temp6 < b_temp6)? 12'd3329+a_temp6-b_temp6 :a_temp6-b_temp6;
            dout[48 +:12]= (a_temp3 < b_temp3)? 12'd3329+a_temp3-b_temp3 :a_temp3-b_temp3;
            dout[60 +:12]= (a_temp4 < b_temp4)? 12'd3329+a_temp4-b_temp4 :a_temp4-b_temp4;
            dout[72 +:12]= (a_temp7 < b_temp7)? 12'd3329+a_temp7-b_temp7 :a_temp7-b_temp7;
            dout[84 +:12]= (a_temp8 < b_temp8)? 12'd3329+a_temp8-b_temp8 :a_temp8-b_temp8;
        end             
		s2: begin
            enw = 1'b0;
            waddr = 8'd0;
            dout = 96'd0;
        end
        default: begin
            enw = 1'b0;
            waddr = 8'd0;
            dout = 96'd0;
        end
    endcase
end

endmodule

//////////////////////

module Theta(input [0:1599]S,output  [0:1599]S_out);

wire A[0:4][0:4][0:63];
wire A_out[0:4][0:4][0:63];
wire C[0:4][0:63],D[0:4][0:63];

//str to state array(A[x][y][z]=S[64*(5*y+x)+z])
generate
        for(genvar zz=0;zz<64;zz=zz+1)begin: str_to_arr
                assign A[0][0][zz]=S[64*(5*0+0)+zz];
                assign A[1][0][zz]=S[64*(5*0+1)+zz];
                assign A[2][0][zz]=S[64*(5*0+2)+zz];
                assign A[3][0][zz]=S[64*(5*0+3)+zz];
                assign A[4][0][zz]=S[64*(5*0+4)+zz];

                assign A[0][1][zz]=S[64*(5*1+0)+zz];
                assign A[1][1][zz]=S[64*(5*1+1)+zz];
                assign A[2][1][zz]=S[64*(5*1+2)+zz];
                assign A[3][1][zz]=S[64*(5*1+3)+zz];
                assign A[4][1][zz]=S[64*(5*1+4)+zz];

                assign A[0][2][zz]=S[64*(5*2+0)+zz];
                assign A[1][2][zz]=S[64*(5*2+1)+zz];
                assign A[2][2][zz]=S[64*(5*2+2)+zz];
                assign A[3][2][zz]=S[64*(5*2+3)+zz];
                assign A[4][2][zz]=S[64*(5*2+4)+zz];

                assign A[0][3][zz]=S[64*(5*3+0)+zz];
                assign A[1][3][zz]=S[64*(5*3+1)+zz];
                assign A[2][3][zz]=S[64*(5*3+2)+zz];
                assign A[3][3][zz]=S[64*(5*3+3)+zz];
                assign A[4][3][zz]=S[64*(5*3+4)+zz];

                assign A[0][4][zz]=S[64*(5*4+0)+zz];
                assign A[1][4][zz]=S[64*(5*4+1)+zz];
                assign A[2][4][zz]=S[64*(5*4+2)+zz];
                assign A[3][4][zz]=S[64*(5*4+3)+zz];
                assign A[4][4][zz]=S[64*(5*4+4)+zz];
        end
endgenerate

//step1
generate
    for(genvar z0=0;z0<64;z0=z0+1)begin: step1_x0
        assign C[0][z0]=A[0][0][z0]^A[0][1][z0]^A[0][2][z0]^A[0][3][z0]^A[0][4][z0];
    end
endgenerate
generate
    for(genvar z1=0;z1<64;z1=z1+1)begin: step1_x1
        assign C[1][z1]=A[1][0][z1]^A[1][1][z1]^A[1][2][z1]^A[1][3][z1]^A[1][4][z1];
    end
endgenerate
generate
    for(genvar z2=0;z2<64;z2=z2+1)begin: step1_x2
        assign C[2][z2]=A[2][0][z2]^A[2][1][z2]^A[2][2][z2]^A[2][3][z2]^A[2][4][z2];
    end
endgenerate
generate
    for(genvar z3=0;z3<64;z3=z3+1)begin: step1_x3
        assign C[3][z3]=A[3][0][z3]^A[3][1][z3]^A[3][2][z3]^A[3][3][z3]^A[3][4][z3];
    end
endgenerate
generate
    for(genvar z4=0;z4<64;z4=z4+1)begin: step1_x4
        assign C[4][z4]=A[4][0][z4]^A[4][1][z4]^A[4][2][z4]^A[4][3][z4]^A[4][4][z4];
    end
endgenerate

//step2
assign D[0][0]=C[4][0]^C[(0+1)%5][63];
generate
     for(genvar z5=1;z5<64;z5=z5+1)begin: step2_x0
        assign D[0][z5]=C[4][z5]^C[(0+1)%5][(z5-1)%64];
    end
endgenerate

assign D[1][0]=C[(1-1)%5][0]^C[(1+1)%5][63];
generate
     for(genvar z6=1;z6<64;z6=z6+1)begin: step2_x1
        assign D[1][z6]=C[(1-1)%5][z6]^C[(1+1)%5][(z6-1)%64];
    end
endgenerate

assign D[2][0]=C[(2-1)%5][0]^C[(2+1)%5][63];
generate
     for(genvar z7=1;z7<64;z7=z7+1)begin: step2_x2
        assign D[2][z7]=C[(2-1)%5][z7]^C[(2+1)%5][(z7-1)%64];
    end
endgenerate

assign D[3][0]=C[(3-1)%5][0]^C[(3+1)%5][63];
generate
     for(genvar z8=1;z8<64;z8=z8+1)begin: step2_x3
        assign D[3][z8]=C[(3-1)%5][z8]^C[(3+1)%5][(z8-1)%64];
    end
endgenerate

assign D[4][0]=C[(4-1)%5][0]^C[(4+1)%5][63];
generate
     for(genvar z9=1;z9<64;z9=z9+1)begin: step2_x4
        assign D[4][z9]=C[(4-1)%5][z9]^C[(4+1)%5][(z9-1)%64];
    end
endgenerate

//step3
generate
        for(genvar i=0;i<64;i=i+1)begin: Lane00
                assign A_out[0][0][i]=A[0][0][i]^D[0][i];
        end
endgenerate
generate
        for(genvar i1=0;i1<64;i1=i1+1)begin: Lane10
                assign A_out[1][0][i1]=A[1][0][i1]^D[1][i1];
        end
endgenerate
generate
        for(genvar i2=0;i2<64;i2=i2+1)begin: Lane20
                assign A_out[2][0][i2]=A[2][0][i2]^D[2][i2];
        end
endgenerate
generate
        for(genvar i3=0;i3<64;i3=i3+1)begin: Lane30
                assign A_out[3][0][i3]=A[3][0][i3]^D[3][i3];
        end
endgenerate
generate
        for(genvar i4=0;i4<64;i4=i4+1)begin: Lane40
                assign A_out[4][0][i4]=A[4][0][i4]^D[4][i4];
        end
endgenerate
generate
        for(genvar i5=0;i5<64;i5=i5+1)begin: Lane01
                assign A_out[0][1][i5]=A[0][1][i5]^D[0][i5];
        end
endgenerate
generate
        for(genvar i6=0;i6<64;i6=i6+1)begin: Lane11
                assign A_out[1][1][i6]=A[1][1][i6]^D[1][i6];
        end
endgenerate
generate
        for(genvar i7=0;i7<64;i7=i7+1)begin: Lane21
                assign A_out[2][1][i7]=A[2][1][i7]^D[2][i7];
        end
endgenerate
generate
        for(genvar i8=0;i8<64;i8=i8+1)begin: Lane31
                assign A_out[3][1][i8]=A[3][1][i8]^D[3][i8];
        end
endgenerate
generate
        for(genvar i9=0;i9<64;i9=i9+1)begin: Lane41
                assign A_out[4][1][i9]=A[4][1][i9]^D[4][i9];
        end
endgenerate
generate
        for(genvar i10=0;i10<64;i10=i10+1)begin: Lane02
                assign A_out[0][2][i10]=A[0][2][i10]^D[0][i10];
        end
endgenerate
generate
        for(genvar i11=0;i11<64;i11=i11+1)begin: Lane12
                assign A_out[1][2][i11]=A[1][2][i11]^D[1][i11];
        end
endgenerate
generate
        for(genvar i12=0;i12<64;i12=i12+1)begin: Lane22
                assign A_out[2][2][i12]=A[2][2][i12]^D[2][i12];
        end
endgenerate
generate
        for(genvar i13=0;i13<64;i13=i13+1)begin: Lane32
                assign A_out[3][2][i13]=A[3][2][i13]^D[3][i13];
        end
endgenerate
generate
        for(genvar i14=0;i14<64;i14=i14+1)begin: Lane42
                assign A_out[4][2][i14]=A[4][2][i14]^D[4][i14];
        end
endgenerate
generate
        for(genvar i15=0;i15<64;i15=i15+1)begin: Lane03
                assign A_out[0][3][i15]=A[0][3][i15]^D[0][i15];
        end
endgenerate
generate
        for(genvar i16=0;i16<64;i16=i16+1)begin: Lane13
                assign A_out[1][3][i16]=A[1][3][i16]^D[1][i16];
        end
endgenerate
generate
        for(genvar i17=0;i17<64;i17=i17+1)begin: Lane23
                assign A_out[2][3][i17]=A[2][3][i17]^D[2][i17];
        end
endgenerate
generate
        for(genvar i18=0;i18<64;i18=i18+1)begin: Lane33
                assign A_out[3][3][i18]=A[3][3][i18]^D[3][i18];
        end
endgenerate
generate
        for(genvar i19=0;i19<64;i19=i19+1)begin: Lane43
                assign A_out[4][3][i19]=A[4][3][i19]^D[4][i19];
        end
endgenerate
generate
        for(genvar i20=0;i20<64;i20=i20+1)begin: Lane04
                assign A_out[0][4][i20]=A[0][4][i20]^D[0][i20];
        end
endgenerate
generate
        for(genvar i21=0;i21<64;i21=i21+1)begin: Lane14
                assign A_out[1][4][i21]=A[1][4][i21]^D[1][i21];
        end
endgenerate
generate
        for(genvar i22=0;i22<64;i22=i22+1)begin: Lane24
                assign A_out[2][4][i22]=A[2][4][i22]^D[2][i22];
        end
endgenerate
generate
        for(genvar i23=0;i23<64;i23=i23+1)begin: Lane34
                assign A_out[3][4][i23]=A[3][4][i23]^D[3][i23];
        end
endgenerate
generate
        for(genvar i24=0;i24<64;i24=i24+1)begin: Lane44
                assign A_out[4][4][i24]=A[4][4][i24]^D[4][i24];
        end
endgenerate

//Convert state array into str
generate
        for(genvar Z=0;Z<64;Z=Z+1)begin: arr_to_str

                assign S_out[Z] = A_out[0][0][Z]; 
                assign S_out[Z+64] = A_out[1][0][Z];
                assign S_out[Z+64*2] = A_out[2][0][Z];
                assign S_out[Z+64*3] = A_out[3][0][Z];
                assign S_out[Z+64*4] = A_out[4][0][Z];
        
                assign S_out[Z+64*5] = A_out[0][1][Z];       
                assign S_out[Z+64*6] = A_out[1][1][Z];
                assign S_out[Z+64*7] = A_out[2][1][Z];
                assign S_out[Z+64*8] = A_out[3][1][Z];
                assign S_out[Z+64*9] = A_out[4][1][Z];
        
                assign S_out[Z+64*10] = A_out[0][2][Z];
                assign S_out[Z+64*11] = A_out[1][2][Z];
                assign S_out[Z+64*12] = A_out[2][2][Z];
                assign S_out[Z+64*13] = A_out[3][2][Z];
                assign S_out[Z+64*14] = A_out[4][2][Z];
       
                assign S_out[Z+64*15] = A_out[0][3][Z];
                assign S_out[Z+64*16] = A_out[1][3][Z];
                assign S_out[Z+64*17] = A_out[2][3][Z];
                assign S_out[Z+64*18] = A_out[3][3][Z];
                assign S_out[Z+64*19] = A_out[4][3][Z];
        
                assign S_out[Z+64*20] = A_out[0][4][Z];
                assign S_out[Z+64*21] = A_out[1][4][Z];
                assign S_out[Z+64*22] = A_out[2][4][Z];
                assign S_out[Z+64*23] = A_out[3][4][Z];
                assign S_out[Z+64*24] = A_out[4][4][Z];
        end
endgenerate

endmodule

//////////////////////////////////

module SHAKE_256(input [0:264-1] M,
                input active, //Let stage go to s1 
                input [1:0] n_num, //1 => n1; 2 => n2
                input clk, rst,
                output reg finish,
                output reg [0:1536-1] Z);

parameter d_SIZE_1 = 1536,//B^(64n1)=8*64*3
          d_SIZE_2 = 1024,//B^(64n2)=8*64*2  
          c_SIZE = 512,
          r_SIZE = 1088, //r=b-c
          M_SIZE = 264; //256+8 (s||b)
parameter j = 818;//j=r_SIZE - (M_SIZE+4+2)

wire [0:(M_SIZE+4)-1] N;
wire [0:((M_SIZE+4)+1+j+1)-1] P;
wire [4:0] nr;
wire [0:1599] str_out;
wire [2:0] cnt;//counter+1
wire [11:0] counter_r_r_SIZE;//counter_r-r_SIZE
reg [2:0] cs,ns;
reg string_val;
reg [0:1599] str, str_temp, str_temp2;
reg [2:0] counter;  //0~n-1
reg [4:0] counter_f;//count rnds of KECCAK_p
reg [11:0] counter_r;//count times of Z=Z||Trunc_r(S)
reg [0:(r_SIZE*2)-1] Z_temp;// r*2 bits

assign N ={M,4'b1111}; //N=M||1111
assign nr = 5'd24;   //nr=24

//pad10*1(r,len(N))
assign P = {N,1'b1,{j{1'b0}},1'b1};
//
parameter n = 1;//n=len(P)/r = 1
assign cnt = counter + 3'd1;//counter+1
assign counter_r_r_SIZE = counter_r-r_SIZE;

parameter s0 = 3'b000,
          s1 = 3'b001,
          s2 = 3'b010,
          s3 = 3'b011,
          s4 = 3'b100,
          s5 = 3'b101,
          s6 = 3'b110,
          s7 = 3'b111;

KECCAK_p keccak_p( .S(str_temp),
                   .nr(nr),
                   .string_val(string_val),
                   .clk(clk), .rst(rst),
                   .S_out(str_out));

always@(posedge clk or posedge rst)begin
        if(rst)begin
            cs <= s0;
            str_temp <= 1600'd0;
            str_temp2 <= 1600'd0;
            counter <= 3'd0;
            counter_f <= 5'd0;
            counter_r <= 12'd0;
            Z_temp <= {r_SIZE*2{1'b0}};

        end
        else begin
            cs <= ns;
            //str_temp= S^(Pi||c(0))
            if(ns == s1)begin
                str_temp <= str^{P[counter+:r_SIZE],{c_SIZE{1'b0}}};
            end
            else if(ns == s4) begin
                str_temp <= str_temp2;
            end
            else begin
                str_temp <= str_temp;
            end
            
            
            //let S equal to str_out after do a S=f(S^(Pi||c(0))) and S=f(S)
            str_temp2 <= (cs == s2 || cs == s5)? str_out:str_temp2;

            counter <= (cs == s2)? counter+3'd1 : counter;
            counter_r <= (ns == s3 || ns==s6)? counter_r+r_SIZE:counter_r;//+r_SIZE
            
            //counter_f
            if((cs == s1)||(cs == s4))begin
                counter_f <= counter_f+5'd1;
            end
            else if((ns == s1) || (ns==s4))begin
                counter_f <= 5'd0;
            end
            else begin
                counter_f <= counter_f;
            end

            //Z=Z||Trunc_r(S)
            if(cs == s3 || cs == s6)begin
                Z_temp[counter_r_r_SIZE +:r_SIZE] <= str_temp2[0:r_SIZE-1];
            end
            else begin
                Z_temp[counter_r_r_SIZE +:r_SIZE] <= Z_temp[counter_r_r_SIZE +:r_SIZE];
            end

        end

end
            


always@(cs or active or counter_f or cnt or counter_r or n_num)begin
	//next stage
	case(cs)
		s0: ns = (active)? s1:s0;
		s1: ns = (counter_f== 5'd25) ? s2:s1;//S=f(S^(Pi||c(0)))
		s2: ns = (cnt == n) ? s3:s1; //counter is from 0 to n-1
        //determine if d<=|Z|
        s3: begin 
            if((n_num == 2'd1) && (counter_r >= d_SIZE_1))begin
                ns = s7;
            end
            else if((n_num == 2'd2) && (counter_r >= d_SIZE_2))begin
                ns = s7;
            end
            else begin
                ns = s4;
            end
        end
        s4: ns = (counter_f == 5'd25) ?s5:s4;//S=f(S)
        s5: ns = s6;
        //determine if d<=|Z|
        s6: begin 
            if((n_num == 2'd1) && (counter_r >= d_SIZE_1))begin
                ns = s7;
            end
            else if((n_num == 2'd2) && (counter_r >= d_SIZE_2))begin
                ns = s7;
            end
            else begin
                ns = s4;
            end
        end
        s7: ns = s7;//output
		default: ns = s0;
	endcase	
end

always@(*)begin
    case(cs)
		s0: begin
                Z = (n_num == 2'd1)? Z_temp[0:d_SIZE_1-1]: Z_temp[0:d_SIZE_2-1];
                string_val = 1'b0;
                str = 1600'd0;
                finish = 1'b0;
            end    
		s1: begin
                Z = (n_num == 2'd1)? Z_temp[0:d_SIZE_1-1]: Z_temp[0:d_SIZE_2-1];
                string_val = 1'b1;//string_val=1
                finish = 1'b0;
                if(counter==3'd0)begin
                    str = 1600'd0;
                end
                else begin
                    str = str_temp2;
                end
            end
		s2: begin
                Z = (n_num == 2'd1)? Z_temp[0:d_SIZE_1-1]: Z_temp[0:d_SIZE_2-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
                finish = 1'b0;
            end
        s3: begin
                Z = (n_num == 2'd1)? Z_temp[0:d_SIZE_1-1]: Z_temp[0:d_SIZE_2-1];
                string_val = 1'b0;
                str = str_temp2;
                finish = 1'b0;
            end
        s4: begin
                Z = (n_num == 2'd1)? Z_temp[0:d_SIZE_1-1]: Z_temp[0:d_SIZE_2-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
                finish = 1'b0;
            end
        s5: begin
                Z = (n_num == 2'd1)? Z_temp[0:d_SIZE_1-1]: Z_temp[0:d_SIZE_2-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
                finish = 1'b0;
            end
        s6: begin
                Z = (n_num == 2'd1)? Z_temp[0:d_SIZE_1-1]: Z_temp[0:d_SIZE_2-1];
                string_val = 1'b0;
                str = str_temp2;
                finish = 1'b0;
            end
        s7: begin
                //Z=Trunc_d(Z)
                Z = (n_num == 2'd1)? Z_temp[0:d_SIZE_1-1]: Z_temp[0:d_SIZE_2-1];
                string_val = 1'b0;
                str = str_temp2;
                finish = 1'b1; //finish = 1
            end
		default: begin
                Z = {d_SIZE_1{1'd0}};
                string_val = 1'b0;
                str = str_temp2;
                finish = 1'b0;
            end
    endcase
end

endmodule

////////////////////////////////////

module SHAKE_128(input [0:272-1] M,
                input active, //Let stage go to s1 
                input clk, rst,
                output reg finish,
                output reg [0:3072-1] Z);

parameter d_SIZE = 3072,//256*12=3072
          c_SIZE = 256,
          r_SIZE = 1344, //r=b-c
          M_SIZE = 272; //256+8+8
parameter j = 1066;//j=r_SIZE - (M_SIZE+4+2)

wire [0:(M_SIZE+4)-1] N;
wire [0:((M_SIZE+4)+1+j+1)-1] P;
wire [4:0] nr;
wire [0:1599] str_out;
wire [2:0] cnt;//counter+1
wire [12:0] counter_r_r_SIZE;//counter_r-r_SIZE
reg [2:0] cs,ns;
reg string_val;
reg [0:1599] str, str_temp, str_temp2;
reg [2:0] counter;  //0~n-1
reg [4:0] counter_f;//count rnds of KECCAK_p
reg [12:0] counter_r;//count times of Z=Z||Trunc_r(S)
reg [0:(r_SIZE*3)-1] Z_temp;// r*3 bits (r*3 > 3072)

assign N ={M,4'b1111}; //N=M||1111
assign nr = 5'd24;   //nr=24

//pad10*1(r,len(N))
assign P = {N,1'b1,{j{1'b0}},1'b1};
//
parameter n = 1;//n=len(P)/r = 1
assign cnt = counter + 3'd1;//counter+1
assign counter_r_r_SIZE = counter_r-r_SIZE;

parameter s0 = 3'b000,
          s1 = 3'b001,
          s2 = 3'b010,
          s3 = 3'b011,
          s4 = 3'b100,
          s5 = 3'b101,
          s6 = 3'b110,
          s7 = 3'b111;

KECCAK_p keccak_p( .S(str_temp),
                   .nr(nr),
                   .string_val(string_val),
                   .clk(clk), .rst(rst),
                   .S_out(str_out));

always@(posedge clk or posedge rst)begin
        if(rst)begin
            cs <= s0;
            str_temp <= 1600'd0;
            str_temp2 <= 1600'd0;
            counter <= 3'd0;
            counter_f <= 5'd0;
            counter_r <= 13'd0;
            Z_temp <= {r_SIZE*3{1'b0}};

        end
        else begin
            cs <= ns;
            //str_temp= S^(Pi||c(0))
            if(ns == s1)begin
                str_temp <= str^{P[counter+:r_SIZE],{c_SIZE{1'b0}}};
            end
            else if(ns == s4) begin
                str_temp <= str_temp2;
            end
            else begin
                str_temp <= str_temp;
            end
            
            
            //let S equal to str_out after do a S=f(S^(Pi||c(0))) and S=f(S)
            str_temp2 <= (cs == s2 || cs == s5)? str_out:str_temp2;

            counter <= (cs == s2)? counter+3'd1 : counter;
            counter_r <= (ns == s3 || ns==s6)? counter_r+r_SIZE:counter_r;//+r_SIZE
            
            //counter_f
            if((cs == s1)||(cs == s4))begin
                counter_f <= counter_f+5'd1;
            end
            else if((ns == s1) || (ns==s4))begin
                counter_f <= 5'd0;
            end
            else begin
                counter_f <= counter_f;
            end

            //Z=Z||Trunc_r(S)
            if(cs == s3 || cs == s6)begin
                Z_temp[counter_r_r_SIZE +:r_SIZE] <= str_temp2[0:r_SIZE-1];
            end
            else begin
                Z_temp[counter_r_r_SIZE +:r_SIZE] <= Z_temp[counter_r_r_SIZE +:r_SIZE];
            end

        end

end
            


always@(cs or active or counter_f or cnt or counter_r)begin
	//next stage
	case(cs)
		s0: ns = (active)? s1:s0;
		s1: ns = (counter_f== 5'd25) ? s2:s1;//S=f(S^(Pi||c(0)))
		s2: ns = (cnt == n) ? s3:s1; //counter is from 0 to n-1
        s3: ns = (counter_r >= d_SIZE)?s7:s4;//determine if d<=|Z|
        s4: ns = (counter_f == 5'd25) ?s5:s4;//S=f(S)
        s5: ns = s6;
        s6: ns = (counter_r >= d_SIZE)?s7:s4;//determine if d<=|Z|
        s7: ns = s7;//output
		default: ns = s0;
	endcase	
end

always@(cs or counter or str_temp2)begin
    case(cs)
		s0: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b0;
                str = 1600'd0;
                finish = 1'b0;
            end    
		s1: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                finish = 1'b0;
                if(counter==3'd0)begin
                    str = 1600'd0;
                end
                else begin
                    str = str_temp2;
                end
            end
		s2: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
                finish = 1'b0;
            end
        s3: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b0;
                str = str_temp2;
                finish = 1'b0;
            end
        s4: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
                finish = 1'b0;
            end
        s5: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
                finish = 1'b0;
            end
        s6: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b0;
                str = str_temp2;
                finish = 1'b0;
            end
        s7: begin
                Z = Z_temp[0:d_SIZE-1]; //Z=Trunc_d(Z)
                string_val = 1'b0;
                str = str_temp2;
                finish = 1'b1; //finish = 1
            end
		default: begin
                Z = {d_SIZE{1'd0}};
                string_val = 1'b0;
                str = str_temp2;
                finish = 1'b0;
            end
    endcase
end

endmodule

//////////////////////////////////////

module SHA3_512(input [0:256-1] M,
                input active, //Let stage go to s1 
                input clk, rst,
                output reg [0:512-1] Z);

parameter d_SIZE = 512,
          c_SIZE = 1024,
          r_SIZE = 576, //r=b-c
          M_SIZE = 256;
parameter j = 316;//j=r_SIZE - (M_SIZE+2+2)

wire [0:(M_SIZE+2)-1] N;
wire [0:((M_SIZE+2)+1+j+1)-1] P;
wire [4:0] nr;
wire [0:1599] str_out;
wire [2:0] cnt;//counter+1
wire [11:0] counter_r_r_SIZE;//counter_r-r_SIZE
reg [2:0] cs,ns;
reg string_val;
reg [0:1599] str, str_temp, str_temp2;
reg [2:0] counter;  //0~n-1
reg [4:0] counter_f;//count rnds of KECCAK_p
reg [11:0] counter_r;//count times of Z=Z||Trunc_r(S)
reg [0:(r_SIZE*2)-1] Z_temp;// r*2 bits

assign N ={M,2'b01}; //N=M||01
assign nr = 5'd24;   //nr=24

//pad10*1(r,len(N))
assign P = {N,1'b1,{j{1'b0}},1'b1};
//
parameter n = 1;//n=len(P)/r = (256+2+1+316+1)/576 = 1
assign cnt = counter + 3'd1;//counter+1
assign counter_r_r_SIZE = counter_r-r_SIZE;

parameter s0 = 3'b000,
          s1 = 3'b001,
          s2 = 3'b010,
          s3 = 3'b011,
          s4 = 3'b100,
          s5 = 3'b101,
          s6 = 3'b110,
          s7 = 3'b111;

KECCAK_p keccak_p( .S(str_temp),
                   .nr(nr),
                   .string_val(string_val),
                   .clk(clk), .rst(rst),
                   .S_out(str_out));

always@(posedge clk or posedge rst)begin
        if(rst)begin
            cs <= s0;
            str_temp <= 1600'd0;
            str_temp2 <= 1600'd0;
            counter <= 3'd0;
            counter_f <= 5'd0;
            counter_r <= 12'd0;
            Z_temp <= {r_SIZE*3{1'b0}};

        end
        else begin
            cs <= ns;
            //str_temp= S^(Pi||c(0))
            if(ns == s1)begin
                str_temp <= str^{P[counter+:r_SIZE],{c_SIZE{1'b0}}};
            end
            else if(ns == s4) begin
                str_temp <= str_temp2;
            end
            else begin
                str_temp <= str_temp;
            end
            
            
            //let S equal to str_out after do a S=f(S^(Pi||c(0))) and S=f(S)
            str_temp2 <= (cs == s2 || cs == s5)? str_out:str_temp2;

            counter <= (cs == s2)? counter+3'd1 : counter;
            counter_r <= (ns == s3 || ns==s6)? counter_r+r_SIZE:counter_r;//+r_SIZE
            
            //counter_f
            if((cs == s1)||(cs == s4))begin
                counter_f <= counter_f+5'd1;
            end
            else if((ns == s1) || (ns==s4))begin
                counter_f <= 5'd0;
            end
            else begin
                counter_f <= counter_f;
            end

            //Z=Z||Trunc_r(S)
            if(cs == s3 || cs == s6)begin
                Z_temp[counter_r_r_SIZE +:r_SIZE] <= str_temp2[0:r_SIZE-1];
            end
            else begin
                Z_temp[counter_r_r_SIZE +:r_SIZE] <= Z_temp[counter_r_r_SIZE +:r_SIZE];
            end

        end

end
            


always@(cs or active or counter_f or cnt or counter_r)begin
	//next stage
	case(cs)
		s0: ns = (active)? s1:s0;
		s1: ns = (counter_f== 5'd25) ? s2:s1;//S=f(S^(Pi||c(0)))
		s2: ns = (cnt == n) ? s3:s1; //counter is from 0 to n-1
        s3: ns = (counter_r >= d_SIZE)?s7:s4;//determine if d<=|Z|
        s4: ns = (counter_f == 5'd25) ?s5:s4;//S=f(S)
        s5: ns = s6;
        s6: ns = (counter_r >= d_SIZE)?s7:s4;//determine if d<=|Z|
        s7: ns = s7;//output
		default: ns = s0;
	endcase	
end

always@(cs or counter or str_temp2)begin
    case(cs)
		s0: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b0;
                str = 1600'd0;
            end    
		s1: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                if(counter==3'd0)begin
                    str = 1600'd0;
                end
                else begin
                    str = str_temp2;
                end
            end
		s2: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
            end
        s3: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b0;
                str = str_temp2;
            end
        s4: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
            end
        s5: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
            end
        s6: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b0;
                str = str_temp2;
            end
        s7: begin
                Z = Z_temp[0:d_SIZE-1]; //Z=Trunc_d(Z)
                string_val = 1'b0;
                str = str_temp2;
            end
		default: begin
                Z = {d_SIZE{1'd0}};
                string_val = 1'b0;
                str = str_temp2;
            end
    endcase
end

endmodule

///////////////////////////////

module Rnd(input [0:1599]S,
        input [7:0]ir,
        output [0:1599]S_out);

wire [0:1599] S_out1,S_out2,S_out3,S_out4;
wire A_out[0:4][0:4][0:63];
wire Aout4[0:4][0:4][0:63];
reg [0:63]RC;
reg [0:7]R;
reg [0:8]R2, R2_temp;
reg [7:0]t;
integer j,i;

Theta theta(.S(S),.S_out(S_out1));
Rho rho(.S(S_out1),.S_out(S_out2));
Pi pi(.S(S_out2),.S_out(S_out3));
Chi chi(.S(S_out3),.S_out(S_out4));

always@(*)begin
    RC = 64'd0;
   
    for(j=0;j<=6;j=j+1)begin
        t = j+(ir+(ir<<2)+(ir<<1)); //t=j+7*ir
        R = 8'b10000000;

        if(t==0)begin   //if t%255=0 return 1, but tmax<255 => t=0 => 0%255=0
            RC[(2**j)-1] = 1;
        end
        else begin
            for(i=1;i<=t;i=i+1)begin
                R2 = {1'b0,{R}};
                R2_temp = R2;
                R2_temp[0]=R2[0]^R2[8];
                R2_temp[4]=R2[4]^R2[8];
                R2_temp[5]=R2[5]^R2[8];
                R2_temp[6]=R2[6]^R2[8];
                R = R2_temp[0:7];
            end
            RC[(2**j)-1] = R[0];
        end
    end
   
end

//str to state array(A[x][y][z]=S[64*(5*y+x)+z])
generate
        for(genvar zz=0;zz<64;zz=zz+1)begin: str_to_arr
                assign Aout4[0][0][zz]=S_out4[64*(5*0+0)+zz];
                assign Aout4[1][0][zz]=S_out4[64*(5*0+1)+zz];
                assign Aout4[2][0][zz]=S_out4[64*(5*0+2)+zz];
                assign Aout4[3][0][zz]=S_out4[64*(5*0+3)+zz];
                assign Aout4[4][0][zz]=S_out4[64*(5*0+4)+zz];

                assign Aout4[0][1][zz]=S_out4[64*(5*1+0)+zz];
                assign Aout4[1][1][zz]=S_out4[64*(5*1+1)+zz];
                assign Aout4[2][1][zz]=S_out4[64*(5*1+2)+zz];
                assign Aout4[3][1][zz]=S_out4[64*(5*1+3)+zz];
                assign Aout4[4][1][zz]=S_out4[64*(5*1+4)+zz];

                assign Aout4[0][2][zz]=S_out4[64*(5*2+0)+zz];
                assign Aout4[1][2][zz]=S_out4[64*(5*2+1)+zz];
                assign Aout4[2][2][zz]=S_out4[64*(5*2+2)+zz];
                assign Aout4[3][2][zz]=S_out4[64*(5*2+3)+zz];
                assign Aout4[4][2][zz]=S_out4[64*(5*2+4)+zz];

                assign Aout4[0][3][zz]=S_out4[64*(5*3+0)+zz];
                assign Aout4[1][3][zz]=S_out4[64*(5*3+1)+zz];
                assign Aout4[2][3][zz]=S_out4[64*(5*3+2)+zz];
                assign Aout4[3][3][zz]=S_out4[64*(5*3+3)+zz];
                assign Aout4[4][3][zz]=S_out4[64*(5*3+4)+zz];

                assign Aout4[0][4][zz]=S_out4[64*(5*4+0)+zz];
                assign Aout4[1][4][zz]=S_out4[64*(5*4+1)+zz];
                assign Aout4[2][4][zz]=S_out4[64*(5*4+2)+zz];
                assign Aout4[3][4][zz]=S_out4[64*(5*4+3)+zz];
                assign Aout4[4][4][zz]=S_out4[64*(5*4+4)+zz];
        end
endgenerate

//A_out[0][0][z1]=Aout4[0][0][z1] ^ RC[z1];
generate
        for(genvar i0=0;i0<64;i0=i0+1)begin: Lane0_0
                assign A_out[0][0][i0]=Aout4[0][0][i0] ^ RC[i0];
        end
endgenerate

//A_out[x][y][z]=Aout4[x][y][z]
generate
        for(genvar i1=0;i1<64;i1=i1+1)begin: otherLane
                assign A_out[1][0][i1]=Aout4[1][0][i1];
                assign A_out[2][0][i1]=Aout4[2][0][i1];
                assign A_out[3][0][i1]=Aout4[3][0][i1];
                assign A_out[4][0][i1]=Aout4[4][0][i1];

                assign A_out[0][1][i1]=Aout4[0][1][i1];
                assign A_out[1][1][i1]=Aout4[1][1][i1];
                assign A_out[2][1][i1]=Aout4[2][1][i1];
                assign A_out[3][1][i1]=Aout4[3][1][i1];
                assign A_out[4][1][i1]=Aout4[4][1][i1];

                assign A_out[0][2][i1]=Aout4[0][2][i1];
                assign A_out[1][2][i1]=Aout4[1][2][i1];
                assign A_out[2][2][i1]=Aout4[2][2][i1];
                assign A_out[3][2][i1]=Aout4[3][2][i1];
                assign A_out[4][2][i1]=Aout4[4][2][i1];

                assign A_out[0][3][i1]=Aout4[0][3][i1];
                assign A_out[1][3][i1]=Aout4[1][3][i1];
                assign A_out[2][3][i1]=Aout4[2][3][i1];
                assign A_out[3][3][i1]=Aout4[3][3][i1];
                assign A_out[4][3][i1]=Aout4[4][3][i1];

                assign A_out[0][4][i1]=Aout4[0][4][i1];
                assign A_out[1][4][i1]=Aout4[1][4][i1];
                assign A_out[2][4][i1]=Aout4[2][4][i1];
                assign A_out[3][4][i1]=Aout4[3][4][i1];
                assign A_out[4][4][i1]=Aout4[4][4][i1];
        end
endgenerate

//Convert state array into str
generate
        for(genvar Z=0;Z<64;Z=Z+1)begin: arr_to_str

                assign S_out[Z] = A_out[0][0][Z]; 
                assign S_out[Z+64] = A_out[1][0][Z];
                assign S_out[Z+64*2] = A_out[2][0][Z];
                assign S_out[Z+64*3] = A_out[3][0][Z];
                assign S_out[Z+64*4] = A_out[4][0][Z];
        
                assign S_out[Z+64*5] = A_out[0][1][Z];       
                assign S_out[Z+64*6] = A_out[1][1][Z];
                assign S_out[Z+64*7] = A_out[2][1][Z];
                assign S_out[Z+64*8] = A_out[3][1][Z];
                assign S_out[Z+64*9] = A_out[4][1][Z];
        
                assign S_out[Z+64*10] = A_out[0][2][Z];
                assign S_out[Z+64*11] = A_out[1][2][Z];
                assign S_out[Z+64*12] = A_out[2][2][Z];
                assign S_out[Z+64*13] = A_out[3][2][Z];
                assign S_out[Z+64*14] = A_out[4][2][Z];
       
                assign S_out[Z+64*15] = A_out[0][3][Z];
                assign S_out[Z+64*16] = A_out[1][3][Z];
                assign S_out[Z+64*17] = A_out[2][3][Z];
                assign S_out[Z+64*18] = A_out[3][3][Z];
                assign S_out[Z+64*19] = A_out[4][3][Z];
        
                assign S_out[Z+64*20] = A_out[0][4][Z];
                assign S_out[Z+64*21] = A_out[1][4][Z];
                assign S_out[Z+64*22] = A_out[2][4][Z];
                assign S_out[Z+64*23] = A_out[3][4][Z];
                assign S_out[Z+64*24] = A_out[4][4][Z];
        end
endgenerate

endmodule

////////////////////////////////

module Rho(input [0:1599]S,output  [0:1599]S_out);

wire A[0:4][0:4][0:63];
wire A_out[0:4][0:4][0:63];



//str to state array(A[x][y][z]=S[64*(5*y+x)+z])
generate
        for(genvar zz=0;zz<64;zz=zz+1)begin: str_to_arr
                assign A[0][0][zz]=S[64*(5*0+0)+zz];
                assign A[1][0][zz]=S[64*(5*0+1)+zz];
                assign A[2][0][zz]=S[64*(5*0+2)+zz];
                assign A[3][0][zz]=S[64*(5*0+3)+zz];
                assign A[4][0][zz]=S[64*(5*0+4)+zz];

                assign A[0][1][zz]=S[64*(5*1+0)+zz];
                assign A[1][1][zz]=S[64*(5*1+1)+zz];
                assign A[2][1][zz]=S[64*(5*1+2)+zz];
                assign A[3][1][zz]=S[64*(5*1+3)+zz];
                assign A[4][1][zz]=S[64*(5*1+4)+zz];

                assign A[0][2][zz]=S[64*(5*2+0)+zz];
                assign A[1][2][zz]=S[64*(5*2+1)+zz];
                assign A[2][2][zz]=S[64*(5*2+2)+zz];
                assign A[3][2][zz]=S[64*(5*2+3)+zz];
                assign A[4][2][zz]=S[64*(5*2+4)+zz];

                assign A[0][3][zz]=S[64*(5*3+0)+zz];
                assign A[1][3][zz]=S[64*(5*3+1)+zz];
                assign A[2][3][zz]=S[64*(5*3+2)+zz];
                assign A[3][3][zz]=S[64*(5*3+3)+zz];
                assign A[4][3][zz]=S[64*(5*3+4)+zz];

                assign A[0][4][zz]=S[64*(5*4+0)+zz];
                assign A[1][4][zz]=S[64*(5*4+1)+zz];
                assign A[2][4][zz]=S[64*(5*4+2)+zz];
                assign A[3][4][zz]=S[64*(5*4+3)+zz];
                assign A[4][4][zz]=S[64*(5*4+4)+zz];
        end
endgenerate



generate
        for(genvar z=0;z<64;z=z+1)begin: Lane00
                assign A_out[0][0][z] = A[0][0][z];
        end
endgenerate

/*
x=1,y=0
for t=0~23 begin
A_out[x][y][z] = A[x][y][(z-(t+1)*(t+2)/2) % 64]
(x,y)=(y,(2x+3y)%5)
end
*/

//t=0
assign A_out[1][0][0] = A[1][0][63];
generate
        for(genvar i=1;i<64;i=i+1)begin: t0
                assign A_out[1][0][i] = A[1][0][(i-(0+1)*(0+2)/2) % 64];
        end
endgenerate

//t=1
assign A_out[0][2][0] = A[0][2][61];
assign A_out[0][2][1] = A[0][2][62];
assign A_out[0][2][2] = A[0][2][63];
generate
        for(genvar i1=3;i1<64;i1=i1+1)begin: t1
                assign A_out[0][2][i1] = A[0][2][(i1-(1+1)*(1+2)/2) % 64];
        end
endgenerate

//t=2
assign A_out[2][1][0] = A[2][1][58];
assign A_out[2][1][1] = A[2][1][59];
assign A_out[2][1][2] = A[2][1][60];
assign A_out[2][1][3] = A[2][1][61];
assign A_out[2][1][4] = A[2][1][62];
assign A_out[2][1][5] = A[2][1][63];
generate
        for(genvar i2=6;i2<64;i2=i2+1)begin: t2
                assign A_out[2][1][i2] = A[2][1][(i2-(2+1)*(2+2)/2) % 64];
        end
endgenerate

//t=3
generate
        for(genvar ii3=0;ii3<10;ii3=ii3+1)begin: t3_1
                assign A_out[1][2][ii3] = A[1][2][54+ii3];
        end
endgenerate
generate
        for(genvar i3=10;i3<64;i3=i3+1)begin: t3_2
                assign A_out[1][2][i3] = A[1][2][(i3-(3+1)*(3+2)/2) % 64];
        end
endgenerate

//t=4
generate
        for(genvar ii4=0;ii4<15;ii4=ii4+1)begin: t4_1
                assign A_out[2][3][ii4] = A[2][3][49+ii4];
        end
endgenerate
generate
        for(genvar i4=15;i4<64;i4=i4+1)begin: t4_2
                assign A_out[2][3][i4] = A[2][3][(i4-(4+1)*(4+2)/2) % 64];
        end
endgenerate

//t=5
generate
        for(genvar ii5=0;ii5<21;ii5=ii5+1)begin: t5_1
                assign A_out[3][3][ii5] = A[3][3][43+ii5];
        end
endgenerate
generate
        for(genvar i5=21;i5<64;i5=i5+1)begin: t5_2
                assign A_out[3][3][i5] = A[3][3][(i5-(5+1)*(5+2)/2) % 64];
        end
endgenerate

//t=6
generate
        for(genvar ii6=0;ii6<28;ii6=ii6+1)begin: t6_1
                assign A_out[3][0][ii6] = A[3][0][36+ii6];
        end
endgenerate
generate
        for(genvar i6=28;i6<64;i6=i6+1)begin: t6_2
                assign A_out[3][0][i6] = A[3][0][(i6-(6+1)*(6+2)/2) % 64];
        end
endgenerate

//t=7
generate
        for(genvar ii7=0;ii7<36;ii7=ii7+1)begin: t7_1
                assign A_out[0][1][ii7] = A[0][1][28+ii7];
        end
endgenerate
generate
        for(genvar i7=36;i7<64;i7=i7+1)begin: t7_2
                assign A_out[0][1][i7] = A[0][1][(i7-(7+1)*(7+2)/2) % 64];
        end
endgenerate

//t=8
generate
        for(genvar ii8=0;ii8<45;ii8=ii8+1)begin: t8_1
                assign A_out[1][3][ii8] = A[1][3][19+ii8];
        end
endgenerate
generate
        for(genvar i8=45;i8<64;i8=i8+1)begin: t8_2
                assign A_out[1][3][i8] = A[1][3][(i8-(8+1)*(8+2)/2) % 64];
        end
endgenerate

//t=9
generate
        for(genvar ii9=0;ii9<55;ii9=ii9+1)begin: t9_1
                assign A_out[3][1][ii9] = A[3][1][9+ii9];
        end
endgenerate
generate
        for(genvar i9=55;i9<64;i9=i9+1)begin: t9_2
                assign A_out[3][1][i9] = A[3][1][(i9-(9+1)*(9+2)/2) % 64];
        end
endgenerate

//t=10
assign A_out[1][4][0] = A[1][4][62];
assign A_out[1][4][1] = A[1][4][63];
generate
        for(genvar i10=2;i10<64;i10=i10+1)begin: t10
                assign A_out[1][4][i10] = A[1][4][i10-2];
        end
endgenerate

//t=11
generate
        for(genvar ii11=0;ii11<14;ii11=ii11+1)begin: t11_1
                assign A_out[4][4][ii11] = A[4][4][50+ii11];
        end
endgenerate
generate
        for(genvar i11=14;i11<64;i11=i11+1)begin: t11_2
                assign A_out[4][4][i11] = A[4][4][i11-14];
        end
endgenerate

//t=12
generate
        for(genvar ii12=0;ii12<27;ii12=ii12+1)begin: t12_1
                assign A_out[4][0][ii12] = A[4][0][37+ii12];
        end
endgenerate
generate
        for(genvar i12=27;i12<64;i12=i12+1)begin: t12_2
                assign A_out[4][0][i12] = A[4][0][i12-27];
        end
endgenerate

//t=13
generate
        for(genvar ii13=0;ii13<41;ii13=ii13+1)begin: t13_1
                assign A_out[0][3][ii13] = A[0][3][23+ii13];
        end
endgenerate
generate
        for(genvar i13=41;i13<64;i13=i13+1)begin: t13_2
                assign A_out[0][3][i13] = A[0][3][i13-41];
        end
endgenerate

//t=14
generate
        for(genvar ii14=0;ii14<56;ii14=ii14+1)begin: t14_1
                assign A_out[3][4][ii14] = A[3][4][8+ii14];
        end
endgenerate
generate
        for(genvar i14=56;i14<64;i14=i14+1)begin: t14_2
                assign A_out[3][4][i14] = A[3][4][i14-56];
        end
endgenerate

//t=15
generate
        for(genvar ii15=0;ii15<8;ii15=ii15+1)begin: t15_1
                assign A_out[4][3][ii15] = A[4][3][56+ii15];
        end
endgenerate
generate
        for(genvar i15=8;i15<64;i15=i15+1)begin: t15_2
                assign A_out[4][3][i15] = A[4][3][i15-8];
        end
endgenerate

//t=16
generate
        for(genvar ii16=0;ii16<25;ii16=ii16+1)begin: t16_1
                assign A_out[3][2][ii16] = A[3][2][39+ii16];
        end
endgenerate
generate
        for(genvar i16=25;i16<64;i16=i16+1)begin: t16_2
                assign A_out[3][2][i16] = A[3][2][i16-25];
        end
endgenerate

//t=17
generate
        for(genvar ii17=0;ii17<43;ii17=ii17+1)begin: t17_1
                assign A_out[2][2][ii17] = A[2][2][21+ii17];
        end
endgenerate
generate
        for(genvar i17=43;i17<64;i17=i17+1)begin: t17_2
                assign A_out[2][2][i17] = A[2][2][i17-43];
        end
endgenerate

//t=18
generate
        for(genvar ii18=0;ii18<62;ii18=ii18+1)begin: t18_1
                assign A_out[2][0][ii18] = A[2][0][2+ii18];
        end
endgenerate
generate
        for(genvar i18=62;i18<64;i18=i18+1)begin: t18_2
                assign A_out[2][0][i18] = A[2][0][i18-62];
        end
endgenerate

//t=19
generate
        for(genvar ii19=0;ii19<18;ii19=ii19+1)begin: t19_1
                assign A_out[0][4][ii19] = A[0][4][46+ii19];
        end
endgenerate
generate
        for(genvar i19=18;i19<64;i19=i19+1)begin: t19_2
                assign A_out[0][4][i19] = A[0][4][i19-18];
        end
endgenerate

//t=20
generate
        for(genvar ii20=0;ii20<39;ii20=ii20+1)begin: t20_1
                assign A_out[4][2][ii20] = A[4][2][25+ii20];
        end
endgenerate
generate
        for(genvar i20=39;i20<64;i20=i20+1)begin: t20_2
                assign A_out[4][2][i20] = A[4][2][i20-39];
        end
endgenerate

//t=21
generate
        for(genvar ii21=0;ii21<61;ii21=ii21+1)begin: t21_1
                assign  A_out[2][4][ii21] = A[2][4][3+ii21];
        end
endgenerate
generate
        for(genvar i21=61;i21<64;i21=i21+1)begin: t21_2
                assign  A_out[2][4][i21] = A[2][4][i21-61];
        end
endgenerate

//t=22
generate
        for(genvar ii22=0;ii22<20;ii22=ii22+1)begin: t22_1
                assign  A_out[4][1][ii22] = A[4][1][44+ii22];
        end
endgenerate
generate
        for(genvar i22=20;i22<64;i22=i22+1)begin: t22_2
                assign  A_out[4][1][i22] = A[4][1][i22-20];
        end
endgenerate

//t=23
generate
        for(genvar ii23=0;ii23<44;ii23=ii23+1)begin: t23_1
                assign  A_out[1][1][ii23] = A[1][1][20+ii23];
        end
endgenerate
generate
        for(genvar i23=44;i23<64;i23=i23+1)begin: t23_2
                assign  A_out[1][1][i23] = A[1][1][i23-44];
        end
endgenerate


//Convert state array into str
generate
        for(genvar Z=0;Z<64;Z=Z+1)begin: arr_to_str

                assign S_out[Z] = A_out[0][0][Z]; 
                assign S_out[Z+64] = A_out[1][0][Z];
                assign S_out[Z+64*2] = A_out[2][0][Z];
                assign S_out[Z+64*3] = A_out[3][0][Z];
                assign S_out[Z+64*4] = A_out[4][0][Z];
        
                assign S_out[Z+64*5] = A_out[0][1][Z];       
                assign S_out[Z+64*6] = A_out[1][1][Z];
                assign S_out[Z+64*7] = A_out[2][1][Z];
                assign S_out[Z+64*8] = A_out[3][1][Z];
                assign S_out[Z+64*9] = A_out[4][1][Z];
        
                assign S_out[Z+64*10] = A_out[0][2][Z];
                assign S_out[Z+64*11] = A_out[1][2][Z];
                assign S_out[Z+64*12] = A_out[2][2][Z];
                assign S_out[Z+64*13] = A_out[3][2][Z];
                assign S_out[Z+64*14] = A_out[4][2][Z];
       
                assign S_out[Z+64*15] = A_out[0][3][Z];
                assign S_out[Z+64*16] = A_out[1][3][Z];
                assign S_out[Z+64*17] = A_out[2][3][Z];
                assign S_out[Z+64*18] = A_out[3][3][Z];
                assign S_out[Z+64*19] = A_out[4][3][Z];
        
                assign S_out[Z+64*20] = A_out[0][4][Z];
                assign S_out[Z+64*21] = A_out[1][4][Z];
                assign S_out[Z+64*22] = A_out[2][4][Z];
                assign S_out[Z+64*23] = A_out[3][4][Z];
                assign S_out[Z+64*24] = A_out[4][4][Z];
        end
endgenerate

endmodule

///////////////////////////////////////////

module Pi(input [0:1599]S,output  [0:1599]S_out);

wire A[0:4][0:4][0:63];
wire A_out[0:4][0:4][0:63];

//str to state array(A[x][y][z]=S[64*(5*y+x)+z])
generate
        for(genvar zz=0;zz<64;zz=zz+1)begin: str_to_arr
                assign A[0][0][zz]=S[64*(5*0+0)+zz];
                assign A[1][0][zz]=S[64*(5*0+1)+zz];
                assign A[2][0][zz]=S[64*(5*0+2)+zz];
                assign A[3][0][zz]=S[64*(5*0+3)+zz];
                assign A[4][0][zz]=S[64*(5*0+4)+zz];

                assign A[0][1][zz]=S[64*(5*1+0)+zz];
                assign A[1][1][zz]=S[64*(5*1+1)+zz];
                assign A[2][1][zz]=S[64*(5*1+2)+zz];
                assign A[3][1][zz]=S[64*(5*1+3)+zz];
                assign A[4][1][zz]=S[64*(5*1+4)+zz];

                assign A[0][2][zz]=S[64*(5*2+0)+zz];
                assign A[1][2][zz]=S[64*(5*2+1)+zz];
                assign A[2][2][zz]=S[64*(5*2+2)+zz];
                assign A[3][2][zz]=S[64*(5*2+3)+zz];
                assign A[4][2][zz]=S[64*(5*2+4)+zz];

                assign A[0][3][zz]=S[64*(5*3+0)+zz];
                assign A[1][3][zz]=S[64*(5*3+1)+zz];
                assign A[2][3][zz]=S[64*(5*3+2)+zz];
                assign A[3][3][zz]=S[64*(5*3+3)+zz];
                assign A[4][3][zz]=S[64*(5*3+4)+zz];

                assign A[0][4][zz]=S[64*(5*4+0)+zz];
                assign A[1][4][zz]=S[64*(5*4+1)+zz];
                assign A[2][4][zz]=S[64*(5*4+2)+zz];
                assign A[3][4][zz]=S[64*(5*4+3)+zz];
                assign A[4][4][zz]=S[64*(5*4+4)+zz];
        end
endgenerate

//A_out[x][y][z]=A[(x+3*y)%5][x][z];
generate
        for(genvar i=0;i<64;i=i+1)begin: Lane00
                assign A_out[0][0][i]=A[(0+3*0)%5][0][i];
        end
endgenerate
generate
        for(genvar i1=0;i1<64;i1=i1+1)begin: Lane10
                assign A_out[1][0][i1]=A[(1+3*0)%5][1][i1];
        end
endgenerate
generate
        for(genvar i2=0;i2<64;i2=i2+1)begin: Lane20
                assign A_out[2][0][i2]=A[(2+3*0)%5][2][i2];
        end
endgenerate
generate
        for(genvar i3=0;i3<64;i3=i3+1)begin: Lane30
                assign A_out[3][0][i3]=A[(3+3*0)%5][3][i3];
        end
endgenerate
generate
        for(genvar i4=0;i4<64;i4=i4+1)begin: Lane40
                assign A_out[4][0][i4]=A[(4+3*0)%5][4][i4];
        end
endgenerate
generate
        for(genvar i5=0;i5<64;i5=i5+1)begin: Lane01
                assign A_out[0][1][i5]=A[(0+3*1)%5][0][i5];
        end
endgenerate
generate
        for(genvar i6=0;i6<64;i6=i6+1)begin: Lane11
                assign A_out[1][1][i6]=A[(1+3*1)%5][1][i6];
        end
endgenerate
generate
        for(genvar i7=0;i7<64;i7=i7+1)begin: Lane21
                assign A_out[2][1][i7]=A[(2+3*1)%5][2][i7];
        end
endgenerate
generate
        for(genvar i8=0;i8<64;i8=i8+1)begin: Lane31
                assign A_out[3][1][i8]=A[(3+3*1)%5][3][i8];
        end
endgenerate
generate
        for(genvar i9=0;i9<64;i9=i9+1)begin: Lane41
                assign A_out[4][1][i9]=A[(4+3*1)%5][4][i9];
        end
endgenerate
generate
        for(genvar i10=0;i10<64;i10=i10+1)begin: Lane02
                assign A_out[0][2][i10]=A[(0+3*2)%5][0][i10];
        end
endgenerate
generate
        for(genvar i11=0;i11<64;i11=i11+1)begin: Lane12
                assign A_out[1][2][i11]=A[(1+3*2)%5][1][i11];
        end
endgenerate
generate
        for(genvar i12=0;i12<64;i12=i12+1)begin: Lane22
                assign A_out[2][2][i12]=A[(2+3*2)%5][2][i12];
        end
endgenerate
generate
        for(genvar i13=0;i13<64;i13=i13+1)begin: Lane32
                assign A_out[3][2][i13]=A[(3+3*2)%5][3][i13];
        end
endgenerate
generate
        for(genvar i14=0;i14<64;i14=i14+1)begin: Lane42
                assign A_out[4][2][i14]=A[(4+3*2)%5][4][i14];
        end
endgenerate
generate
        for(genvar i15=0;i15<64;i15=i15+1)begin: Lane03
                assign A_out[0][3][i15]=A[(0+3*3)%5][0][i15];
        end
endgenerate
generate
        for(genvar i16=0;i16<64;i16=i16+1)begin: Lane13
                assign A_out[1][3][i16]=A[(1+3*3)%5][1][i16];
        end
endgenerate
generate
        for(genvar i17=0;i17<64;i17=i17+1)begin: Lane23
                assign A_out[2][3][i17]=A[(2+3*3)%5][2][i17];
        end
endgenerate
generate
        for(genvar i18=0;i18<64;i18=i18+1)begin: Lane33
                assign A_out[3][3][i18]=A[(3+3*3)%5][3][i18];
        end
endgenerate
generate
        for(genvar i19=0;i19<64;i19=i19+1)begin: Lane43
                assign A_out[4][3][i19]=A[(4+3*3)%5][4][i19];
        end
endgenerate
generate
        for(genvar i20=0;i20<64;i20=i20+1)begin: Lane04
                assign A_out[0][4][i20]=A[(0+3*4)%5][0][i20];
        end
endgenerate
generate
        for(genvar i21=0;i21<64;i21=i21+1)begin: Lane14
                assign A_out[1][4][i21]=A[(1+3*4)%5][1][i21];
        end
endgenerate
generate
        for(genvar i22=0;i22<64;i22=i22+1)begin: Lane24
                assign A_out[2][4][i22]=A[(2+3*4)%5][2][i22];
        end
endgenerate
generate
        for(genvar i23=0;i23<64;i23=i23+1)begin: Lane34
                assign A_out[3][4][i23]=A[(3+3*4)%5][3][i23];
        end
endgenerate
generate
        for(genvar i24=0;i24<64;i24=i24+1)begin: Lane44
                assign A_out[4][4][i24]=A[(4+3*4)%5][4][i24];
        end
endgenerate

//Convert state array into str
generate
        for(genvar Z=0;Z<64;Z=Z+1)begin: arr_to_str

                assign S_out[Z] = A_out[0][0][Z]; 
                assign S_out[Z+64] = A_out[1][0][Z];
                assign S_out[Z+64*2] = A_out[2][0][Z];
                assign S_out[Z+64*3] = A_out[3][0][Z];
                assign S_out[Z+64*4] = A_out[4][0][Z];
        
                assign S_out[Z+64*5] = A_out[0][1][Z];       
                assign S_out[Z+64*6] = A_out[1][1][Z];
                assign S_out[Z+64*7] = A_out[2][1][Z];
                assign S_out[Z+64*8] = A_out[3][1][Z];
                assign S_out[Z+64*9] = A_out[4][1][Z];
        
                assign S_out[Z+64*10] = A_out[0][2][Z];
                assign S_out[Z+64*11] = A_out[1][2][Z];
                assign S_out[Z+64*12] = A_out[2][2][Z];
                assign S_out[Z+64*13] = A_out[3][2][Z];
                assign S_out[Z+64*14] = A_out[4][2][Z];
       
                assign S_out[Z+64*15] = A_out[0][3][Z];
                assign S_out[Z+64*16] = A_out[1][3][Z];
                assign S_out[Z+64*17] = A_out[2][3][Z];
                assign S_out[Z+64*18] = A_out[3][3][Z];
                assign S_out[Z+64*19] = A_out[4][3][Z];
        
                assign S_out[Z+64*20] = A_out[0][4][Z];
                assign S_out[Z+64*21] = A_out[1][4][Z];
                assign S_out[Z+64*22] = A_out[2][4][Z];
                assign S_out[Z+64*23] = A_out[3][4][Z];
                assign S_out[Z+64*24] = A_out[4][4][Z];
        end
endgenerate

endmodule

////////////////////////////////

`ifndef KECCAK_P
`define KECCAK_P

module KECCAK_p(input [0:1599] S,
                input [4:0] nr,
                input string_val, //Let stage go to s1
                input clk, rst,
                output reg [0:1599] S_out);

wire [7:0]ir;
reg [1:0]cs,ns;
reg [4:0]counter;
reg [0:1599]A;
reg [0:1599]A_temp;
wire [0:1599]A_out;

integer x1,y1,z1, x2,y2,z2;

parameter s0 = 2'b00,
          s1 = 2'b01,
          s2 = 2'b10,
          s3 = 2'b11;

//call Rnd
assign ir = {3'd0,{counter}}-8'd1;
Rnd rnd(.S(A_temp),.ir(ir),.S_out(A_out));

always@(posedge clk or posedge rst)begin
        if(rst)begin
                cs <= s0;
                counter <= 5'd1; //set to 1
                
                A_temp <= 1600'd0;
        end
        else begin
                cs <= ns;
                //ns=s2?A => A_temp
                A_temp <= (ns ==s2)? A:A_temp;
                
                //s2=> a Rnd ; In s3 => counter=24 => ir not change
                if((cs == s2) && (counter != 5'd24))begin
                        counter <= counter+5'd1;
                end
                else if(ns == s0)begin
                        counter <= 5'd1;
                end
                else begin
                        counter <= counter;
                end

        end
end

always@(cs or nr or counter or string_val)begin
	//next state
	case(cs)
		s0: ns = (string_val)? s1:s0;
		s1: ns = s2;
		s2: ns = (counter>=nr) ? s3:s2; //nr=24
                s3: ns = s0;
		default: ns = s0;
	endcase	
end

always@(*)begin
        //state output
	case(cs)
		s0: begin
                        S_out = A_out;     
                        A=A_temp;                      
                end
                //string to A
		s1:  begin
                        S_out = A_out;
                        A=S;
                                        
                end
                //a round => Rnd; total 24 round(cycle)
		s2: begin
                        S_out = A_out;                         
                        A=A_out;
                                     
                end
                //output final value
                s3: begin
                        S_out = A_out;
                        A=A_out;
                end
		default:  begin
                        S_out = 1600'd0;
                        A=1600'd0;
                end
        endcase
end


endmodule

`endif

/////////////////////////////////////

module Chi(input [0:1599]S,output  [0:1599]S_out);

wire A[0:4][0:4][0:63];
wire A_out[0:4][0:4][0:63];

//str to state array(A[x][y][z]=S[64*(5*y+x)+z])
generate
        for(genvar zz=0;zz<64;zz=zz+1)begin: str_to_arr
                assign A[0][0][zz]=S[64*(5*0+0)+zz];
                assign A[1][0][zz]=S[64*(5*0+1)+zz];
                assign A[2][0][zz]=S[64*(5*0+2)+zz];
                assign A[3][0][zz]=S[64*(5*0+3)+zz];
                assign A[4][0][zz]=S[64*(5*0+4)+zz];

                assign A[0][1][zz]=S[64*(5*1+0)+zz];
                assign A[1][1][zz]=S[64*(5*1+1)+zz];
                assign A[2][1][zz]=S[64*(5*1+2)+zz];
                assign A[3][1][zz]=S[64*(5*1+3)+zz];
                assign A[4][1][zz]=S[64*(5*1+4)+zz];

                assign A[0][2][zz]=S[64*(5*2+0)+zz];
                assign A[1][2][zz]=S[64*(5*2+1)+zz];
                assign A[2][2][zz]=S[64*(5*2+2)+zz];
                assign A[3][2][zz]=S[64*(5*2+3)+zz];
                assign A[4][2][zz]=S[64*(5*2+4)+zz];

                assign A[0][3][zz]=S[64*(5*3+0)+zz];
                assign A[1][3][zz]=S[64*(5*3+1)+zz];
                assign A[2][3][zz]=S[64*(5*3+2)+zz];
                assign A[3][3][zz]=S[64*(5*3+3)+zz];
                assign A[4][3][zz]=S[64*(5*3+4)+zz];

                assign A[0][4][zz]=S[64*(5*4+0)+zz];
                assign A[1][4][zz]=S[64*(5*4+1)+zz];
                assign A[2][4][zz]=S[64*(5*4+2)+zz];
                assign A[3][4][zz]=S[64*(5*4+3)+zz];
                assign A[4][4][zz]=S[64*(5*4+4)+zz];
        end
endgenerate

//A_out[x][y][z]= A[x][y][z] ^ ((A[(x+1)%5][y][z] ^ 1) & A[(x+2)%5][y][z])
generate
        for(genvar i=0;i<64;i=i+1)begin: Lane00
                assign A_out[0][0][i]=A[0][0][i] ^ ((A[(0+1)%5][0][i] ^ 1'b1) & A[(0+2)%5][0][i]);
        end
endgenerate
generate
        for(genvar i1=0;i1<64;i1=i1+1)begin: Lane10
                assign A_out[1][0][i1]=A[1][0][1] ^ ((A[(1+1)%5][0][i1] ^ 1'b1) & A[(1+2)%5][0][i1]);
        end
endgenerate
generate
        for(genvar i2=0;i2<64;i2=i2+1)begin: Lane20
                assign A_out[2][0][i2]=A[2][0][i2] ^ ((A[(2+1)%5][0][i2] ^ 1'b1) & A[(2+2)%5][0][i2]);
        end
endgenerate
generate
        for(genvar i3=0;i3<64;i3=i3+1)begin: Lane30
                assign A_out[3][0][i3]=A[3][0][i3] ^ ((A[(3+1)%5][0][i3] ^ 1'b1) & A[(3+2)%5][0][i3]);
        end
endgenerate
generate
        for(genvar i4=0;i4<64;i4=i4+1)begin: Lane40
                assign A_out[4][0][i4]=A[4][0][i4] ^ ((A[(4+1)%5][0][i4] ^ 1'b1) & A[(4+2)%5][0][i4]);
        end
endgenerate
generate
        for(genvar i5=0;i5<64;i5=i5+1)begin: Lane01
                assign A_out[0][1][i5]=A[0][1][i5] ^ ((A[(0+1)%5][1][i5] ^ 1'b1) & A[(0+2)%5][1][i5]);
        end
endgenerate
generate
        for(genvar i6=0;i6<64;i6=i6+1)begin: Lane11
                assign A_out[1][1][i6]=A[1][1][i6] ^ ((A[(1+1)%5][1][i6] ^ 1'b1) & A[(1+2)%5][1][i6]);
        end
endgenerate
generate
        for(genvar i7=0;i7<64;i7=i7+1)begin: Lane21
                assign A_out[2][1][i7]=A[2][1][i7] ^ ((A[(2+1)%5][1][i7] ^ 1'b1) & A[(2+2)%5][1][i7]);
        end
endgenerate
generate
        for(genvar i8=0;i8<64;i8=i8+1)begin: Lane31
                assign A_out[3][1][i8]=A[3][1][i8] ^ ((A[(3+1)%5][1][i8] ^ 1'b1) & A[(3+2)%5][1][i8]);
        end
endgenerate
generate
        for(genvar i9=0;i9<64;i9=i9+1)begin: Lane41
                assign A_out[4][1][i9]=A[4][1][i9] ^ ((A[(4+1)%5][1][i9] ^ 1'b1) & A[(4+2)%5][1][i9]);
        end
endgenerate
generate
        for(genvar i10=0;i10<64;i10=i10+1)begin: Lane02
                assign A_out[0][2][i10]=A[0][2][i10] ^ ((A[(0+1)%5][2][i10] ^ 1'b1) & A[(0+2)%5][2][i10]);
        end
endgenerate
generate
        for(genvar i11=0;i11<64;i11=i11+1)begin: Lane12
                assign A_out[1][2][i11]=A[1][2][i11] ^ ((A[(1+1)%5][2][i11] ^ 1'b1) & A[(1+2)%5][2][i11]);
        end
endgenerate
generate
        for(genvar i12=0;i12<64;i12=i12+1)begin: Lane22
                assign A_out[2][2][i12]=A[2][2][i12] ^ ((A[(2+1)%5][2][i12] ^ 1'b1) & A[(2+2)%5][2][i12]);
        end
endgenerate
generate
        for(genvar i13=0;i13<64;i13=i13+1)begin: Lane32
                assign A_out[3][2][i13]=A[3][2][i13] ^ ((A[(3+1)%5][2][i13] ^ 1'b1) & A[(3+2)%5][2][i13]);
        end
endgenerate
generate
        for(genvar i14=0;i14<64;i14=i14+1)begin: Lane42
                assign A_out[4][2][i14]=A[4][2][i14] ^ ((A[(4+1)%5][2][i14] ^ 1'b1) & A[(4+2)%5][2][i14]);
        end
endgenerate
generate
        for(genvar i15=0;i15<64;i15=i15+1)begin: Lane03
                assign A_out[0][3][i15]=A[0][3][i15] ^ ((A[(0+1)%5][3][i15] ^ 1'b1) & A[(0+2)%5][3][i15]);
        end
endgenerate
generate
        for(genvar i16=0;i16<64;i16=i16+1)begin: Lane13
                assign A_out[1][3][i16]=A[1][3][i16] ^ ((A[(1+1)%5][3][i16] ^ 1'b1) & A[(1+2)%5][3][i16]);
        end
endgenerate
generate
        for(genvar i17=0;i17<64;i17=i17+1)begin: Lane23
                assign A_out[2][3][i17]=A[2][3][i17] ^ ((A[(2+1)%5][3][i17] ^ 1'b1) & A[(2+2)%5][3][i17]);
        end
endgenerate
generate
        for(genvar i18=0;i18<64;i18=i18+1)begin: Lane33
                assign A_out[3][3][i18]=A[3][3][i18] ^ ((A[(3+1)%5][3][i18] ^ 1'b1) & A[(3+2)%5][3][i18]);
        end
endgenerate
generate
        for(genvar i19=0;i19<64;i19=i19+1)begin: Lane43
                assign A_out[4][3][i19]=A[4][3][i19] ^ ((A[(4+1)%5][3][i19] ^ 1'b1) & A[(4+2)%5][3][i19]);
        end
endgenerate
generate
        for(genvar i20=0;i20<64;i20=i20+1)begin: Lane04
                assign A_out[0][4][i20]=A[0][4][i20] ^ ((A[(0+1)%5][4][i20] ^ 1'b1) & A[(0+2)%5][4][i20]); 
        end
endgenerate
generate
        for(genvar i21=0;i21<64;i21=i21+1)begin: Lane14
                assign A_out[1][4][i21]=A[1][4][i21] ^ ((A[(1+1)%5][4][i21] ^ 1'b1) & A[(1+2)%5][4][i21]);
        end
endgenerate
generate
        for(genvar i22=0;i22<64;i22=i22+1)begin: Lane24
                assign A_out[2][4][i22]=A[2][4][i22] ^ ((A[(2+1)%5][4][i22] ^ 1'b1) & A[(2+2)%5][4][i22]);
        end
endgenerate
generate
        for(genvar i23=0;i23<64;i23=i23+1)begin: Lane34
                assign A_out[3][4][i23]=A[3][4][i23] ^ ((A[(3+1)%5][4][i23] ^ 1'b1) & A[(3+2)%5][4][i23]);
        end
endgenerate
generate
        for(genvar i24=0;i24<64;i24=i24+1)begin: Lane44
                assign A_out[4][4][i24]=A[4][4][i24] ^ ((A[(4+1)%5][4][i24] ^ 1'b1) & A[(4+2)%5][4][i24]);
        end
endgenerate

//Convert state array into str
generate
        for(genvar Z=0;Z<64;Z=Z+1)begin: arr_to_str

                assign S_out[Z] = A_out[0][0][Z]; 
                assign S_out[Z+64] = A_out[1][0][Z];
                assign S_out[Z+64*2] = A_out[2][0][Z];
                assign S_out[Z+64*3] = A_out[3][0][Z];
                assign S_out[Z+64*4] = A_out[4][0][Z];
        
                assign S_out[Z+64*5] = A_out[0][1][Z];       
                assign S_out[Z+64*6] = A_out[1][1][Z];
                assign S_out[Z+64*7] = A_out[2][1][Z];
                assign S_out[Z+64*8] = A_out[3][1][Z];
                assign S_out[Z+64*9] = A_out[4][1][Z];
        
                assign S_out[Z+64*10] = A_out[0][2][Z];
                assign S_out[Z+64*11] = A_out[1][2][Z];
                assign S_out[Z+64*12] = A_out[2][2][Z];
                assign S_out[Z+64*13] = A_out[3][2][Z];
                assign S_out[Z+64*14] = A_out[4][2][Z];
       
                assign S_out[Z+64*15] = A_out[0][3][Z];
                assign S_out[Z+64*16] = A_out[1][3][Z];
                assign S_out[Z+64*17] = A_out[2][3][Z];
                assign S_out[Z+64*18] = A_out[3][3][Z];
                assign S_out[Z+64*19] = A_out[4][3][Z];
        
                assign S_out[Z+64*20] = A_out[0][4][Z];
                assign S_out[Z+64*21] = A_out[1][4][Z];
                assign S_out[Z+64*22] = A_out[2][4][Z];
                assign S_out[Z+64*23] = A_out[3][4][Z];
                assign S_out[Z+64*24] = A_out[4][4][Z];
        end
endgenerate

endmodule

/////////////////////////////////////////

module A_generator(  input [0:272-1] M, //256+8+8
                    input [7:0] ram_w_start_offset, 
                    input clk,rst, active,
                    output reg enw,
                    output reg [7:0] waddr,
                    output reg [95:0] dout);

wire [11:0] d1,d2,d3,d4,d5,d6,d7,d8;
wire [11:0] i_0,i_1,i_2,i2_0,i2_1,i2_2,i3_0,i3_1,i3_2,i4_0,i4_1,i4_2;
wire [3072-1:0] b;
wire enable;
reg [1:0] cs,ns;
reg [7:0]counter;
reg [11:0] i;

parameter s0 = 2'b00,
          s1 = 2'b01,
          s2 = 2'b10;

SHAKE_128 XOF(.M(M),.active(active),.clk(clk),.rst(rst),.finish(enable),.Z(b));

assign i_0 = i<<3;//i_0=i*8
assign i_1 = (i+12'd1)<<3;//i_1=(i+1)*8
assign i_2 = (i+12'd2)<<3;//i_2=(i+2)*8
assign i2_0 = (i+(12'd3 << 5))<<3;//i2_0=(i+3*32)*8
assign i2_1 = (i+(12'd3 << 5)+12'd1)<<3;//i_1=(i+3*32+1)*8
assign i2_2 = (i+(12'd3 << 5)+12'd2)<<3;//i_2=(i+3*32+2)*8
assign i3_0 = (i+(12'd3 << 6))<<3;//i_0=(i+3*64)*8
assign i3_1 = (i+(12'd3 << 6)+12'd1)<<3;//i_1=(i+3*64+1)*8
assign i3_2 = (i+(12'd3 << 6)+12'd2)<<3;//i_2=(i+3*64+2)*8
assign i4_0 = (i+(12'd3 << 6)+(12'd3 << 5))<<3;//i_0=(i+3*96)*8
assign i4_1 = (i+(12'd3 << 6)+(12'd3 << 5)+12'd1)<<3;//i_1=(i+3*96+1)*8
assign i4_2 = (i+(12'd3 << 6)+(12'd3 << 5)+12'd2)<<3;//i_2=(i+3*96+2)*8

//when i=0 => d1=a0, d2=a1
assign d1 = {4'd0, b[i_0 +:8]} + (({8'd0, b[i_1+:4]})<<8);//d1=b[i]+256(b[i+1] mod+ 16)
assign d2 = ({4'd0, b[i_1+:8]}>>4) + ({4'd0, b[i_2+:8]}<<4);//d2=b[i+1]/16 + b[i+2]*16

//when i=0 => d3=a64, d4=a65
assign d3 = {4'd0, b[i2_0 +:8]} + (({8'd0, b[i2_1+:4]})<<8);
assign d4 = ({4'd0, b[i2_1+:8]}>>4) + ({4'd0, b[i2_2+:8]}<<4);

//when i=0 => d5=a128, d4=a129
assign d5 = {4'd0, b[i3_0 +:8]} + (({8'd0, b[i3_1+:4]})<<8);
assign d6 = ({4'd0, b[i3_1+:8]}>>4) + ({4'd0, b[i3_2+:8]}<<4);

//when i=0 => d7=a192, d8=a193
assign d7 = {4'd0, b[i4_0 +:8]} + (({8'd0, b[i4_1+:4]})<<8);
assign d8 = ({4'd0, b[i4_1+:8]}>>4) + ({4'd0, b[i4_2+:8]}<<4);

always@(posedge clk or posedge rst)begin
    if(rst)begin
        cs <= 2'd0;
        counter <= 8'd0;
        i <= 12'd0;
    end
    else begin
        cs <= ns;
        counter <= ((ns == s1)&&(cs != s0))? counter + 8'd1: counter;
        i <= ((ns == s1)&&(cs != s0))? i+12'd3: i; //i=i+3

    end
end

always@(cs or enable or counter)begin
	//next state
	case(cs)
		s0: ns = (enable)? s1:s0;
		s1: ns =(counter < 8'd31)? s1:s2;
		s2: ns = s2;
		default: ns = s0;
	endcase	
end

//output
always@(cs or d1 or d2 or d3 or d4 or d5 or d6 or d7 or d8 or counter or ram_w_start_offset)begin
	case(cs)
		s0: begin
            enw = 1'b0;
            waddr = 8'd0;
            dout = 96'd0;                
        end           
		s1: begin
            //next clk write 8 coeff
            enw = 1'b1; //enw=1
            waddr = ram_w_start_offset + counter;
            //addr 0 => coeff: 193 192 65 64 129 128 1 0
            dout[0 +:12]=(d1 >= 12'd3329)? {1'b0,{d1[10:0]}}:d1;
            dout[12 +:12]=(d2 >= 12'd3329)? {1'b0,{d2[10:0]}}:d2;
            dout[24 +:12]=(d5 >= 12'd3329)? {1'b0,{d5[10:0]}}:d5;
            dout[36 +:12]=(d6 >= 12'd3329)? {1'b0,{d6[10:0]}}:d6;
            dout[48 +:12]=(d3 >= 12'd3329)? {1'b0,{d3[10:0]}}:d3;
            dout[60 +:12]=(d4 >= 12'd3329)? {1'b0,{d4[10:0]}}:d4;
            dout[72 +:12]=(d7 >= 12'd3329)? {1'b0,{d7[10:0]}}:d7;
            dout[84 +:12]=(d8 >= 12'd3329)? {1'b0,{d8[10:0]}}:d8;
                       
        end                
        s2: begin
            enw = 1'b0;
            waddr = 8'd0;
            dout = 96'd0;                     
        end
		default:  begin
            enw = 1'b0;
            waddr = 8'd0;
            dout = 96'd0;                    
        end
        endcase
end

endmodule

///////////////////////////////////////////
