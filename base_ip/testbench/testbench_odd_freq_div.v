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
// 占空比 50% 的奇数分频的验证平台
`timescale 1ns/1ps

module testbench_odd_freq_div(

);

parameter CLK_PERIOD = 20;

reg clk_i;
reg rst_n;

wire clk_o;

// 生成时钟
always #(CLK_PERIOD/2) clk_i = ~clk_i;

// 例化
odd_freq_div #(
    .DIV_NUM    (3)
) u_odd_freq_div(
    .clk_i(clk_i),
    .rst_n(rst_n),
    .clk_o(clk_o)
);


// 初始化时钟和复位
initial begin
    clk_i = 1'b0;
    rst_n = 1'b0;
    #100;
    @(posedge clk_i);
    rst_n = 1'b1;
    #1500;
    $stop;
end


endmodule