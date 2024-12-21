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
// 统计输入的多比特信号中 1 的个数，并且输出等于 1 的最高数位和最低数位索引
//
`timescale 1ns/1ps

module num_one_counter#(
    parameter DATA_WIDTH = 8
)(
    input                           clk,
    input                           rstn,
    input                           data_valid,
    input [DATA_WIDTH-1:0]          data_in,
    output                          data_ready_out,
    output [$clog2(DATA_WIDTH):0]   num_of_one,
    output [$clog2(DATA_WIDTH):0]   max_index,
    output [$clog2(DATA_WIDTH):0]   min_index
);

reg                             data_ready_out_reg; 
reg [$clog2(DATA_WIDTH):0]      num_of_one_reg_1='b0;
reg [$clog2(DATA_WIDTH):0]      num_of_one_reg_2;
reg [$clog2(DATA_WIDTH):0]      max_index_reg=DATA_WIDTH-1'b1;
reg [$clog2(DATA_WIDTH):0]      min_index_reg=DATA_WIDTH-1'b1;

assign min_index = min_index_reg;
assign max_index = max_index_reg;
assign num_of_one = num_of_one_reg_2;
assign data_ready_out = data_ready_out_reg;


// 统计输入信号中 1 的个数
integer i;
always @(*) begin
    num_of_one_reg_1 = 'b0;
    for(i=0; i<DATA_WIDTH; i=i+1) begin
        if(data_in[i] == 1'b1) begin
            num_of_one_reg_1 = num_of_one_reg_1 + 1'b1;
        end
    end
end


// 输出数据有效和统计 1 数量数据信号
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        data_ready_out_reg <= 1'b0;
        num_of_one_reg_2 <= 'b0;
    end
    else if(data_valid == 1'b1) begin
        data_ready_out_reg <= 1'b1;
        num_of_one_reg_2 <= num_of_one_reg_1;
    end
    else begin
        data_ready_out_reg <= 1'b0;
        num_of_one_reg_2 <= num_of_one_reg_2;
    end
end


// 输出最高位和最低位索引
/*
always @(*) begin
    for(i=0; i<DATA_WIDTH; i=i+1) begin
        if(data_in[i] == 1'b1) begin
            min_index_reg = i;
            break;
        end
    end
end

always @(*) begin
    for(i=DATA_WIDTH-1; i>=0; i=i-1) begin
        if(data_in[i] == 1'b1) begin
            max_index_reg = i;
            break;
        end
    end
end
*/

endmodule