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
// ÐòÁÐ¼ì²âÆ÷
//
`timescale 1ns/1ps

module seq_detect(
    input               clk,
    input               rstn,
    input               data,
    output              seq_true
);

parameter SEQ = 4'b1001;
parameter S0 = 4'b0000,
          S1 = 4'b0001,
          S2 = 4'b0010,
          S3 = 4'b0100,
          S4 = 4'b1000;

reg [3:0]  state;

assign seq_true = ((state == S3) && (data == SEQ[3]));

// ×´Ì¬»ú
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        state <= 'b0;
    end
    else begin
        case(state)
            S0: begin
                if(data == SEQ[0]) begin
                    state <= S1;
                end
                else begin
                    state <= S0;
                end
            end
            S1: begin
                if(data == SEQ[1]) begin
                    state <= S2;
                end
                else begin
                    state <= S0;
                end
            end
            S2: begin
                if(data == SEQ[2]) begin
                    state <= S3;
                end
                else begin
                    state <= S0;
                end
            end
            S3: begin
                state <= S0;
            end
            default: begin
                state <= S0;
            end
        endcase
    end
end

endmodule