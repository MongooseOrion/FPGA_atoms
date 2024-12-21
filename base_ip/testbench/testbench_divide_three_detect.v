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
// 模三序列检测器验证代码
//
`timescale 1ns/1ps

module testbench_divide_three_detect(

);

parameter CLK_PERIOD = 20;

reg clk;
reg rst_n;
reg data_in;
reg valid;

wire detect_true;

// 连接
divide_three_detect divide_three_detect_inst(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid(valid),
    .detect_true(detect_true)
);


// 时钟
always #(CLK_PERIOD/2) clk = ~clk;


// 初始化
initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    data_in = 1'b0;
    valid = 1'b0;
    #100;
    rst_n = 1'b1;
    #100

    @(posedge clk);
    valid = 1'b1;
    data_in = 1'b1;
    @(posedge clk);
    data_in = 1'b0;
    #50;
    @(posedge clk);
    data_in = 1'b1;
    #100;
    @(posedge clk);
    data_in = 1'b0;
    @(posedge clk);
    valid = 1'b0;

    #100;
    $stop;
end

endmodule