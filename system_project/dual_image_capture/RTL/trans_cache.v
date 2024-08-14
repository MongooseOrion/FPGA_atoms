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
    input                           ddr_clk,
    input                           ddr_init,
    input                           cmos1_init,
    input                           cmos2_init,

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
    input                           sync_clk        ,
    output  [7:0]                   cmos_data_out   ,

    output                          init_done       /*synthesis PAP_MARK_DEBUG = "1"*/,

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

wire                            channel1_rd_en      ;
wire                            channel1_rready     ;
wire [MEM_DQ_WIDTH*8-1'b1:0]    channel1_data       ;
wire                            channel2_rd_en      ;
wire                            channel2_rready     ;
wire [MEM_DQ_WIDTH*8-1'b1:0]    channel2_data       ;   
wire                            pose_vs1_pclk       ;
wire                            pre_en_1            ;
wire                            pre_en_2            ;
wire [MEM_DQ_WIDTH*8-1'b1:0]    buf_wr_data         ;
wire                            buf_wr_en           ;
wire                            rd_buf_rst          ;

reg                             cmos1_vs_d1         ;
reg                             cmos2_vs_d1         ;
reg [7:0]                       pix_count_1         ;
reg [7:0]                       pix_count_2         ;

assign pose_vs1_pclk = ((cmos1_vs_in) && (!cmos1_vs_d1)) ? 1'b1 : 1'b0;
assign pose_vs2_pclk = ((cmos2_vs_in) && (!cmos2_vs_d1)) ? 1'b1 : 1'b0;


// 将数据延迟一个时钟以匹配使能信号
always @(posedge cmos1_pclk or negedge cmos1_init) begin
    if(!cmos1_init) begin
        cmos1_vs_d1 <= 'b0;
    end
    else begin
        cmos1_vs_d1 <= cmos1_vs_in;
    end
end

always @(posedge cmos2_pclk or negedge cmos2_init) begin
    if(!cmos2_init) begin
        cmos2_vs_d1 <= 'b0;
    end
    else begin
        cmos2_vs_d1 <= cmos2_vs_in;
    end
end


// 存储 cmos1 数据
cmos_data_cache cmos1_data_fifo(
    .wr_clk             (cmos1_pclk),                // input
    .wr_rst             ((!cmos1_init) || (pose_vs1_pclk)),                // input
    .wr_en              (cmos1_de_in),                  // input
    .wr_data            (cmos1_data),              // input [7:0]
    .wr_full            (),              // output
    .almost_full        (channel1_rready),      // output
    .rd_clk             (ddr_clk),                // input
    .rd_rst             ((!cmos1_init) || (pose_vs1_pclk)),                // input
    .rd_en              ((channel1_rd_en) || (pre_en_1)),                  // input
    .rd_data            (channel1_data),              // output [255:0]
    .rd_empty           (),            // output
    .almost_empty       ()     // output
);

// 存储 cmos2 数据
cmos_data_cache cmos2_data_fifo(
    .wr_clk             (cmos2_pclk),                // input
    .wr_rst             ((!cmos2_init) || (pose_vs2_pclk)),                // input
    .wr_en              (cmos2_de_in),                  // input
    .wr_data            (cmos2_data),              // input [7:0]
    .wr_full            (),              // output
    .almost_full        (channel2_rready),      // output
    .rd_clk             (ddr_clk),                // input
    .rd_rst             ((!cmos2_init) || (pose_vs2_pclk)),                // input
    .rd_en              ((channel2_rd_en) || (pre_en_2)),                  // input
    .rd_data            (channel2_data),              // output [255:0]
    .rd_empty           (),            // output
    .almost_empty       ()     // output
);


// 每帧开头预读数据
always @(posedge ddr_clk or negedge ddr_init) begin
    if(!ddr_init) begin
        pix_count_1 <= 'b0;
    end
    else if(pose_vs1_pclk == 1'b1) begin
        pix_count_1 <= 8'b0;
    end
    else if((cmos1_de_in == 1'b1) && (pix_count_1 < 8'd50)) begin
        pix_count_1 <= pix_count_1 + 1'b1;
    end
    else begin
        pix_count_1 <= pix_count_1;
    end
end

always @(posedge ddr_clk or negedge ddr_init) begin
    if(!ddr_init) begin
        pix_count_2 <= 'b0;
    end
    else if(pose_vs1_pclk == 1'b1) begin
        pix_count_2 <= 8'b0;
    end
    else if((cmos2_de_in == 1'b1) && (pix_count_2 < 8'd50)) begin
        pix_count_2 <= pix_count_1 + 1'b1;
    end
    else begin
        pix_count_2 <= pix_count_2;
    end
end

assign pre_en_1 = (pix_count_1 == 8'd47) ? 1'b1 : 1'b0;
assign pre_en_2 = (pix_count_2 == 8'd47) ? 1'b1 : 1'b0;


// 数据经过 AXI 总线写入 DDR
axi_interconnect_wr u_axi_interconnect_wr(
    .clk                            (ddr_clk            ),
    .rst                            (ddr_init           ),

    .channel1_vsync                 (cmos1_vs_in        ),
    .channel1_rready                (channel1_rready    ),
    .channel1_rd_en                 (channel1_rd_en     ),
    .channel1_data                  (channel1_data      ),

    .channel2_vsync                 (cmos2_vs_in        ),
    .channel2_rready                (channel2_rready    ),
    .channel2_rd_en                 (channel2_rd_en     ),
    .channel2_data                  (channel2_data      ),

    .axi_awaddr                     (axi_awaddr  ),
    .axi_awid                       (axi_awid    ),
    .axi_awlen                      (axi_awlen   ),
    .axi_awsize                     (axi_awsize  ),
    .axi_awburst                    (axi_awburst ),
    .axi_awready                    (axi_awready ),
    .axi_awvalid                    (axi_awvalid ),
    .axi_wdata                      (axi_wdata   ),
    .axi_wstrb                      (axi_wstrb   ),
    .axi_wlast                      (axi_wlast   ),
    .axi_wvalid                     (axi_wvalid  ),
    .axi_wready                     (axi_wready  ),
    .axi_bid                        (axi_bid     ),
    .axi_bvalid                     (axi_bvalid  ),
    .axi_bready                     (axi_bready  )
);


// AXI 总线读逻辑
axi_interconnect_rd u_axi_interconnect_rd(
    .clk                        (ddr_clk        ),
    .rst                        (ddr_init       ),

    .buf_wr_data                (buf_wr_data    ),
    .buf_wr_en                  (buf_wr_en      ),
    .buf_wr_rst                 (rd_buf_rst     ),

    .vsync_in                   (vsync_in),
    .href_in                    (href_in),

    .axi_arvalid                (axi_arvalid ),
    .axi_arready                (axi_arready ),
    .axi_araddr                 (axi_araddr  ),
    .axi_arid                   (axi_arid    ),
    .axi_arlen                  (axi_arlen   ),
    .axi_arsize                 (axi_arsize  ),
    .axi_arburst                (axi_arburst ),        
    .axi_rready                 (axi_rready  ),
    .axi_rdata                  (axi_rdata   ),
    .axi_rvalid                 (axi_rvalid  ),
    .axi_rlast                  (axi_rlast   ),
    .axi_rid                    (axi_rid     )
);


// axi 读出数据缓存
axi_rd_fifo u_axi_rd_fifo(
    .wr_clk             (ddr_clk),                // input
    .wr_rst             ((rd_buf_rst) || (!ddr_init)),                // input
    .wr_en              (buf_wr_en),                  // input
    .wr_data            (buf_wr_data),              // input[255:0]
    .wr_full            (),              // output
    .almost_full        (almost_full_3),      // output
    .rd_clk             (sync_clk),                // input
    .rd_rst             ((rd_buf_rst) || (!ddr_init)),                // input
    .rd_en              (href_in),                  // input
    .rd_data            (cmos_data_out),              // output[7:0]
    .rd_empty           (),            // output
    .almost_empty       ()     // output
);


endmodule