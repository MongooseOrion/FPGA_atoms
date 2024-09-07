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
// 串行信号转并行信号
`timescale 1ns/1ps
module serial_to_parallel#(
    parameter DATA_WIDTH = 8
)(
    input                           clk,
    input                           rstn,
    input                           data_valid,
    input                           serial_data,

    output                          data_ready_out,
    output  [DATA_WIDTH-1'b1:0]     parallel_data
);

localparam DATA_NUM = DATA_WIDTH - 1'b1;

reg                                 data_valid_1;
reg                                 serial_data_1;
reg [$clog2(DATA_WIDTH)-1'b1:0]     cnt_bit;
reg                                 data_ready_out_reg;
reg [DATA_WIDTH-1'b1:0]             parallel_data_reg;

assign data_ready_out = data_ready_out_reg;
assign parallel_data = parallel_data_reg;


// 将输入数据延迟一拍
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        data_valid_1 <= 1'b0;
        serial_data_1 <= 1'b0;
    end
    else begin
        data_valid_1 <= data_valid;
        serial_data_1 <= serial_data;
    end
end


// 计数信号
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        cnt_bit <= 'b0;
    end
    else begin
        if(data_valid_1 == 1'b1) begin
            if(cnt_bit < DATA_NUM) begin
                cnt_bit <= cnt_bit + 1'b1;
            end
            else begin
                cnt_bit <= 'd0;
            end
        end
        else begin
            cnt_bit <= cnt_bit;
        end
    end
end


// 拼合并行数据
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        parallel_data_reg <= 'b0;
    end
    else begin
        if((cnt_bit <= DATA_NUM) && (data_valid_1 == 1'b1)) begin
            parallel_data_reg <= {serial_data_1, parallel_data_reg[DATA_WIDTH-1'b1:1]};
        end
        else if(data_ready_out == 1'b1) begin
            parallel_data_reg <= 'd0;
        end
        else begin
            parallel_data_reg <= parallel_data_reg;
        end
    end
end


// 准备好输出信号
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        data_ready_out_reg <= 1'b0;
    end
    else begin
        if(cnt_bit == DATA_NUM) begin
            data_ready_out_reg <= 1'b1;
        end
        else begin
            data_ready_out_reg <= 1'b0;
        end
    end
end


endmodule