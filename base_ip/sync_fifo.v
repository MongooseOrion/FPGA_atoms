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
//
// 同步 FIFO
`timescale 1ns/1ps

module sync_fifo#(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 8
)(
    input                               clk     ,
    input                               rstn    ,

    input                               wr_en   ,
    input       [DATA_WIDTH-1'b1:0]     wr_data ,
    output                              wr_full ,

    input                               rd_en   ,
    output      [DATA_WIDTH-1'b1:0]     rd_data ,
    output                              rd_empty
);

reg [ADDR_WIDTH:0]      wr_addr;
reg [ADDR_WIDTH:0]      rd_addr;

// 写满和读空
assign wr_full = (rd_addr == {~wr_addr[ADDR_WIDTH], wr_addr[ADDR_WIDTH-1:0]});
assign rd_empty = (rd_addr == wr_addr);


// 读写地址
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        wr_addr <= 0;
    end
    else begin
        if((wr_en == 1'b1) && (wr_full == 1'b0)) begin
            wr_addr <= wr_addr + 1;
        end
        else begin
            wr_addr <= wr_addr;
        end
    end
end

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        rd_addr <= 0;
    end
    else begin
        if((rd_en == 1'b1) && (rd_empty == 1'b0)) begin
            rd_addr <= rd_addr + 1;
        end
        else begin
            rd_addr <= rd_addr;
        end
    end
end


// RAM
dual_port_RAM #(
    .ADDR_WIDTH     (ADDR_WIDTH),
    .DATA_WIDTH     (DATA_WIDTH)
) dual_port_RAM_inst (
    .wr_clk         (clk),
    .wr_en          ((wr_en) && (!wr_full)),
    .wr_addr        (wr_addr[ADDR_WIDTH-1:0]),  
    .wr_data        (wr_data),       
    .rd_clk         (clk),
    .rd_en          ((rd_en) && (!rd_empty)),
    .rd_addr        (rd_addr[ADDR_WIDTH-1:0]),  //深度对2取对数，得到地址的位宽。
    .rd_data        (rd_data)   //数据输出
);


endmodule