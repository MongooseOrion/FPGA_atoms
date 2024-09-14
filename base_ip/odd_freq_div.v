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
// 占空比 50% 的奇数分频
`timescale 1ns/1ps

module odd_freq_div #(
    parameter DIV_NUM = 'd7
)(
    input           clk_i,
    input           rst_n,
    output          clk_o
);

localparam CLK_CNT_NUM = DIV_NUM - 1'b1;
localparam CLK_HIGH_CNT = CLK_CNT_NUM / 2;

reg [$clog2(DIV_NUM)+1:0]   cnt_posedge;
reg [$clog2(DIV_NUM)+1:0]   cnt_negedge;
reg                         clk_phase_posedge;
reg                         clk_phase_negedge;

// 时钟输出
assign clk_o = clk_phase_posedge | clk_phase_negedge;


// 上升沿触发的时钟计数器
always @(posedge clk_i or negedge rst_n) begin
    if(!rst_n) begin
        cnt_posedge <= 'b0;
    end
    else begin
        if(cnt_posedge == CLK_CNT_NUM) begin
            cnt_posedge <= 'd0;
        end
        else begin
            cnt_posedge <= cnt_posedge + 1'b1;
        end
    end
end


// 下降沿触发的时钟计数器
always @(negedge clk_i or negedge rst_n) begin
    if(!rst_n) begin
        cnt_negedge <= 'b0;
    end
    else begin
        if(cnt_negedge == CLK_CNT_NUM) begin
            cnt_negedge <= 'd0;
        end
        else begin
            cnt_negedge <= cnt_negedge + 1'b1;
        end
    end
end


// 以上升沿触发的计数器控制的时钟相位
always @(posedge clk_i or negedge rst_n) begin
    if(!rst_n) begin
        clk_phase_posedge <= 1'b0;
    end
    else begin
        if(cnt_posedge == 'b0) begin
            clk_phase_posedge <= 1'b1;
        end
        else if(cnt_posedge == CLK_HIGH_CNT) begin
            clk_phase_posedge <= 1'b0;
        end
        else begin
            clk_phase_posedge <= clk_phase_posedge;
        end
    end
end


// 以下降沿触发的计数器控制的时钟相位
always @(negedge clk_i or negedge rst_n) begin
    if(!rst_n) begin
        clk_phase_negedge <= 1'b0;
    end
    else begin
        if(cnt_negedge == 'b0) begin
            clk_phase_negedge <= 1'b1;
        end
        else if(cnt_negedge == CLK_HIGH_CNT) begin
            clk_phase_negedge <= 1'b0;
        end
        else begin
            clk_phase_negedge <= clk_phase_negedge;
        end
    end
end

endmodule