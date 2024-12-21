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
// 使用 2 选 1 多路选择器实现 N 选 1 多路选择器
//
module mux_n#(
    parameter N = 8, 
    parameter WIDTH = 1
)(
    input  [N*WIDTH-1:0]        data_in,
    input  [$clog2(N)-1:0]      sel, 
    output [WIDTH-1:0]          data_out
);

localparam STAGES = $clog2(N);                              // 总的级数
wire [WIDTH-1:0] stage_out [0:STAGES-1][0:(1<<STAGES)-1];   // 每级的输出信号


// 初始阶段（第 0 级）：直接将输入连接到第 0 级的输出
genvar i;
generate
    for (i = 0; i < N; i = i + 1) begin
        assign stage_out[0][i] = data_in[i*WIDTH +: WIDTH];
    end
endgenerate


// 后续阶段：逐步合并信号
genvar stage, idx;
generate
    for (stage = 1; stage < STAGES; stage = stage + 1) begin : stage_gen
        for (idx = 0; idx < (1 << (STAGES - stage)); idx = idx + 1) begin : mux_gen
            mux2 #(
                .WIDTH  (WIDTH)
            ) u_mux2(
                .in1    (stage_out[stage-1][2*idx]),
                .in2    (stage_out[stage-1][2*idx+1]),
                .sel    (sel[STAGES-stage]),
                .out    (stage_out[stage][idx])
            );
        end
    end
endgenerate

// 最后一级的输出
assign data_out = stage_out[STAGES-1][0];

endmodule


// 2选1多路选择器模块
module mux2 #(
    parameter WIDTH = 1
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  sel,
    output [WIDTH-1:0] y
);
assign y = sel ? b : a;

endmodule