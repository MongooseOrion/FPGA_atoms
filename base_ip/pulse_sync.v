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
// 脉冲异步时钟同步器（快时钟域到慢时钟域）
//
`timescale 1ns/1ps

module pulse_sync(
    input                           clk_in,
    input                           pulse_in,

    input                           clk_out,
    output                          pulse_out
);

reg     pulse_reg_1;
reg     state=1'b0;
reg     pulse_cache;
reg     pulse_out_ready;
reg     pulse_out_reg;
reg     state_reg;

assign pulse_out = pulse_out_reg;


// 信号延迟
always @(posedge clk_in) begin
    pulse_reg_1 <= pulse_in;
end


// 在下级时钟域采集到数据前保持脉冲状态
always @(posedge clk_in) begin
    if(pulse_reg_1 == !pulse_in) begin
        state <= 1'b1;
    end
    else if(pulse_out_ready == 1'b1) begin
        state <= 1'b0;
    end
    else begin
    state <= state; 
    end
end


// 脉冲状态缓存
always @(posedge clk_in) begin
    if((pulse_reg_1 == !pulse_in) && (state == 1'b0)) begin
        pulse_cache <= pulse_in;
    end
    else begin
        pulse_cache <= pulse_cache;
    end
end


// 输出脉冲
always @(posedge clk_out) begin
    state_reg <= state;
end

always @(posedge clk_out) begin
    if(state && ~state_reg) begin
        pulse_out_ready <= 1'b1;
        pulse_out_reg <= pulse_cache;
    end
    else begin
        pulse_out_ready <= 1'b0;
        pulse_out_reg <= ~pulse_cache;
    end
end


endmodule