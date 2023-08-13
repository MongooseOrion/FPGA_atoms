//
// ���� UART ����
//

module uart_recv #(
    parameter UART_BOT = 'd9600
) (
    input               sys_clk,            // 50MHz
    input               sys_rst,
    input               uart_rx,
    output reg [7:0]    recv_data,
    output reg          finish_flag         // һ�ֽ� 8bit ���ݽ�������ź�
);

// ����ÿһ bit ����Ч����ʱ��
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

// �ӳ�����ʱ�����ڣ�ʹ�ź��ȶ�
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


// ��⿪ʼ������½���
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


// ��ʼ������Ϣ��ʹ���ź�
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        work_en <= 0;
    end
    else if(rvalid) begin
        work_en <= 1'b1;
    end
    else if(bit_flag == 1'b1 && recv_bit_cnt == 4'd8) begin     // �������źž�����������ȷ����ÿ�ֽڴ�����ɺ�ʹ���źſ�������
        work_en <= 1'b0;
    end
    else begin
        work_en <= work_en;
    end
end


// ÿһλ��Ч����ʱ������
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


// ��������ĳһλ�ı�־λ������Ϊ��Чʱ�����в����Ա�֤���ݵ�׼ȷ��
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


// ÿ�ֽ����� bit ������������ʼλ��ֹͣλ�� 10 bit һ�ֽ����ݣ�
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


// ÿ����һλ��Ч���ݣ�������һ�Σ�ֱ��һ�ֽ����ݶ��������
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        rx_data <= 0;
    end
    // �� 0 ������ʼλ���� 9 ���ǽ���λ��ֻҪ 1-8 λ����Ч����
    else if ((recv_bit_cnt > 'd0) && (recv_bit_cnt < 'd9) && (bit_flag == 1'b1)) begin
        rx_data <= {rx_reg3, rx_data[7:1]}          // �������λ7��7:1λ��������Ϊ6:0���� 7 ��
    end
    else begin
        rx_data <= 8'b0;
    end
end


// һ�ֽڽ�����ɱ�־
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


// ���һ�ֽ�����
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


// 1 �ֽ����ݽ��ս�����־
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