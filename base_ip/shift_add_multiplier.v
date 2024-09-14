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
// 8bit 移位相加乘法器
`timescale 1ns/1ps
module shift_add_multiplier#(
    parameter DATA_WIDTH = 'd8
)(
    input                           clk,
    input                           rst_n,
    input  [DATA_WIDTH-1'b1:0]      a,
    input  [DATA_WIDTH-1'b1:0]      b,
    input                           valid,
    output                          done,
    output                          state,  // 0: idle, 1: busy
    output [DATA_WIDTH*2-1'b1:0]    result
);

reg [$clog2(DATA_WIDTH):0]      cnt;
reg [DATA_WIDTH-1'b1:0]         multiplicand;   // 被乘数
reg [DATA_WIDTH-1'b1:0]         multiplier;     // 乘数
reg [DATA_WIDTH*2-1'b1:0]       product;        // 乘积
reg                             finish;
reg                             enable;

assign done = finish;
assign result = product;
assign state = (enable || finish);


// 计算使能条件
always @(*) begin
    if(valid == 1'b1)begin
        enable = 1'b1;
    end
    else if(finish == 1'b1) begin
        enable = 1'b0;
    end
    else begin
        enable = enable;
    end
end


// 计数器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 'b0;
    end 
    else if(enable == 1'b1) begin
        if(cnt == DATA_WIDTH + 1'b1) begin
            cnt <= 'b0;
        end
        else begin
            cnt <= cnt + 1'b1;
        end
    end
    else begin
        cnt <= 'd0;
    end
end


// 乘法器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        multiplicand <= 'd0;
        multiplier <= 'd0;
        product <= 'd0;
    end
    else if(enable == 1'b1) begin
        if(cnt == 'd0) begin
            multiplicand <= a;
            multiplier <= b;
            product <= 'd0;
        end
        else if((cnt != 'd0) && (cnt <= DATA_WIDTH)) begin
            if(multiplier[0] == 1'b1) begin
                product <= product + (multiplicand << (cnt - 1'b1));
            end
            multiplier <= multiplier >> 1;
        end
    end
    else begin
        multiplicand <= 'd0;
        multiplier <= 'd0;
        product <= product;
    end
end


// 结束标志
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        finish <= 1'b0;
    end
    else if(enable == 1'b1) begin
        if(cnt == DATA_WIDTH + 1'b1) begin
            finish <= 1'b1;
        end
        else begin
            finish <= 1'b0;
        end
    end
    else begin
        finish <= 1'b0;
    end
end


endmodule