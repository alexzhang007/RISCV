//Author  : AlexZhang (cgalexzhang@sina.com)
//Date    : 01-06-2020
//Comment : Integer and Float-point register file
//          if the following decoded instructions are not conflicted with the load destination register, the fetch is not stall
//          support 4 outstanding request to memory.
module RVRegisterFile (
input               sclk                 ,
input               rstn                 ,
input      [31:0]   PC                   ,
input      [7:0]    dec2regf_instr_main  ,
input      [7:0]    dec2regf_instr_func  ,
input      [4:0]    dec2regf_instr_rs1   ,
input      [4:0]    dec2regf_instr_rs2   ,
input      [4:0]    dec2regf_instr_rd    ,
input      [31:0]   dec2regf_instr_immd  ,
output reg [31:0]   regf2isq_regval_rs1  , //register_file to issue_queue register source 1 data
output reg [31:0]   regf2isq_regval_rs2  , //register_file to issue_queue register source 2 data
output reg [4:0]    regf2isq_instr_rd    , //register_file to issue_queue destination register pipelined
output reg [7:0]    regf2isq_instr_func  ,
output reg [31:0]   regf2isq_instr_immd  ,
output reg          regf2pc_jmp_en       ,
output reg          regf2pc_stall_en     ,

input               mem2regf_req_ready   ,
output reg [31:0]   regf2mem_req_addr    ,
output reg [31:0]   regf2mem_req_data    ,
output reg [1:0]    regf2mem_req_type    , // 2'b01- write, 2'b10- read
output reg          regf2mem_req_valid   , 
output reg [3:0]    regf2mem_req_len     , // 4'h0- 4 byte
output reg [3:0]    regf2mem_req_mask    , // to support byte store
output reg [4:0]    regf2mem_req_cid     , // here use the register id

input      [4:0]    mem2regf_rsp_cid     ,
input      [31:0]   mem2regf_rsp_data    ,
input               mem2regf_rsp_vld     ,
output              regf2mem_rsp_ready   ,
             
input               rob2regf_wr_en       ,
input      [5:0]    rob2regf_wr_addr     , //the high bit is indiate float or integer purpose register file
input      [31:0]   rob2regf_wr_data     
);

`include "RVParameters.vh"

//integer purpose register file
reg [31:0]  x0_zero ;  //hardware connects to zero
reg [31:0]  x1_ra   ;  //return address register
reg [31:0]  x2_sp   ;  //stack pointer register
reg [31:0]  x3_gp   ;  //global pointer register
reg [31:0]  x4_tp   ;  //thread point register
reg [31:0]  x5_t0   ;  //temporary variable 0  
reg [31:0]  x6_t1   ;  //temporary variable 0  
reg [31:0]  x7_t2   ;  //temporary variable 0  
reg [31:0]  x8_s0fp ;  //saved register0 / frame register
reg [31:0]  x9_s1   ;  //saved register 1
reg [31:0]  x10_a0  ;  //function parameter 
reg [31:0]  x11_a1  ;  //function return 
reg [31:0]  x12_a2  ;  //function parameter 
reg [31:0]  x13_a3  ;  //function parameter 
reg [31:0]  x14_a4  ;  //function parameter 
reg [31:0]  x15_a5  ;  //function parameter 
reg [31:0]  x16_a6  ;  //function parameter 
reg [31:0]  x17_a7  ;  //function parameter 
reg [31:0]  x18_s2  ;  //reserved register
reg [31:0]  x19_s3  ;  //reserved register
reg [31:0]  x20_s4  ;  //reserved register
reg [31:0]  x21_s5  ;  //reserved register
reg [31:0]  x22_s6  ;  //reserved register
reg [31:0]  x23_s7  ;  //reserved register
reg [31:0]  x24_s8  ;  //reserved register
reg [31:0]  x25_s9  ;  //reserved register
reg [31:0]  x26_s10 ;  //reserved register
reg [31:0]  x27_s11 ;  //reserved register
reg [31:0]  x28_t3  ;  //temporary register
reg [31:0]  x29_t4  ;  //temporary register
reg [31:0]  x30_t5  ;  //temporary register
reg [31:0]  x31_t6  ;  //temporary register

reg [31:0]  f0_ft0  ; //float point temporary register
reg [31:0]  f1_ft1  ; //float point temporary register
reg [31:0]  f2_ft2  ; //float point temporary register
reg [31:0]  f3_ft3  ; //float point temporary register
reg [31:0]  f4_ft4  ; //float point temporary register
reg [31:0]  f5_ft5  ; //float point temporary register
reg [31:0]  f6_ft6  ; //float point temporary register
reg [31:0]  f7_ft7  ; //float point temporary register
reg [31:0]  f8_fs0  ; //float point reserved  register
reg [31:0]  f9_fs1  ; //float point reserved  register
reg [31:0]  f10_fa0 ; //float point parameter register
reg [31:0]  f11_fa1 ; //float point return value
reg [31:0]  f12_fa2 ; //float point parameter register
reg [31:0]  f13_fa3 ; //float point parameter register
reg [31:0]  f14_fa4 ; //float point parameter register
reg [31:0]  f15_fa5 ; //float point parameter register
reg [31:0]  f16_fa6 ; //float point parameter register
reg [31:0]  f17_fa7 ; //float point parameter register
reg [31:0]  f18_fs2 ; //float point reserved register
reg [31:0]  f19_fs3 ; //float point reserved register
reg [31:0]  f20_fs4 ; //float point reserved register
reg [31:0]  f21_fs5 ; //float point reserved register
reg [31:0]  f22_fs6 ; //float point reserved register
reg [31:0]  f23_fs7 ; //float point reserved register
reg [31:0]  f24_fs8 ; //float point reserved register
reg [31:0]  f25_fs9 ; //float point reserved register
reg [31:0]  f26_fs10; //float point reserved register
reg [31:0]  f27_fs11; //float point reserved register
reg [31:0]  f28_ft8 ; //float point temporary register
reg [31:0]  f29_ft9 ; //float point temporary register
reg [31:0]  f30_ft10; //float point temporary register
reg [31:0]  f31_ft11; //float point temporary register

wire load_immd_direct ;
wire jmp_ret_addr_save;

always @(posedge sclk or negedge rstn)
  if (~rstn)
    x0_zero  <= 32'b0;  //hardware connects to zero
    x1_ra    <= 32'b0;  //return address register
    x2_sp    <= 32'b0;  //stack pointer register
    x3_gp    <= 32'b0;  //global pointer register
    x4_tp    <= 32'b0;  //thread point register
    x5_t0    <= 32'b0;  //temporary variable 0  
    x6_t1    <= 32'b0;  //temporary variable 0  
    x7_t2    <= 32'b0;  //temporary variable 0  
    x8_s0fp  <= 32'b0;  //saved register0 / frame register
    x9_s1    <= 32'b0;  //saved register 1
    x10_a0   <= 32'b0;  //function parameter 
    x11_a1   <= 32'b0;  //function return 
    x12_a2   <= 32'b0;  //function parameter 
    x13_a3   <= 32'b0;  //function parameter 
    x14_a4   <= 32'b0;  //function parameter 
    x15_a5   <= 32'b0;  //function parameter 
    x16_a6   <= 32'b0;  //function parameter 
    x17_a7   <= 32'b0;  //function parameter 
    x18_s2   <= 32'b0;  //reserved register
    x19_s3   <= 32'b0;  //reserved register
    x20_s4   <= 32'b0;  //reserved register
    x21_s5   <= 32'b0;  //reserved register
    x22_s6   <= 32'b0;  //reserved register
    x23_s7   <= 32'b0;  //reserved register
    x24_s8   <= 32'b0;  //reserved register
    x25_s9   <= 32'b0;  //reserved register
    x26_s10  <= 32'b0;  //reserved register
    x27_s11  <= 32'b0;  //reserved register
    x28_t3   <= 32'b0;  //temporary register
    x29_t4   <= 32'b0;  //temporary register
    x30_t5   <= 32'b0;  //temporary register
    x31_t6   <= 32'b0;  //temporary register

    f0_ft0   <= 32'b0; //float point temporary register
    f1_ft1   <= 32'b0; //float point temporary register
    f2_ft2   <= 32'b0; //float point temporary register
    f3_ft3   <= 32'b0; //float point temporary register
    f4_ft4   <= 32'b0; //float point temporary register
    f5_ft5   <= 32'b0; //float point temporary register
    f6_ft6   <= 32'b0; //float point temporary register
    f7_ft7   <= 32'b0; //float point temporary register
    f8_fs0   <= 32'b0; //float point reserved  register
    f9_fs1   <= 32'b0; //float point reserved  register
    f10_fa0  <= 32'b0; //float point parameter register
    f11_fa1  <= 32'b0; //float point return value
    f12_fa2  <= 32'b0; //float point parameter register
    f13_fa3  <= 32'b0; //float point parameter register
    f14_fa4  <= 32'b0; //float point parameter register
    f15_fa5  <= 32'b0; //float point parameter register
    f16_fa6  <= 32'b0; //float point parameter register
    f17_fa7  <= 32'b0; //float point parameter register
    f18_fs2  <= 32'b0; //float point reserved register
    f19_fs3  <= 32'b0; //float point reserved register
    f20_fs4  <= 32'b0; //float point reserved register
    f21_fs5  <= 32'b0; //float point reserved register
    f22_fs6  <= 32'b0; //float point reserved register
    f23_fs7  <= 32'b0; //float point reserved register
    f24_fs8  <= 32'b0; //float point reserved register
    f25_fs9  <= 32'b0; //float point reserved register
    f26_fs10 <= 32'b0; //float point reserved register
    f27_fs11 <= 32'b0; //float point reserved register
    f28_ft8  <= 32'b0; //float point temporary register
    f29_ft9  <= 32'b0; //float point temporary register
    f30_ft10 <= 32'b0; //float point temporary register
    f31_ft11 <= 32'b0; //float point temporary register
  end else begin  
    //SW will make sure the load immediate, jump save, read response from memory, rob retire up request are not happend at same time. 
    if (rob2regf_wr_en) begin 
      if (rob2regf_wr_addr[5]) begin  //float point register file
        case (rob2regf_wr_addr[4:0])
           5'b0_0000 : f0_ft0    <= rob2regf_wr_data; //FIXME : tie to 0
           5'b0_0001 : f1_ft1    <= rob2regf_wr_data; 
           5'b0_0010 : f2_ft2    <= rob2regf_wr_data; 
           5'b0_0011 : f3_ft3    <= rob2regf_wr_data; 
           5'b0_0100 : f4_ft4    <= rob2regf_wr_data; 
           5'b0_0101 : f5_ft5    <= rob2regf_wr_data; 
           5'b0_0110 : f6_ft6    <= rob2regf_wr_data; 
           5'b0_0111 : f7_ft7    <= rob2regf_wr_data; 
           5'b0_1000 : f8_fs0    <= rob2regf_wr_data; 
           5'b0_1001 : f9_fs1    <= rob2regf_wr_data; 
           5'b0_1010 : f10_fa0   <= rob2regf_wr_data; 
           5'b0_1011 : f11_fa1   <= rob2regf_wr_data; 
           5'b0_1100 : f12_fa2   <= rob2regf_wr_data; 
           5'b0_1101 : f13_fa3   <= rob2regf_wr_data; 
           5'b0_1110 : f14_fa4   <= rob2regf_wr_data; 
           5'b0_1111 : f15_fa5   <= rob2regf_wr_data; 
           5'b1_0000 : f16_fa6   <= rob2regf_wr_data; 
           5'b1_0001 : f17_fa7   <= rob2regf_wr_data; 
           5'b1_0010 : f18_fs2   <= rob2regf_wr_data; 
           5'b1_0011 : f19_fs3   <= rob2regf_wr_data; 
           5'b1_0100 : f20_fs4   <= rob2regf_wr_data; 
           5'b1_0101 : f21_fs5   <= rob2regf_wr_data; 
           5'b1_0110 : f22_fs6   <= rob2regf_wr_data; 
           5'b1_0111 : f23_fs7   <= rob2regf_wr_data; 
           5'b1_1000 : f24_fs8   <= rob2regf_wr_data; 
           5'b1_1001 : f25_fs9   <= rob2regf_wr_data; 
           5'b1_1010 : f26_fs10  <= rob2regf_wr_data; 
           5'b1_1011 : f27_fs11  <= rob2regf_wr_data; 
           5'b1_1100 : f28_ft8   <= rob2regf_wr_data; 
           5'b1_1101 : f29_ft9   <= rob2regf_wr_data; 
           5'b1_1110 : f30_ft10  <= rob2regf_wr_data; 
           5'b1_1111 : f31_ft11  <= rob2regf_wr_data; 
        endcase
      end else begin //general purpose register files
        case (rob2regf_wr_addr[4:0])
           5'b0_0001 : x1_ra    <= rob2regf_wr_data; 
           5'b0_0010 : x2_sp    <= rob2regf_wr_data; 
           5'b0_0011 : x3_gp    <= rob2regf_wr_data; 
           5'b0_0100 : x4_tp    <= rob2regf_wr_data; 
           5'b0_0101 : x5_t0    <= rob2regf_wr_data; 
           5'b0_0110 : x6_t1    <= rob2regf_wr_data; 
           5'b0_0111 : x7_t2    <= rob2regf_wr_data; 
           5'b0_1000 : x8_s0fp  <= rob2regf_wr_data; 
           5'b0_1001 : x9_s1    <= rob2regf_wr_data; 
           5'b0_1010 : x10_a0   <= rob2regf_wr_data; 
           5'b0_1011 : x11_a1   <= rob2regf_wr_data; 
           5'b0_1100 : x12_a2   <= rob2regf_wr_data; 
           5'b0_1101 : x13_a3   <= rob2regf_wr_data; 
           5'b0_1110 : x14_a4   <= rob2regf_wr_data; 
           5'b0_1111 : x15_a5   <= rob2regf_wr_data; 
           5'b1_0000 : x16_a6   <= rob2regf_wr_data; 
           5'b1_0001 : x17_a7   <= rob2regf_wr_data; 
           5'b1_0010 : x18_s2   <= rob2regf_wr_data; 
           5'b1_0011 : x19_s3   <= rob2regf_wr_data; 
           5'b1_0100 : x20_s4   <= rob2regf_wr_data; 
           5'b1_0101 : x21_s5   <= rob2regf_wr_data; 
           5'b1_0110 : x22_s6   <= rob2regf_wr_data; 
           5'b1_0111 : x23_s7   <= rob2regf_wr_data; 
           5'b1_1000 : x24_s8   <= rob2regf_wr_data; 
           5'b1_1001 : x25_s9   <= rob2regf_wr_data; 
           5'b1_1010 : x26_s10  <= rob2regf_wr_data; 
           5'b1_1011 : x27_s11  <= rob2regf_wr_data; 
           5'b1_1100 : x28_t3   <= rob2regf_wr_data; 
           5'b1_1101 : x29_t4   <= rob2regf_wr_data; 
           5'b1_1110 : x30_t5   <= rob2regf_wr_data; 
           5'b1_1111 : x31_t6   <= rob2regf_wr_data; 
        endcase
      end 
    end 
    if (dec2regf_instr_main == RV_MEMORY && dec2regf_instr_func == LD_UNSIGNED) begin 
      case (dec2regf_instr_rd)
         5'b0_0001 : x1_ra    <= dec2regf_instr_immd; 
         5'b0_0010 : x2_sp    <= dec2regf_instr_immd; 
         5'b0_0011 : x3_gp    <= dec2regf_instr_immd; 
         5'b0_0100 : x4_tp    <= dec2regf_instr_immd; 
         5'b0_0101 : x5_t0    <= dec2regf_instr_immd; 
         5'b0_0110 : x6_t1    <= dec2regf_instr_immd; 
         5'b0_0111 : x7_t2    <= dec2regf_instr_immd; 
         5'b0_1000 : x8_s0fp  <= dec2regf_instr_immd; 
         5'b0_1001 : x9_s1    <= dec2regf_instr_immd; 
         5'b0_1010 : x10_a0   <= dec2regf_instr_immd; 
         5'b0_1011 : x11_a1   <= dec2regf_instr_immd; 
         5'b0_1100 : x12_a2   <= dec2regf_instr_immd; 
         5'b0_1101 : x13_a3   <= dec2regf_instr_immd; 
         5'b0_1110 : x14_a4   <= dec2regf_instr_immd; 
         5'b0_1111 : x15_a5   <= dec2regf_instr_immd; 
         5'b1_0000 : x16_a6   <= dec2regf_instr_immd; 
         5'b1_0001 : x17_a7   <= dec2regf_instr_immd; 
         5'b1_0010 : x18_s2   <= dec2regf_instr_immd; 
         5'b1_0011 : x19_s3   <= dec2regf_instr_immd; 
         5'b1_0100 : x20_s4   <= dec2regf_instr_immd; 
         5'b1_0101 : x21_s5   <= dec2regf_instr_immd; 
         5'b1_0110 : x22_s6   <= dec2regf_instr_immd; 
         5'b1_0111 : x23_s7   <= dec2regf_instr_immd; 
         5'b1_1000 : x24_s8   <= dec2regf_instr_immd; 
         5'b1_1001 : x25_s9   <= dec2regf_instr_immd; 
         5'b1_1010 : x26_s10  <= dec2regf_instr_immd; 
         5'b1_1011 : x27_s11  <= dec2regf_instr_immd; 
         5'b1_1100 : x28_t3   <= dec2regf_instr_immd; 
         5'b1_1101 : x29_t4   <= dec2regf_instr_immd; 
         5'b1_1110 : x30_t5   <= dec2regf_instr_immd; 
         5'b1_1111 : x31_t6   <= dec2regf_instr_immd; 
      endcase 
    end 
    if (dec2regf_instr_main == RV_PREDICT && dec2regf_instr_func == JAL) begin
      case (dec2regf_instr_rd)
         5'b0_0001 : x1_ra    <= PC + 'h4; 
         5'b0_0010 : x2_sp    <= PC + 'h4; 
         5'b0_0011 : x3_gp    <= PC + 'h4; 
         5'b0_0100 : x4_tp    <= PC + 'h4; 
         5'b0_0101 : x5_t0    <= PC + 'h4; 
         5'b0_0110 : x6_t1    <= PC + 'h4; 
         5'b0_0111 : x7_t2    <= PC + 'h4; 
         5'b0_1000 : x8_s0fp  <= PC + 'h4; 
         5'b0_1001 : x9_s1    <= PC + 'h4; 
         5'b0_1010 : x10_a0   <= PC + 'h4; 
         5'b0_1011 : x11_a1   <= PC + 'h4; 
         5'b0_1100 : x12_a2   <= PC + 'h4; 
         5'b0_1101 : x13_a3   <= PC + 'h4; 
         5'b0_1110 : x14_a4   <= PC + 'h4; 
         5'b0_1111 : x15_a5   <= PC + 'h4; 
         5'b1_0000 : x16_a6   <= PC + 'h4; 
         5'b1_0001 : x17_a7   <= PC + 'h4; 
         5'b1_0010 : x18_s2   <= PC + 'h4; 
         5'b1_0011 : x19_s3   <= PC + 'h4; 
         5'b1_0100 : x20_s4   <= PC + 'h4; 
         5'b1_0101 : x21_s5   <= PC + 'h4; 
         5'b1_0110 : x22_s6   <= PC + 'h4; 
         5'b1_0111 : x23_s7   <= PC + 'h4; 
         5'b1_1000 : x24_s8   <= PC + 'h4; 
         5'b1_1001 : x25_s9   <= PC + 'h4; 
         5'b1_1010 : x26_s10  <= PC + 'h4; 
         5'b1_1011 : x27_s11  <= PC + 'h4; 
         5'b1_1100 : x28_t3   <= PC + 'h4; 
         5'b1_1101 : x29_t4   <= PC + 'h4; 
         5'b1_1110 : x30_t5   <= PC + 'h4; 
         5'b1_1111 : x31_t6   <= PC + 'h4; 
      endcase 
    end 
    if(mem2regf_rsp_vld & regf2mem_rsp_ready ) begin 
      case (mem2regf_rsp_cid)
         5'b0_0001 : x1_ra    <= mem2regf_rsp_data; 
         5'b0_0010 : x2_sp    <= mem2regf_rsp_data; 
         5'b0_0011 : x3_gp    <= mem2regf_rsp_data; 
         5'b0_0100 : x4_tp    <= mem2regf_rsp_data; 
         5'b0_0101 : x5_t0    <= mem2regf_rsp_data; 
         5'b0_0110 : x6_t1    <= mem2regf_rsp_data; 
         5'b0_0111 : x7_t2    <= mem2regf_rsp_data; 
         5'b0_1000 : x8_s0fp  <= mem2regf_rsp_data; 
         5'b0_1001 : x9_s1    <= mem2regf_rsp_data; 
         5'b0_1010 : x10_a0   <= mem2regf_rsp_data; 
         5'b0_1011 : x11_a1   <= mem2regf_rsp_data; 
         5'b0_1100 : x12_a2   <= mem2regf_rsp_data; 
         5'b0_1101 : x13_a3   <= mem2regf_rsp_data; 
         5'b0_1110 : x14_a4   <= mem2regf_rsp_data; 
         5'b0_1111 : x15_a5   <= mem2regf_rsp_data; 
         5'b1_0000 : x16_a6   <= mem2regf_rsp_data; 
         5'b1_0001 : x17_a7   <= mem2regf_rsp_data; 
         5'b1_0010 : x18_s2   <= mem2regf_rsp_data; 
         5'b1_0011 : x19_s3   <= mem2regf_rsp_data; 
         5'b1_0100 : x20_s4   <= mem2regf_rsp_data; 
         5'b1_0101 : x21_s5   <= mem2regf_rsp_data; 
         5'b1_0110 : x22_s6   <= mem2regf_rsp_data; 
         5'b1_0111 : x23_s7   <= mem2regf_rsp_data; 
         5'b1_1000 : x24_s8   <= mem2regf_rsp_data; 
         5'b1_1001 : x25_s9   <= mem2regf_rsp_data; 
         5'b1_1010 : x26_s10  <= mem2regf_rsp_data; 
         5'b1_1011 : x27_s11  <= mem2regf_rsp_data; 
         5'b1_1100 : x28_t3   <= mem2regf_rsp_data; 
         5'b1_1101 : x29_t4   <= mem2regf_rsp_data; 
         5'b1_1110 : x30_t5   <= mem2regf_rsp_data; 
         5'b1_1111 : x31_t6   <= mem2regf_rsp_data; 
      endcase 

    end 
  end 

wire general_purpose_regfile_access = dec2regf_instr_main == RV_ADDER  || 
                                      dec2regf_instr_main == RV_MULDIV || 
                                      dec2regf_instr_main == RV_LOGIC  ;
wire float_point_regfile_access     = dec2regf_instr_main == RV_FPU    ;

reg [31:0]  regval_rs1;
reg [31:0]  regval_rs2;

always @(*) begin
  case (dec2regf_instr_rs1)
     5'b0_0000 : regval_rs1 <= x0_zero  ; 
     5'b0_0001 : regval_rs1 <= x1_ra    ; 
     5'b0_0010 : regval_rs1 <= x2_sp    ; 
     5'b0_0011 : regval_rs1 <= x3_gp    ; 
     5'b0_0100 : regval_rs1 <= x4_tp    ; 
     5'b0_0101 : regval_rs1 <= x5_t0    ; 
     5'b0_0110 : regval_rs1 <= x6_t1    ; 
     5'b0_0111 : regval_rs1 <= x7_t2    ; 
     5'b0_1000 : regval_rs1 <= x8_s0fp  ; 
     5'b0_1001 : regval_rs1 <= x9_s1    ; 
     5'b0_1010 : regval_rs1 <= x10_a0   ; 
     5'b0_1011 : regval_rs1 <= x11_a1   ; 
     5'b0_1100 : regval_rs1 <= x12_a2   ; 
     5'b0_1101 : regval_rs1 <= x13_a3   ; 
     5'b0_1110 : regval_rs1 <= x14_a4   ; 
     5'b0_1111 : regval_rs1 <= x15_a5   ; 
     5'b1_0000 : regval_rs1 <= x16_a6   ; 
     5'b1_0001 : regval_rs1 <= x17_a7   ; 
     5'b1_0010 : regval_rs1 <= x18_s2   ; 
     5'b1_0011 : regval_rs1 <= x19_s3   ; 
     5'b1_0100 : regval_rs1 <= x20_s4   ; 
     5'b1_0101 : regval_rs1 <= x21_s5   ; 
     5'b1_0110 : regval_rs1 <= x22_s6   ; 
     5'b1_0111 : regval_rs1 <= x23_s7   ; 
     5'b1_1000 : regval_rs1 <= x24_s8   ; 
     5'b1_1001 : regval_rs1 <= x25_s9   ; 
     5'b1_1010 : regval_rs1 <= x26_s10  ; 
     5'b1_1011 : regval_rs1 <= x27_s11  ; 
     5'b1_1100 : regval_rs1 <= x28_t3   ; 
     5'b1_1101 : regval_rs1 <= x29_t4   ; 
     5'b1_1110 : regval_rs1 <= x30_t5   ; 
     5'b1_1111 : regval_rs1 <= x31_t6   ; 
  endcase 
end 
always @(*) begin
  case (dec2regf_instr_rs2)
     5'b0_0000 : regval_rs2 <= x0_zero  ; 
     5'b0_0001 : regval_rs2 <= x1_ra    ; 
     5'b0_0010 : regval_rs2 <= x2_sp    ; 
     5'b0_0011 : regval_rs2 <= x3_gp    ; 
     5'b0_0100 : regval_rs2 <= x4_tp    ; 
     5'b0_0101 : regval_rs2 <= x5_t0    ; 
     5'b0_0110 : regval_rs2 <= x6_t1    ; 
     5'b0_0111 : regval_rs2 <= x7_t2    ; 
     5'b0_1000 : regval_rs2 <= x8_s0fp  ; 
     5'b0_1001 : regval_rs2 <= x9_s1    ; 
     5'b0_1010 : regval_rs2 <= x10_a0   ; 
     5'b0_1011 : regval_rs2 <= x11_a1   ; 
     5'b0_1100 : regval_rs2 <= x12_a2   ; 
     5'b0_1101 : regval_rs2 <= x13_a3   ; 
     5'b0_1110 : regval_rs2 <= x14_a4   ; 
     5'b0_1111 : regval_rs2 <= x15_a5   ; 
     5'b1_0000 : regval_rs2 <= x16_a6   ; 
     5'b1_0001 : regval_rs2 <= x17_a7   ; 
     5'b1_0010 : regval_rs2 <= x18_s2   ; 
     5'b1_0011 : regval_rs2 <= x19_s3   ; 
     5'b1_0100 : regval_rs2 <= x20_s4   ; 
     5'b1_0101 : regval_rs2 <= x21_s5   ; 
     5'b1_0110 : regval_rs2 <= x22_s6   ; 
     5'b1_0111 : regval_rs2 <= x23_s7   ; 
     5'b1_1000 : regval_rs2 <= x24_s8   ; 
     5'b1_1001 : regval_rs2 <= x25_s9   ; 
     5'b1_1010 : regval_rs2 <= x26_s10  ; 
     5'b1_1011 : regval_rs2 <= x27_s11  ; 
     5'b1_1100 : regval_rs2 <= x28_t3   ; 
     5'b1_1101 : regval_rs2 <= x29_t4   ; 
     5'b1_1110 : regval_rs2 <= x30_t5   ; 
     5'b1_1111 : regval_rs2 <= x31_t6   ; 
  endcase 
end 
reg[2:0]  regf2mem_osreq_num;
wire      load_request;
wire      store_request;
assign    load_request = dec2regf_instr_main == RV_MEMORY  && (dec2regf_instr_func == LD_BYTE          || 
                                                               dec2regf_instr_func == LD_HWORD         || 
                                                               dec2regf_instr_func == LD_WORD          || 
                                                               dec2regf_instr_func == LD_BYTE_UNSIGNED ||
                                                               dec2regf_instr_func == LD_HWORD_UNSIGNED||
                                                               dec2regf_instr_func == LD_WORD_UNSIGNED );
assign    store_request= dec2regf_instr_main == RV_MEMORY  && (dec2regf_instr_func == ST_BYTE          ||
                                                               dec2regf_instr_func == ST_HWORD         || 
                                                               dec2regf_instr_func == ST_WORD          );


always @(posedge sclk or negedge rstn)
  if (~rstn) begin
    regf2pc_jmp_en               <= 1'b0;
    regf2mem_req_valid           <= 1'b0;
    regf2mem_req_addr            <= 'h0;
    regf2mem_osreq_num           <= 'h0;
    regf2mem_req_data            <= 'h0;
  end else begin
    regf2pc_jmp_en        <= dec2regf_instr_main == RV_PREDICT && dec2regf_instr_func == JAL  ||
                             dec2regf_instr_main == RV_ADDER   && dec2regf_instr_func == AUIPC;

    if (mem2regf_req_ready && regf2mem_osreq_num < 'h4) begin 
      regf2mem_req_valid  <= load_request | store_request;
      regf2mem_req_cid    <= load_request ? dec2regf_instr_rd : 'h0;
      regf2mem_osreq_num  <= regf2mem_osreq_num + 1'b1;
      regf2mem_req_type   <= load_request ? 2'b10 :
                             store_request? 2'b01 : 2'b00; //read
      regf2mem_req_len    <= 4'h4;  // 4byte
      regf2mem_req_mask   <= (dec2regf_instr_func == LD_BYTE || dec2regf_instr_func == LD_BYTE_UNSIGNED  || dec2regf_instr_func == ST_BYTE ) ? 4'b0001 :
                             (dec2regf_instr_func == LD_HWORD|| dec2regf_instr_func == LD_HWORD_UNSIGNED || dec2regf_instr_func == ST_HWORD) ? 4'b0011 : 4'b1111; 
      regf2mem_req_addr   <= regval_rs1 + regf2isq_instr_immd ;
      regf2mem_req_data   <= store_request ? regval_rs2 : 'h0;
    end else if (mem2regf_rsp_vld && mem2regf_rsp_ready) begin 
      regf2mem_osreq_num <= regf2mem_osreq_num - 1'b1;
    end 
  end 
 
assign regf2mem_rsp_ready = 1'b1;

always @(posedge sclk or negedge rstn)
  if (~rstn) begin
   regf2isq_instr_rd   <= 'h0;
   regf2isq_instr_func <= 'h0;
   regf2isq_instr_immd <= 'h0;
   regf2isq_regval_rs1 <= 'h0;
   regf2isq_regval_rs2 <= 'h0;
  end else begin
   regf2isq_instr_rd   <= dec2regf_instr_rd  ;
   regf2isq_instr_func <= dec2regf_instr_func;
   regf2isq_instr_immd <= dec2regf_instr_immd;
   regf2isq_regval_rs1 <= regval_rs1; 
   regf2isq_regval_rs2 <= regval_rs2; 
  end 

wire[6-1:0]   regf2isq_wr_addr ;
wire[55-1:0]  regf2isq_wr_data ;
reg           regf2isq_wr_en   ;
reg           regf2isq_rd_en   ;
reg[6-1:0]    regf2isq_rd_addr ;
wire[55-1:0]  regf2isq_rd_data ;

//depedency 
reg [31:0]     check_depend_list;      //if the register is destination register, mark the bit 1, if the following instructions are dependent of the destination register, put it into the issue queue. if all the issue_queue are full, stall the fetch 
reg [5+6-1:0]  isq_depend_chain[0:31]; // 32-entry {rd, isq_addr} pair to store the outstanding requests
wire           load_rsp;
assign         load_rsp =mem2regf_rsp_vld & regf2mem_rsp_ready; 
always @(posedge sclk or negedge rstn) 
  if (~rstn) begin 
    check_depend_list <= 32'b0;
  end else begin 
    case ({load_request, load_rsp})
      2'b10 : check_depend_list[dec2regf_instr_rd] <= 1'b1;
      2'b01 : check_depend_list[mem2regf_rsp_cid]  <= 1'b0;
      2'b11 : begin 
                if (dec2regf_instr_rd == mem2regf_rsp_cid ) $display("Error: load crash.");
                else begin 
                  check_depend_list[dec2regf_instr_rd] <= 1'b1;
                  check_depend_list[mem2regf_rsp_cid]  <= 1'b0;
                end 
              end  
    endcase
  end 

assign regf2isq_wr_data = {dec2regf_instr_func, dec2regf_instr_rs1, dec2regf_instr_rs2, dec2regf_instr_rd, dec2regf_instr_immd};

always @(posedge sclk or negedge rstn)
  if (~rstn) 
    regf2isq_wr_addr <= 'h0;
  else 
    case ({load_request, load_rsp})
      2'b10   : regf2isq_wr_addr <= regf2isq_wr_addr + 1'b1;
      2'b01   : regf2isq_wr_addr <= regf2isq_wr_addr - 1'b1;
      default : regf2isq_wr_addr <= regf2isq_wr_addr;
    endcase


//64 depth issue queue
RVSram #(.DW(55), .AW(6)) issue_queue (
  .sclk    (sclk             ),
  .rstn    (rstn             ),
  .wr_addr (regf2isq_wr_addr ),
  .wr_data (regf2isq_wr_data ),
  .wr_en   (regf2isq_wr_en   ),
  .rd_en   (regf2isq_rd_en   ),
  .rd_addr (regf2isq_rd_addr ),
  .rd_data (regf2isq_rd_data ) 
);

endmodule 
