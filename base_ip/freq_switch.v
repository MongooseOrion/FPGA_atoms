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
// 输入 2 时钟，根据选择信号实现频率切换，且无毛刺
//
`timescale 1ns/1ps

module freq_switch(
    input               clk_1,
    input               clk_2,
    input               sel,
    output reg          clk_out
);

reg     sel_clk_1;
reg     sel_clk_2;


// 基于两者的下降沿采集片选信号，假设 sel 为 0 时，输出 clk_1，否则输出 clk_2
always @(negedge clk_1) begin
    if(sel_clk_2 == 1'b0) begin
        sel_clk_1 <= ~sel;
    end
    else begin
        sel_clk_1 <= 1'b0;
    end
end

always @(negedge clk_2) begin
    if(sel_clk_1 == 1'b0) begin
        sel_clk_2 <= sel;
    end
    else begin
        sel_clk_2 <= 1'b0;
    end
end


// 根据先后顺序输出时钟
always @(*) begin
    if(sel_clk_1 == 1'b1) begin
        clk_out = clk_1;
    end
    else if(sel_clk_2 == 1'b1) begin
        clk_out = clk_2;
    end
    else begin
        clk_out = 1'b0;
    end
end



endmodule