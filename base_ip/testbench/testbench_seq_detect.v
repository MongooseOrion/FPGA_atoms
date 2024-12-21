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
// 序列检测器验证代码
//
`timescale 1ns/1ps

module testbench_seq_detect(

);

reg                 clk;
reg                 rstn;
reg                 data;
wire                seq_true;

parameter CLK_PERIOD = 20;

seq_detect seq_detect_inst(
    .clk        (clk),
    .rstn       (rstn),
    .data       (data),
    .seq_true   (seq_true)
);

always #(CLK_PERIOD/2) clk = ~clk;

initial begin
    clk = 1'b0;
    rstn = 1'b0;
    data = 1'b0;
    #100;
    rstn = 1'b1;
    #100;
    @(posedge clk);
    data = 1'b0;
    @(posedge clk);
    data = 1'b1;
    @(posedge clk);
    data = 1'b0;
    @(posedge clk);
    data = 1'b0;
    @(posedge clk);
    data = 1'b1;
    @(posedge clk);
    data = 1'b0;
    @(posedge clk);
    data = 1'b0;
    @(posedge clk);
    data = 1'b0;
    @(posedge clk);
    data = 1'b1;
    @(posedge clk);
    data = 1'b0;
    @(posedge clk);
    data = 1'b0;
    #50;
    $stop;
end

endmodule