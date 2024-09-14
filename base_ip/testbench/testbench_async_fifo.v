/* =======================================================================
* Copyright (c) 2023, MongooseOrion.
* All rights reserved.
*
* The following code snippet may contain portions that are derived from
* OPEN-SOURCE communities, and these portions will be licensed with: 
*
* <NULL>
*
* If there is no OPEN-SOURCE licenses are listed, it indicates none of
* content in this Code document is sourced from OPEN-SOURCE communities. 
*
* In this case, the document is protected by copyright, and any use of
* all or part of its content by individuals, organizations, or companies
* without authorization is prohibited, unless the project repository
* associated with this document has added relevant OPEN-SOURCE licenses
* by github.com/MongooseOrion. 
*
* Please make sure using the content of this document in accordance with 
* the respective OPEN-SOURCE licenses. 
* 
* THIS CODE IS PROVIDED BY https://github.com/MongooseOrion. 
* FILE ENCODER TYPE: GBK
* ========================================================================
*/
// 异步 FIFO 验证平台
`timescale 1ns/1ps
module testbench_async_fifo(

);

reg         wr_clk;
reg         wr_rstn;
reg         wr_en;
reg [7:0]   wr_data;

reg         rd_clk;
reg         rd_rstn;
reg         rd_en;

wire        wr_full;
wire        rd_empty;
wire [9:0]  wr_count;
wire [9:0]  rd_count;
wire [7:0]  rd_data;

parameter WR_CLK_PERIOD = 20;
parameter RD_CLK_PERIOD = 10;


// 产生时钟
always #(WR_CLK_PERIOD/2) wr_clk = ~wr_clk;
always #(RD_CLK_PERIOD/2) rd_clk = ~rd_clk;


// 例化模块
async_fifo #(
    .ADDR_WIDTH('d7),
    .DATA_WIDTH('d8)
) async_fifo_inst(
    .wr_clk         (wr_clk),
    .wr_rstn        (wr_rstn),
    .wr_en          (wr_en),
    .wr_data        (wr_data),
    .wr_full        (wr_full),
    .wr_count       (wr_count),
    .rd_clk         (rd_clk),
    .rd_rstn        (rd_rstn),
    .rd_en          (rd_en),
    .rd_data        (rd_data),
    .rd_empty       (rd_empty),
    .rd_count       (rd_count)
);

integer i;
// 产生写通道数据
initial begin
    wr_clk = 1'b0;
    wr_rstn = 1'b0;
    #500;
    wr_rstn = 1'b1;
    #500;
    wr_en = 1'b1;
    for(i=0; i<2048; i=i+1) begin
        wr_data = i;
        #WR_CLK_PERIOD;
    end
    #500;
end

// 产生读通道数据
initial begin
    rd_clk = 1'b0;
    rd_rstn = 1'b0;
    #500;
    rd_rstn = 1'b1;
    #2000;
    rd_rstn = 1'b1;
    #500;
    rd_en = 1'b1;
    #3000;
    $stop;
end

endmodule