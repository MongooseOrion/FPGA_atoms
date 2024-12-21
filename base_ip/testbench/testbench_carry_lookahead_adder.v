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
// 超前进位加法器验证
//
`timescale 1ns/1ps

module testbench_carry_lookahead_adder(

);

parameter CLK_PERIOD = 20;

reg   clk;
reg   rstn;
reg [7:0] a_in;
reg [7:0]  b_in;
reg   cin_in;

wire  co;
wire [7:0] s;

carry_lookahead_adder#(
    .DATA_WIDTH (8)
) carry_lookahead_adder_inst(
    .A_in       (a_in),
    .B_in       (b_in),
    .C_in     (cin_in),
    .CO         (co),
    .S          (s)
);

always #(CLK_PERIOD/2) clk = ~clk;

initial begin
    clk = 0;
    rstn = 0;

    #100;
    rstn = 1;
    a_in = 8'd23;
    b_in = 8'd45;
    cin_in = 1'b1;

    #100;
    a_in = 8'd254;
    b_in = 8'd1;
    cin_in = 1'b0;

    #100;
    a_in = 8'd255;
    b_in = 8'd1;
    cin_in = 1'b1;

    #100;
    $stop;

end

endmodule