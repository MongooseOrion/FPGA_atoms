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
// 串行转并行验证代码
`timescale 1ns/1ps

module testbench_serial_to_parallel(
    
);

reg     clk;
reg     rstn;
reg     data_valid;
reg     serial_data;

wire        data_ready_out;
wire [7:0]  parallel_data;

parameter CLK_PERIOD = 20;

// 产生时钟
always #(CLK_PERIOD/2) clk = ~clk;

// 例化模块
serial_to_parallel #(
    .DATA_WIDTH(8)
) serial_to_parallel_inst (
    .clk            (clk),
    .rstn           (rstn),
    .data_valid     (data_valid),
    .serial_data    (serial_data),
    .data_ready_out (data_ready_out),
    .parallel_data  (parallel_data)
);


initial begin
    clk = 1'b0;
    rstn = 1'b0;

    #500; 
    rstn = 1'b1;

    repeat(10) begin
        @(posedge clk);
        data_valid = 1'b1;
        serial_data = 1'b1;
        #50;
        serial_data = 1'b0;
        #50;
        data_valid = 1'b0;
        #50;
    end

    $stop;
end


endmodule