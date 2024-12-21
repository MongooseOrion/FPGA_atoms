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
// 脉冲异步时钟同步器验证代码
//
`timescale 1ns/1ps

module testbench_pulse_sync(

);

parameter CLK_PERIOD_IN = 10;
parameter CLK_PERIOD_OUT = 24;

reg     clk_in;
reg     pulse_in;
reg     clk_out;

wire    pulse_out;

pulse_sync pulse_sync_inst(
    .clk_in     (clk_in),
    .pulse_in   (pulse_in),
    .clk_out    (clk_out),
    .pulse_out  (pulse_out)
);

always #(CLK_PERIOD_IN/2) clk_in = ~clk_in;
always #(CLK_PERIOD_OUT/2) clk_out = ~clk_out;

initial begin
    clk_in = 1'b0;
    pulse_in = 1'b1;
    clk_out = 1'b0;

    #100;
    @(posedge clk_in)
    pulse_in = 1'b0;
    @(posedge clk_in)
    pulse_in = 1'b1;
    #100;
    @(posedge clk_in)
    pulse_in = 1'b0;
    @(posedge clk_in)
    pulse_in = 1'b1;

    #100;

    $stop;
end


endmodule