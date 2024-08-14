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
// 缓存帧图像至 DDR，以便可以传输双目摄像头数据
module trans_cache#(
    parameter       MEM_ROW_WIDTH       = 12'd15    ,
    parameter       MEM_COLUMN_WIDTH    = 12'd10    ,
    parameter       MEM_BANK_WIDTH      = 12'd3     ,
    parameter       CTRL_ADDR_WIDTH = MEM_ROW_WIDTH + MEM_BANK_WIDTH + MEM_COLUMN_WIDTH,
    parameter       MEM_DQ_WIDTH        = 12'd32    ,
    parameter       BURST_LEN           = 12'd16    ,
    parameter       IMAGE_H             = 12'd720   ,
    parameter       IMAGE_W             = 12'd1280
)(
    input                           clk,
    input                           cmos1_rst,
    input                           cmos2_rst,
    input                           rst,

    // cmos1
    input                           cmos1_pclk      ,
    input                           cmos1_vs_in     ,
    input                           cmos1_de_in     ,
    input   [7:0]                   cmos1_data      ,

    // cmos2
    input                           cmos2_pclk      ,
    input                           cmos2_vs_in     ,
    input                           cmos2_de_in     ,
    input   [7:0]                   cmos2_data      ,

    // 数据信号重载
    input                           vsync_in        ,
    input                           href_in         ,
    output  [7:0]                   cmos_data_out   ,

    output reg                      init_done       /*synthesis PAP_MARK_DEBUG = "1"*/,

    // axi bus
    output [CTRL_ADDR_WIDTH-1:0]    axi_awaddr      ,
    output [3:0]                    axi_awid        ,
    output [3:0]                    axi_awlen       ,
    output [2:0]                    axi_awsize      ,
    output [1:0]                    axi_awburst     ,
    input                           axi_awready     ,
    output                          axi_awvalid     ,

    output [MEM_DQ_WIDTH*8-1:0]     axi_wdata       ,
    output [MEM_DQ_WIDTH -1 :0]     axi_wstrb       ,
    input                           axi_wlast       /*synthesis PAP_MARK_DEBUG = "1"*/,
    output                          axi_wvalid      ,
    input                           axi_wready      ,
    input  [3 : 0]                  axi_bid         ,                               

    output [CTRL_ADDR_WIDTH-1:0]    axi_araddr      ,
    output [3:0]                    axi_arid        ,
    output [3:0]                    axi_arlen       ,
    output [2:0]                    axi_arsize      ,
    output [1:0]                    axi_arburst     ,
    output                          axi_arvalid     ,
    input                           axi_arready     ,

    output                          axi_rready      ,
    input  [MEM_DQ_WIDTH*8-1:0]     axi_rdata       ,
    input                           axi_rvalid      ,
    input                           axi_rlast       ,
    input  [3:0]                    axi_rid         
);


// axi 读写参数
parameter   WR_INIT = 4'd0  ,
            WR1_WAIT = 4'd1 ,
            WR1_ADDR = 4'd2 ,
            WR1_PROC = 4'd3 ,
            WR2_WAIT = 4'd4 ,
            WR2_ADDR = 4'd5 ,
            WR2_PROC = 4'd6 ;
parameter   RD_INIT = 4'd0  ,
            RD1_INIT = 4'd1 ,
            RD1_PROC = 4'd2 ,
            RD2_INIT = 4'd3 ,
            RD2_PROC = 4'd4 ,
            RD3_INIT = 4'd5 ,
            RD3_PROC = 4'd6 ,
            RD4_INIT = 4'd7 ,
            RD4_PROC = 4'd8 ;

// DDR 地址空间
parameter FRAME_ADDR_OFFSET = 'd500_000;
parameter CMOS1_FRAME_1 = 'd0;
parameter CMOS1_FRAME_2 = CMOS1_FRAME_1 + FRAME_ADDR_OFFSET;
parameter CMOS2_FRAME_1 = CMOS1_FRAME_2 + FRAME_ADDR_OFFSET;
parameter CMOS2_FRAME_2 = CMOS2_FRAME_1 + FRAME_ADDR_OFFSET;
parameter ADDR_STEP = BURST_LEN * 8;
parameter FRAME_ADDR = IMAGE_H * IMAGE_W / 2;


wire                            almost_full_1   ;
wire                            almost_full_2   ;
wire                            pose_vs1_pclk   ;
wire                            pose_vs2_pclk   ;
wire                            pose_vs1        ;
wire                            pose_vs2        ;
wire                            nege_vs1        ;
wire                            nege_vs2        ;
wire                            pre_en_1        ;
wire                            pre_en_2        ;
wire [MEM_DQ_WIDTH*8-1'b1:0]    rd_data_1       ;
wire [MEM_DQ_WIDTH*8-1'b1:0]    rd_data_2       ;
wire                            pose_vsync_in   ;
wire                            nege_vsync_in   ;
wire                            pose_awvalid    ;
wire                            pose_arvalid    ;
wire                            wr_full_1       ;
wire                            wr_full_2       ;

reg [7:0]                       cmos1_data_d1       ;
reg [7:0]                       cmos2_data_d1       ;
reg                             cmos1_vs_d1         ;
reg                             cmos2_vs_d1         ;
reg                             cmos1_vs_clk_d1     ;
reg                             cmos1_vs_clk_d2     ;
reg                             cmos2_vs_clk_d1     ;
reg                             cmos2_vs_clk_d2     ;
reg [3:0]                       axi_wr_state        ;
reg [3:0]                       axi_rd_state        ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_awaddr_1f1  /*synthesis PAP_MARK_DEBUG = "1"*/;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_awaddr_1f2  /*synthesis PAP_MARK_DEBUG = "1"*/;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_awaddr_2f1  ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_awaddr_2f2  ;
reg                             almost_full_1_d1    ;
reg                             almost_full_2_d1    ;
reg                             almost_full_1_d2    ;
reg                             almost_full_2_d2    ;
reg [5:0]                       pix_cnt_1           ;
reg [5:0]                       pix_cnt_2           ;
reg                             pre_rd_inst1        ;
reg                             pre_rd_inst1_d1     ;
reg                             pre_rd_inst2        ;
reg                             pre_rd_inst2_d1     ;
reg                             rd_en_1             ;
reg                             rd_en_2             ;
reg                             frame_rd_done       ;
reg [2:0]                       frame_inst_rd       ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_araddr_1    ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_araddr_2    ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_araddr_3    ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_araddr_4    ;
reg                             vsync_in_d1         ;
reg                             vsync_in_d2         ;
reg                             awvalid_temp        ;
reg                             arvalid_temp        ;

reg                             frame_inst_wr_1     ;
reg                             frame_inst_wr_2     ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_awaddr      /*synthesis PAP_MARK_DEBUG = "1"*/;
reg                             reg_axi_awvalid     ;
reg [MEM_DQ_WIDTH*8-1'b1:0]     reg_axi_wdata       ;
reg                             reg_axi_wvalid      ;
reg                             reg_axi_bready      ;
reg                             reg_axi_rready      ;
reg [CTRL_ADDR_WIDTH-1:0]       reg_axi_araddr      ;
reg                             reg_axi_arvalid     ;
reg [MEM_DQ_WIDTH*8-1'b1:0]     reg_axi_rdata       ;
reg                             reg_axi_rvalid      ;


assign axi_awaddr   = reg_axi_awaddr        ;
assign axi_awvalid  = reg_axi_awvalid       ;
assign axi_awlen    = BURST_LEN - 1'b1      ;   // 突发长度：16
assign axi_awsize   = MEM_DQ_WIDTH          ;   // DATA_LEN = 256
assign axi_awburst  = 2'b01                 ;
assign axi_wdata    = reg_axi_wdata         ;
assign axi_wvalid   = reg_axi_wvalid        ;
assign axi_wstrb    = {MEM_DQ_WIDTH{1'b1}}  ;
assign axi_bready   = reg_axi_bready        ;
assign axi_arvalid  = reg_axi_arvalid       ;
assign axi_araddr   = reg_axi_araddr        ;
assign axi_arlen    = BURST_LEN - 1'b1      ;   // 突发长度
assign axi_arsize   = MEM_DQ_WIDTH*8/8      ;   // DATA_LEN = 256
assign axi_arburst  = 2'b01                 ;
assign axi_rready   = 1'b1                  ;

assign pose_vs1_pclk = ((cmos1_vs_in) && (!cmos1_vs_d1)) ? 1'b1 : 1'b0;
assign pose_vs2_pclk = ((cmos2_vs_in) && (!cmos2_vs_d1)) ? 1'b1 : 1'b0;

assign pose_awvalid = ((awvalid_temp) && (!axi_awvalid)) ? 1'b1 : 1'b0;
assign pose_arvalid = ((arvalid_temp) && (!axi_arvalid)) ? 1'b1 : 1'b0;


// 将数据延迟一个时钟以匹配使能信号
always @(posedge cmos1_pclk or negedge cmos1_rst) begin
    if(!cmos1_rst) begin
        cmos1_data_d1 <= 'b0;
        cmos1_vs_d1 <= 'b0;
    end
    else begin
        cmos1_data_d1 <= cmos1_data;
        cmos1_vs_d1 <= cmos1_vs_in;
    end
end

always @(posedge cmos2_pclk or negedge cmos2_rst) begin
    if(!cmos2_rst) begin
        cmos2_data_d1 <= 'b0;
        cmos2_vs_d1 <= 'b0;
    end
    else begin
        cmos2_data_d1 <= cmos1_data;
        cmos2_vs_d1 <= cmos2_vs_in;
    end
end


// 帧计数
always @(posedge cmos1_pclk or negedge cmos1_rst) begin
    if(!cmos1_rst) begin
        frame_inst_wr_1 <= 'b1;
    end
    else begin
        if(pose_vs1_pclk == 1'b1) begin
            frame_inst_wr_1 <= ~frame_inst_wr_1;
        end
        else begin
            frame_inst_wr_1 <= frame_inst_wr_1;
        end
    end
end

always @(posedge cmos2_pclk or negedge cmos2_rst) begin
    if(!cmos2_rst) begin
        frame_inst_wr_2 <= 'b1;
    end
    else begin
        if(pose_vs2_pclk == 1'b1) begin
            frame_inst_wr_2 <= ~frame_inst_wr_2;
        end
        else begin
            frame_inst_wr_2 <= frame_inst_wr_2;
        end
    end
end


// 存储 cmos1 数据
cmos_data_cache cmos1_data_fifo(
    .wr_clk             (cmos1_pclk),                // input
    .wr_rst             ((!cmos1_rst) || (pose_vs1_pclk)),                // input
    .wr_en              (cmos1_de_in),                  // input
    .wr_data            (cmos1_data),              // input [7:0]
    .wr_full            (wr_full_1),              // output
    .almost_full        (almost_full_1),      // output
    .rd_clk             (clk),                // input
    .rd_rst             ((!cmos1_rst) || (pose_vs1)),                // input
    .rd_en              ((rd_en_1) || (pre_en_1)),                  // input
    .rd_data            (rd_data_1),              // output [255:0]
    .rd_empty           (),            // output
    .almost_empty       ()     // output
);

// 存储 cmos2 数据
cmos_data_cache cmos2_data_fifo(
    .wr_clk             (cmos2_pclk),                // input
    .wr_rst             ((!cmos2_rst) || (pose_vs2_pclk)),                // input
    .wr_en              (cmos2_de_in),                  // input
    .wr_data            (cmos2_data),              // input [7:0]
    .wr_full            (wr_full_2),              // output
    .almost_full        (almost_full_2),      // output
    .rd_clk             (clk),                // input
    .rd_rst             ((!cmos2_rst) || (pose_vs2)),                // input
    .rd_en              ((rd_en_2) || (pre_en_2)),                  // input
    .rd_data            (rd_data_2),              // output [255:0]
    .rd_empty           (),            // output
    .almost_empty       ()     // output
);


// 每帧开头预读一个数据到信号线
always @(posedge cmos1_pclk or negedge cmos1_rst) begin
    if(!cmos1_rst) begin
        pix_cnt_1 <= 'b0;
    end
    else if(nege_vs1 == 1'b1) begin
        pix_cnt_1 <= 'b0;
    end
    else if(cmos1_de_in == 1'b1) begin
        if(pix_cnt_1 == 6'd32) begin
            pix_cnt_1 <= pix_cnt_1;
        end
        else begin
            pix_cnt_1 <= pix_cnt_1 + 1'b1;
        end
    end
    else begin
        pix_cnt_1 <= pix_cnt_1;
    end
end

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        pre_rd_inst1 <= 'b0;
        pre_rd_inst1_d1 <= 'b0;
    end
    else if(pix_cnt_1 == 6'd32) begin
        pre_rd_inst1 <= 1'b1;
        pre_rd_inst1_d1 <= pre_rd_inst1;
    end
    else if(pose_vs1 == 1'b1) begin
        pre_rd_inst1 <= 1'b0;
        pre_rd_inst1_d1 <= pre_rd_inst1;
    end
    else begin
        pre_rd_inst1 <= pre_rd_inst1;
        pre_rd_inst1_d1 <= pre_rd_inst1;
    end
end

assign pre_en_1 = ((pre_rd_inst1) && (!pre_rd_inst1_d1)) ? 1'b1 : 1'b0;

always @(posedge cmos2_pclk or negedge cmos2_rst) begin
    if(!cmos2_rst) begin
        pix_cnt_2 <= 'b0;
    end
    else if(nege_vs2 == 1'b1) begin
        pix_cnt_2 <= 'b0;
    end
    else if(cmos2_de_in == 1'b1) begin
        if(pix_cnt_2 == 6'd32) begin
            pix_cnt_2 <= pix_cnt_2;
        end
        else begin
            pix_cnt_2 <= pix_cnt_2 + 1'b1;
        end
    end
    else begin
        pix_cnt_2 <= pix_cnt_2;
    end
end

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        pre_rd_inst2 <= 'b0;
        pre_rd_inst2_d1 <= 'b0;
    end
    else if(pix_cnt_2 == 6'd32) begin
        pre_rd_inst2 <= 1'b1;
        pre_rd_inst2_d1 <= pre_rd_inst2;
    end
    else if(pose_vs2 == 1'b1) begin
        pre_rd_inst2 <= 1'b0;
        pre_rd_inst2_d1 <= pre_rd_inst2;
    end
    else begin
        pre_rd_inst2 <= pre_rd_inst2;
        pre_rd_inst2_d1 <= pre_rd_inst2;
    end
end

assign pre_en_2 = ((pre_rd_inst2) && (!pre_rd_inst2_d1)) ? 1'b1 : 1'b0;


// 读时钟下的 pose_vs 信号
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        cmos1_vs_clk_d1 <= 'b0;
        cmos1_vs_clk_d2 <= 'b0;
        cmos1_vs_clk_d1 <= 'b0;
        cmos1_vs_clk_d2 <= 'b0;
    end
    else begin
        cmos1_vs_clk_d1 <= cmos1_vs_in;
        cmos1_vs_clk_d2 <= cmos1_vs_clk_d1;
        cmos2_vs_clk_d1 <= cmos2_vs_in;
        cmos2_vs_clk_d2 <= cmos2_vs_clk_d1;
    end
end
assign pose_vs1 = ((cmos1_vs_clk_d1) && (!cmos1_vs_clk_d2)) ? 1'b1 : 1'b0;
assign pose_vs2 = ((cmos2_vs_clk_d1) && (!cmos2_vs_clk_d2)) ? 1'b1 : 1'b0;
assign nege_vs1 = ((!cmos1_vs_clk_d1) && (cmos1_vs_clk_d2)) ? 1'b1 : 1'b0;
assign nege_vs2 = ((!cmos2_vs_clk_d1) && (cmos2_vs_clk_d2)) ? 1'b1 : 1'b0;


// axi 写状态机跳转
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        axi_wr_state <= 'b0;
    end
    else begin
        case(axi_wr_state)
            WR_INIT: begin
                axi_wr_state <= WR1_WAIT;
            end
            WR1_WAIT: begin
                if(almost_full_1 == 1'b1) begin
                    axi_wr_state <= WR1_ADDR;
                end
                else if(almost_full_2 == 1'b1) begin
                    axi_wr_state <= WR2_WAIT;
                end
                else begin
                    axi_wr_state <= WR1_WAIT;
                end
            end
            WR1_ADDR: begin
                if((axi_awvalid == 1'b1) && (axi_awready == 1'b1)) begin
                    axi_wr_state <= WR1_PROC;
                end
                else begin
                    axi_wr_state <= axi_wr_state;
                end
            end
            WR1_PROC: begin
                if(axi_wlast == 1'b1) begin
                    if(almost_full_1 == 1'b1) begin
                        axi_wr_state <= WR1_WAIT;
                    end
                    else begin
                        axi_wr_state <= WR2_WAIT;
                    end
                end
                else begin
                    axi_wr_state <= axi_wr_state;
                end
            end
            WR2_WAIT: begin
                if(almost_full_2 == 1'b1) begin
                    axi_wr_state <= WR2_ADDR;
                end
                else begin
                    axi_wr_state <= WR1_WAIT;
                end
            end
            WR2_ADDR: begin
                if((axi_awvalid == 1'b1) && (axi_awready == 1'b1)) begin
                    axi_wr_state <= WR2_PROC;
                end
                else begin
                    axi_wr_state <= axi_wr_state;
                end
            end
            WR2_PROC: begin
                if(axi_wlast == 1'b1) begin
                    if(almost_full_2 == 1'b1) begin
                        axi_wr_state <= WR2_WAIT;
                    end
                    else begin
                        axi_wr_state <= WR1_WAIT;
                    end
                end
                else begin
                    axi_wr_state <= axi_wr_state;
                end
            end
            default: begin
                axi_wr_state <= axi_wr_state;
            end
        endcase
    end
end


// axi 写地址输入
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        reg_axi_awaddr_1f1 <= CMOS1_FRAME_1;
        reg_axi_awaddr_1f2 <= CMOS1_FRAME_2;
        reg_axi_awaddr_2f1 <= CMOS2_FRAME_1;
        reg_axi_awaddr_2f2 <= CMOS2_FRAME_2;
        reg_axi_awaddr <= 'b0;
        reg_axi_awvalid <= 'b0;
        awvalid_temp <= 'b0;
    end
    else if(pose_vs1) begin
        reg_axi_awaddr_1f1 <= CMOS1_FRAME_1;
        reg_axi_awaddr_1f2 <= CMOS1_FRAME_2;
    end
    else if(pose_vs2) begin
        reg_axi_awaddr_2f1 <= CMOS2_FRAME_1;
        reg_axi_awaddr_2f2 <= CMOS2_FRAME_2;
    end
    else begin
        case(axi_wr_state)
            WR1_ADDR: begin
                if(axi_awready == 1'b1) begin
                    awvalid_temp <= 1'b0;
                    reg_axi_awvalid <= 1'b0;
                end
                else begin
                    awvalid_temp <= 1'b1;
                    reg_axi_awvalid <= awvalid_temp;
                end

                if(frame_inst_wr_1 == 1'b0) begin
                    if(pose_awvalid == 1'b1) begin
                        reg_axi_awaddr <= reg_axi_awaddr_1f1;
                    end
                    else if((axi_awvalid == 1'b1) && (axi_awready == 1'b1)) begin
                        reg_axi_awaddr_1f1 <= reg_axi_awaddr_1f1 + ADDR_STEP;
                    end
                    else begin
                        reg_axi_awaddr_1f1 <= reg_axi_awaddr_1f1;
                        reg_axi_awaddr <= reg_axi_awaddr;
                    end
                end
                else if(frame_inst_wr_1 == 1'b1) begin
                    if(pose_awvalid == 1'b1) begin
                        reg_axi_awaddr <= reg_axi_awaddr_1f2;
                    end
                    else if((axi_awvalid == 1'b1) && (axi_awready == 1'b1)) begin
                        reg_axi_awaddr_1f2 <= reg_axi_awaddr_1f2 + ADDR_STEP;
                    end
                    else begin
                        reg_axi_awaddr_1f2 <= reg_axi_awaddr_1f2;
                        reg_axi_awaddr <= reg_axi_awaddr;
                    end
                end
                else begin
                    reg_axi_awaddr_1f1 <= reg_axi_awaddr_1f1;
                    reg_axi_awaddr_1f2 <= reg_axi_awaddr_1f2;
                    reg_axi_awaddr <= reg_axi_awaddr;
                end
            end
            WR2_ADDR: begin
                if(axi_awready == 1'b1) begin
                    awvalid_temp <= 1'b0;
                    reg_axi_awvalid <= 1'b0;
                end
                else begin
                    awvalid_temp <= 1'b1;
                    reg_axi_awvalid <= awvalid_temp;
                end

                if(frame_inst_wr_2 == 1'b0) begin
                    if(pose_awvalid == 1'b1) begin
                        reg_axi_awaddr <= reg_axi_awaddr_2f1;
                    end
                    else if((axi_awvalid == 1'b1) && (axi_awready == 1'b1)) begin
                        reg_axi_awaddr_2f1 <= reg_axi_awaddr_2f1 + ADDR_STEP;
                    end
                    else begin
                        reg_axi_awaddr_2f1 <= reg_axi_awaddr_2f1;
                        reg_axi_awaddr <= reg_axi_awaddr;
                    end
                end
                else if(frame_inst_wr_2 == 1'b1) begin
                    if(pose_awvalid == 1'b1) begin
                        reg_axi_awaddr <= reg_axi_awaddr_2f2;
                    end
                    else if((axi_awvalid == 1'b1) && (axi_awready == 1'b1)) begin
                        reg_axi_awaddr_2f2 <= reg_axi_awaddr_2f2 + ADDR_STEP;
                    end
                    else begin
                        reg_axi_awaddr_2f2 <= reg_axi_awaddr_2f2;
                        reg_axi_awaddr <= reg_axi_awaddr;
                    end
                end
                else begin
                    reg_axi_awaddr_2f1 <= reg_axi_awaddr_2f1;
                    reg_axi_awaddr_2f2 <= reg_axi_awaddr_2f2;
                    reg_axi_awaddr <= reg_axi_awaddr;
                end
            end
            default: begin
                reg_axi_awaddr_1f1 <= reg_axi_awaddr_1f1;
                reg_axi_awaddr_1f2 <= reg_axi_awaddr_1f2;
                reg_axi_awaddr_2f1 <= reg_axi_awaddr_2f1;
                reg_axi_awaddr_2f2 <= reg_axi_awaddr_2f2;
                reg_axi_awaddr <= reg_axi_awaddr;
                awvalid_temp <= 1'b0;
                reg_axi_awvalid <= 1'b0;
            end
        endcase
    end
end


// axi 写数据输入
always @(*) begin
    case(axi_wr_state)
        WR1_PROC: begin
            rd_en_1 <= axi_wready;
            reg_axi_wdata <= rd_data_1;
        end
        WR2_PROC: begin
            rd_en_2 <= axi_wready;
            reg_axi_wdata <= rd_data_2;
        end
        default: begin
            rd_en_1 <= 1'b0;
            rd_en_2 <= 1'b0;
            reg_axi_wdata <= 'b0;
        end
    endcase
end


// 指示生成重读的行场同步信号
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        init_done <= 'b0;
    end
    else if(reg_axi_awaddr_1f1 > CMOS1_FRAME_1 + FRAME_ADDR - 10 * ADDR_STEP) begin
        init_done <= 1'b1;
    end
    else begin
        init_done <= init_done;
    end
end


// 指示当前要读取的帧
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
assign pose_vsync_in = ((vsync_in_d1) && (!vsync_in_d2)) ? 1'b1 : 1'b0;
assign nege_vsync_in = ((!vsync_in_d1) && (vsync_in_d2)) ? 1'b1 : 1'b0;

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


// axi 读控制逻辑
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        axi_rd_state <= 'd0;
    end
    else begin
        case(axi_rd_state)
            RD_INIT: begin
                axi_rd_state <= RD1_INIT;
            end
            RD1_INIT: begin
                if(pose_vsync_in == 1'b1) begin
                    axi_rd_state <= RD1_PROC;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD1_PROC: begin
                if(frame_rd_done == 1'b1) begin
                    axi_rd_state <= RD2_INIT;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD2_INIT: begin
                if(pose_vsync_in == 1'b1) begin
                    axi_rd_state <= RD2_PROC;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD2_PROC: begin
                if(frame_rd_done == 1'b1) begin
                    axi_rd_state <= RD3_INIT;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD3_INIT: begin
                if(pose_vsync_in == 1'b1) begin
                    axi_rd_state <= RD3_PROC;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD3_PROC: begin
                if(frame_rd_done == 1'b1) begin
                    axi_rd_state <= RD4_INIT;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD4_INIT: begin
                if(pose_vsync_in == 1'b1) begin
                    axi_rd_state <= RD4_PROC;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            RD4_PROC: begin
                if(frame_rd_done == 1'b1) begin
                    axi_rd_state <= RD_INIT;
                end
                else begin
                    axi_rd_state <= axi_rd_state;
                end
            end
            default: begin
                axi_rd_state <= RD_INIT;
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
            RD1_PROC: begin
                if((frame_inst_rd == 3'd1) && (reg_axi_araddr < CMOS1_FRAME_1 + FRAME_ADDR - ADDR_STEP)) begin
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
            RD2_PROC: begin
                if((frame_inst_rd == 3'd2) && (reg_axi_araddr < CMOS2_FRAME_1 + FRAME_ADDR - ADDR_STEP)) begin
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
            RD3_PROC: begin
                if((frame_inst_rd == 3'd3) && (reg_axi_araddr < CMOS1_FRAME_2 + FRAME_ADDR - ADDR_STEP)) begin
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
            RD4_PROC: begin
                if((frame_inst_rd == 3'd4) && (reg_axi_araddr < CMOS2_FRAME_2 + FRAME_ADDR - ADDR_STEP)) begin
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

axi_rd_fifo u_axi_rd_fifo(
    .wr_clk             (clk),                // input
    .wr_rst             ((pose_vs1) || (!rst)),                // input
    .wr_en              (reg_axi_rvalid),                  // input
    .wr_data            (reg_axi_rdata),              // input[255:0]
    .wr_full            (),              // output
    .almost_full        (almost_full_3),      // output
    .rd_clk             (cmos1_pclk),                // input
    .rd_rst             ((pose_vs1_pclk) || (!rst)),                // input
    .rd_en              (href_in),                  // input
    .rd_data            (cmos_data_out),              // output[7:0]
    .rd_empty           (),            // output
    .almost_empty       ()     // output
);


endmodule