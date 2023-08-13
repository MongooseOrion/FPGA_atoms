//
// 接收 UART 数据
//

module uart_recv #(
    parameter UART_BOT = 'd9600
) (
    input               sys_clk,            // 50MHz
    input               sys_rst,
    input               uart_rx,
    output reg [7:0]    recv_data,
    output reg          finish_flag         // 一字节 8bit 数据接收完成信号
);

// 定义每一 bit 的有效接收时长
localparam BIT_CNT_MAX = 'd50_000_000 / UART_BOT ;

reg         rx_reg1 ;
reg         rx_reg2 ;
reg         rx_reg3 ;
reg         rvalid ;
reg         work_en ;
reg [12:0]  bit_cnt ;
reg         bit_flag ;
reg [3:0]   recv_bit_cnt ;
reg [7:0]   rx_data ;
reg         rx_flag ;

// 延迟两个时钟周期，使信号稳定
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        rx_reg1 <= 0;
    end
    else begin
        rx_reg1 <= uart_rx;
    end
end
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        rx_reg2 <= 0;
    end
    else begin
        rx_reg2 <= rx_reg1;
    end
end


// 检测开始传输的下降沿
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        rx_reg3 <= 0;
    end
    else begin
        rx_reg3 <= rx_reg2;
    end
end
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        rvalid <= 0;
    end
    else if((~rx_reg2) && (rx_reg3)) begin
        rvalid <= 1'b1;
    end
    else begin
        rvalid <= 1'b0;
    end
end


// 开始接收信息的使能信号
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        work_en <= 0;
    end
    else if(rvalid) begin
        work_en <= 1'b1;
    end
    else if(bit_flag == 1'b1 && recv_bit_cnt == 4'd8) begin     // 这两个信号均独立计数，确保在每字节传输完成后使能信号可以拉低
        work_en <= 1'b0;
    end
    else begin
        work_en <= work_en;
    end
end


// 每一位有效接收时长计数
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        bit_cnt <= 0;
    end
    else if (work_en == 1'b1) begin
        bit_cnt <= bit_cnt + 1'b1;
    end
    else if ((work_en == 1'b0) || (bit_cnt == BIT_CNT_MAX - 1)) begin
        bit_cnt <= 13'b0;
    end
    else begin
        bit_cnt <= bit_cnt;
    end
end


// 决定接收某一位的标志位，设置为有效时长的中部，以保证数据的准确性
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        bit_flag <= 0;
    end
    else if (bit_cnt == BIT_CNT_MAX/2 - 1) begin
        bit_flag <= 1'b1;
    end
    else begin
        bit_flag <= 1'b0;
    end
end


// 每字节数据 bit 计数（包含起始位和停止位共 10 bit 一字节数据）
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        recv_bit_cnt <= 0;
    end
    else if (bit_flag == 1'b1 && recv_bit_cnt < 'd10) begin
        recv_bit_cnt = recv_bit_cnt + 1'b1;
    end
    else begin
        recv_bit_cnt <= 4'b0;
    end
end


// 每接收一位有效数据，就右移一次，直到一字节数据都接收完成
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        rx_data <= 0;
    end
    // 第 0 个是起始位，第 9 个是结束位，只要 1-8 位是有效数据
    else if ((recv_bit_cnt > 'd0) && (recv_bit_cnt < 'd9) && (bit_flag == 1'b1)) begin
        rx_data <= {rx_reg3, rx_data[7:1]}          // 赋给最高位7，7:1位整体右移为6:0，移 7 次
    end
    else begin
        rx_data <= 8'b0;
    end
end


// 一字节接收完成标志
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        rx_flag <= 0;
    end
    else if (bit_cnt == 'd8 && bit_flag == 1'b1) begin
        rx_flag <= 1'b1;
    end
    else begin
        rx_flag <= 1'b0;
    end
end


// 输出一字节数据
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        recv_data <= 0;
    end
    else if (rx_flag) begin
        recv_data <= rx_data;
    end
    else begin
        recv_data <= 8'b0;
    end
end


// 1 字节数据接收结束标志
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        finish_flag <= 0;
    end
    else if (rx_flag) begin
        finish_flag <= 1'b1;
    end
    else begin
        finish_flag <= 1'b0;
    end
end

endmodule