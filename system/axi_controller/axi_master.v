//
// д���裺
/*  1. ����д�׵�ַ��
    2. ����д valid �źţ��ȴ����� ready �źţ�
    3. awvalid && awready �׵�ַ��Ч��
    4. ����д��������
    5. ���һλ��������д last �źţ�
    6. ��֤�ɹ�д�룬slave ���� bvalid �ȴ� master ��Ӧ bready��ͬʱ��Чʱ slave ���� bresp == 2'b00��
    7. ע��ͻ�����ȣ�ѡȡ���ʵ���һ��д�׵�ַ��
*/
// �����裺
/*  1. ���ɶ��׵�ַ��
    2. arvalid && arready �׵�ַ��Ч��
    3. �ӻ����������������һλ���� master �� last �źţ�
*/
// AXI Master Interface

module axi_master#(
    parameter M_SLAVE_BASE_ADDR = 32'h40_000_000,
    parameter M_AXI_BURST_LEN = 6'd16,
    parameter M_AXI_ID_WIDTH = 6'd1,
    parameter M_AXI_ADDR_WIDTH = 6'd32,
    parameter M_AXI_DATA_WIDTH = 6'd32,
    parameter M_AXI_AWUSER_WIDTH = 6'd0,
    parameter M_AXI_ARUSER_WIDTH = 6'd0,
    parameter M_AXI_WUSER_WIDTH = 6'd0,
    parameter M_AXI_RUSER_WIDTH = 6'd0,
    parameter M_AXI_BUSER_WIDTH = 6'd0
)(
    input                                   m_axi_aclk,
    input                                   m_axi_aresetn,

    input       [M_AXI_DATA_WIDTH-1'b1:0]   data_in,

    // д��ַͨ��
    output      [M_AXI_ID_WIDTH-1'b1:0]     m_axi_awid,     // д��ַ ID
    output      [M_AXI_ADDR_WIDTH-1'b1:0]   m_axi_awaddr,   // д��ַ
    output      [7:0]                       m_axi_awlen,    // ͻ��д����
    output      [2:0]                       m_axi_awsize,   // ͻ��д���Ȳ�������
    output      [1:0]                       m_axi_awburst,  // ͻ������
    output                                  m_axi_awlock,   // ������
    output      [3:0]                       m_axi_awcache,  // ��������
    output      [2:0]                       m_axi_awprot,   // ��������
    output      [3:0]                       m_axi_awqos,    // д QOS ��־��
    output      [M_AXI_AWUSER_WIDTH-1'b1:0] m_axi_awuser,   
    output                                  m_axi_awvalid,  // д��ַ��Ч
    input                                   m_axi_awready,  // д��ַ׼��
    // д����ͨ��
    output      [M_AXI_DATA_WIDTH-1'b1:0]   m_axi_wdata,
    output      [M_AXI_DATA_WIDTH/8-1'b1:0] m_axi_wstrb,    // дѡͨ
    output                                  m_axi_wlast,
    output      [M_AXI_WUSER_WIDTH-1'b1:0]  m_axi_wuser,
    output                                  m_axi_wvalid,
    input                                   m_axi_wready,
    // д��Ӧͨ��
    input       [M_AXI_ID_WIDTH-1'b1:0]     m_axi_bid,      // д��Ӧ ID
    input       [1:0]                       m_axi_bresp,    // д��Ӧ
    input       [M_AXI_BUSER_WIDTH-1'b1:0]  m_axi_buser,
    input                                   m_axi_bvalid,   // д��Ӧ��Ч
    output                                  m_axi_bready,   // д��Ӧ׼��
    // ����ַͨ��
    output      [M_AXI_ID_WIDTH-1'b1:0]     m_axi_arid,
    output      [M_AXI_ADDR_WIDTH-1'b1:0]   m_axi_araddr,
    output      [7:0]                       m_axi_arlen,
    output      [2:0]                       m_axi_arsize,
    output      [1:0]                       m_axi_arburst,
    output                                  m_axi_arlock,
    output      [3:0]                       m_axi_arcache,
    output      [2:0]                       m_axi_arprot,
    output      [3:0]                       m_axi_arqos,
    output      [M_AXI_ARUSER_WIDTH-1'b1:0] m_axi_aruser,
    output                                  m_axi_arvalid,
    output                                  m_axi_arready,
    // ������ͨ��
    input       [M_AXI_ID_WIDTH-1'b1:0]     m_axi_rid,
    input       [M_AXI_DATA_WIDTH-1'b1:0]   m_axi_rdata,
    input       [1:0]                       m_axi_rresp,
    input                                   m_axi_rlast,
    input       [M_AXI_RUSER_WIDTH-1'b1:0]  m_axi_ruser,
    input                                   m_axi_rvalid,
    output                                  m_axi_rready
);

// �����������ݵĶ�����λ������ͻ������ĳߴ�
function integer clogb2(input integer number);
begin
    for(clogb2 = 0; number > 0; clogb2 = clogb2 + 1)
        number = number >> 1;
end
endfunction

wire                            clk;
wire                            rst;

reg [M_AXI_ADDR_WIDTH-1'b1:0]   reg_m_axi_awaddr;
reg                             reg_m_axi_awvalid;
reg [M_AXI_DATA_WIDTH-1'b1:0]   reg_m_axi_wdata;
reg                             reg_m_axi_wlast;
reg                             reg_m_axi_wvalid;
reg [M_AXI_ADDR_WIDTH-1'b1:0]   reg_m_axi_araddr;
reg                             reg_m_axi_arvalid;
reg                             reg_m_axi_rready;

reg                             write_start;
reg [7:0]                       burst_data_cnt;

assign m_axi_awid = 'b0;
assign m_axi_awaddr = reg_m_axi_awaddr + M_SLAVE_BASE_ADDR;
assign m_axi_awvalid = reg_m_axi_awvalid;
assign m_axi_awlen = M_AXI_BURST_LEN - 1'b1;
assign m_axi_awsize = clogb2((M_AXI_DATA_WIDTH/8) - 1'b1);  // 000:1, 001:2, 010:4, 011:8, 100: 16
assign m_axi_awburst = 2'b01;                               // 00:�̶�ģʽ, 01:����ģʽ
assign m_axi_awlock = 1'b0;
assign m_axi_awcache = 4'b0010;                             // 0010:�޻����� buffer
assign m_axi_awprot = 3'b0;                                 // 000:����Ȩ����
assign m_axi_awqos = 4'b0;
assign m_axi_awuser = 'b0;

assign m_axi_wdata = reg_m_axi_wdata;
assign m_axi_wstrb = {(M_AXI_DATA_WIDTH/8){1'b1}};
assign m_axi_wlast = reg_m_axi_wlast;
assign m_axi_wuser = 'b0;
assign m_axi_wvalid = reg_m_axi_wvalid;

assign m_axi_bready = 1'b1;

assign m_axi_arid = 'b0;
assign m_axi_araddr = reg_m_axi_araddr + M_SLAVE_BASE_ADDR;
assign m_axi_arlen = M_AXI_BURST_LEN - 1'b1;
assign m_axi_arsize = clogb2((M_AXI_DATA_WIDTH/8) - 1'b1);
assign m_axi_arburst = 2'b01;
assign m_axi_arlock = 1'b0;
assign m_axi_arcache = 4'b0010;
assign m_axi_arprot = 3'b0;
assign m_axi_arqos = 4'b0;
assign m_axi_aruser = 'b0;
assign m_axi_arvalid = reg_m_axi_arvalid;

assign m_axi_rready = reg_m_axi_rready;

assign clk = m_axi_aclk;
assign rst = m_axi_aresetn;


// д��ַ��Ч�ź�
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        reg_m_axi_awvalid <= 'b0;
    end
    else if(write_start) begin              // �ڴ˱�־�źź�ʼд����
        reg_m_axi_awvalid <= 1'b1;
    end
    else if((m_axi_awvalid == 1'b1) && (m_axi_awready == 1'b1)) begin
        reg_m_axi_awvalid <= 1'b0;
    end
    else begin
        reg_m_axi_awvalid <= reg_m_axi_awvalid;
    end
end


// д�׵�ַ���˴�����Ϊ 1
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        reg_m_axi_awaddr <= 'b0;
    end
    else if(write_start) begin
        reg_m_axi_awaddr <= 'd1;
    end
    else begin
        reg_m_axi_awaddr <= 'd0;
    end
end


// д��Ч�źţ�ֻҪ�ܱ�֤ awvalid �� awready ͬʱΪ��ʱ���ź��Ѿ�Ϊ�߼���
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        reg_m_axi_wvalid <= 'b0;
    end
    else if(write_start) begin      // ѡ���� awvalid ͬʱ����
        reg_m_axi_wvalid <= 1'b1;
    end
    else if(m_axi_wlast) begin
        reg_m_axi_wvalid <= 1'b0;
    end
    else begin
        reg_m_axi_wvalid <= reg_m_axi_wvalid;
    end
end


// д�����ź�
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        reg_m_axi_wdata <= 'b0;
    end
    else if((m_axi_awvalid == 1'b1) && (m_axi_awready == 1'b1)) begin
        reg_m_axi_wdata <= data_in;
    end
    else if(m_axi_wlast) begin
        reg_m_axi_wdata <= 'b0;
    end
    else begin
        reg_m_axi_wdata <= reg_m_axi_wdata;
    end
end


// д���ݼ���
// ֻ������ͻ�����ȴ��� 2 �����
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        burst_data_cnt <= 8'b0;
    end
    else if((m_axi_wready == 1'b1) && (m_axi_wvalid == 1'b1)) begin
        burst_data_cnt <= burst_data_cnt + 1'b1;
    end
    else if(burst_data_cnt == M_AXI_BURST_LEN - 1'b1) begin
        burst_data_cnt <= 8'b0;
    end
end

// д���һ�����ݱ�־
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        reg_m_axi_wlast <= 'b0;
    end
    else if(burst_data_cnt == M_AXI_BURST_LEN - 2'd2) begin
        reg_m_axi_wlast <= 1'b1;
    end
    else begin
        reg_m_axi_wlast <= 1'b0;
    end
end


// д��Ӧ׼��


// ����ַ��Ч�ź�


endmodule