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
    output  wire    [1:0]       txp             

);

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

wire    [7:0]   cfg_pbus_num            ;
wire    [4:0]   cfg_pbus_dev_num        ;
wire            axis_slave0_tready/* synthesis PAP_MARK_DEBUG="1" */;
wire            axis_slave1_tready/* synthesis PAP_MARK_DEBUG="1" */;


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



dma_ctrl dma_ctrl_inst (
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
    .vs_in             (vs_in),
    .de_in             (de_in)
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
  .axis_slave0_tvalid('d0),                  // input
  .axis_slave0_tdata ('d0),                    // input [127:0]
  .axis_slave0_tlast ('d0),                    // input
  .axis_slave0_tuser ('d0),                    // input

  .axis_slave2_tready(axis_slave1_tready),                  // output
  .axis_slave2_tvalid('d0),                  // input
  .axis_slave2_tdata ('d0),                    // input [127:0]
  .axis_slave2_tlast ('d0),                    // input
  .axis_slave2_tuser ('d0),                    // input

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

endmodule
