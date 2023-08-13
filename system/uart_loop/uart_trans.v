//
// UART 发送模块
//
//
module uart_trans #(
    parameter UART_BOT = 'd9600
)(
    input               sys_clk,
    input               sys_rst,

    input      [7:0]    trans_data,
    input               trans_valid,

    output reg          tx_data
);

localparam  BIT_CNT_MAX = 'd50_000_000 / UART_BOT;

reg         work_en;
reg [12:0]  bit_cnt;
reg         bit_flag;
reg [3:0]   trans_bit_cnt;


// 发送使能信号
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_clk) begin
        work_en <= 0;
    end
    else if (trans_valid == 1'b1) begin
        work_en <= 1'b1;
    end
    else if ((bit_flag == 1'b1) && (bit_cnt == 'd9))begin
        work_en <= 1'b0;
    end
    else begin
        work_en <= work_en;
    end
end


// 每一 bit 数据最大有效时长计数
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_clk) begin
        bit_cnt <= 0;
    end
    else if (work_en == 1'b1) begin
        bit_cnt <= bit_cnt + 1'b1;
    end
    else if ((bit_cnt == BIT_CNT_MAX -1) || (work_en == 1'b0))begin
        bit_cnt <= 13'b0;
    end
    else begin
        bit_cnt <= bit_cnt
end


// 决定接收一位数据的位置，这里设置为有效时长中部位置
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_clk) begin
        bit_flag <= 0;
    end
    else if (bit_cnt == BIT_CNT_MAX/2 - 1) begin
        bit_flag <= 1'b1;
    end
    else begin
        bit_flag <= 1'b0;
    end
end


// 每字节数据 bit 计数，每字节应该有 10bit 数据
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_clk) begin
        trans_bit_cnt <= 0;
    end
    else if ((bit_flag == 1'b1) && (trans_bit_cnt < 'd10)) begin // 传输第一位是索引号 1，而不是 0
        trans_bit_cnt <= trans_bit_cnt + 1'b1;
    end
    else if ((trans_bit_cnt == 'd10) && (bit_flag == 1'b1)) begin
        trans_bit_cnt <= 4'b0;
    end
    else begin
        trans_bit_cnt <= trans_bit_cnt;
    end
end


// 输出每字节数据
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_clk) begin
        tx_data <= 0;
    end
    else if (bit_flag == 1'b1) begin
        case (trans_bit_cnt)
            0:      1'b0;
            1:      tx_data <= trans_data[0];   // 起始位
            2:      tx_data <= trans_data[1];   // 有效数据[1:8]
            3:      tx_data <= trans_data[2];
            4:      tx_data <= trans_data[3];
            5:      tx_data <= trans_data[4];
            6:      tx_data <= trans_data[5];
            7:      tx_data <= trans_data[6];
            8:      tx_data <= trans_data[7];
            9:      tx_data <= trans_data[8];
            10:     tx_data <= 1'b1;
            default:tx_data <= 1'b1;
        endcase
    end 
    else begin
        tx_data <= 1'b0;
    end
end



endmodule