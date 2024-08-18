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
// cmos 相机通道数选择
// 
module cmos_channel_sel(
    input               rst             ,

    input               cmos1_pclk      ,
    input               cmos1_vsync     ,
    input               cmos1_href      ,
    input [7:0]         cmos1_data      ,

    input               cmos2_pclk      ,
    input               cmos2_vsync     ,
    input               cmos2_href      ,
    input [7:0]         cmos2_data      ,

    output              cmos_out_pclk   ,
    output reg          cmos_out_vsync  /*synthesis PAP_MARK_DEBUG = "1"*/,
    output reg          cmos_out_href   /*synthesis PAP_MARK_DEBUG = "1"*/,
    output reg [7:0]    cmos_out_data   
);

parameter   SWITCH_INIT = 3'b000,
            CH1_INIT = 3'b001,
            CH1_TRANS = 3'b010,
            CH2_INIT = 3'b011,
            CH2_TRANS = 3'b100;

wire            cmos1_href_d2       ; 
wire            cmos1_vsync_d2      ; 
wire [7:0]      cmos1_data_d2       ; 
wire            cmos2_href_d2       ; 
wire            cmos2_vsync_d2      ; 
wire [7:0]      cmos2_data_d2       ; 
wire            pose_cmos1_vsync    ;
wire            nege_cmos1_vsync    ;
wire            pose_cmos2_vsync    ;
wire            nege_cmos2_vsync    ;

reg [2:0]       switch_state        /*synthesis PAP_MARK_DEBUG = "1"*/;
reg             cmos1_vsync_d3      ;
reg             cmos2_vsync_d3      ;
reg [7:0]       cmos1_vs_cnt        ;
reg [7:0]       cmos2_vs_cnt        ;
reg [11:0]      cmos1_de_cnt        ;
reg [11:0]      cmos2_de_cnt        ;

assign cmos_out_pclk = cmos1_pclk;


// 全部在一个时钟域下采集信号，并延迟 3 个时钟周期
camera_delay cmos1_delay(
    .cmos_pclk              (cmos1_pclk     ),
    .cmos_href              (cmos1_href    ),
    .cmos_vsync             (cmos1_vsync     ),
    .cmos_data              (cmos1_data     ),

    .cmos_href_delay        (cmos1_href_d2  ),
    .cmos_vsync_delay       (cmos1_vsync_d2 ),
    .cmos_data_delay        (cmos1_data_d2  )
);

camera_delay cmos2_delay(
    .cmos_pclk              (cmos1_pclk     ),
    .cmos_href              (cmos2_href    ),
    .cmos_vsync             (cmos2_vsync     ),
    .cmos_data              (cmos2_data     ),

    .cmos_href_delay        (cmos2_href_d2  ),
    .cmos_vsync_delay       (cmos2_vsync_d2 ),
    .cmos_data_delay        (cmos2_data_d2  )
);


// 生成状态机跳转指示信号
always @(posedge cmos1_pclk or negedge rst) begin
    if(!rst) begin
        cmos1_vsync_d3 <= 'b0;
        cmos2_vsync_d3 <= 'b0;
    end
    else begin
        cmos1_vsync_d3 <= cmos1_vsync_d2;
        cmos2_vsync_d3 <= cmos2_vsync_d2;
    end
end
assign pose_cmos1_vsync = ((cmos1_vsync_d2) && (!cmos1_vsync_d3)) ? 1'b1 : 1'b0;
assign nege_cmos1_vsync = ((!cmos1_vsync_d2) && (cmos1_vsync_d3)) ? 1'b1 : 1'b0;
assign pose_cmos2_vsync = ((cmos2_vsync_d2) && (!cmos2_vsync_d3)) ? 1'b1 : 1'b0;
assign nege_cmos2_vsync = ((!cmos2_vsync_d2) && (cmos2_vsync_d3)) ? 1'b1 : 1'b0;


// 状态机跳转
always @(posedge cmos1_pclk or negedge rst) begin
    if(!rst) begin
        switch_state <= 'b0;
    end
    else begin
        case(switch_state)
            SWITCH_INIT: begin
                switch_state <= CH1_INIT;
            end
            CH1_INIT: begin
                if(nege_cmos1_vsync == 1'b1) begin
                    switch_state <= CH1_TRANS;
                end
                else begin
                    switch_state <= switch_state;
                end
            end
            CH1_TRANS: begin
                if(pose_cmos1_vsync == 1'b1) begin
                    switch_state <= CH2_INIT;
                end
                else begin
                    switch_state <= switch_state;
                end
            end
            CH2_INIT: begin
                if(nege_cmos2_vsync == 1'b1) begin
                    switch_state <= CH2_TRANS;
                end
                else begin
                    switch_state <= switch_state;
                end
            end
            CH2_TRANS: begin
                if(pose_cmos2_vsync == 1'b1) begin
                    switch_state <= SWITCH_INIT;
                end
                else begin
                    switch_state <= switch_state;
                end
            end
            default: switch_state <= SWITCH_INIT;
        endcase
    end
end


// 重新生成帧同步信号
always @(posedge cmos1_pclk or negedge rst) begin
    if(!rst) begin
        cmos1_vs_cnt <= 'b0;
    end
    else if(switch_state == CH1_TRANS) begin
        if(cmos1_vs_cnt > 8'd100) begin
            cmos1_vs_cnt <= cmos1_vs_cnt;
        end
        else if(pose_cmos1_vsync == 1'b1) begin
            cmos1_vs_cnt <= 8'd0;
        end
        else begin
            cmos1_vs_cnt <= cmos1_vs_cnt + 1'b1;
        end
    end
    else begin
        cmos1_vs_cnt <= 8'd0;
    end
end

always @(posedge cmos1_pclk or negedge rst) begin
    if(!rst) begin
        cmos2_vs_cnt <= 'b0;
    end
    else if(switch_state == CH2_TRANS) begin
        if(cmos2_vs_cnt > 8'd100) begin
            cmos2_vs_cnt <= cmos2_vs_cnt;
        end
        else if(pose_cmos2_vsync == 1'b1) begin
            cmos2_vs_cnt <= 8'd0;
        end
        else begin
            cmos2_vs_cnt <= cmos2_vs_cnt + 1'b1;
        end
    end
    else begin
        cmos2_vs_cnt <= 8'd0;
    end
end


// 在每帧开头加入一个新行，以标识来自 CMOS1 和 CMOS2 的数据
// cmos1: \xff\xa1\xff\xa1，cmos2: \xff\xa2\xff\xa2
always @(posedge cmos1_pclk or negedge rst) begin
    if(!rst) begin
        cmos1_de_cnt <= 'b0;
    end
    else if(cmos1_vs_cnt > 8'd100) begin
        if(cmos1_de_cnt > 11'd1100) begin
            cmos1_de_cnt <= cmos1_de_cnt;
        end
        else if(pose_cmos1_vsync == 1'b1) begin
            cmos1_de_cnt <= 11'd0;
        end
        else begin
            cmos1_de_cnt <= cmos1_de_cnt + 1'b1;
        end
    end
    else begin
        cmos1_de_cnt <= 11'd0;
    end
end

always @(posedge cmos1_pclk or negedge rst) begin
    if(!rst) begin
        cmos2_de_cnt <= 'b0;
    end
    else if(cmos2_vs_cnt > 8'd100) begin
        if(cmos2_de_cnt > 11'd1100) begin
            cmos2_de_cnt <= cmos2_de_cnt;
        end
        else if(pose_cmos2_vsync == 1'b1) begin
            cmos2_de_cnt <= 11'd0;
        end
        else begin
            cmos2_de_cnt <= cmos2_de_cnt + 1'b1;
        end
    end
    else begin
        cmos2_de_cnt <= 11'd0;
    end
end


// 输出的 cmos 信号
always @(posedge cmos1_pclk or negedge rst) begin
    if(!rst) begin
        cmos_out_vsync <= 'b0;
        cmos_out_href <= 'b0;
        cmos_out_data <= 'b0;
    end
    else begin
        case(switch_state)
            CH1_TRANS: begin
                if(cmos1_vs_cnt < 8'd50) begin
                    cmos_out_vsync <= 1'b1;
                end
                else begin
                    cmos_out_vsync <= 1'b0;
                end
                if((cmos1_de_cnt >= 11'd3) && (cmos1_de_cnt <= 11'd1026)) begin
                    cmos_out_href <= 1'b1;
                end
                else begin
                    cmos_out_href <= cmos1_href_d2;
                end
                if((cmos1_de_cnt >= 11'd3) && (cmos1_de_cnt <= 11'd1026)) begin
                    case(cmos1_de_cnt) 
                        11'd256: cmos_out_data <= 8'hff;
                        11'd257: cmos_out_data <= 8'ha1;
                        11'd258: cmos_out_data <= 8'hff;
                        11'd259: cmos_out_data <= 8'ha1;
                        default: cmos_out_data <= 8'h00;
                    endcase
                end
                else begin
                    cmos_out_data <= cmos1_data_d2;
                end
            end
            CH2_TRANS: begin
                if(cmos2_vs_cnt < 8'd50) begin
                    cmos_out_vsync <= 1'b1;
                end
                else begin
                    cmos_out_vsync <= 1'b0;
                end
                if((cmos2_de_cnt >= 11'd3) && (cmos2_de_cnt <= 11'd1026)) begin
                    cmos_out_href <= 1'b1;
                end
                else begin
                    cmos_out_href <= cmos2_href_d2;
                end
                if((cmos2_de_cnt >= 11'd3) && (cmos2_de_cnt <= 11'd1026)) begin
                    case(cmos2_de_cnt) 
                        11'd256: cmos_out_data <= 8'hff;
                        11'd257: cmos_out_data <= 8'ha2;
                        11'd258: cmos_out_data <= 8'hff;
                        11'd259: cmos_out_data <= 8'ha2;
                        default: cmos_out_data <= 8'h00;
                    endcase
                end
                else begin
                    cmos_out_data <= cmos2_data_d2;
                end
            end
            default: begin
                cmos_out_vsync <= 1'b0;
                cmos_out_href <= 1'b0;
                cmos_out_data <= 8'b0;
            end
        endcase
    end
end


endmodule