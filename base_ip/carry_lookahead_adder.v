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
// 4 λ��ǰ��λ�ӷ���
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

// CO ��ʾ���λ�Ľ�λ
assign CO = C[DATA_WIDTH-1];

generate
    genvar i;
    for(i = 0; i < DATA_WIDTH; i = i + 1) begin : default_name
        // ��λ�����źţ���ʾ�� i λ��ֱ�ӽ�λ�����ź�
        assign G[i] = A_in[i] & B_in[i];
        
        // ��λ�����źţ��� P[i] Ϊ 1 ʱ���� i λ�ļӷ��Ὣ����ǰһλ�Ľ�λ���ݵ���һλ
        assign P[i] = A_in[i] ^ B_in[i];
        
        // C[i] ��ʾ�� i λ�Ľ�λ��S[i] ��ʾ�� i λ�ĺ�
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