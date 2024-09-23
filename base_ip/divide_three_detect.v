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
// 模三序列检测器
`timescale 1ns/1ps

module divide_three_detect(
    input               clk,
    input               rst_n,
    input               data_in,
    input               valid,
    output              detect_true
);

parameter INIT = 4'b0000,
          S0 = 4'b0001,
          S1 = 4'b0010,
          S2 = 4'b0100,
          S3 = 4'b1000;

reg [3:0]   state;


// 状态转移
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= INIT;
    end
    else begin
        case(state)
            INIT: begin
                if((valid == 1'b1) && (data_in == 1'b1)) begin
                    state <= S1;
                end
                else begin
                    state <= INIT;
                end
            end
            S0: begin               // 余数为 1 的情况
                if(valid == 1'b1) begin
                    if(data_in == 1'b1) begin
                        state <= S1;
                    end
                    else begin
                        state <= INIT;
                    end
                end
                else begin
                    state <= state;
                end
            end
            S1: begin               // 余数为 2 的情况
                if(valid == 1'b1) begin
                    if(data_in == 1'b1) begin
                        state <= S2;
                    end
                    else begin
                        state <= S0;
                    end
                end
                else begin
                    state <= state;
                end
            end
            S2: begin
                if(valid) begin
                    if(data_in == 1'b1) begin
                        state <= S2;
                    end
                    else begin
                        state <= S0;
                    end
                end
                else begin
                    state <= state;
                end
            end
            default: begin
                state <= INIT;
            end
        endcase
    end
end


// 输出
assign data_out = (state == S2) ? 1'b1 : 1'b0;


endmodule