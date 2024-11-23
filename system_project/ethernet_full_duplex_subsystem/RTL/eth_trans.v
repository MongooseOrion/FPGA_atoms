// 数据以太网传输
module eth_trans (

    input                       sys_clk     ,               // 50MHz
    input                       rst_n       ,
    output                      led         ,

    // 输入数据
    input                   data_tx_clk         ,           // 源数据时钟
    input                   data_tx_vsync       ,           // 源数据帧场同步信号
    input                   data_tx_href        ,           // 源数据行同步信号
    input [7:0]             source_tx_data      ,           // 源数据（字节流）

    // 输出数据
    input                   data_rx_clk         ,           // 目的数据时钟
    input                   data_rx_rd_en       ,           // 目的数据读使能
    output [15:0]           rx_data             ,           // 目的数据（字节流）
    output                  data_rx_ready       ,           // 目的数据就绪信号

    // RJ45 网口时序
    output                      e_mdc,                      //MDIO的时钟信号，用于读写PHY的寄存器
    inout                       e_mdio,                     //MDIO的数据信号，用于读写PHY的寄存器                         
    output [3:0]                rgmii_txd,                  //RGMII 发送数据
    output                      rgmii_txctl,                //RGMII 发送有效信号
    output                      rgmii_txc,                  //125Mhz ethernet rgmii tx clock
    input    [3:0]              rgmii_rxd,                  //RGMII 接收数据
    input                       rgmii_rxctl,                //RGMII 接收数据有效信号
    input                       rgmii_rxc                   //125Mhz ethernet gmii rx clock    
);

wire   [ 7:0]   gmii_txd;
wire            gmii_tx_en;
wire            gmii_tx_er;
wire            gmii_tx_clk;
wire            gmii_crs;
wire            gmii_col;
wire   [ 7:0]   gmii_rxd;
wire            gmii_rx_dv;
wire            gmii_rx_er;
wire            gmii_rx_clk;
wire  [ 1:0]    speed_selection; // 1x gigabit, 01 100Mbps, 00 10mbps
wire            duplex_mode;     // 1 full, 0 half

wire            data_tx_vsync_delay/*synthesis PAP_MARK_DEBUG="1"*/;
wire            data_tx_href_delay/*synthesis PAP_MARK_DEBUG="1"*/;
wire [7:0]      source_tx_data_delay/*synthesis PAP_MARK_DEBUG="1"*/;

wire [7:0]       udp_rec_data/*synthesis PAP_MARK_DEBUG="1"*/;
wire             udp_rec_valid/*synthesis PAP_MARK_DEBUG="1"*/;

//MDIO config
assign speed_selection = 2'b10;
assign duplex_mode = 1'b1;


util_gmii_to_rgmii util_gmii_to_rgmii_m0(
	.reset          (1'b0),
	
	.rgmii_td                   (rgmii_txd),
	.rgmii_tx_ctl               (rgmii_txctl),
	.rgmii_txc                  (rgmii_txc),
	.rgmii_rd                   (rgmii_rxd),
	.rgmii_rx_ctl               (rgmii_rxctl),
	.gmii_rx_clk                (gmii_rx_clk),
	.gmii_txd                   (gmii_txd),
	.gmii_tx_en                 (gmii_tx_en),
	.gmii_tx_er                 (1'b0),
	.gmii_tx_clk                (gmii_tx_clk),
	.gmii_crs                   (gmii_crs),
	.gmii_col                   (gmii_col),
	.gmii_rxd                   (gmii_rxd),
    .rgmii_rxc                  (rgmii_rxc),//add
	.gmii_rx_dv                 (gmii_rx_dv),
	.gmii_rx_er                 (gmii_rx_er),
	.speed_selection            (speed_selection),
	.duplex_mode                (duplex_mode),
    .led                        (led),
    .pll_phase_shft_lock        (),
    .clk                        (),
    .sys_clk                    (sys_clk)
	);


frame_sync_delay signal_delay_inst(
   .data_clk            (data_tx_clk),             
   .data_href           (data_tx_href),            
   .data_vsync          (data_tx_vsync),           
   .source_data         (source_tx_data),          

   .data_href_delay     (data_tx_href_delay),      
   .data_vsync_delay    (data_tx_vsync_delay),     
   .source_data_delay   (source_tx_data_delay)     
) ;


//
// tx fifo
wire [10:0] fifo_data_count;
wire [7:0]  fifo_data;
wire        fifo_rd_en;
pre_trans_fifo u_pre_trans_fifo(
    .wr_clk             (data_tx_clk),
    .wr_rst             (data_tx_vsync),
    .wr_en              (data_tx_href_delay),
    .wr_data            (source_tx_data_delay), // addr: [11:0], data: [7:0]
    .wr_full            (),
    .wr_water_level     (),
    .almost_full        (),
    .rd_clk             (gmii_rx_clk),
    .rd_rst             (data_tx_vsync),
    .rd_en              (fifo_rd_en),
    .rd_data            (fifo_data),
    .rd_empty           (),
    .rd_water_level     (fifo_data_count),
    .almost_empty       ()
);


//
// mac layer
mac_package u_mac_package (
    .gmii_tx_clk            (gmii_tx_clk        ),
    .gmii_rx_clk            (gmii_rx_clk        ) ,
    .rst_n                  (rst_n              ),
    
    .data_tx_vsync           (data_tx_vsync     ),
    .data_tx_href            (data_tx_href      ),
    .reg_conf_done           (reg_conf_done     ),
    .fifo_data               (fifo_data         ),         
    .fifo_data_count         (fifo_data_count   ),            
    .fifo_rd_en              (fifo_rd_en        ), 
    .udp_rec_data            (udp_rec_data      ),
    .udp_rec_data_valid      (udp_rec_data_valid),  
    .udp_rec_data_state      (udp_rec_data_state),
    
    
    .udp_send_data_length   (16'd1024           ), 
    .gmii_rx_dv             (gmii_rx_dv         ),
    .gmii_rxd               (gmii_rxd           ),
    .gmii_tx_en             (gmii_tx_en         ),
    .gmii_txd               (gmii_txd           )
 
);	


// 
// rx fifo
rx_cache u_rx_cache(
    .wr_clk                 (rgmii_rxc),                // input
    .wr_rst                 (!rst_n),                // input
    .wr_en                  (udp_rec_data_valid),                  // input
    .wr_data                (udp_rec_data),              // input [7:0]
    .wr_full                (),              // output
    .almost_full            (),      // output
    .rd_clk                 (data_rx_clk),                // input
    .rd_rst                 (!rst_n),                // input
    .rd_en                  (data_rx_rd_en),                  // input
    .rd_data                (rx_data),              // output [15:0]
    .rd_empty               (),            // output
    .almost_empty           (data_rx_ready)     // output
);



endmodule