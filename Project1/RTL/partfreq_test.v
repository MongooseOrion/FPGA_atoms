#
# 验证平台代码
#

module partfreq_test(
    input       clk,
    input       rst,
    output reg  clk_out
);

partfreq    partfreq_test_1(
    .clk        (clk),
    .rst        (rst),
    .clk_out    (clk_out)
);



endmodule