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
module carry_lookahead_adder(
  input  [3:0]      A_in  ,
  input  [3:0]      B_in  ,
  input             C_in  ,

  output            CO    ,
  output [3:0]      S
);
    
wire [3:0] G;
wire [3:0] P;
wire [3:0] C;

// ��λ�����źţ���ʾ�� i λ��ֱ�ӽ�λ�����ź�
assign G[0] = A_in[0] & B_in[0];
assign G[1] = A_in[1] & B_in[1];
assign G[2] = A_in[2] & B_in[2];
assign G[3] = A_in[3] & B_in[3];

// ��λ�����źţ��� P[i] Ϊ 1 ʱ���� i λ�ļӷ��Ὣ����ǰһλ�Ľ�λ���ݵ���һλ
assign P[0] = A_in[0] ^ B_in[0];
assign P[1] = A_in[1] ^ B_in[1];
assign P[2] = A_in[2] ^ B_in[2];
assign P[3] = A_in[3] ^ B_in[3];

// C[i] ��ʾ�� i λ�Ľ�λ
assign C[0] = G[0] | P[0] & C_in;
assign C[1] = G[1] | P[1] & C[0];
assign C[2] = G[2] | P[2] & C[1];
assign C[3] = G[3] | P[3] & C[2];

// S[i] ��ʾ�� i λ�ĺ�
assign S[0] = P[0] ^ C_in;
assign S[1] = P[1] ^ C[0];
assign S[2] = P[2] ^ C[1];
assign S[3] = P[3] ^ C[2];

// CO ��ʾ���λ�Ľ�λ
assign CO = C[3];
    
endmodule