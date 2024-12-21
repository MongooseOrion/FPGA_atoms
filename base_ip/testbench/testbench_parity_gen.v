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
// 奇偶校验生成器验证
//
`timescale 1ns/1ps

module testbench_parity_gen(

);

parameter CLK_PERIOD = 20;

reg    clk;
reg    rstn;
reg    data_valid;
reg [7:0] data_in;

wire   data_ready_out;
wire [8:0] data_out;

parity_gen#(
    .DATA_WIDTH     (8),
    .PARITY_TYPE    (1'b1)
) parity_gen_inst(
    .clk            (clk),
    .rstn           (rstn),
    .data_valid     (data_valid),
    .data_in        (data_in),
    .data_ready_out (data_ready_out),
    .data_out       (data_out)
);

always #(CLK_PERIOD/2) clk = ~clk;

initial begin
    clk = 0;
    rstn = 0;
    data_valid = 0;
    data_in = 8'b0;

    #100;
    rstn = 1;
    #40;
    @(posedge clk)
    data_valid = 1'b1;
    data_in = 8'b10101010;
    @(posedge clk)
    data_valid = 1'b0;

    #100;
    @(posedge clk)
    data_valid = 1'b1;
    data_in = 8'b10101011;
    @(posedge clk)
    data_valid = 1'b0;

    #100;
    $stop;
end

endmodule