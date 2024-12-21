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
// ��żУ��������
//
`timescale 1ns/1ps

module parity_gen#(
    parameter DATA_WIDTH = 8,
    parameter PARITY_TYPE = 1'b0        // 0: ��У�� 1: żУ��
)(
    input                   clk,
    input                   rstn,
    input                   data_valid,
    input [DATA_WIDTH-1:0]  data_in,

    output reg                  data_ready_out,
    output reg [DATA_WIDTH:0]   data_out
);

wire        check_bit;          // ��� 1 �ĸ�����Ϊ 0 ��ʾż������

assign check_bit = (data_valid == 1'b1) ? ^data_in : 1'b0;


// ������żУ���ź�
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        data_ready_out <= 1'b0;
        data_out <= 'd0;
    end
    else if(data_valid == 1'b1) begin
        data_ready_out <= 1'b1;
        data_out = {~(PARITY_TYPE ^ check_bit), data_in};
    end
    else begin
        data_ready_out <= 1'b0;
        data_out <= data_out;
    end
end


endmodule 