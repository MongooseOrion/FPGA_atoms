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
// 以太网音频输入
//
`timescale 1ns/1ps

module ethernet_voice_in(
    input               sys_clk         ,//50MHz
    input               rst_n             ,
    //ES7243E  ADC  in
    output              es7243_scl      ,//CCLK
    inout               es7243_sda      ,//CDATA
    output              es0_mclk        ,//MCLK  clk_12M
    input               es0_sdin        ,//SDOUT i2s数据输入             i2s_sdin
    input               es0_dsclk       ,//SCLK  i2s数据时钟             i2s_sck   
    input               es0_alrck       ,//LRCK  i2s数据左右信道帧时钟     i2s_ws
    //ES8156  DAC   out
    output              es8156_scl      ,//CCLK
    inout               es8156_sda      ,//CDATA 
    output              es1_mclk        ,//MCLK  clk_12M
    input               es1_sdin        ,//SDOUT 回放信号反馈？
    output              es1_sdout       ,//SDIN  DAC i2s数据输出          i2s_sdout
    input               es1_dsclk       ,//SCLK  i2s数据位时钟            i2s_sck
    input               es1_dlrc        ,//LRCK  i2s数据左右信道帧时钟      i2s_ws
  
    input               left_in_detect  ,//麦克风插入检测
    input               left_out_detect ,//扬声器检测   
    output              plugin_led       ,//插入指示灯 
    output              adc_dac_init,

    // 以太网
    output      	    e_mdc,
    inout       	    e_mdio,
    output	[3:0] 	    rgmii_txd,
    output      	    rgmii_txctl,
    output      	    rgmii_txc,
    input	[3:0]  	    rgmii_rxd,
    input       	    rgmii_rxctl,
    input       	    rgmii_rxc,
    output      	    ethernet_led
);

assign lin_led=left_in_detect?1'b0:1'b1;
assign lout_led=left_out_detect?1'b0:1'b1;
assign plugin_led=left_in_detect&left_out_detect?1'b0:1'b1;

wire        udp_rec_data_ready_out;
wire [15:0] voice_data_out;

wire        locked         ;
wire        rstn_out       ;
wire        es7243_init    ;
wire        es8156_init    ;
wire        clk_12M        ;

    pll u_pll (
      .clkin1       (sys_clk   ),   // input//50MHz
      .pll_lock     (locked    ),   // output
      .clkout0      (clk_12M   )    // output//12.288MHz
    );
assign es0_mclk    =    clk_12M;

reg  [19:0]                 cnt_12M   ;
reg                         ce        /*synthesis PAP_MARK_DEBUG="1"*/; 
    always @(posedge clk_12M)
    begin
    	if(!locked|!rst_n)
    	    cnt_12M <= 20'h0;
    	else
    	begin
    		if(cnt_12M == 20'h10000)
    		    cnt_12M <= cnt_12M;
    		else
    		    cnt_12M <= cnt_12M + 1'b1;
    	end
    end

    always @(posedge clk_12M)
    begin
    	if(!locked|!rst_n)
    	    ce <= 1'h0;
    	else
    	begin
    		if((cnt_12M <= 20'h1)|(cnt_12M == 20'h10000))
    		    ce <= 1'h1;
    		else
    		    ce <= 1'h0;
    	end
    end



assign es1_mclk    =    clk_12M;
assign clk_test    =    clk_12M;
reg  [19:0]                 rstn_1ms            ;
    always @(posedge clk_12M)
    begin
    	if(!locked|!rst_n)
    	    rstn_1ms <= 20'h0;
    	else
    	begin
    		if(rstn_1ms == 20'h50000)
    		    rstn_1ms <= rstn_1ms;
    		else
    		    rstn_1ms <= rstn_1ms + 1'b1;
    	end
    end
    
    assign rstn_out = (rstn_1ms == 20'h50000);

ES7243E_reg_config	ES7243E_reg_config(
    	.clk_12M                 (clk_12M           ),//input
    	.rstn                    (rstn_out          ),//input	
    	.i2c_sclk                (es7243_scl        ),//output
    	.i2c_sdat                (es7243_sda        ),//inout
    	.reg_conf_done           (es7243_init       ),//output config_finished
        .clock_i2c               (clock_i2c)
    );
ES8156_reg_config	ES8156_reg_config(
    	.clk_12M                 (clk_12M           ),//input
    	.rstn                    (rstn_out            ),//input	
    	.i2c_sclk                (es8156_scl        ),//output
    	.i2c_sdat                (es8156_sda        ),//inout
    	.reg_conf_done           (es8156_init       )//output config_finished
    );

assign adc_dac_init = es7243_init&&es8156_init;

wire [15:0]rx_data/*synthesis PAP_MARK_DEBUG="1"*/;
wire       rx_l_vld/*synthesis PAP_MARK_DEBUG="1"*/;
wire       rx_r_vld/*synthesis PAP_MARK_DEBUG="1"*/;

wire [15:0]ldata;
wire [15:0]rdata;


// ES7243E ADC
pgr_i2s_rx#(
    .DATA_WIDTH(16)
)ES7243_i2s_rx(
    .rst_n          (es7243_init      ),// input

    .sck            (es0_dsclk        ),// input
    .ws             (es0_alrck        ),// input
    .sda            (es0_sdin         ),// input

    .data           (rx_data          ),// output[15:0]
    .l_vld          (rx_l_vld         ),// output
    .r_vld          (rx_r_vld         ) // output
);


// ES8156 DAC
pgr_i2s_tx#(
    .DATA_WIDTH(16)
)ES8156_i2s_tx(
    .rst_n          (es8156_init    ),// input

    .sck            (es1_dsclk      ),// input  //SCLK  i2s数据位时钟  
    .ws             (es1_dlrc       ),// input  //LRCK  i2s数据左右信道帧时钟 
    .sda            (es1_sdout      ),// output //SDIN  DAC i2s数据输出

    .ldata          (voice_data_out ),// input[15:0]
    .l_req          (          ),// output
    .rdata          (voice_data_out ),// input[15:0]
    .r_req          (          ) // output
);


//I2S LOOP
i2s_loop#(
    .DATA_WIDTH(16)
)i2s_loop(
    .rst_n          (adc_dac_init),// input
    .sck            (es0_dsclk  ),// input
    .ldata          (ldata      ),// output[15:0]
    .rdata          (rdata      ),// output[15:0]
    .data           (rx_data    ),// input[15:0]
    .r_vld          (rx_r_vld   ),// input
    .l_vld          (rx_l_vld   ) // input
);


// 以太网
reg         udp_rec_data_rd_en;
ethernet_global ethernet_global_inst(
    .sys_clk                    (sys_clk            ),  
    .key                        (1'b1),
    .rst_n                      (rstn_out),

    .udp_rec_data_clk           (es1_dlrc          ),
    .udp_rec_data_rd_en         (udp_rec_data_rd_en),
    .udp_rec_data               (voice_data_out),
    .udp_rec_data_ready_out     (udp_rec_data_ready_out),
    .phy_rst_n                  (),
    .e_mdc                      (e_mdc              ),
    .e_mdio                     (e_mdio             ),
    .rgmii_txd                  (rgmii_txd          ),
    .rgmii_txctl                (rgmii_txctl        ),
    .rgmii_txc                  (rgmii_txc          ),
    .rgmii_rxd                  (rgmii_rxd          ),
    .rgmii_rxctl                (rgmii_rxctl        ),
    .rgmii_rxc                  (rgmii_rxc          ),
    .state_led                  (ethernet_led       )
);

always @(*) begin
    if(adc_dac_init == 1'b1) begin
        if(udp_rec_data_ready_out == 1'b1) begin
            udp_rec_data_rd_en = 1'b1;
        end
        else begin
            udp_rec_data_rd_en = udp_rec_data_rd_en;
        end
    end
    else begin
        udp_rec_data_rd_en = 1'b0;
    end
end


endmodule
