///////////////////////////////////
// 四位加法器验证平台代码
///////////////////////////////////

`timescale 1ns/1ps
module testbench_sumfour(

);

parameter CLK_PERIORD = 10;

reg         clk;
reg         rst;
wire [3:0]  o_cnt_1;
wire [3:0]  o_cnt_2;

// 连接模块
sumfour sumfour_test(
    .clk        (clk),
    .rst        (rst),
    .o_cnt_1    (o_cnt_1),
    .o_cnt_2    (o_cnt_2)
);

// 初始化时钟
initial begin
    clk <= 0;
    rst <= 0;
    #1000;
    rst <= 1;
end

always #(CLK_PERIORD / 2) clk = ~clk;

// 产生测试信号

endmodule

