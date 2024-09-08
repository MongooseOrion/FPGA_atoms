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
// Ë«¶Ë¿Ú RAM
module dual_port_RAM #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 8
)(
    input                               wr_clk  ,
    input                               wr_en   ,
    input       [ADDR_WIDTH-1'b1:0]     wr_addr ,
    input       [DATA_WIDTH-1'b1:0]     wr_data ,
    input                               rd_clk  ,
    input                               rd_en   ,
    input       [ADDR_WIDTH-1'b1:0]     rd_addr ,
    output      [DATA_WIDTH-1'b1:0]     rd_data
);

reg [DATA_WIDTH-1'b1:0] RAM_MEM [0:ADDR_WIDTH-1'b1];
reg [DATA_WIDTH-1'b1:0] rd_data_reg;

assign rd_data = rd_data_reg;

always @(posedge wr_clk ) begin
    if(wr_en) begin
        RAM_MEM[wr_addr] <= wr_data;
    end
    else begin
        RAM_MEM[wr_addr] <= RAM_MEM[wr_addr];
    end
end 

always @(posedge rd_clk) begin
    if(rd_en) begin
        rd_data_reg <= RAM_MEM[rd_addr];
    end
    else begin
        rd_data_reg <= rd_data_reg;
    end
end 

endmodule  