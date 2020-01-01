//Author  : AlexZhang (cgalexzhang@sina.com)
//Date    : 01-01-2020
//Comment : Decoding the RISCV32&64 Instructions
module RVDecoder (
input  [31:0]  dec_instr,
output [7:0]   instr_main,
output [7:0]   instr_func,
output [4:0]   instr_rs1 ,
output [4:0]   instr_rs2 ,
output [4:0]   instr_rd  ,
output [31:0]  instr_immd
);
parameter  RV_ADDER    = 8'b0000_0001,  //Integer + or -
           RV_MULDIV   = 8'b0000_1000,  //Integer * or /
           RV_LOGIC    = 8'b0000_0010,  //xor 
           RV_MEMORY   = 8'b0000_0011,  //load / store
           RV_SHIFT    = 8'b0000_0100,  //shift *
           RV_PREDICT  = 8'b0000_0101,  //Branch / Jump
           RV_FPU      = 8'b0000_0110,  // 32 bit float
         //RV_DPU      = 8'b0000_0111,  // 64bit double
           RV_VECTOR   = 8'b0001_0000,
           RV_ATOMIC   = 8'b0001_0001,
           RV_CSR      = 8'b0001_0010,
           RV_SYNC     = 8'b0001_0011, //Fench / Flush
           RV_SYSTEM   = 8'b0001_0100; //ECALL

//Memory type func 
parameter LD_UNSIGNED = 8'b0000_0001,
          

//ADDER type

wire dec_inst_32bit;
wire [6:0] dec_op;
wire [2:0] dec_funct3;
wire [6:0] dec_funct7;
assign dec_inst_32bit = (dec_instr[1:0] == 2'b11) && (dec_instr[4:2]!= 3'b111);
assign dec_op         =  dec_instr[6:0];
assign dec_funct3     =  dec_instr[14:12];  
assign dec_funct7     =  dec_instr[31:25];


reg [7:0]  instr_main;
reg [7:0]  instr_func;
reg [4:0]  instr_rs1 ;
reg [4:0]  instr_rs2 ;
reg [4:0]  instr_rd  ;
reg [31:0] instr_immd;

wire [5:0] shamt;
//RV64's shamt 's 1 bit more than RV32's. Op, funct3 are also same.
assign shamt = dec_instr[25:20];

always @(*) begin 
  casex({dec_funct7, dec_funct3, dec_op})
    17'b???????_???_0110111 : begin //Load unsigned immediate, RV32I,  [rd] <- immediate
                                instr_main = RV_MEMORY;
                                instr_func = LD_UNSIGNED;
                                instr_immd = {dec_instr[31:12] , 11'b0};
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  = 5'b0;
                                instr_rs2  = 5'b0;
                              end 
    17'b???????_???_0010111 : begin //Add upper immediate to PC, RV32I, [rd] <- PC + immdeiate
                                instr_main = RV_ADDER;
                                instr_func = AUIPC;
                                instr_rd   = dec_instr[11:7];
                                instr_rs1  = 5'b0;
                                instr_rs2  = 5'b0;
                                instr_immd = {dec_instr[31:12] , 11'b0};
                              end 
    17'b???????_???_1101111 : begin //Jump and link- JAL, RV32I, save [rd] <- PC + 4; then jump : PC <- immediate + PC
                                instr_main = RV_PREDICT;
                                instr_func = JAL;
                                instr_rd   = dec_instr[11:7];
                                instr_rs1  = 5'b0;
                                instr_rs2  = 5'b0;
                                instr_immd = {{11{dec_instr[31]}}, dec_instr[31], dec_instr[19:12], dec_instr[20], dec_instr[30:21] , 1'b0};
                              end  
    17'b???????_000_1100111 : begin //Jump and link register- JALR, RV32I, save [rd] <- PC + 4; then jump : PC <- immediate + PC + [rs1]
                                instr_main = RV_PREDICT;
                                instr_func = JALR;
                                instr_rd   = dec_instr[11:7];
                                instr_rs1  = dec_instr[19:15];
                                instr_rs2  = 5'b0;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20]};
                              end 
    17'b???????_000_1100011 : begin  //branch if equal, if [rs1] == [rs2], then PC <- PC + immediate
                                instr_main = RV_PREDICT;
                                instr_func = BEQ;
                                instr_rd   = 5'b0;
                                instr_rs1  = dec_instr[19:15];
                                instr_rs2  = dec_instr[24:20];
                                instr_immd = {{19{dec_instr[31]}} , dec_instr[31], dec_instr[7], dec_instr[30:25], dec_instr[11:8] , 1'b0};
                              end   
    17'b???????_001_1100111 : begin  //branch if not equal, if [rs1] != [rs2], then PC <- PC + immediate
                                instr_main = RV_PREDICT;
                                instr_func = BNE;
                                instr_rd   = 5'b0;
                                instr_rs1  = dec_instr[19:15];
                                instr_rs2  = dec_instr[24:20];
                                instr_immd = {{19{dec_instr[31]}} , dec_instr[31], dec_instr[7], dec_instr[30:25], dec_instr[11:8] , 1'b0};
                              end   
    17'b???????_100_1100011 : begin  //branch if less than, if [rs1] < [rs2] (signed compare), then PC <- PC + immediate
                                instr_main = RV_PREDICT;
                                instr_func = BLT;
                                instr_rd   = 5'b0;
                                instr_rs1  = dec_instr[19:15];
                                instr_rs2  = dec_instr[24:20];
                                instr_immd = {{19{dec_instr[31]}} , dec_instr[31], dec_instr[7], dec_instr[30:25], dec_instr[11:8] , 1'b0};
                              end   
    17'b???????_101_1100011 : begin  //branch if greater than, if [rs1] >= [rs2](signed compare), then PC <- PC + immediate
                                instr_main = RV_PREDICT;
                                instr_func = BGE;
                                instr_rd   = 5'b0;
                                instr_rs1  = dec_instr[19:15];
                                instr_rs2  = dec_instr[24:20];
                                instr_immd = {{19{dec_instr[31]}} , dec_instr[31], dec_instr[7], dec_instr[30:25], dec_instr[11:8] , 1'b0};
                              end   
    17'b???????_110_1100011 : begin  //branch if greater than, if [rs1] < [rs2](unsigend compare), then PC <- PC + immediate
                                instr_main = RV_PREDICT;
                                instr_func = BLTU;
                                instr_rd   = 5'b0;
                                instr_rs1  = dec_instr[19:15];
                                instr_rs2  = dec_instr[24:20];
                                instr_immd = {{19{dec_instr[31]}} , dec_instr[31], dec_instr[7], dec_instr[30:25], dec_instr[11:8] , 1'b0};
                              end  
    17'b???????_111_1100011 : begin  //branch if greater than, if [rs1] >= [rs2](unsigned compare), then PC <- PC + immediate
                                instr_main = RV_PREDICT;
                                instr_func = BGEU;
                                instr_rd   = 5'b0;
                                instr_rs1  = dec_instr[19:15];
                                instr_rs2  = dec_instr[24:20];
                                instr_immd = {{19{dec_instr[31]}} , dec_instr[31], dec_instr[7], dec_instr[30:25], dec_instr[11:8] , 1'b0};
                              end   
    17'b???????_000_0000011 : begin  //load byte from [rd] <- [rs1] + immdiate (signed), rd low byte is loaded, other bytes are 0. 
                                instr_main = RV_MEMORY;
                                instr_func = LD_BYTE;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20]};
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  = 5'b0;
                              end
    17'b???????_001_0000011 : begin  //load half word from [rd] <- [rs1] + immdiate (signed), rd low 2bytes are loaded, other bytes are 0.
                                instr_main = RV_MEMORY;
                                instr_func = LD_HWORD;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20]};
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  = 5'b0;
                              end
    17'b???????_010_0000011 : begin  //load word from [rd] <- [rs1] + immdiate (signed)
                                instr_main = RV_MEMORY;
                                instr_func = LD_WORD;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20]};
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  = 5'b0;
                              end          
    17'b???????_100_0000011 : begin  //load byte from [rd] <- [rs1] + immdiate (unsigned), rd low byte is loaded, other bytes are 0 
                                instr_main = RV_MEMORY;
                                instr_func = LD_BYTE_UNSIGNED;
                                instr_immd = {20'b0, dec_instr[31:20]};
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  = 5'b0;
                              end
    17'b???????_101_0000011 : begin  //load harf word from [rd] <- [rs1] + immdiate (unsigned),RV32, rd low 2bytes are loaded, other bytes are 0 
                                instr_main = RV_MEMORY;
                                instr_func = LD_HWORD_UNSIGNED;
                                instr_immd = {20'b0, dec_instr[31:20]};
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  = 5'b0;
                              end
    17'b???????_110_0000011 : begin  //load word unsigned from [rd] <- [rs1] + immdiate (unsigned),RV64, rd low word are loaded, other word are 0 
                                instr_main = RV_MEMORY;
                                instr_func = LD_WORD_UNSIGNED;
                                instr_immd = {20'b0, dec_instr[31:20]};
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  = 5'b0;
                              end
    17'b???????_011_0000011 : begin  //load word unsigned from [rd] <- [rs1] + immdiate (unsigned),RV64,
                                instr_main = RV_MEMORY;
                                instr_func = LD_DWORD;
                                instr_immd = { {20{dec_instr[31]}}, dec_instr[31:20]};
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  = 5'b0;
                              end
    17'b???????_000_0100011 : begin  //store byte to MEM([rs1] + immediate) <- [rs2] , load low byte of rs2 to .
                                instr_main = RV_MEMORY;
                                instr_func = ST_BYTE;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:25], dec_instr[11:7]};
                                instr_rd   =  5'b0;
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];
                              end
    17'b???????_001_0100011 : begin  //store half word to MEM([rs1] + immediate) <- [rs2] , load low byte of rs2 to .
                                instr_main = RV_MEMORY;
                                instr_func = ST_HWORD;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:25], dec_instr[11:7]};
                                instr_rd   =  5'b0;
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];
                              end
    17'b???????_010_0100011 : begin  //store half word to MEM([rs1] + immediate) <- [rs2] , load low byte of rs2 to .
                                instr_main = RV_MEMORY;
                                instr_func = ST_WORD;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:25], dec_instr[11:7]};
                                instr_rd   =  5'b0;
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];
                              end
    17'b???????_011_0100011 : begin  //store half word to MEM([rs1] + immediate) <- [rs2] , RV64
                                instr_main = RV_MEMORY;
                                instr_func = ST_DWORD;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:25], dec_instr[11:7]};
                                instr_rd   =  5'b0;
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];
                              end

    17'b???????_000_0010011 : begin  //add immediate, RV32,   [rd] <- [rs1] + immediate
                                instr_main = RV_ADDER;
                                instr_func = ADD_IMMED;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20] };
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end 
    17'b???????_000_0011011 : begin  //add immediate, RV64,   [rd] <- [rs1] + immediate,  Only low word is added
                                instr_main = RV_ADDER;
                                instr_func = ADD_IMMED_WORD;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20] };
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end 
    17'b0000000_001_0011011 : begin  //add immediate, RV64,   [rd] <- [rs1] << shamt[4:0],  Only low word is saved to rd
                                instr_main = RV_SHIFT;
                                instr_func = SLLIW;
                                instr_immd = 32'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end 
    17'b0000000_101_0011011 : begin  //add immediate, RV64,   [rd] <- [rs1] >> shamt[4:0],  Only low word is saved to rd
                                instr_main = RV_SHIFT;
                                instr_func = SRLIW;
                                instr_immd = 32'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end 
    17'b0100000_101_0011011 : begin  //add immediate, RV64,   [rd] <- [rs1] >> shamt[4:0],  Only low word is saved to rd
                                instr_main = RV_SHIFT;
                                instr_func = SRAIW;
                                instr_immd = 32'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end 

    17'b???????_010_0010011 : begin  //set less than immediate, RV32,   if ([rs1] < immediate, signed compare) rd = 1 else rd = 0;
                                instr_main = RV_LOGIC;
                                instr_func = SLTI;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20] };
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end 
    17'b???????_010_0010011 : begin  //set less than immediate, RV32,   if ([rs1] < immediate, unsigned compare) rd = 1 else rd = 0;
                                instr_main = RV_LOGIC;
                                instr_func = SLTIU;
                                instr_immd = {{20'b0}, dec_instr[31:20] };
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end 
    17'b???????_100_0010011 : begin  //xor signed extended immediate, RV32,   [rd] <- [rs1] ^ immediate (signed extended);
                                instr_main = RV_LOGIC;
                                instr_func = XORI;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20] };
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end 
    17'b???????_110_0010011 : begin  //or signed extended immediate, RV32,   [rd] <- [rs1] | immediate (signed extended);
                                instr_main = RV_LOGIC;
                                instr_func = ORI;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20] };
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end     
    17'b???????_111_0010011 : begin  //and signed extended immediate, RV32,   [rd] <- [rs1] | immediate (signed extended);
                                instr_main = RV_LOGIC;
                                instr_func = ANDI;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20] };
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end            
    17'b0000000_001_0010011 : begin  //shift left logic with 0 fill , RV32,   [rd] <- [rs1] << shamt
                                instr_main = RV_SFHIT;
                                instr_func = SLLI;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end            
    17'b0000000_101_0010011 : begin  //shift right logic with 0 fill, RV32,   [rd] <- [rs1] >> shamt
                                instr_main = RV_SFHIT;
                                instr_func = SRLI;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end                     
    17'b0100000_101_0010011 : begin  //shift right logic with signed extened, RV32,   [rd] <- [rs1] >> shamt
                                instr_main = RV_SFHIT;
                                instr_func = SRAI;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  5'b0;                          
                              end       
    17'b0000000_000_0110011 : begin  //add with signed extened, RV32,   [rd] <- [rs1] + [rs2] 
                                instr_main = RV_LOGIC;
                                instr_func = ADD;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end    
    17'b0000000_000_0111011 : begin  //shift right logic with signed extened, RV64,   [rd] <- [rs1] + [rs2], clamp it 32bit
                                instr_main = RV_LOGIC;
                                instr_func = ADDW;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end  
    17'b0100000_000_0110011 : begin  //sub with signed extened, RV32,  [rd] <- [rs1] - [rs2]  
                                instr_main = RV_LOGIC;
                                instr_func = SUB;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end     
    17'b0100000_000_0111011 : begin  //subw with signed extened, RV64,   [rd] <- [rs1] - [rs2] 
                                instr_main = RV_LOGIC;
                                instr_func = SUBW;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end 
    17'b0000000_001_0110011 : begin  //shift left logic , RV32,   [rd] <- [rs1] << [ rs2[5:0] ]
                                instr_main = RV_SHIFT;
                                instr_func = SLL;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end   
    17'b0000000_001_0111011 : begin  //shift left logic , RV64,   [rd] <- [rs1] << [ rs2[5:0] ]
                                instr_main = RV_SHIFT;
                                instr_func = SLLW;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end   
    17'b0000000_010_0110011 : begin  //set less than , RV32,  if([rs1] <[rs2])  [rd] <- 1 else [rd] <- 0; signed compare
                                instr_main = RV_LOGIC;
                                instr_func = SLT;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end   
    17'b0000000_011_0110011 : begin  //set less than , RV32,  if([rs1] <[rs2])  [rd] <- 1 else [rd] <- 0; unsigned compare
                                instr_main = RV_LOGIC;
                                instr_func = SLTU;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end   
    17'b0000000_100_0110011 : begin  //XOR , RV32,  if([rs1] <[rs2])  [rd] <- 1 else [rd] <- 0; unsigned compare
                                instr_main = RV_LOGIC;
                                instr_func = XOR;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end   
    17'b0000000_101_0110011 : begin  //shift right logic , RV32,   [rd] <- [rs1] >> [ rs2[5:0] ]
                                instr_main = RV_SHIFT;
                                instr_func = SRL;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end  
    17'b0000000_101_0111011 : begin  //shift right logic , RV64,   [rd] <- [rs1] >> [ rs2[5:0] ]
                                instr_main = RV_SHIFT;
                                instr_func = SRLW;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end  

    17'b0100000_101_0110011 : begin  //shift right algorithm , RV32,   [rd] <- [rs1] >> [ rs2[5:0] ] with rs1 sign bit exteneded
                                instr_main = RV_SHIFT;
                                instr_func = SRA;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end  
    17'b0000000_110_0110011 : begin  //bit OR , RV32,  [rd] <- [rs1] | [rs2]
                                instr_main = RV_LOGIC;
                                instr_func = OR;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end  
    17'b0000000_111_0110011 : begin  //bit AND , RV32,  [rd] <- [rs1] & [rs2]
                                instr_main = RV_LOGIC;
                                instr_func = AND;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11:7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                          
                              end  
    17'b???????_000_0001111 : begin  //Fence
                                instr_main = RV_SYNC;
                                instr_func = FENCE;
                                instr_immd = 'h0;
                                instr_rd   = 'h0;
                                instr_rs1  = 'h0;
                                instr_rs2  = 'h0;        
                              end
    17'b???????_001_0001111 : begin  //Fence.I
                                instr_main = RV_SYNC;
                                instr_func = FENCEI;
                                instr_immd = 'h0;
                                instr_rd   = 'h0;
                                instr_rs1  = 'h0;
                                instr_rs2  = 'h0;        
                              end   
    17'b???????_000_1110011 : begin  //Fence.I
                                instr_main = RV_SYSTEM;
                                instr_func = (dec_instr[31:21]== 11'b0)  ?  (dec_instr[20]  : EBREAK : ECALL ): SYS_OTHERS;
                                instr_immd = 'h0;
                                instr_rd   = 'h0;
                                instr_rs1  = 'h0;
                                instr_rs2  = 'h0;        
                              end  
    17'b???????_010_0000111 : begin //float load word,  f[rd] <- MEM[[rs1] + immediate]
                                instr_main = RV_FPU;
                                instr_func = FLW;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20] };;
                                instr_rd   =  dec_instr[11:4];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  = 'h0;                                     
                              end 
    17'b???????_011_0000111 : begin //double load word,  d[rd] <- MEM[[rs1] + immediate]
                                instr_main = RV_FPU;
                                instr_func = FLD;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:20] };;
                                instr_rd   =  dec_instr[11:4];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  = 'h0;                                     
                              end 

    17'b???????_010_0100111 : begin //float store word,   MEM[[rs1] + immediate] <- f[rs2]
                                instr_main = RV_FPU;
                                instr_func = FSW;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:25], dec_instr[11:7] };;
                                instr_rd   = 'h0;
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                                     
                              end  
    17'b???????_010_0100111 : begin //double store word,   MEM[[rs1] + immediate] <- d[rs2]
                                instr_main = RV_FPU;
                                instr_func = FSD;
                                instr_immd = {{20{dec_instr[31]}}, dec_instr[31:25], dec_instr[11:7] };;
                                instr_rd   = 'h0;
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                                     
                              end    
    17'b0000000_???_1010011 : begin //float add,   f[rd] <- f[rs1] + f[rs2]
                                instr_main = RV_FPU;
                                instr_func = FADDS;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11: 7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                                     
                              end  
    17'b0000001_???_1010011 : begin //double add,   d[rd] <- d[rs1] + d[rs2]
                                instr_main = RV_FPU;
                                instr_func = FADDD;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11: 7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                                     
                              end  
    17'b0000100_???_1010011 : begin //float sub,   f[rd] <- f[rs1] - f[rs2]
                                instr_main = RV_FPU;
                                instr_func = FSUBS;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11: 7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                                     
                              end       
    17'b0000101_???_1010011 : begin //double sub,   f[rd] <- f[rs1] - f[rs2]
                                instr_main = RV_FPU;
                                instr_func = FSUBD;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11: 7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                                     
                              end 
    17'b0001000_???_1010011 : begin //float mul,   f[rd] <- f[rs1] * f[rs2]
                                instr_main = RV_FPU;
                                instr_func = FMULS;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11: 7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                                     
                              end  
    17'b0001001_???_1010011 : begin //double mul,   d[rd] <- d[rs1] * d[rs2]
                                instr_main = RV_FPU;
                                instr_func = FMULD;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11: 7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                                     
                              end  
    17'b0001100_???_1010011 : begin //float div,   f[rd] <- f[rs1] / f[rs2]
                                instr_main = RV_FPU;
                                instr_func = FDIVS;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11: 7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                                     
                              end  
    17'b0001101_???_1010011 : begin //double div,   f[rd] <- f[rs1] / f[rs2]
                                instr_main = RV_FPU;
                                instr_func = FDIVD;
                                instr_immd = 'h0;
                                instr_rd   =  dec_instr[11: 7];
                                instr_rs1  =  dec_instr[19:15];
                                instr_rs2  =  dec_instr[24:20];                                     
                              end  
    default                 : begin 
                                $display("Unknown RISCV instruction : %08x", dec_instr);
                              end 
  endcase 
end 

endmodule 
