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
// axi 读逻辑
//
module axi_interconnect_rd#(
    parameter MEM_ROW_WIDTH        = 15     ,
    parameter MEM_COLUMN_WIDTH     = 10     ,
    parameter MEM_BANK_WIDTH       = 3      ,
    parameter CTRL_ADDR_WIDTH = MEM_ROW_WIDTH + MEM_BANK_WIDTH + MEM_COLUMN_WIDTH,
    parameter DQ_WIDTH          = 12'd32    ,
    parameter BURST_LEN         = 12'd16    ,
    parameter FRAME_HEIGHT = 'd720          ,
    parameter FRAME_WIDTH = 'd1280           
)(
    input                               clk             ,
    input                               rst             ,
    // 外部同步信号时序
    input                               vsync_in        ,
    input                               href_in         ,  

    output                              buf_wr_en       ,
    output                              buf_wr_rst      ,
    output  [DQ_WIDTH*8-1:0]            buf_wr_data     ,

    // AXI READ INTERFACE
    output                              axi_arvalid     ,  
    input                               axi_arready     , 
    output [CTRL_ADDR_WIDTH-1:0]        axi_araddr      ,  
    output [3:0]                        axi_arid        ,  
    output [3:0]                        axi_arlen       ,  
    output [2:0]                        axi_arsize      ,  
    output [1:0]                        axi_arburst     ,  
                                                         
    output                              axi_rready      ,  
    input  [DQ_WIDTH*8-1:0]             axi_rdata       ,  
    input                               axi_rvalid      /*synthesis PAP_MARK_DEBUG="1"*/,  
    input                               axi_rlast       ,  
    input  [3:0]                        axi_rid          
);

parameter   INIT_WAIT = 4'b0000,              // AXI 读状态机
            RD1_PRE = 4'b0001,
            RD1_ADDR = 4'b0010,
            RD2_PRE = 4'b0011,
            RD2_ADDR = 4'b0100,
            RD3_PRE = 4'b0101,
            RD3_ADDR = 4'b0110,
            RD4_PRE = 4'b0111,
            RD4_ADDR = 4'b1000;
parameter FRAME_ADDR_OFFSET_1 = 'd200_000;
parameter   CMOS1_FRAME_1 = 'd0,
            CMOS1_FRAME_2 = CMOS1_FRAME_1 + FRAME_ADDR_OFFSET_1,
            CMOS2_FRAME_1 = CMOS1_FRAME_2 + FRAME_ADDR_OFFSET_1,
            CMOS2_FRAME_2 = CMOS2_FRAME_1 + FRAME_ADDR_OFFSET_1;  
parameter FRAME_ADDR = 'd1024 * 'd150;
parameter ADDR_STEP = BURST_LEN * 8;       // 首地址自增步长，1 个地址 32 位数据，这与芯片的 DQ 宽度有关

wire                            pose_vsync_in   ;
wire                            nege_vsync_in   ;

reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_araddr  /*synthesis PAP_MARK_DEBUG="1"*/;
reg                             reg_axi_arvalid ;
reg                             reg_axi_rready  ;
reg [DQ_WIDTH*8-1:0]            reg_axi_rdata   ;
reg                             reg_axi_rvalid ;

reg                             vsync_in_d1         ;
reg                             vsync_in_d2         ;
reg [3:0]                       axi_rd_state        ;
reg [2:0]                       frame_inst_rd       ;
reg                             arvalid_temp        ;
reg                             frame_rd_done       ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_araddr_1    ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_araddr_2    ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_araddr_3    ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_araddr_4    ;

assign axi_arvalid  = reg_axi_arvalid       ;
assign axi_araddr   = reg_axi_araddr        ;
assign axi_arlen    = BURST_LEN - 1'b1      ;   // 突发长度
assign axi_arsize   = DQ_WIDTH*8/8          ;   // DATA_LEN = 256
assign axi_arburst  = 2'b01                 ;
assign axi_rready   = 1'b1                  ;

assign pose_vsync_in = ((vsync_in_d1) && (!vsync_in_d2)) ? 1'b1 : 1'b0;
assign nege_vsync_in = ((!vsync_in_d1) && (vsync_in_d2)) ? 1'b1 : 1'b0;
assign pose_arvalid = ((arvalid_temp) && (!reg_axi_arvalid)) ? 1'b1 : 1'b0;
assign buf_wr_en = reg_axi_rvalid;
assign buf_wr_data = reg_axi_rdata;
assign rd_buf_rst = pose_vsync_in;


// 检测输入帧同步时序信号作为 axi 开始读的信号
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        vsync_in_d1 <= 'b0;
        vsync_in_d2 <= 'b0;
    end
    else begin
        vsync_in_d1 <= vsync_in;
        vsync_in_d2 <= vsync_in_d1;
    end
end


// 当前读帧的指示信号
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        frame_inst_rd <= 'b0;
    end
    else if(nege_vsync_in == 1'b1) begin
        if(frame_inst_rd == 3'd4) begin
            frame_inst_rd <= 3'd1;
        end
        else begin
            frame_inst_rd <= frame_inst_rd + 1'b1;
        end
    end
    else begin
        frame_inst_rd <= frame_inst_rd;
    end
end


// axi 读控制逻辑，cmos1_frame1 -> cmos2_frame1 -> cmos1_frame2 -> cmos2_frame2
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        axi_rd_state <= 'd0;
    end
    else begin
        case(axi_rd_state)
            INIT_WAIT: begin
                axi_rd_state <= RD1_PRE;
            end
            RD1_PRE: begin
                if(pose_vsync_in == 1'b1) begin
                    axi_rd_state <= RD1_ADDR;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD1_ADDR: begin
                if(frame_rd_done == 1'b1) begin
                    axi_rd_state <= RD2_PRE;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD2_PRE: begin
                if(pose_vsync_in == 1'b1) begin
                    axi_rd_state <= RD2_ADDR;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD2_ADDR: begin
                if(frame_rd_done == 1'b1) begin
                    axi_rd_state <= RD3_PRE;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD3_PRE: begin
                if(pose_vsync_in == 1'b1) begin
                    axi_rd_state <= RD3_ADDR;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD3_ADDR: begin
                if(frame_rd_done == 1'b1) begin
                    axi_rd_state <= RD4_PRE;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD4_PRE: begin
                if(pose_vsync_in == 1'b1) begin
                    axi_rd_state <= RD4_ADDR;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD4_ADDR: begin
                if(frame_rd_done == 1'b1) begin
                    axi_rd_state <= INIT_WAIT;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            default: begin
                axi_rd_state <= INIT_WAIT;
            end
        endcase
    end
end


// axi 读地址输入
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        reg_axi_araddr_1 <= CMOS1_FRAME_1;
        reg_axi_araddr_2 <= CMOS2_FRAME_1;
        reg_axi_araddr_3 <= CMOS1_FRAME_2;
        reg_axi_araddr_4 <= CMOS2_FRAME_2;
        reg_axi_araddr <= 'b0;
        arvalid_temp <= 'b0;
        reg_axi_arvalid <= 'b0;
        frame_rd_done <= 'b0;
    end
    else begin
        case(axi_rd_state)
            RD1_ADDR: begin
                if((frame_inst_rd == 3'd1) && (reg_axi_araddr < CMOS1_FRAME_1 + FRAME_ADDR)) begin
                    arvalid_temp <= 1'b1;
                    reg_axi_arvalid <= arvalid_temp;
                end
                else if((axi_arvalid == 1'b1) && (axi_arready == 1'b1) && 
                        (reg_axi_araddr == CMOS1_FRAME_1 + FRAME_ADDR)) begin
                    reg_axi_arvalid <= 1'b0;
                    frame_rd_done <= 1'b1;
                end
                else begin
                    arvalid_temp <= 1'b0;
                    reg_axi_arvalid <= 1'b0;
                    frame_rd_done <= 1'b0;
                end

                if(pose_arvalid == 1'b1) begin
                    reg_axi_araddr <= reg_axi_araddr_1;
                end
                else if ((axi_arvalid == 1'b1) && (axi_arready == 1'b1)) begin
                    if(reg_axi_araddr_1 < CMOS1_FRAME_1 + FRAME_ADDR) begin
                        reg_axi_araddr_1 <= reg_axi_araddr_1 + ADDR_STEP;
                    end
                    else begin
                        reg_axi_araddr_1 <= CMOS1_FRAME_1;
                    end
                end
                else begin
                    reg_axi_araddr_1 <= reg_axi_araddr_1;
                end
            end
            RD2_ADDR: begin
                if((frame_inst_rd == 3'd2) && (reg_axi_araddr < CMOS2_FRAME_1 + FRAME_ADDR)) begin
                    arvalid_temp <= 1'b1;
                    reg_axi_arvalid <= arvalid_temp;
                end
                else if((axi_arvalid == 1'b1) && (axi_arready == 1'b1) && 
                        (reg_axi_araddr == CMOS2_FRAME_1 + FRAME_ADDR)) begin
                    reg_axi_arvalid <= 1'b0;
                    frame_rd_done <= 1'b1;
                end
                else begin
                    arvalid_temp <= 1'b0;
                    reg_axi_arvalid <= 1'b0;
                    frame_rd_done <= 1'b0;
                end

                if(pose_arvalid == 1'b1) begin
                    reg_axi_araddr <= reg_axi_araddr_2;
                end
                else if ((axi_arvalid == 1'b1) && (axi_arready == 1'b1)) begin
                    if(reg_axi_araddr_2 < CMOS1_FRAME_2 + FRAME_ADDR) begin
                        reg_axi_araddr_2 <= reg_axi_araddr_2 + ADDR_STEP;
                    end
                    else begin
                        reg_axi_araddr_2 <= CMOS2_FRAME_1;
                    end
                end
                else begin
                    reg_axi_araddr_2 <= reg_axi_araddr_2;
                end
            end
            RD3_ADDR: begin
                if((frame_inst_rd == 3'd3) && (reg_axi_araddr < CMOS1_FRAME_2 + FRAME_ADDR)) begin
                    arvalid_temp <= 1'b1;
                    reg_axi_arvalid <= arvalid_temp;
                end
                else if((axi_arvalid == 1'b1) && (axi_arready == 1'b1) && 
                        (reg_axi_araddr == CMOS1_FRAME_2 + FRAME_ADDR)) begin
                    reg_axi_arvalid <= 1'b0;
                    frame_rd_done <= 1'b1;
                end
                else begin
                    arvalid_temp <= 1'b0;
                    reg_axi_arvalid <= 1'b0;
                    frame_rd_done <= 1'b0;
                end

                if(pose_arvalid == 1'b1) begin
                    reg_axi_araddr <= reg_axi_araddr_3;
                end
                else if ((axi_arvalid == 1'b1) && (axi_arready == 1'b1)) begin
                    if(reg_axi_araddr_3 < CMOS1_FRAME_2 + FRAME_ADDR) begin
                        reg_axi_araddr_3 <= reg_axi_araddr_3 + ADDR_STEP;
                    end
                    else begin
                        reg_axi_araddr_3 <= CMOS1_FRAME_2;
                    end
                end
                else begin
                    reg_axi_araddr_3 <= reg_axi_araddr_3;
                end
            end
            RD4_ADDR: begin
                if((frame_inst_rd == 3'd4) && (reg_axi_araddr < CMOS2_FRAME_2 + FRAME_ADDR)) begin
                    arvalid_temp <= 1'b1;
                    reg_axi_arvalid <= arvalid_temp;
                end
                else if((axi_arvalid == 1'b1) && (axi_arready == 1'b1) && 
                        (reg_axi_araddr == CMOS2_FRAME_2 + FRAME_ADDR)) begin
                    reg_axi_arvalid <= 1'b0;
                    frame_rd_done <= 1'b1;
                end
                else begin
                    arvalid_temp <= 1'b0;
                    reg_axi_arvalid <= 1'b0;
                    frame_rd_done <= 1'b0;
                end

                if(pose_arvalid == 1'b1) begin
                    reg_axi_araddr <= reg_axi_araddr_4;
                end
                else if((axi_arvalid == 1'b1) && (axi_arready == 1'b1)) begin
                    if(reg_axi_araddr_4 < CMOS2_FRAME_2 + FRAME_ADDR) begin
                        reg_axi_araddr_4 <= reg_axi_araddr_4 + ADDR_STEP;
                    end
                    else begin
                        reg_axi_araddr_4 <= CMOS2_FRAME_2;
                    end
                end
                else begin
                    reg_axi_araddr_4 <= reg_axi_araddr_4;
                end
            end
            default: begin
                reg_axi_araddr_1 <= CMOS1_FRAME_1;
                reg_axi_araddr_2 <= CMOS2_FRAME_1;
                reg_axi_araddr_3 <= CMOS1_FRAME_2;
                reg_axi_araddr_4 <= CMOS2_FRAME_2;
                reg_axi_araddr <= 'b0;
                arvalid_temp <= 1'b0;
                reg_axi_arvalid <= 'b0;
                frame_rd_done <= 1'b0;
            end
        endcase
    end
end


// axi 读出数据送入 FIFO 中
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        reg_axi_rvalid <= 'b0;
        reg_axi_rdata <= 'b0;
    end
    else begin
        reg_axi_rvalid <= axi_rvalid;
        reg_axi_rdata <= axi_rdata;
    end
end


endmodule