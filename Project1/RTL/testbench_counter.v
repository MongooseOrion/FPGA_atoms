//
// �������ź�ʹ��ʱ��������֤ƽ̨����
//

`timescale 1ns/1ps
module testbench_counter(

);

parameter CLK_PERIOD = 10;

reg         clk;
reg         rst;
reg         pulse;
reg         en_count;
wire [15:0] count;

// ���Ӳ���ģ��
counter counter_test(
    .clk        (clk),
    .rst        (rst),
    .pulse      (pulse),
    .en_count   (en_count),
    .count      (count)
);

// ��ʼ����λ��ʱ��
initial begin
    clk <= 0;
    rst <= 0;
    #1000
    rst <= 1;
end

always #(CLK_PERIOD/2) clk = ~clk;

// �������Լ���
initial begin
    en_count <= 0;
    pulse <= 0;

    @(posedge rst);

    @(posedge clk);
    #10;
    en_count <= 1;
    repeat(1000) begin
        @(posedge clk);
    end
    en_count <= 0;

    #10000;

    $stop;
end

// ���������ź���������Ϊ 40 ��ʱ�䵥λ
always begin
    #(CLK_PERIOD*2);
    pulse = ~pulse;
end

// ������ 250 ��
// �ظ��� 1000 �β��������أ���ôʹ���źŴ��������ص�ʱ��Ӧ����
// 1000*10 ��ʱ�䵥λ��Ȼ�� 10000/40 =250 �����ȷ

endmodule