//Author  : AlexZhang (cgalexzhang@sina.com)
//Date    : 01-06-2020
//Comment : Instruction memory initial verison inorder to start the Decoder
//          16KB memory size with Word align
module RVMemory (
input             mclk,
input             rstn, 
input      [31:0] PC  ,
output reg [31:0] instrData
);

reg [31:0]  iMemory[0:4096];

initial begin 
  //$readmemh ();
end 

wire [11:0] addr;
//PC is byte index
assign addr = PC[13:2];

always @(posedge mclk or negedge rstn)
  if (~rstn) begin 
    instrData <= 32'h0;
  end else begin 
    instrData <= iMemory[addr];
  end 


endmodule 
