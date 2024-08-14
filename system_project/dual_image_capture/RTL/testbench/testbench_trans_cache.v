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
// trans_cache 文件测试平台代码
//
`timescale 1ns/1ps
module testbench_trans_cache();

parameter CLK_PERIOD = 10;
parameter PCLK_1 = 12;
parameter PCLK_2 = 12;

reg         clk         ;
reg         rst         ;
reg         flag_1      ;
reg         flag_2      ;

reg         cmos1_rst   ;
reg         cmos2_rst   ;
reg         cmos1_pclk  ;
reg         cmos1_vs_in ;
reg         cmos1_de_in ;
reg [7:0]   cmos1_data  ;
reg         cmos2_pclk  ;
reg         cmos2_vs_in ;
reg         cmos2_de_in ;
reg [7:0]   cmos2_data  ;
reg         vsync_regenrate;
reg         href_regenerate;

wire [27:0] axi_awaddr     ;
wire [3:0]       axi_awid       ;
wire [3:0]       axi_awlen      ;
wire [2:0]       axi_awsize     ;
wire [1:0]       axi_awburst    ;
reg        axi_awready    ;
wire        axi_awvalid    ;
wire [255:0]  axi_wdata      ;
wire [31:0]  axi_wstrb      ;
reg        axi_wlast      ;
wire        axi_wvalid     ;
reg        axi_wready     ;
wire [3:0]   axi_bid        ;
wire [27:0]   axi_araddr     ;
wire [3:0]      axi_arid       ;
wire [3:0]      axi_arlen      ;
wire [2:0]      axi_arsize     ;
wire [1:0]      axi_arburst    ;
wire        axi_arvalid    ;
reg        axi_arready    ;
reg       axi_rready     ;
reg  [255:0]  axi_rdata      ;
wire        axi_rvalid     ;
reg        axi_rlast      ;
wire [3:0]   axi_rid        ;

wire         cmos_data_out;
wire         init_done;

always #(CLK_PERIOD/2) clk = ~clk;

always @(*) begin
    if(flag_1 == 1'b1) begin
        #(PCLK_1/2);
        cmos1_pclk <= ~cmos1_pclk;
    end
    else begin
        cmos1_pclk <= 1'b0;
    end
end

always @(*) begin
    if(flag_2 == 1'b1) begin
        #(PCLK_2/2);
        cmos2_pclk <= ~cmos2_pclk;
    end
    else begin
        cmos2_pclk <= 1'b0;
    end
end

trans_cache test_trans_cache(
    .clk                            (clk),
    .cmos1_rst                      (cmos1_rst),
    .cmos2_rst                      (cmos2_rst),
    .rst                            (rst),

    .cmos1_pclk                     (cmos1_pclk         ),
    .cmos1_data                     (cmos1_data         ),
    .cmos1_vs_in                    (cmos1_vs_in        ),
    .cmos1_de_in                    (cmos1_de_in        ),
    .cmos2_pclk                     (cmos2_pclk         ),
    .cmos2_data                     (cmos2_data         ),
    .cmos2_vs_in                    (cmos2_vs_in        ),
    .cmos2_de_in                    (cmos2_de_in        ),
    
    .vsync_in                       (vsync_regenerate   ),
    .href_in                        (href_regenerate    ),
    .cmos_data_out                  (cmos_data_out      ),

    .init_done                      (init_done          ),        
     
    .axi_awaddr             (axi_awaddr     ),
    .axi_awid               (axi_awuser_id  ),
    .axi_awlen              (axi_awlen      ),
    .axi_awsize             (     ),
    .axi_awburst            (    ),
    .axi_awready            (axi_awready    ),
    .axi_awvalid            (axi_awvalid    ),
    .axi_wdata              (axi_wdata      ),
    .axi_wstrb              (axi_wstrb      ),
    .axi_wlast              (axi_wlast),
    .axi_wvalid             (     ),
    .axi_wready             (axi_wready     ),
    .axi_bid                (axi_bid        ),
    .axi_araddr             (axi_araddr     ),
    .axi_arid               (axi_aruser_id  ),
    .axi_arlen              (axi_arlen      ),
    .axi_arsize             (     ),
    .axi_arburst            (    ),
    .axi_arvalid            (axi_arvalid    ),
    .axi_arready            (axi_arready    ),
    .axi_rready             (     ),
    .axi_rdata              (axi_rdata      ),
    .axi_rvalid             (axi_rvalid     ),
    .axi_rlast              (axi_rlast      ),
    .axi_rid                (axi_rid        )
);

initial begin
    clk <= 'b0;
    rst <= 'b0;
    cmos1_rst <= 'b0;
    cmos2_rst <= 'b0;
    axi_awready <= 'b0;
    axi_wready <= 'b0;
    axi_wlast <= 'b0;
    axi_arready <= 'b0;
    axi_rready <= 'b0;
    axi_rlast <= 'b0;
    axi_rdata <= 'b0;
    cmos1_pclk <= 'b0;
    cmos2_pclk <= 'b0;
    #500;
    rst <= 1'b1;
    #100;
    cmos1_rst <= 1'b1;
    cmos2_rst <= 1'b1;
    flag_1 <= 1'b1;
    #5;
    flag_2 <= 1'b1;
end

integer k;
initial begin
    cmos1_de_in <= 1'b0;
    cmos1_vs_in <= 1'b0;
    @(posedge rst);

    repeat(50) begin
        @(posedge cmos1_pclk);
        cmos1_vs_in <= 1'b1;
        #100;
        cmos1_vs_in <= 1'b0;
        #200;
        for(k=0;k<540;k=k+1) begin
            cmos1_de_in <= 1'b1;
            #1000;
            cmos1_de_in <= 1'b0;
            #100;
        end
        #100;
    end
end

integer h;
initial begin
    cmos2_de_in <= 1'b0;
    cmos2_vs_in <= 1'b0;
    @(posedge rst);

    repeat(50) begin
        @(posedge cmos2_pclk);
        cmos2_vs_in <= 1'b1;
        #100;
        cmos2_vs_in <= 1'b0;
        #200;
        for(h=0;h<540;h=h+1) begin
            cmos2_de_in <= 1'b1;
            #1000;
            cmos2_de_in <= 1'b0;
            #100;
        end
        #100;
    end
end

integer a;
initial begin
    vsync_regenrate <= 1'b0;
    href_regenerate <= 1'b0;
    @(posedge init_done);

    repeat(50) begin
        @(posedge cmos1_pclk);
        vsync_regenrate <= 1'b1;
        #100;
        vsync_regenrate <= 1'b0;
        #200;
        for(h=0;h<540;h=h+1) begin
            href_regenerate <= 1'b1;
            #1000;
            href_regenerate <= 1'b0;
            #100;
        end
        #100;
    end
end


integer i;
initial begin
    cmos1_data <= 8'b0;
    @(posedge cmos1_de_in);
    cmos1_data <= 8'b1000_1000;
    for(i=0;i<1280*720/4;i=i+1) begin
        if(cmos1_de_in == 1'b1) begin
            @(posedge cmos1_pclk);
            cmos1_data <= cmos1_data + 1'b1;
        end
    end
end

integer j;
initial begin
    cmos2_data <= 8'b0;
    @(posedge cmos2_de_in);
    cmos2_data <= 8'b1000_1000;
    for(j=0;j<1280*720/4;j=j+1) begin
        if(cmos2_de_in == 1'b1) begin
            @(posedge cmos2_pclk);
            cmos2_data <= cmos2_data + 1'b1;
        end
    end
end


integer m;
initial begin
    @(posedge rst);
    for(m=0;m<500;m=m+1) begin
        @(posedge axi_awvalid);
        #40;
        @(posedge clk);
        axi_awready <= 1'b1;
        @(posedge clk);
        axi_awready <= 1'b0;
        #40;
        @(posedge clk);
        axi_wready <= 1'b1;
        #160;
        @(posedge clk);
        axi_wlast <= 1'b1;
        @(posedge clk);
        axi_wlast <= 1'b0;
        axi_wready <= 1'b0;
    end
end

always@(*) begin
    @(posedge rst);
    if(axi_arvalid == 1'b1) begin
        #30;
        axi_arready <= 1'b1;
        #1;
        axi_arready <= 1'b0;
        #30;
        axi_rready <= 1'b1;
        #16;
        axi_rlast <= 1'b1;
        #1;
        axi_rlast <= 1'b0;
        axi_rready <= 1'b0;
    end
end

always @(*) begin
    if(axi_rready == 1'b1) begin
        axi_rdata <= 256'd230;
    end
end

GTP_GRS GRS_INST(
.GRS_N (grs_n)
);

endmodule