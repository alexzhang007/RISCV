//Author  : AlexZhang (cgalexzhang@sina.com)
//Date    : 01-06-2020
//Comment : top level Cpu

module  RVCpu (
input   sclk,
input   rstn
);

//Program Counter
reg[31:0]  PC;
wire[31:0] regf2isq_instr_immd;
wire       regf2pc_jmp_en     ;
wire[7:0]  dec2regf_instr_main;
wire[7:0]  dec2regf_instr_func;
wire[4:0]  dec2regf_instr_rs1 ;
wire[4:0]  dec2regf_instr_rs2 ;
wire[4:0]  dec2regf_instr_rd  ;
wire[31:0] dec2regf_instr_immd;
wire[31:0] regf2isq_regval_rs1;
wire[31:0] regf2isq_regval_rs2;
wire[4:0]  regf2isq_instr_rd  ;
wire[7:0]  regf2isq_instr_func;


always @(posedge sclk or negedge rstn)
  if (~rstn) 
    PC <= 32'h0;
  else 
    PC <= regf2pc_jmp_en ? PC + regf2isq_instr_immd  : PC +32'h4;


wire [31:0]  instrData;
wire [7:0]   dec2regf_instr_main;
wire [7:0]   dec2regf_instr_func;
wire [4:0]   dec2regf_instr_rs1 ;
wire [4:0]   dec2regf_instr_rs2 ;
wire [4:0]   dec2regf_instr_rd  ;
wire [4:0]   dec2regf_instr_immd;

wire [31:0]  regf2isq_regval_rs1 ; //register_file to issue_queue register source 1 data
wire [31:0]  regf2isq_regval_rs2 ; //register_file to issue_queue register source 2 data
wire [4:0]   regf2isq_instr_rd   ; //register_file to issue_queue destination register pipelined
wire [7:0]   regf2isq_instr_func ;
wire [31:0]  regf2isq_instr_immd ;
wire         regf2pc_jmp_en      ;
wire         regf2pc_stall_en    ;

wire         mem2regf_req_ready  ; 
wire [31:0]  regf2mem_req_addr   ; 
wire [31:0]  regf2mem_req_data   ; 
wire [1:0]   regf2mem_req_type   ;  // 2'b01- write, 2'b10- read
wire         regf2mem_req_valid  ;  
wire [3:0]   regf2mem_req_len    ;  // 4'h0- 4 byte
wire [3:0]   regf2mem_req_mask   ;  // to support byte store
wire [4:0]   regf2mem_req_cid    ;  // here use the register id
wire
wire [4:0]   mem2regf_rsp_cid    ; 
wire [31:0]  mem2regf_rsp_data   ; 
wire         mem2regf_rsp_vld    ; 
wire         regf2mem_rsp_ready  ; 

RVMemory imem (
  .mclk         (sclk               ),
  .rstn         (rstn               ),
  .PC           (PC                 ),
  .instrData    (instrData          )
);

RVDecoder  decoder(
  .dec_instr    (instrData          ),
  .instr_main   (dec2regf_instr_main),
  .instr_func   (dec2regf_instr_func),
  .instr_rs1    (dec2regf_instr_rs1 ),
  .instr_rs2    (dec2regf_instr_rs2 ),
  .instr_rd     (dec2regf_instr_rd  ),
  .instr_immd   (dec2regf_instr_immd)
);


RVRegisterFile reg_file(
  .sclk                (sclk               ),
  .rstn                (rstn               ),
  .PC                  (PC                 ),
  .dec2regf_instr_main (dec2regf_instr_main),
  .dec2regf_instr_func (dec2regf_instr_func),
  .dec2regf_instr_rs1  (dec2regf_instr_rs1 ),
  .dec2regf_instr_rs2  (dec2regf_instr_rs2 ),
  .dec2regf_instr_rd   (dec2regf_instr_rd  ),
  .dec2regf_instr_immd (dec2regf_instr_immd),
  .regf2isq_regval_rs1 (regf2isq_regval_rs1), //register_file to issue_queue register source 1 data
  .regf2isq_regval_rs2 (regf2isq_regval_rs2), //register_file to issue_queue register source 2 data
  .regf2isq_instr_rd   (regf2isq_instr_rd  ), //register_file to issue_queue destination register pipelined
  .regf2isq_instr_func (regf2isq_instr_func),
  .regf2isq_instr_immd (regf2isq_instr_immd),
  .regf2pc_jmp_en      (regf2pc_jmp_en     ),
  .regf2pc_stall_en    (regf2pc_stall_en   ),
  .mem2regf_req_ready  (mem2regf_req_ready ),
  .regf2mem_req_addr   (regf2mem_req_addr  ),
  .regf2mem_req_data   (regf2mem_req_data  ),
  .regf2mem_req_type   (regf2mem_req_type  ), // 2'b01- write, 2'b10- read
  .regf2mem_req_valid  (regf2mem_req_valid ), 
  .regf2mem_req_len    (regf2mem_req_len   ), // 4'h0- 4 byte
  .regf2mem_req_mask   (regf2mem_req_mask  ), // to support byte store
  .regf2mem_req_cid    (regf2mem_req_cid   ), // here use the register id
                                           
  .mem2regf_rsp_cid    (mem2regf_rsp_cid   ),
  .mem2regf_rsp_data   (mem2regf_rsp_data  ),
  .mem2regf_rsp_vld    (mem2regf_rsp_vld   ),
  .regf2mem_rsp_ready  (regf2mem_rsp_ready ),  
  .rob2regf_wr_en      ('b0),
  .rob2regf_wr_addr    ('b0), //the high bit is indiate float or integer purpose register file
  .rob2regf_wr_data    ('b0)
);


endmodule 
