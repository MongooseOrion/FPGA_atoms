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
    // д��ַͨ��
    output      [M_AXI_ID_WIDTH-1'b1:0]     m_axi_awid,
    output      [M_AXI_ADDR_WIDTH-1'b1:0]   m_axi_awaddr,
    output      [7:0]                       m_axi_awlen,
    output      [2:0]                       m_axi_awsize,
    output      [1:0]                       m_axi_awburst,
    output                                  m_axi_awlock,
    output      [3:0]                       m_axi_awcache,
    output      [2:0]                       m_axi_awprot,
    output      [3:0]                       m_axi_awqos,
    output      [M_AXI_AWUSER_WIDTH-1'b1:0] m_axi_awuser,
    output                                  m_axi_awvalid,
    input                                   m_axi_awready,
    // д����ͨ��
    output      [M_AXI_DATA_WIDTH-1'b1:0]   m_axi_data,
    output      [M_AXI_DATA_WIDTH/8-1'b1:0] m_axi_wstrb,
    output                                  m_axi_wlast,
    output      [M_AXI_WUSER_WIDTH-1'b1:0]  m_axi_wuser,
    output                                  m_axi_wvalid,
    input                                   m_axi_wready,
    // д��Ӧͨ��
    input       [M_AXI_ID_WIDTH-1'b1:0]     m_axi_bid,
    input       [1:0]                       m_axi_bresp,
    input       [M_AXI_BUSER_WIDTH-1'b1:0]  m_axi_buser,
    input                                   m_axi_bvalid,
    output                                  m_axi_bready,
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

// �����������ݵĶ�����λ��


endmodule