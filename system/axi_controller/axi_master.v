//
// 写步骤：
/*  1. 生成写首地址；
    2. 生成写 valid 信号，等待发回 ready 信号；
    3. awvalid && awready 首地址有效；
    4. 送入写数据流；
    5. 最后一位数据拉高写 last 信号；
    6. 验证成功写入，slave 发送 bvalid 等待 master 回应 bready，同时有效时 slave 发送 bresp == 2'b00；
    7. 注意突发长度，选取合适的下一个写首地址。
*/
// 读步骤：
/*  1. 生成读首地址；
    2. arvalid && arready 首地址有效；
    3. 从机发出数据流，最后一位传入 master 读 last 信号；
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
    // 写地址通道
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
    // 写数据通道
    output      [M_AXI_DATA_WIDTH-1'b1:0]   m_axi_data,
    output      [M_AXI_DATA_WIDTH/8-1'b1:0] m_axi_wstrb,
    output                                  m_axi_wlast,
    output      [M_AXI_WUSER_WIDTH-1'b1:0]  m_axi_wuser,
    output                                  m_axi_wvalid,
    input                                   m_axi_wready,
    // 写响应通道
    input       [M_AXI_ID_WIDTH-1'b1:0]     m_axi_bid,
    input       [1:0]                       m_axi_bresp,
    input       [M_AXI_BUSER_WIDTH-1'b1:0]  m_axi_buser,
    input                                   m_axi_bvalid,
    output                                  m_axi_bready,
    // 读地址通道
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
    // 读数据通道
    input       [M_AXI_ID_WIDTH-1'b1:0]     m_axi_rid,
    input       [M_AXI_DATA_WIDTH-1'b1:0]   m_axi_rdata,
    input       [1:0]                       m_axi_rresp,
    input                                   m_axi_rlast,
    input       [M_AXI_RUSER_WIDTH-1'b1:0]  m_axi_ruser,
    input                                   m_axi_rvalid,
    output                                  m_axi_rready
);

// 计算输入数据的二进制位宽


endmodule