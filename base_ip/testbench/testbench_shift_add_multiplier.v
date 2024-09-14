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
// 8bit 移位相加乘法器验证平台
`timescale 1ns/1ps
module testbench_shift_add_multiplier(

);

parameter CLK_PERIOD = 20;
parameter DATA_WIDTH = 'd8;

reg                     clk;
reg                     rst_n;
reg [DATA_WIDTH-1'b1:0] a;
reg [DATA_WIDTH-1'b1:0] b;
reg                     valid;

wire                        done;
wire [DATA_WIDTH*2-1'b1:0]  result;

always #(CLK_PERIOD/2) clk = ~clk;


shift_add_multiplier #(
    .DATA_WIDTH(8)
) u_shift_add_multiplier(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .valid(valid),
    .done(done),
    .result(result)
);


initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    #500;
    rst_n = 1'b1;
    
    #100;
    @(posedge clk);
    a = 'd15;
    b = 'd11;
    valid = 1'b1;
    @(posedge clk);
    valid = 1'b0;

    @(negedge done)
    #100
    @(posedge clk);
    a = 'd255;
    b = 'd255;
    valid = 1'b1;
    @(posedge clk);
    valid = 1'b0;
    #300;
    $stop;
end

endmodule
