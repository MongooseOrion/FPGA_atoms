`timescale 1ns / 1ps  

module ethernet_global(
    input       	sys_clk,
    input       	key,
    input       	rst_n,

    input           udp_rec_data_clk,
    input           udp_rec_data_rd_en,
    output [15:0]	udp_rec_data,
    output  		udp_rec_data_ready_out,
    
    output      	phy_rst_n,
    output      	e_mdc,
    inout       	e_mdio,
    output	[3:0] 	rgmii_txd,
    output      	rgmii_txctl,
    output      	rgmii_txc,
    input	[3:0]  	rgmii_rxd,
    input       	rgmii_rxctl,
    input       	rgmii_rxc,
    output      	state_led
);


wire            reset_n;
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
wire            rgmii_rxcpll;

wire [7:0]      udp_rec_ram_rdata;
wire  			udp_rec_ram_read_en;

wire 			udp_rec_ram_read_en_1;
reg  			udp_rec_ram_read_en_2;
wire            rd_empty_test/*synthesis PAP_MARK_DEBUG="1"*/;
wire            wr_full_test/*synthesis PAP_MARK_DEBUG="1"*/;

assign speed_selection = 2'b10;
assign duplex_mode = 1'b1;
assign state_led = led;

reset_dly delay_u0(
.clk       (sys_clk        ),
.rst_n     (rst_n ),
.rst_n_dly (phy_rst_n          )
);
util_gmii_to_rgmii util_gmii_to_rgmii_m0(
    .reset          (1'b0),
    
    .rgmii_td       (rgmii_txd),
    .rgmii_tx_ctl   (rgmii_txctl),
    .rgmii_txc      (rgmii_txc),
    .rgmii_rd       (rgmii_rxd),
    .rgmii_rx_ctl(rgmii_rxctl),
    .gmii_rx_clk(gmii_rx_clk),
    .gmii_txd(gmii_txd),
    .gmii_tx_en(gmii_tx_en),
    .gmii_tx_er(1'b0),
    .gmii_tx_clk(gmii_tx_clk),
    .gmii_crs(gmii_crs),
    .gmii_col(gmii_col),
    .gmii_rxd(gmii_rxd),
    .rgmii_rxc(rgmii_rxc),//add
    .gmii_rx_dv(gmii_rx_dv),
    .gmii_rx_er(gmii_rx_er),
    .speed_selection(speed_selection),
    .duplex_mode(duplex_mode),
    .led(led),
    .pll_phase_shft_lock(pll_phase_shft_lock),
    .clk(clk),
    .sys_clk(sys_clk)
    );

assign gmii_tx_clk_test=~gmii_tx_clk;
wire[15:0] udp_send_data_length;

mac_test mac_test0
(
    .gmii_tx_clk            (gmii_tx_clk),
    .gmii_rx_clk            (gmii_rx_clk) ,
    .rst_n                  (rst_n),
    .push_button            (key),
    .gmii_rx_dv             (gmii_rx_dv),
    .gmii_rxd               (gmii_rxd ),
    .gmii_tx_en             (gmii_tx_en),
    .gmii_txd               (gmii_txd ),
    .udp_send_data_length	(udp_send_data_length),
    .write_sel				(write_sel),
    .udp_rec_data_valid		(udp_rec_data_valid),
    .al_full 				(al_full),
    .emp_sum 				(emp_sum),
    .checksum_wr			(checksum_wr),
    .use_rd  				(use_rd),
    .udp_rec_ram_rdata		(udp_rec_ram_rdata) ,
    .udp_rec_ram_read_addr	(udp_rec_ram_read_addr) ,
    .udp_rec_data_length	(udp_rec_data_length),     
    .udp_rec_ram_read_en	(udp_rec_ram_read_en_1)
); 


// 最后一级缓存 FIFO
fifo_rd_cache fifo_rd_cache_inst(
    .wr_clk			(gmii_rx_clk),                // input
    .wr_rst			(!rst_n),                // input
    .wr_en			(udp_rec_ram_read_en_2),                  // input
    .wr_data		(udp_rec_ram_rdata),              // input [7:0]
    .wr_full		(wr_full_test),              // output
    .almost_full	(udp_rec_data_ready_out),      // output
    .rd_clk			(udp_rec_data_clk),                // input
    .rd_rst			(!rst_n),                // input
    .rd_en			(udp_rec_data_rd_en),                  // input
    .rd_data		(udp_rec_data),              // output [15:0]
    .rd_empty		(rd_empty_test),            // output
    .almost_empty	()     // output
);


// 使能信号应该延迟一个周期
always @(posedge gmii_rx_clk or negedge rst_n) begin
    if(!rst_n) begin
        udp_rec_ram_read_en_2 <= 1'b0;
    end
    else begin
        udp_rec_ram_read_en_2 <= udp_rec_ram_read_en_1;
    end
end


endmodule
