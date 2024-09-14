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
// �첽 FIFO������˫�˿� RAM
`timescale 1ns/1ps

//
// ˫�˿� RAM
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

reg [DATA_WIDTH-1'b1:0] RAM_MEM [(2**ADDR_WIDTH)-1'b1:0];
reg [DATA_WIDTH-1'b1:0] rd_data_reg;

assign rd_data = rd_data_reg;

always @(posedge wr_clk) begin
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


//
// �첽 FIFO
module async_fifo#(
    parameter ADDR_WIDTH = 'd16,
    parameter DATA_WIDTH = 'd8
)(
    input                           wr_clk              , 
    input                           wr_rstn             ,
    input                           wr_en               ,
    input   [DATA_WIDTH-1'b1:0]     wr_data             ,
    output                          wr_full             ,
    output  [ADDR_WIDTH-1'b1:0]     wr_count            ,

    input                           rd_rstn             ,
    input                           rd_clk              ,   
    input                           rd_en               ,
    output  [DATA_WIDTH-1'b1:0]     rd_data             ,
    output                          rd_empty            ,
    output  [ADDR_WIDTH-1'b1:0]     rd_count  
);

reg [ADDR_WIDTH:0]          wr_addr;
reg [ADDR_WIDTH:0]          rd_addr;
reg [ADDR_WIDTH:0]          waddr_gray_reg;
reg [ADDR_WIDTH:0]          raddr_gray_reg;
reg [ADDR_WIDTH:0]          addr_r2w_1;
reg [ADDR_WIDTH:0]          addr_r2w_2;
reg [ADDR_WIDTH:0]          addr_w2r_1;
reg [ADDR_WIDTH:0]          addr_w2r_2;
reg [ADDR_WIDTH-1'b1:0]     almost_full_count   ;
reg [ADDR_WIDTH-1'b1:0]     almost_empty_count  ;

// ע�ⲻ�ܼ� 1����Ϊ������Ҫ������� 2^n ������
wire [ADDR_WIDTH:0] wr_addr_gray;
wire [ADDR_WIDTH:0] rd_addr_gray;

// ����ַ��������תΪ������
assign wr_addr_gray = wr_addr ^ (wr_addr>>1);
assign rd_addr_gray = rd_addr ^ (rd_addr>>1);

// ��Ч��ַֻ�� ADDR_WIDTH-1 λ����һλ�����洢дָ��ǹ�����ַ��һȦ��
// ������� 4 λ��ַ�ߣ���дָ������ 01000 ���� 10000
assign wr_full = (waddr_gray_reg == {~addr_r2w_2[ADDR_WIDTH:ADDR_WIDTH-'d1], addr_r2w_2[ADDR_WIDTH-'d2:0]});
assign rd_empty = (raddr_gray_reg == addr_w2r_2);

// ��д�����ź�
assign wr_count = almost_full_count;
assign rd_count = almost_empty_count;


// ��д��ַ
always @(posedge wr_clk or negedge wr_rstn) begin
    if(!wr_rstn) begin
        wr_addr <= 'b0;
    end 
    else begin
        if((wr_en==1'b1) && (wr_full==1'b0)) begin
            wr_addr <= wr_addr + 1'b1;
        end 
        else begin
            wr_addr <= wr_addr;    
        end 
    end 
end 

always @(posedge rd_clk or negedge rd_rstn) begin
    if(!rd_rstn) begin
        rd_addr <= 'b0;
    end 
    else begin
        if((rd_en==1'b1) && (rd_empty==1'b0)) begin
            rd_addr <= rd_addr + 1'b1;
        end 
        else begin
            rd_addr <= rd_addr;    
        end 
    end 
end 


// д�����Ͷ������ź�
always @(posedge wr_clk or negedge wr_rstn) begin
    if(!wr_rstn) begin
        almost_full_count <= 'd0;
    end 
    else begin
        if((wr_en == 1'b1) && (wr_full == 1'b0)) begin
            almost_full_count <= almost_full_count + 1'b1;
        end 
        else begin
            almost_full_count <= almost_full_count;
        end
    end 
end

always @(posedge rd_clk or negedge rd_rstn) begin
    if(!rd_rstn) begin
        almost_empty_count <= 'd0;
    end 
    else begin
        if((rd_en == 1'b1) && (rd_empty == 1'b0)) begin
            almost_empty_count <= almost_empty_count + 1'b1;
        end 
        else begin
            almost_empty_count <= almost_empty_count;
        end
    end 
end


// ʹ�ø��������ж϶�дָ��״̬��ȷ���Ƿ�ջ���
always @(posedge wr_clk or negedge wr_rstn) begin
    if(!wr_rstn) begin
        waddr_gray_reg <= 'd0;
    end
    else begin
        waddr_gray_reg <= wr_addr_gray;
    end 
end 

always @(posedge rd_clk or negedge rd_rstn) begin
    if(!rd_rstn) begin
        raddr_gray_reg <= 'd0;
    end
    else begin
        raddr_gray_reg <= rd_addr_gray;
    end 
end


// �ӳ�һ�����ڣ��Ա�������̬
always @(posedge wr_clk or negedge wr_rstn) begin
    if(!wr_rstn) begin
        addr_r2w_1 <= 'd0;
        addr_r2w_2 <= 'd0;
    end
    else begin
        addr_r2w_1 <= raddr_gray_reg;
        addr_r2w_2 <= addr_r2w_1;
    end 
end 

always @ (posedge rd_clk or negedge rd_rstn) begin
    if(!rd_rstn) begin
        addr_w2r_1 <= 'd0;
        addr_w2r_2 <= 'd0;
    end
    else begin
        addr_w2r_1 <= waddr_gray_reg;
        addr_w2r_2 <= addr_w2r_1;
    end 
end 


dual_port_RAM #(
    .ADDR_WIDTH     (ADDR_WIDTH),
    .DATA_WIDTH     (DATA_WIDTH)
) dual_port_RAM_inst (
    .wr_clk         (wr_clk),
    .wr_en          ((wr_en) && (!wr_full)),
    .wr_addr        (wr_addr[ADDR_WIDTH-1:0]),  
    .wr_data        (wr_data),       
    .rd_clk         (rd_clk),
    .rd_en          ((rd_en) && (!rd_empty)),
    .rd_addr        (rd_addr[ADDR_WIDTH-1:0]),  //��ȶ�2ȡ�������õ���ַ��λ��
    .rd_data        (rd_data)   //�������
);    

endmodule