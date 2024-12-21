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
// 4 位超前进位加法器
`timescale 1ns/1ps

`timescale 1ns / 1ps
module carry_lookahead_adder#(
    parameter DATA_WIDTH = 4
)(
  input  [DATA_WIDTH-1:0]   A_in  ,
  input  [DATA_WIDTH-1:0]   B_in  ,
  input                     C_in  ,

  output                    CO    ,
  output [DATA_WIDTH-1:0]   S
);
    
wire [DATA_WIDTH-1:0]   G;
wire [DATA_WIDTH-1:0]   P;
wire [DATA_WIDTH-1:0]   C;

// CO 表示最高位的进位
assign CO = C[DATA_WIDTH-1];

generate
    genvar i;
    for(i = 0; i < DATA_WIDTH; i = i + 1) begin : default_name
        // 进位生成信号，表示第 i 位的直接进位生成信号
        assign G[i] = A_in[i] & B_in[i];
        
        // 进位传递信号，当 P[i] 为 1 时，第 i 位的加法会将来自前一位的进位传递到下一位
        assign P[i] = A_in[i] ^ B_in[i];
        
        // C[i] 表示第 i 位的进位，S[i] 表示第 i 位的和
        if(i==0) begin
            assign C[i] = G[i] | P[i] & C_in;
            assign S[i] = P[i] ^ C_in;
        end
        else begin
            assign C[i] = G[i] | P[i] & C[i-1];
            assign S[i] = P[i] ^ C[i-1];
        end
    end
endgenerate
    
endmodule