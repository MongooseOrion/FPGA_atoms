`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:Meyesemi 
// Engineer: Will
// 
// Create Date: 2023-01-29 20:31  
// Design Name:  
// Module Name: 
// Project Name: 
// Target Devices: Pango
// Tool Versions: 
// Description: 
//      
// Dependencies: 
// 
// Revision:
// Revision 1.0 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define UD #1

module hdmi_loop(
    input wire        sys_clk,     // input system clock 50MHz
//hdimi相关
    output            rstn_out,
    output            iic_scl,
    inout             iic_sda, 
    output            iic_tx_scl,
    inout             iic_tx_sda, 
    input             pixclk_in,                        
    input             vs_in, 
    input             hs_in, 
    input             de_in,
    input     [7:0]   r_in, 
    input     [7:0]   g_in, 
    input     [7:0]   b_in,  

    output               pixclk_out,                            
    output reg           vs_out, 
    output reg           hs_out, 
    output reg           de_out,
    output reg    [7:0]  r_out, 
    output reg    [7:0]  g_out, 
    output reg    [7:0]  b_out,
    output               led_int,
//pcie
    //clk and rst
    input                       ref_clk_n       ,      
    input                       ref_clk_p       ,      
    //diff signals
    input             rst_board,  
    input             pcie_perst_n ,  

    input           [1:0]       rxn             ,
    input           [1:0]       rxp             ,
    output  wire    [1:0]       txn             ,
    output  wire    [1:0]       txp       ,

    // RJ45  eth2
    output              e_mdc2                   ,//MDIO的时钟信号，用于读写PHY的寄存器
    inout               e_mdio2                  ,//MDIO的数据信号，用于读写PHY的寄存器  
    output  [3:0]       rgmii_txd2               ,//RGMII 发送数据
    output              rgmii_txctl2             ,//RGMII 发送有效信号
    output              rgmii_txc2               ,//125Mhz ethernet rgmii tx clock
    input   [3:0]       rgmii_rxd2               ,//RGMII 接收数据
    input               rgmii_rxctl2             ,//RGMII 接收数据有效信号
    input               rgmii_rxc2               ,//125Mhz ethernet rgmii RX clock
    // RJ45  eth1
    output              e_mdc                   ,//MDIO的时钟信号，用于读写PHY的寄存器
    inout               e_mdio                  ,//MDIO的数据信号，用于读写PHY的寄存器  
    output  [3:0]       rgmii_txd               ,//RGMII 发送数据
    output              rgmii_txctl             ,//RGMII 发送有效信号
    output              rgmii_txc               ,//125Mhz ethernet rgmii tx clock
    input   [3:0]       rgmii_rxd              ,//RGMII 接收数据
    input               rgmii_rxctl             ,//RGMII 接收数据有效信号
    input               rgmii_rxc               ,//125Mhz ethernet rgmii RX clock


    output              eth_init      

);



// ****************************************************************************************
    parameter   X_WIDTH = 4'd12;
    parameter   Y_WIDTH = 4'd12;    
//MODE_1080p
    parameter V_TOTAL = 12'd1125;
    parameter V_FP = 12'd4;
    parameter V_BP = 12'd36;
    parameter V_SYNC = 12'd5;
    parameter V_ACT = 12'd1080;
    parameter H_TOTAL = 12'd2200;
    parameter H_FP = 12'd88;
    parameter H_BP = 12'd148;
    parameter H_SYNC = 12'd44;
    parameter H_ACT = 12'd1920;
    parameter HV_OFFSET = 12'd0;

    reg [15:0]  rstn_1ms       ;
    wire        pix_clk        ;
    wire        cfg_clk        ;
    wire        locked         ;


//pcie
wire pclk;
wire pclk_div2/* synthesis PAP_MARK_DEBUG="1" */; //axis时钟
wire ref_clk;
wire core_rst_n;
//AXIS master interface
wire            axis_master_tvalid      ;
wire            axis_master_tready      ;
wire    [127:0] axis_master_tdata       ;
wire    [3:0]   axis_master_tkeep       ;
wire            axis_master_tlast       ;
wire    [7:0]   axis_master_tuser       ;

//axis slave 2 interface
wire            axis_slave2_tready      /* synthesis PAP_MARK_DEBUG="1" */ ;
wire            axis_slave2_tvalid      /* synthesis PAP_MARK_DEBUG="1" */ ;
wire    [127:0] axis_slave2_tdata       /* synthesis PAP_MARK_DEBUG="1" */ ;
wire            axis_slave2_tlast       /* synthesis PAP_MARK_DEBUG="1" */ ;
wire            axis_slave2_tuser       /* synthesis PAP_MARK_DEBUG="1" */ ;

//axis slave 1 interface
wire            axis_slave1_tready      /* synthesis PAP_MARK_DEBUG="1" */ ;
wire            axis_slave1_tvalid      /* synthesis PAP_MARK_DEBUG="1" */ ;
wire    [127:0] axis_slave1_tdata       /* synthesis PAP_MARK_DEBUG="1" */ ;
wire            axis_slave1_tlast       /* synthesis PAP_MARK_DEBUG="1" */ ;
wire            axis_slave1_tuser       /* synthesis PAP_MARK_DEBUG="1" */ ;

//
//axis slave 1 interface
wire            axis_slave0_tready      /* synthesis PAP_MARK_DEBUG="1" */ ;
wire            axis_slave0_tvalid      /* synthesis PAP_MARK_DEBUG="1" */ ;
wire    [127:0] axis_slave0_tdata       /* synthesis PAP_MARK_DEBUG="1" */ ;
wire            axis_slave0_tlast       /* synthesis PAP_MARK_DEBUG="1" */ ;
wire            axis_slave0_tuser       /* synthesis PAP_MARK_DEBUG="1" */ ;

wire    [7:0]   cfg_pbus_num            ;
wire    [4:0]   cfg_pbus_dev_num        ;

//eth1
wire  rc_valid1/*synthesis PAP_MARK_DEBUG="1"*/;
wire  [7:0] rc_data1/*synthesis PAP_MARK_DEBUG="1"*/;
wire  gmii_rx_clk1;
wire  eth_href/*synthesis PAP_MARK_DEBUG="1"*/;
wire  eth_vsync/*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0] eth_data/*synthesis PAP_MARK_DEBUG="1"*/;
//eth2
wire  rc_valid2/*synthesis PAP_MARK_DEBUG="1"*/;
wire  [7:0] rc_data2/*synthesis PAP_MARK_DEBUG="1"*/;
wire  gmii_rx_clk2;
wire  adc_href/*synthesis PAP_MARK_DEBUG="1"*/;
wire  adc_vsync/*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0] adc_data/*synthesis PAP_MARK_DEBUG="1"*/;
wire  eth_init2/*synthesis PAP_MARK_DEBUG="1"*/;
wire  eth_init1/*synthesis PAP_MARK_DEBUG="1"*/;
assign  eth_init = eth_init1 & eth_init2;

    PLL u_pll (
      .clkin1       (sys_clk   ),   // input//50MHz
      .pll_lock     (locked    ),   // output
      .clkout0      (cfg_clk   )    // output//10MHz
    );

    ms72xx_ctl ms72xx_ctl(
        .clk         (  cfg_clk    ), //input       clk,
        .rst_n       (  rstn_out   ), //input       rstn,
                                
        .init_over   (  init_over  ), //output      init_over,
        .iic_tx_scl  (  iic_tx_scl ), //output      iic_scl,
        .iic_tx_sda  (  iic_tx_sda ), //inout       iic_sda
        .iic_scl     (  iic_scl    ), //output      iic_scl,
        .iic_sda     (  iic_sda    )  //inout       iic_sda
    );

    assign    led_int  =  init_over; 

    always @(posedge cfg_clk)
    begin
    	if(!locked)
    	    rstn_1ms <= 16'd0;
    	else
    	begin
    		if(rstn_1ms == 16'h2710)
    		    rstn_1ms <= rstn_1ms;
    		else
    		    rstn_1ms <= rstn_1ms + 1'b1;
    	end
    end
    
    assign rstn_out = (rstn_1ms == 16'h2710);

//HDMI_OUT  =  HDMI_IN 
    assign pixclk_out   =  pixclk_in    ;

    always  @(posedge pixclk_out)begin
        if(!init_over)begin
    	        vs_out       <=  1'b0        ;
            hs_out       <=  1'b0        ;
            de_out       <=  1'b0        ;
            r_out        <=  8'b0        ;
            g_out        <=  8'b0        ;
            b_out        <=  8'b0        ;
        end
    	    else begin
            vs_out       <=  vs_in        ;
            hs_out       <=  hs_in        ;
            de_out       <=  de_in        ;
            r_out        <=  r_in         ;
            g_out        <=  g_in         ;
            b_out        <=  b_in         ;
        end
    end

//----------------------------------------------------------rst debounce ----------------------------------------------------------
//ASYNC RST  define IPSL_PCIE_SPEEDUP_SIM when simulation
hsst_rst_cross_sync_v1_0 #(
    `ifdef IPSL_PCIE_SPEEDUP_SIM
    .RST_CNTR_VALUE     (16'h10             )
    `else
    .RST_CNTR_VALUE     (16'hC000           )
    `endif
)
u_refclk_buttonrstn_debounce(
    .clk                (ref_clk            ),
    .rstn_in            (rst_board          ),
    .rstn_out           (sync_button_rst_n  )
);

hsst_rst_cross_sync_v1_0 #(
    `ifdef IPSL_PCIE_SPEEDUP_SIM
    .RST_CNTR_VALUE     (16'h10             )
    `else
    .RST_CNTR_VALUE     (16'hC000           )
    `endif
)
u_refclk_perstn_debounce(
    .clk                (ref_clk            ),
    .rstn_in            (pcie_perst_n            ),
    .rstn_out           (sync_perst_n       )
);

ipsl_pcie_sync_v1_0  u_ref_core_rstn_sync    (
    .clk                (ref_clk            ),
    .rst_n              (core_rst_n         ),
    .sig_async          (1'b1               ),
    .sig_synced         (ref_core_rst_n     )
);

ipsl_pcie_sync_v1_0  u_pclk_core_rstn_sync   (
    .clk                (pclk               ),
    .rst_n              (core_rst_n         ),
    .sig_async          (1'b1               ),
    .sig_synced         (s_pclk_rstn        )
);

ipsl_pcie_sync_v1_0  u_pclk_div2_core_rstn_sync   (
    .clk                (pclk_div2          ),
    .rst_n              (core_rst_n         ),
    .sig_async          (1'b1               ),
    .sig_synced         (s_pclk_div2_rstn   )
);



dma_ctrl dma_ctrl_video (
    .pcie_clk          (pclk_div2),
    .pix_clk           (pixclk_in),
    .rstn              (rstn_out | core_rst_n),
    .axis_master_tvalid(axis_master_tvalid),
    .axis_master_tready(axis_master_tready),
    .axis_master_tdata (axis_master_tdata),
    .axis_master_tkeep (axis_master_tkeep),
    .axis_master_tlast (axis_master_tlast),
    .axis_master_tuser (axis_master_tuser),
    .ep_bus_num        (cfg_pbus_num),
    .ep_dev_num        (cfg_pbus_dev_num),
    .axis_slave_tready (axis_slave2_tready),
    .axis_slave_tvalid (axis_slave2_tvalid),
    .axis_slave_tdata  (axis_slave2_tdata ),
    .axis_slave_tlast  (axis_slave2_tlast ),
    .axis_slave_tuser  (axis_slave2_tuser ),
    .hdmi_data_in      ({r_in[7:3],g_in[7:2],b_in[7:3]}),
//.hdmi_data_in      (voice_data_eth),
    .vs_in             (vs_in),
    .de_in             (de_in)
);

dma_ctrl  #(
    .CMD_REG_ADDR1(12'h110),
    .CMD_REG_ADDR2(12'h130),
    .CMD_REG_ADDR3(12'h150) 
) dma_ctrl_adc(
    .pcie_clk          (pclk_div2),
    .pix_clk           (pclk_div2),
    .rstn              (rstn_out | core_rst_n),
    .axis_master_tvalid(axis_master_tvalid),
    .axis_master_tready(axis_master_tready),
    .axis_master_tdata (axis_master_tdata),
    .axis_master_tkeep (axis_master_tkeep),
    .axis_master_tlast (axis_master_tlast),
    .axis_master_tuser (axis_master_tuser),
    .ep_bus_num        (cfg_pbus_num),
    .ep_dev_num        (cfg_pbus_dev_num),
    .axis_slave_tready (axis_slave1_tready),
    .axis_slave_tvalid (axis_slave1_tvalid),
    .axis_slave_tdata  (axis_slave1_tdata ),
    .axis_slave_tlast  (axis_slave1_tlast ),
    .axis_slave_tuser  (axis_slave1_tuser ),
    .hdmi_data_in      (adc_data),
//.hdmi_data_in      (voice_data_eth),
    .vs_in             (adc_vsync),
    .de_in             (adc_href)
);

dma_ctrl  #(
    .CMD_REG_ADDR1(12'h170),
    .CMD_REG_ADDR2(12'h180),
    .CMD_REG_ADDR3(12'h190) 
) dma_ctrl_eth(
    .pcie_clk          (pclk_div2),
    .pix_clk           (pclk_div2),
    .rstn              (rstn_out | core_rst_n),
    .axis_master_tvalid(axis_master_tvalid),
    .axis_master_tready(axis_master_tready),
    .axis_master_tdata (axis_master_tdata),
    .axis_master_tkeep (axis_master_tkeep),
    .axis_master_tlast (axis_master_tlast),
    .axis_master_tuser (axis_master_tuser),
    .ep_bus_num        (cfg_pbus_num),
    .ep_dev_num        (cfg_pbus_dev_num),
    .axis_slave_tready (axis_slave0_tready),
    .axis_slave_tvalid (axis_slave0_tvalid),
    .axis_slave_tdata  (axis_slave0_tdata ),
    .axis_slave_tlast  (axis_slave0_tlast ),
    .axis_slave_tuser  (axis_slave0_tuser ),
    .hdmi_data_in      (eth_data),
//.hdmi_data_in      (voice_data_eth),
    .vs_in             (eth_vsync),
    .de_in             (eth_href)
);

pcie_trans pcie_trans_inst (
  .free_clk(sys_clk),                                      // input,系统时钟输入，50MHz
  .pclk(pclk),                                              // output
  .pclk_div2(pclk_div2),                                    // output      axis时钟
  .ref_clk(ref_clk),                                        // output  暂时不用

  .ref_clk_n(ref_clk_n),                                    // input
  .ref_clk_p(ref_clk_p),                                    // input
  .button_rst_n(sync_button_rst_n),                                     // input    按键复位信号
  .power_up_rst_n(sync_perst_n),                          // input
  .perst_n(sync_perst_n),                                        // input
  .core_rst_n(core_rst_n),                                  // output

//system signal
  .smlh_link_up(),                              // output
  .rdlh_link_up(),                              // output
  .smlh_ltssm_state(),                      // output [4:0]

//APB interface to  DBI cfg
  .p_sel(),                                            // input
  .p_strb(),                                          // input [3:0]
  .p_addr(),                                          // input [15:0]
  .p_wdata(),                                        // input [31:0]
  .p_ce(),                                              // input
  .p_we(),                                              // input
  .p_rdy(),                                            // output
  .p_rdata(),                                        // output [31:0]
//PHY diff signals
  .rxn(rxn),                                                // input [1:0]
  .rxp(rxp),                                                // input [1:0]
  .txn(txn),                                                // output [1:0]
  .txp(txp),                                                // output [1:0]

  .pcs_nearend_loop ({2{1'b0}}),                      // input [1:0]
  .pma_nearend_ploop({2{1'b0}}),                    // input [1:0]
  .pma_nearend_sloop({2{1'b0}}),                    // input [1:0]

  .axis_master_tvalid(axis_master_tvalid),                  // output
  .axis_master_tready(axis_master_tready),                  // input
  .axis_master_tdata(axis_master_tdata),                    // output [127:0]
  .axis_master_tkeep(axis_master_tkeep),                    // output [3:0]
  .axis_master_tlast(axis_master_tlast),                    // output
  .axis_master_tuser(axis_master_tuser),                    // output [7:0]

  .axis_slave0_tready(axis_slave0_tready),                  // output
  .axis_slave0_tvalid(axis_slave0_tvalid),                  // input
  .axis_slave0_tdata (axis_slave0_tdata ),                    // input [127:0]
  .axis_slave0_tlast (axis_slave0_tlast ),                    // input
  .axis_slave0_tuser (axis_slave0_tuser ),                    // input

  .axis_slave2_tready(axis_slave1_tready),                  // output
  .axis_slave2_tvalid(axis_slave1_tvalid),                  // input
  .axis_slave2_tdata (axis_slave1_tdata ),                    // input [127:0]
  .axis_slave2_tlast (axis_slave1_tlast ),                    // input
  .axis_slave2_tuser (axis_slave1_tuser ),                    // input

  .axis_slave1_tready(axis_slave2_tready),                  // output
  .axis_slave1_tvalid(axis_slave2_tvalid),                  // input
  .axis_slave1_tdata(axis_slave2_tdata),                    // input [127:0]
  .axis_slave1_tlast(axis_slave2_tlast),                    // input
  .axis_slave1_tuser(axis_slave2_tuser),                    // input

  .pm_xtlh_block_tlp(),                    // output

  .cfg_send_cor_err_mux(),              // output
  .cfg_send_nf_err_mux(),                // output
  .cfg_send_f_err_mux(),                  // output
  .cfg_sys_err_rc(),                          // output
  .cfg_aer_rc_err_mux(),                  // output

  .radm_cpl_timeout(),                      // output
  .cfg_max_rd_req_size(),                // output [2:0]
  .cfg_bus_master_en(),                    // output
  .cfg_max_payload_size(),              // output [2:0]
  .cfg_ext_tag_en(),                          // output
  .cfg_rcb(),                                        // output
  .cfg_mem_space_en(),                      // output
  .cfg_pm_no_soft_rst(),                  // output
  .cfg_crs_sw_vis_en(),                    // output
  .cfg_no_snoop_en(),                        // output
  .cfg_relax_order_en(),                  // output
  .cfg_tph_req_en(),                          // output [1:0]
  .cfg_pf_tph_st_mode(),                  // output [2:0]

  .cfg_pbus_num(cfg_pbus_num),                              // output [7:0]
  .cfg_pbus_dev_num(cfg_pbus_dev_num),                      // output [4:0]

  .rbar_ctrl_update(),                      // output
  .cfg_atomic_req_en(),                    // output
  .radm_idle(),                                    // output
  .radm_q_not_empty(),                      // output
  .radm_qoverflow(),                          // output

  .diag_ctrl_bus('d0),                            // input [1:0]
  .dyn_debug_info_sel('d0),                  // input [3:0]

  .cfg_link_auto_bw_mux(),              // output
  .cfg_bw_mgt_mux(),                          // output
  .cfg_pme_mux(),                                // output
  .debug_info_mux(),                          // output [132:0]

  .app_ras_des_sd_hold_ltssm('d0),    // input
  .app_ras_des_tba_ctrl('d0)               // input [1:0]
);

//以太网1接收上位机
send_data_protocol u_send_data_protocol_eth(
    .clk_data_in    (gmii_rx_clk1),
    .rst            (rstn_out),
    .clk_data_out   (pclk_div2),
    .i_valid        (rc_valid1),
    .i_data         (rc_data1),
    .o_data         (eth_data),
    .o_href         (eth_href),
    .o_vsync        (eth_vsync)
);

eth_trans #(
.SOURCE_MAC_ADDR     (48'h00_0a_35_01_fe_c2 ) ,
.SOURCE_IP_ADDR      (32'hc0a80006 ) ,
.DESTINATION_IP_ADDR (32'hc0a80007 )  
)
u_eth_trans_1
(
    .sys_clk        (sys_clk    ),
    .rst_n          (rstn_out   ),
    .led            (eth_init1   ),
    .e_mdc          (e_mdc),
    .e_mdio         (e_mdio),
    .rgmii_txd      (rgmii_txd),
    .rgmii_txctl    (rgmii_txctl),
    .rgmii_txc      (rgmii_txc),
    .rgmii_rxd      (rgmii_rxd),
    .rgmii_rxctl    (rgmii_rxctl),
    .rgmii_rxc      (rgmii_rxc),
    .rc_valid       (rc_valid1),
    .rc_data        (rc_data1),
    .gmii_rx_clk    (gmii_rx_clk1)
);

// 通过以太网2接收另一张板卡adc数据
send_data_protocol u_send_data_protocol_adc(
    .clk_data_in    (gmii_rx_clk2),
    .rst            (rstn_out),
    .clk_data_out   (pclk_div2),
    .i_valid        (rc_valid2),
    .i_data         (rc_data2),
    .o_data         (adc_data),
    .o_href         (adc_href),
    .o_vsync        (adc_vsync)
);

eth_trans #(
.SOURCE_MAC_ADDR     (48'h00_0a_35_01_fe_c2 ) ,
.SOURCE_IP_ADDR      (32'hc0a80005 ) ,
.DESTINATION_IP_ADDR (32'hc0a80004 )  
)
u_eth_trans_2
(
    .sys_clk        (sys_clk    ),
    .rst_n          (rstn_out   ),
    .led            (eth_init2   ),
    .e_mdc          (e_mdc2),
    .e_mdio         (e_mdio2),
    .rgmii_txd      (rgmii_txd2),
    .rgmii_txctl    (rgmii_txctl2),
    .rgmii_txc      (rgmii_txc2),
    .rgmii_rxd      (rgmii_rxd2),
    .rgmii_rxctl    (rgmii_rxctl2),
    .rgmii_rxc      (rgmii_rxc2),
    .rc_valid       (rc_valid2),
    .rc_data        (rc_data2),
    .gmii_rx_clk    (gmii_rx_clk2)
);

//对rc_valid2的下降沿次数在1s内进行计数，在50mhz sys_clk下
reg [20:0] cnt_rc_valid2/* synthesis PAP_MARK_DEBUG="1" */;
reg rc_valid2_d1;
reg rc_valid2_d2;
reg [11:0]  rc_valid2_cnt/* synthesis PAP_MARK_DEBUG="1" */;
//计数拉高时间
always @(posedge gmii_rx_clk2 or negedge rstn_out) begin
    if(!rstn_out) begin
        rc_valid2_cnt <= 12'b0;
    end
    else begin
        if(rc_valid2) begin
            rc_valid2_cnt <= rc_valid2_cnt + 1'b1;
        end
        else begin
            rc_valid2_cnt <= 12'b0;
        end
    end
end
reg [32:0] cnt_1s/* synthesis PAP_MARK_DEBUG="1" */;
// 1s计数
always @(posedge sys_clk or negedge rstn_out) begin
    if(!rstn_out) begin
        cnt_1s <= 32'b0;
    end
    else begin
        if(cnt_1s == 'd500000000) begin
            cnt_1s <= 32'b0;
        end
        else begin
            cnt_1s <= cnt_1s + 1'b1;
        end
    end
end
always @(posedge sys_clk or negedge rstn_out) begin
    if(!rstn_out) begin
        cnt_rc_valid2 <= 'b0;
    end
    else begin
        if(rc_valid2_d1 == 1'b1 && rc_valid2_d2 == 1'b0) begin
            cnt_rc_valid2 <= cnt_rc_valid2 + 1'b1;
        end
        else if(cnt_1s == 'd500000000) begin
            cnt_rc_valid2 <= 'b0;
        end
        else begin
            cnt_rc_valid2 <= cnt_rc_valid2;
        end
    end
end

//同理，对adc_vsync下降沿也计数
reg [20:0] cnt_adc_vsync/* synthesis PAP_MARK_DEBUG="1" */;
reg adc_vsync_d1;
reg adc_vsync_d2;
// 1s计数
always @(posedge sys_clk or negedge rstn_out) begin
    if(!rstn_out) begin
        cnt_adc_vsync <= 'b0;
    end
    else begin
        if(adc_vsync_d1 == 1'b1 && adc_vsync_d2 == 1'b0) begin
            cnt_adc_vsync <= cnt_adc_vsync + 1'b1;
        end
        else if(cnt_1s == 'd500000000) begin
            cnt_adc_vsync <= 'b0;
        end
        else begin
            cnt_adc_vsync <= cnt_adc_vsync;
        end
    end
end


//对信号打拍，跨时钟域处理场信号
always @(posedge sys_clk or negedge rstn_out) begin
    if(!rstn_out) begin
        rc_valid2_d1 <= 1'b0;
        rc_valid2_d2 <= 1'b0;
    end
    else begin
        rc_valid2_d1 <= rc_valid2;
        rc_valid2_d2 <= rc_valid2_d1;
    end

end

always @(posedge sys_clk or negedge rstn_out) begin
    if(!rstn_out) begin
        adc_vsync_d1 <= 1'b0;
        adc_vsync_d2 <= 1'b0;
    end
    else begin
        adc_vsync_d1 <= adc_vsync;
        adc_vsync_d2 <= adc_vsync_d1;
    end
    end




endmodule
