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
//  ±÷”«–ªª—È÷§
//
`timescale 1ns/1ps

module testbench_freq_switch(

);

parameter CLK_PERIOD_1 = 10;
parameter CLK_PERIOD_2 = 20;

reg     clk_1;
reg     clk_2;
reg     sel;
reg     rst_1;
reg     rst_2;

wire    clk_out;

freq_switch freq_switch_0(
    .clk_1(clk_1),
    .clk_2(clk_2),
    .sel(sel),
    .clk_out(clk_out)
);

always #(CLK_PERIOD_1/2) clk_1 = ~clk_1;

initial begin
    clk_2 = 1'b0;
    #123;
    forever #(CLK_PERIOD_2/2) clk_2 = ~clk_2;
end

initial begin
    clk_1 = 1'b0;
    sel = 1'b0;

    #247;
    sel = 1'b1;
    #240;
    sel = 1'b0;
    #243;
    sel = 1'b1;
    #200;
    $stop;

end

endmodule