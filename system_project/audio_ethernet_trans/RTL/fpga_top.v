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
// ����
//
module fpga_top(

    input               sys_clk                 ,//50MHz
    input               sys_rst                 ,
    
    //ES7243E  ADC  in
    output              es7243_scl              ,//CCLK
    inout               es7243_sda              ,//CDATA
    output              es0_mclk                ,//MCLK  clk_12M
    input               es0_sdin                ,//SDOUT i2s��������             i2s_sdin
    input               es0_dsclk               ,//SCLK  i2s����ʱ��             i2s_sck   
    input               es0_alrck               ,//LRCK  i2s���������ŵ�֡ʱ��     i2s_ws
    
    //ES8156  DAC   out
    output              es8156_scl              ,//CCLK
    inout               es8156_sda              ,//CDATA 
    output              es1_mclk                ,//MCLK  clk_12M
    input               es1_sdin                ,//SDOUT �ط��źŷ�����
    output              es1_sdout               ,//SDIN  DAC i2s�������          i2s_sdout
    input               es1_dsclk               ,//SCLK  i2s����λʱ��            i2s_sck
    input               es1_dlrc                ,//LRCK  i2s���������ŵ�֡ʱ��      i2s_ws
    
    //  
    input               lin_detect              ,//��˷������
    input               lout_detect             ,//���������
    output              insert_detect_led       ,
    output              codec_init              ,

    // RJ45
    output              e_mdc                   ,//MDIO��ʱ���źţ����ڶ�дPHY�ļĴ���
    inout               e_mdio                  ,//MDIO�������źţ����ڶ�дPHY�ļĴ���  
    output  [3:0]       rgmii_txd               ,//RGMII ��������
    output              rgmii_txctl             ,//RGMII ������Ч�ź�
    output              rgmii_txc               ,//125Mhz ethernet rgmii tx clock
    input   [3:0]       rgmii_rxd               ,//RGMII ��������
    input               rgmii_rxctl             ,//RGMII ����������Ч�ź�
    input               rgmii_rxc               ,//125Mhz ethernet rgmii RX clock
    output              eth_init
);


wire            locked          ;
wire            rstn_out        ;
wire            es7243_init     ;
wire            es8156_init     ;
wire            clk_12M         ;
wire            clk_50M         ;
wire [15:0]     rx_data         ;
wire            rx_l_vld        ;
wire            rx_r_vld        ;
wire [15:0]     ldata_out       ;
wire [15:0]     rdata_out       ;
wire [15:0]     ldata_out1      ;
wire [15:0]     rdata_out1      ;
wire [15:0]     ldata           ;
wire [15:0]     rdata           ;

reg  [19:0]     rstn_1ms        ;
reg             insert_detect   ;

assign es0_mclk = clk_12M;
assign es1_mclk = clk_12M;
assign codec_init = es7243_init && es8156_init;
assign insert_detect_led = insert_detect;


// ����Ƿ������˷����������Ȼ������
always @(posedge clk_50M or negedge sys_rst) begin
    if(!sys_rst) begin
        insert_detect <= 'b0;
    end
    else if((lin_detect == 1'b0) && (lout_detect == 1'b0)) begin
        insert_detect <= 1'b1;
    end
    else begin
        insert_detect <= 1'b0;
    end
end


//
// ʱ��
sys_pll u_sys_pll (
    .clkin1       (sys_clk   ),   // input//50MHz
    .pll_lock     (locked    ),   // output
    .clkout0      (clk_12M   ),    // output//12.288MHz
    .clkout1      (clk_50M   )
);


//
// �����ϵ��ӳٸ�λ�ź�
always @(posedge clk_12M)
begin
    if(!locked|!sys_rst)
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


//
// ��Ƶ�������оƬ i2s �Ĵ�������
ES7243E_reg_config	ES7243E_reg_config(
    .clk_12M                 (clk_12M           ),//input
    .rstn                    (rstn_out          ),//input	
    .i2c_sclk                (es7243_scl        ),//output�����õ�����
    .i2c_sdat                (es7243_sda        ),//inout�����õ�����
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


// 
// ES7243E
pgr_i2s_rx#(
    .DATA_WIDTH(16)
)ES7243_i2s_rx(
    .rst_n          (es7243_init      ),// input

    .sck            (es0_dsclk        ),// input
    .ws             (es0_alrck        ),// input
    .sda            (es0_sdin         ),// input

    .data           (rx_data          ),// output[15:0]  //���յ����������������ݣ��ǻ���һ���
    .l_vld          (rx_l_vld         ),// output
    .r_vld          (rx_r_vld         ) // output
);


//
// ES8156
pgr_i2s_tx#(
    .DATA_WIDTH(16)
)ES8156_i2s_tx(
    .rst_n          (es8156_init    ),// input

    .sck            (es1_dsclk      ),// input  //SCLK  i2s����λʱ��  
    .ws             (es1_dlrc       ),// input  //LRCK  i2s���������ŵ�֡ʱ�� 
    .sda            (es1_sdout      ),// output //SDIN  DAC i2s�������

    .ldata          (ldata          ),// input[15:0]
    .l_req          (          ),// output
    .rdata          (rdata          ),// input[15:0]
    .r_req          (          ) // output
);


//
// ���� ADC ���յ����ݰ� i2s ʱ�����Ϊ������������
i2s_loop#(
    .DATA_WIDTH(16)
)i2s_loop(
    .rst_n          (codec_init),// input
    .sck            (es0_dsclk  ),// input
    .ldata          (ldata      ),// output[15:0]
    .rdata          (rdata      ),// output[15:0]
    .data           (rx_data    ),// input[15:0]   //��������������ʱ���������������ݷ����ldata��rdata
    .r_vld          (rx_r_vld   ),// input
    .l_vld          (rx_l_vld   ) // input
);


//
// ��ƵԪ���� UDP ����
eth_trans u_eth_trans(
    .sys_clk        (clk_50M    ),
    .rst_n          (rstn_out   ),
    .led            (eth_init   ),

    .vin_clk        (es1_dlrc   ),
    .vin_sck        (es1_dsclk  ),
    .vin_ldata      (ldata      ),

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
