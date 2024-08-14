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
`timescale 1ns / 1ps

module fpga_top#(
    parameter MEM_ROW_ADDR_WIDTH   = 15         ,
	parameter MEM_COL_ADDR_WIDTH   = 10         ,
	parameter MEM_BADDR_WIDTH      = 3          ,
	parameter MEM_DQ_WIDTH         =  32        ,
    parameter CTRL_ADDR_WIDTH = MEM_ROW_ADDR_WIDTH + MEM_BADDR_WIDTH + MEM_COL_ADDR_WIDTH,
	parameter MEM_DQS_WIDTH        =  32/8      
)
(
    input                               sys_clk                ,
    input                               sys_rst              ,
    input                               uart_rx                 ,
    //cmos1	
    output reg                          cmos_init_led           ,
    inout                               cmos1_scl              ,//cmos1 i2c 
    inout                               cmos1_sda              ,//cmos1 i2c 
    input                               cmos1_vsync            ,//cmos1 vsync
    input                               cmos1_href             ,//cmos1 hsync refrence,data valid
    input                               cmos1_pclk             ,//cmos1 pixel clock
    input   [7:0]                       cmos1_data             ,//cmos1 data
    output                              cmos1_reset            ,//cmos1 reset
    //cmos2
    inout                               cmos2_scl              ,//cmos2 i2c 
    inout                               cmos2_sda              ,//cmos2 i2c 
    input                               cmos2_vsync            ,//cmos2 vsync
    input                               cmos2_href             ,//cmos2 hsync refrence,data valid
    input                               cmos2_pclk             ,//cmos2 pxiel clock
    input   [7:0]                       cmos2_data             ,//cmos2 data
    output                              cmos2_reset            ,//cmos2 reset
    
    // RJ45 网口时序
    output                      e_mdc                               ,//MDIO的时钟信号，用于读写PHY的寄存器
    inout                       e_mdio                              ,//MDIO的数据信号，用于读写PHY的寄存器                         
    output [3:0]                rgmii_txd                           ,//RGMII 发送数据
    output                      rgmii_txctl                         ,//RGMII 发送有效信号
    output                      rgmii_txc                           ,//125Mhz ethernet rgmii tx clock
    input    [3:0]              rgmii_rxd                           ,//RGMII 接收数据
    input                       rgmii_rxctl                         ,//RGMII 接收数据有效信号
    input                       rgmii_rxc                           ,//125Mhz ethernet rgmii uart_rx clock
    output                      eth_init                            ,

    // DDR
    output                                  mem_rst_n       ,
    output                                  mem_ck          ,
    output                                  mem_ck_n        ,
    output                                  mem_cke         ,
    output                                  mem_cs_n        ,
    output                                  mem_ras_n       ,
    output                                  mem_cas_n       ,
    output                                  mem_we_n        ,
    output                                  mem_odt         ,
    output      [MEM_ROW_ADDR_WIDTH-1:0]    mem_a           ,
    output      [MEM_BADDR_WIDTH-1:0]       mem_ba          ,
    inout       [MEM_DQ_WIDTH/8-1:0]        mem_dqs         ,
    inout       [MEM_DQ_WIDTH/8-1:0]        mem_dqs_n       ,
    inout       [MEM_DQ_WIDTH-1:0]          mem_dq          ,
    output      [MEM_DQ_WIDTH/8-1:0]        mem_dm          ,
    output                                  ddr_init_done
);


// cmos
wire [1:0]                  cmos_init_done      ;
wire                        cmos_scl            ;//cmos i2c clock
wire                        cmos_sda            ;//cmos i2c data
wire                        cmos_vsync          ;//cmos vsync
wire                        cmos_href           ;//cmos hsync refrence,data valid
wire                        cmos_pclk           ;//cmos pxiel clock
wire [7:0]                  cmos_data           ;//cmos data
wire                        cmos_reset          ;//cmos reset
wire                        initial_en          ;
wire [15:0]                 cmos1_d_16bit       ;
wire                        cmos1_href_16bit    ;
wire                        cmos1_pclk_16bit    ;

wire                        clk_50M             ;
wire                        clk_25M             ;
wire                        clk_100M            ;
wire                        cmos_out_pclk       ;
wire                        cmos_out_vsync      ;
wire                        cmos_out_href       ;
wire [7:0]                  cmos_out_data       ;

// axi bus   
wire [CTRL_ADDR_WIDTH-1:0]  axi_awaddr          ;
wire                        axi_awuser_ap       ;
wire [3:0]                  axi_awuser_id       ;
wire [3:0]                  axi_awlen           ;
wire                        axi_awready         ;
wire                        axi_awvalid         ;
wire [MEM_DQ_WIDTH*8-1:0]   axi_wdata           ;
wire [MEM_DQ_WIDTH*8/8-1:0] axi_wstrb           ;
wire                        axi_wready          ;
wire [3:0]                  axi_wusero_id       ;
wire                        axi_wusero_last     ;
wire [CTRL_ADDR_WIDTH-1:0]  axi_araddr          ;
wire                        axi_aruser_ap       ;
wire [3:0]                  axi_aruser_id       ;
wire [3:0]                  axi_arlen           ;
wire                        axi_arready         ;
wire                        axi_arvalid         ;
wire [MEM_DQ_WIDTH*8-1:0]   axi_rdata           ;
wire                        axi_rvalid          ;
wire [3:0]                  axi_rid             ;
wire                        axi_rlast           ;

wire [7:0]                  command_data;
wire [7:0]                  cmos_data_out;

reg [7:0]                   cmos1_d_d0          ;
reg                         cmos1_href_d0       ;
reg                         cmos1_vsync_d0      ;
reg [7:0]                   cmos2_d_d0          ;
reg                         cmos2_href_d0       ;
reg                         cmos2_vsync_d0      ;


//
// 系统时钟
sys_pll u_sys_pll(
    .pll_rst    (!sys_rst),      // input
    .clkin1     (sys_clk),        // input
    .pll_lock   (locked),    // output
    .clkout0    (clk_50M),      // output, 50MHz
    .clkout1    (clk_25M)       // output, 25MHz
);


// 
// 配置CMOS
// OV5640 register configure enable    
power_on_delay	power_on_delay_inst(
    .clk_50M                 (clk_50M       ),//input
    .reset_n                 (1'b1          ),//input	
    .camera1_rstn            (cmos1_reset    ),//output
    .camera2_rstn            (cmos2_reset    ),//output
    .camera_pwnd             (               ),//output
    .initial_en              (initial_en     ) //output		
);
// CMOS1 Camera 
reg_config_1	coms1_reg_config(
    .clk_25M                 (clk_25M            ),//input
    .camera_rstn             (cmos1_reset        ),//input
    .initial_en              (initial_en         ),//input	
    .i2c_sclk                (cmos1_scl          ),//output
    .i2c_sdat                (cmos1_sda          ),//inout
    .reg_conf_done           (cmos_init_done[0]  ),//output config_finished
    .reg_index               (                   ),//output reg [8:0]
    .clock_20k               (                   ) //output reg
);
// CMOS2 Camera 
reg_config_1	coms2_reg_config(
    .clk_25M                 (clk_25M            ),//input
    .camera_rstn             (cmos2_reset        ),//input
    .initial_en              (initial_en         ),//input		
    .i2c_sclk                (cmos2_scl          ),//output
    .i2c_sdat                (cmos2_sda          ),//inout
    .reg_conf_done           (cmos_init_done[1]  ),//output config_finished
    .reg_index               (                   ),//output reg [8:0]
    .clock_20k               (                   ) //output reg
);


//
// cmos_init 显示 LED 灯
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        cmos_init_led <= 'b0;
    end
    else if(cmos_init_done == 2'b11) begin
        cmos_init_led <= 1'b1;
    end
    else begin
        cmos_init_led <= 1'b0;
    end
end


//
// CMOS 8bit转16bit
// CMOS1
always@(posedge cmos1_pclk)begin
    cmos1_d_d0        <= cmos1_data    ;
    cmos1_href_d0     <= cmos1_href    ;
    cmos1_vsync_d0    <= cmos1_vsync   ;
end

cmos_8_16bit cmos1_8_16bit(
    .pclk           (cmos1_pclk       ),//input
    .rst_n          (cmos_init_done[0]   ),//input
    .pdata_i        (cmos1_d_d0       ),//input[7:0]
    .de_i           (cmos1_href_d0    ),//input
    .vs_i           (cmos1_vsync_d0    ),//input
    
    .pixel_clk      (cmos1_pclk_16bit ),//output
    .pdata_o        (cmos1_d_16bit    ),//output[15:0]
    .de_o           (cmos1_href_16bit ) //output
);

// CMOS2
always@(posedge cmos2_pclk)begin
    cmos2_d_d0        <= cmos2_data    ;
    cmos2_href_d0     <= cmos2_href    ;
    cmos2_vsync_d0    <= cmos2_vsync   ;
end

cmos_8_16bit cmos2_8_16bit(
    .pclk           (cmos2_pclk       ),//input
    .rst_n          (cmos_init_done[1]),//input
    .pdata_i        (cmos2_d_d0       ),//input[7:0]
    .de_i           (cmos2_href_d0    ),//input
    .vs_i           (cmos2_vsync_d0    ),//input
    
    .pixel_clk      (cmos2_pclk_16bit ),//output
    .pdata_o        (cmos2_d_16bit    ),//output[15:0]
    .de_o           (cmos2_href_16bit ) //output
);


// cmos 通道选择
cmos_channel_sel u_cmos_channel_sel(
    .rst                    (sys_rst & cmos_init_done),
    .cmos1_pclk             (cmos1_pclk     ),
    .cmos1_vsync            (cmos1_vsync_d0 ),
    .cmos1_href             (cmos1_href_d0  ),
    .cmos1_data             (cmos1_d_d0     ),

    .cmos2_pclk             (cmos2_pclk     ),
    .cmos2_vsync            (cmos2_vsync_d0 ),
    .cmos2_href             (cmos2_href_d0  ),
    .cmos2_data             (cmos2_d_d0     ),

    .cmos_out_pclk          (cmos_out_pclk  ),
    .cmos_out_vsync         (cmos_out_vsync ),
    .cmos_out_href          (cmos_out_href  ),
    .cmos_out_data          (cmos_out_data  )
);


//
// 以太网传输模块
eth_trans  trans_sys  (
    .sys_clk        (clk_50M),
    .rst_n          (sys_rst),
    .led            (eth_init),

    .vin_clk        (cmos_out_pclk  ),
    .vin_data       (cmos_out_data  ),// 8bit, not 16bit
    .vin_vsync      (cmos_out_vsync ),
    .vin_href       (cmos_out_href  ),

    .e_mdc          (e_mdc),
    .e_mdio         (e_mdio),
    .rgmii_txd      (rgmii_txd),
    .rgmii_txctl    (rgmii_txctl),
    .rgmii_txc      (rgmii_txc),
    .rgmii_rxd      (rgmii_rxd),
    .rgmii_rxctl    (rgmii_rxctl),
    .rgmii_rxc      (rgmii_rxc)
);


endmodule