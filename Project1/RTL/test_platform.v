//
// 验证平台代码
//

module test_platform(
    input       clk,
    input       rst,
    output reg  clk_out
);

partfreq    partfreq_test(
    .clk        (clk),
    .rst        (rst),
    .clk_out    (clk_out)
);



endmodule