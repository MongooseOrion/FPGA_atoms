module mul2port(
    input               clk,
    input               rst,
    input   wire        sel_a,
    input   wire        sel_b,
    input   wire  [2:0] din_a,
    input   wire  [1:0] din_b,
    input   wire  [3:0] din_c,
    input   wire  [3:0] din_d,
    output  reg   [6:0] result_a,
    output  reg   [5:0] result_b
);

reg         clk_sel;
reg  [3:0]  sel_rel;
reg         a_and_b;

wire [6:0]  result_a_tmp;
wire [5:0]  result_b_tmp;


//
// 一级结构
//
always@(*)
begin
   a_and_b = sel_a && sel_b;
end

always@(posedge clk or negedge rst)
begin
    if(!rst) begin
        clk_sel <= 1'b0;
    end
    else begin
        clk_sel <= a_and_b;
    end
end

always@(*)
begin
    if(clk_sel == 1'b0) begin
        sel_rel = din_c;
    end
    else begin
        sel_rel = din_d;
end

//
// 二级结构
//
// 对 mul 模块的预定义参数进行修改，以匹配此处信号位宽
mul_module#(.A_W(3),.B_W(4)) mul_module_1(
    .mul_a          (din_a),
    .mul_b          (sel_rel),
    .sysclk         (clk),
    .rst            (rst),
    .mul_result     (result_a_tmp)
);

mul_module#(.A_W(2),.B_W(4)) mul_module_2(
    .mul_a          (din_b),
    .mul_b          (sel_rel),
    .sysclk         (clk),
    .rst            (rst),
    .mul_result     (result_b_tmp)
);

//
// 三级结构
//
always@(posedge clk or negedge rst)
begin
    if(!rst) begin
        result_a <= 0;
    end
    else begin
        result_a <= result_a_tmp;
    end
end

always@(posedge clk or negedge rst)
begin
    if(!rst) begin
        result_b <= 0;
    end
    else begin
        result_b <= result_b_tmp;
    end
end

endmodule
