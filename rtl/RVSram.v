//Author  : AlexZhang (cgalexzhang@sina.com)
//Date    : 01-07-2020
//Comment : Two port SRAM 
//          read and write at the different ports
module RVSram #(parameter DW=32, AW = 6 ) (
input              sclk   ,
input              rstn   ,
input [AW-1:0]     wr_addr,
input [DW-1:0]     wr_data,
input              wr_en  ,
input              rd_en  ,
input [AW-1:0]     rd_addr,
output reg[DW-1:0] rd_data 
);

parameter depth  = 1'b1 << AW - 1;
reg [DW-1: 0] sram[0: depth];

always @(posedge sclk )
  if (wr_en)
    sram[wr_addr] <= wr_data;

always @(posedge sclk or negedge rstn)
  if (~rstn)
    rd_data <= 'h0;
  else 
    if (rd_en)
      rd_data <= sram[rd_addr];

endmodule 
