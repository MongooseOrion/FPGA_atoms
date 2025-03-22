module dma_ctrl #(
    parameter CMD_REG_ADDR1 = 12'h100,
    parameter CMD_REG_ADDR2 = 12'h120,
    parameter CMD_REG_ADDR3 = 12'h140 

)(
    input wire                pcie_clk                ,
    input wire                pix_clk            ,
    input wire                rstn               ,
    input wire                axis_master_tvalid /* synthesis PAP_MARK_DEBUG="1" */,    
    output wire               axis_master_tready /* synthesis PAP_MARK_DEBUG="1" */,    
    input wire    [127:0]     axis_master_tdata  /* synthesis PAP_MARK_DEBUG="1" */,    
    input wire    [3:0]       axis_master_tkeep  /* synthesis PAP_MARK_DEBUG="1" */,    
    input wire                axis_master_tlast  /* synthesis PAP_MARK_DEBUG="1" */,    
    input wire    [7:0]       axis_master_tuser  /* synthesis PAP_MARK_DEBUG="1" */,     
    
    input         [7 : 0]     ep_bus_num         , //bdf��Ϣ
    input         [4 : 0]     ep_dev_num         ,

    input                     axis_slave_tready   /* synthesis PAP_MARK_DEBUG="1" */,
    output reg                axis_slave_tvalid   /* synthesis PAP_MARK_DEBUG="1" */,
    output reg    [127:0]     axis_slave_tdata   /* synthesis PAP_MARK_DEBUG="1" */ ,
    output reg                axis_slave_tlast    /* synthesis PAP_MARK_DEBUG="1" */,
    output reg                axis_slave_tuser    /* synthesis PAP_MARK_DEBUG="1" */,
//HDMI IN
    input         [15: 0]     hdmi_data_in        /* synthesis PAP_MARK_DEBUG="1" */ , //rgb565��ʽ
    input                     vs_in                /* synthesis PAP_MARK_DEBUG="1" */,
    input                     de_in            /* synthesis PAP_MARK_DEBUG="1" */   
      
   );

parameter TLP_LENGTH = 10'd32;  //1280*720*2*8/32 = 460800dw,460800/32 = 14400,һ֡ͼ��Ҫdmaд14400��
parameter ADDR_STEP = TLP_LENGTH*4;  
parameter DTAT_CNT_MAX = TLP_LENGTH*4*8/128;  //��fifo�ж�ȡ�����ݸ���
parameter IDLE = 5'b00001;
parameter WAIT = 5'b00010;
parameter ADDR = 5'b00100;
parameter TLP_MWR_HEADER = 5'b01000;
parameter TLP_MWR_DATA = 5'b10000;
reg [4:0] state/* synthesis PAP_MARK_DEBUG="1" */;

reg vs_in_d0;
reg vs_in_d1;
reg vs_in_d2;
reg axis_master_tvalid_d0;
reg [11:0] cmd_reg_addr;
reg [9:0] tlp_lenght_rc;
reg [31:0] dma_addr0/* synthesis PAP_MARK_DEBUG="1" */;
reg [31:0] dma_addr1/* synthesis PAP_MARK_DEBUG="1" */;
reg [31:0] dma_addr2/* synthesis PAP_MARK_DEBUG="1" */;
reg [31:0] dma_addr_high/* synthesis PAP_MARK_DEBUG="1" */;
reg        dma_addr_valid/* synthesis PAP_MARK_DEBUG="1" */;
wire       almost_empty;
wire       almost_full/* synthesis PAP_MARK_DEBUG="1" */;
reg        almost_full_d0;
wire [127:0] rd_data;
reg        rd_en;
reg [2:0]  tlp_fmt  ;
reg [4:0]  tlp_type ;
reg        write_addr3_flag_d0;
wire       axis_slave_tvalid1;
reg        write_buf_flag/* synthesis PAP_MARK_DEBUG="1" */; //д����Ƭbuf����־
reg        write_addr3_flag/* synthesis PAP_MARK_DEBUG="1" */; //д�����Ƭbuf����־
reg [3:0]  write_data_cnt; //����TLP_MWR_DATA״̬ʱ������
reg [4:0]  rd_en_cnt; //��fifo�ж�ȡ���ݼ���
reg [31:0] dma_addr/* synthesis PAP_MARK_DEBUG="1" */; //ʵ��д��dma��ַ
assign     axis_master_tready = 1'b1;
assign     axis_slave_tvalid1 = ((state == TLP_MWR_HEADER) || (state == TLP_MWR_DATA)) ? 1'b1 : 1'b0;
//���ģ���ʱ�������ź�
always @(posedge pcie_clk or negedge rstn) begin
    if(!rstn) begin
        axis_master_tvalid_d0 <= 'd0;
        vs_in_d0 <= 'd0;
        vs_in_d1 <= 'd0;
        vs_in_d2 <= 'd0;
        almost_full_d0 <= 'd0;
        write_addr3_flag_d0 <= 'd0;
        axis_slave_tvalid <= 'd0;
    end
    else begin
        axis_master_tvalid_d0 <= axis_master_tvalid;
        vs_in_d0 <= vs_in;
        vs_in_d1 <= vs_in_d0;
        vs_in_d2 <= vs_in_d1;
        almost_full_d0 <= almost_full;
        write_addr3_flag_d0 <= write_addr3_flag;
        axis_slave_tvalid <= axis_slave_tvalid1;
    end
end
//�����������ݷ�����ʽ
always @(posedge pcie_clk or negedge rstn) begin
    if(!rstn) begin
        tlp_fmt  <= 'd0;
        tlp_type <= 'd0;
        cmd_reg_addr <= 'd0;
        tlp_lenght_rc <= 'd0;
    end
    else if(axis_master_tvalid & (~axis_master_tvalid_d0))begin //��ȡtlp����hedder��Ϣ
        tlp_fmt  <= axis_master_tdata[31:29];          
        tlp_type <= axis_master_tdata[28:24];
        cmd_reg_addr <= axis_master_tdata[75:64];//cmdƫ�Ƶ�ַ
        tlp_lenght_rc <= axis_master_tdata[9:0];//TLP���ݰ�����
    end
    else begin
        tlp_fmt  <= 'd0;
        tlp_type <= 'd0;
        cmd_reg_addr <= 'd0;
        tlp_lenght_rc <= 'd0;
    end
end

always @(posedge pcie_clk or negedge rstn) begin//����rc���͵�tlp������ȡdma��ַ
    if(!rstn) begin
        dma_addr0         <= 'd0;
        dma_addr1         <= 'd0;
        dma_addr2         <= 'd0;
        dma_addr_high     <= 'd0;
    end
    else if(({tlp_fmt,tlp_type} == 8'h40 )&& (tlp_lenght_rc == 1) && (cmd_reg_addr == CMD_REG_ADDR1)) begin  
        dma_addr0 <= {axis_master_tdata[7:0],axis_master_tdata[15:8],axis_master_tdata[23:16],axis_master_tdata[31:24]};  //��λ�Ǹ��ֽ�
    end
    else if(({tlp_fmt,tlp_type} == 8'h40 )&& (tlp_lenght_rc == 1) && (cmd_reg_addr == CMD_REG_ADDR2)) begin  
        dma_addr1 <= {axis_master_tdata[7:0],axis_master_tdata[15:8],axis_master_tdata[23:16],axis_master_tdata[31:24]};  //��λ�Ǹ��ֽ�
    end
    else if(({tlp_fmt,tlp_type} == 8'h40 )&& (tlp_lenght_rc == 1) && (cmd_reg_addr == CMD_REG_ADDR3)) begin  
        dma_addr2 <= {axis_master_tdata[7:0],axis_master_tdata[15:8],axis_master_tdata[23:16],axis_master_tdata[31:24]};  //��λ�Ǹ��ֽ�
    end
    else if(({tlp_fmt,tlp_type} == 8'h40 )&& (tlp_lenght_rc == 1) && (cmd_reg_addr == 12'h160)) begin  
        dma_addr_high <= {axis_master_tdata[7:0],axis_master_tdata[15:8],axis_master_tdata[23:16],axis_master_tdata[31:24]};  //��λ�Ǹ��ֽ�
    end
    else begin
        dma_addr0 <= dma_addr0;
        dma_addr1 <= dma_addr1;
        dma_addr2 <= dma_addr2;
        dma_addr_high <= dma_addr_high;
    end

end

always @(posedge pcie_clk or negedge rstn) begin  //��ʾ��ַ�Ѿ�ȫ���������
    if(!rstn) begin
        dma_addr_valid <= 'd0;
    end
    else if( (dma_addr0 != 'd0 )&& (dma_addr1 != 'd0) && (dma_addr2 != 'd0) && (vs_in_d2 == 1'b1) ) begin  
        dma_addr_valid <= 'd1;
    end
    else begin
        dma_addr_valid <= dma_addr_valid;
    end
    
end


//write_data_cnt����
always @(posedge pcie_clk or negedge rstn) begin
    if(!rstn) begin
        write_data_cnt <= 'd0;
    end
    else if(state == TLP_MWR_DATA) begin
        write_data_cnt <= write_data_cnt + 1;
    end
    else begin
        write_data_cnt <= 'd0;
    end
end

//rd_en_cnt����
always @(posedge pcie_clk or negedge rstn) begin
    if(!rstn) begin
        rd_en_cnt <= 'd0;
    end
    else if(rd_en == 1'b1) begin
        rd_en_cnt <= rd_en_cnt + 1;
    end
    else begin
        rd_en_cnt <= 'd0;
    end
end
//TLP���ķ���,ѭ����addr0,addr1д�����ݣ�tlp���ݰ�����Ϊ32dw.    ÿ֡ͼ��д��ǰ����addr2д�����ݣ�tlp���ݰ�����Ϊ1dw
//״̬����ת
always @(posedge pcie_clk or negedge rstn) begin
    if (!rstn) begin
        state <= IDLE;
        write_buf_flag <= 'd1;
        write_addr3_flag <= 'd0;
    end
    else begin
        case(state)
            IDLE: begin
                write_addr3_flag <= 'd0;
                if(dma_addr_valid) begin
                    state <= WAIT;
                end
                else begin
                    state <= IDLE;
                end
            end
            WAIT: begin
                //���ź��½��أ�write_buf_flag��ת
                if(vs_in_d2 == 1'b1 && vs_in_d1 == 1'b0 && axis_slave_tready == 1'b1) begin
                    write_buf_flag <= ~write_buf_flag;
                    write_addr3_flag <= 'd1;
                    state <= ADDR;
                end
                else if(almost_full_d0 & axis_slave_tready) begin
                    state <= ADDR;
                    write_addr3_flag <= 'd0;
                end
                else begin
                    state <= WAIT;
                end
            end
            ADDR: begin
                state <= TLP_MWR_HEADER;
            end
            TLP_MWR_HEADER: begin
                state <= TLP_MWR_DATA;
            end
            TLP_MWR_DATA: begin
                if(write_addr3_flag == 1'b1) begin
                    state <= WAIT;
                end
                else if(write_data_cnt == DTAT_CNT_MAX - 1'b1) begin
                    state <= WAIT;
                end
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end
end

//״̬���źű仯
always @(posedge pcie_clk or negedge rstn) begin
    if(!rstn) begin  
        axis_slave_tdata <= 'd0;
        axis_slave_tlast <= 'd0;
        axis_slave_tuser <= 'd0;
        rd_en <= 'd0;
    end
    else begin
        case(state)
            IDLE: begin
                axis_slave_tdata <= 'd0;
                axis_slave_tlast <= 'd0;
                rd_en <= 'd0;
            end
            WAIT: begin
                axis_slave_tdata <= 'd0;
                axis_slave_tlast <= 'd0;
                rd_en <= 'd0;
            end
            ADDR: begin
                if (write_addr3_flag == 1'b1) begin
                    dma_addr <= dma_addr2; //д��ڱ�־buf��
                end
                else if (write_addr3_flag == 1'b0 && write_addr3_flag_d0 == 1'b1) begin  //write_buf_flag�½��أ��л�buf��
                    if(write_buf_flag == 1'b0) begin
                        dma_addr <= dma_addr0;
                    end
                    else begin
                        dma_addr <= dma_addr1;
                    end
                end
                else begin
                    dma_addr <= dma_addr + ADDR_STEP;
                end
                rd_en <= 'd1; //���TLP_MWR_DATA��ǰ����ʱ���������߶�ʹ��,��Ӱ��dma_addr3����Ϊ��ʱfifoΪ�գ�����Ӱ����������
            end

            TLP_MWR_HEADER: begin
                axis_slave_tlast  <= 'd0;
                if(write_addr3_flag == 1'b1) begin
                    axis_slave_tdata[9:0]  <= 'd1;
                end
                else begin
                    axis_slave_tdata[9:0]  <= TLP_LENGTH;
                end
                axis_slave_tdata[11 :10]   <= 'h0;        //AT
                axis_slave_tdata[13 :12]   <= 'h0;        //Attr
                axis_slave_tdata[14]       <= 'h0;        //EP
                axis_slave_tdata[15]       <= 'h0;        //TD
                axis_slave_tdata[16]       <= 'h0;        //TH
                axis_slave_tdata[17]       <= 'h0;        //����
                axis_slave_tdata[18]       <= 'h0;        //Attr2
                axis_slave_tdata[19]       <= 'h0;        //����
                axis_slave_tdata[22 : 20]  <= 'h0;        //TC
                axis_slave_tdata[23]       <= 'h0;        //����
                axis_slave_tdata[28 : 24]  <= 'h0;        //Type
                axis_slave_tdata[31 : 29]  <= 3'b011;     //Fmt 3DW Mwr                           
                axis_slave_tdata[35 : 32]  <= 4'hf;    //ȫ����Ч����������
                axis_slave_tdata[39 : 36]  <= 4'hf;    //ȫ����Ч����������
                axis_slave_tdata[47 : 40]  <= 8'h01;        //Tag
                axis_slave_tdata[63 : 48]  <= {ep_bus_num,ep_dev_num,3'b0};  //Requester ID [63:56] Bus Num [55:51] Device Num [50:48] Function Num 
                axis_slave_tdata[95 : 64]  <= dma_addr_high;//r_dma_addr;     //3dw�ĵ�ַ             
                axis_slave_tdata[127: 96]  <= dma_addr;   //64λ�ĵ�30λ��ַ������λ������
            end
            TLP_MWR_DATA: begin
                if(rd_en_cnt == DTAT_CNT_MAX - 1'b1) begin
                    rd_en <= 'd0 ;
                end

                if(write_addr3_flag == 1'b1) begin
                    axis_slave_tlast <= 'd1;
                end
                else if(write_data_cnt == DTAT_CNT_MAX - 1'b1) begin
                    axis_slave_tlast <= 'd1;
                end
                else begin
                    axis_slave_tlast <= 'd0;
                end

                if(write_addr3_flag == 1'b1) begin
                    axis_slave_tdata[127:0] <= {128{write_buf_flag}}; //д�����Ƭbuf��,д���־λ
                end
                else begin
                    axis_slave_tdata[127:0] <= {rd_data[103: 96],rd_data[111:104],rd_data[119:112],rd_data[127:120],rd_data[71 : 64],rd_data[79 : 72],rd_data[87 : 80],rd_data[95 : 88],rd_data[39 : 32],rd_data[47 : 40],rd_data[55 : 48],rd_data[63 : 56],rd_data[7  :  0],rd_data[15 :  8],rd_data[23 : 16],rd_data[31 : 24] }; 
                end
            end
            default: begin
                axis_slave_tdata <= 'd0;
                axis_slave_tlast <= 'd0;
                rd_en <= 'd0;
            end
        endcase
    end
end

i_16_128_o_128_16 the_instance_name (
  .wr_clk(pix_clk),                // input
  .wr_rst(!rstn | vs_in),                // input
  .wr_en(de_in),                  // input
  .wr_data(hdmi_data_in),              // input [15:0]
  .wr_full(),                     // output
  .almost_full(almost_full),      // output
  .rd_clk(pcie_clk),                // input
  .rd_rst(~dma_addr_valid),                // input
  .rd_en(rd_en),                  // input
  .rd_data(rd_data),              // output [127:0]
  .rd_empty(rd_empty),            // output
  .almost_empty(almost_empty)     // output
);

endmodule