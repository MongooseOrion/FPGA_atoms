//
// ���ĳһ���뼤���źŷ����仯ʱ�������ػ��½��ر仯����֤ƽ̨����
//

`timescale 1ns/1ps
module testbench_posenege(

);

parameter CLK_PERIOD = 10;

reg         clk;
reg         rst;
reg         pulse;
wire        rise_edge;
wire        fall_edge;

posenege posenege_test(
    .clk        (clk),
    .rst        (rst),
    .pulse      (pulse),
    .rise_edge  (rise_edge),
    .fall_edge  (fall_edge)
);

// ��ʼ����λ��ʱ��
initial begin
    clk <= 0;
    rst <= 0;
    #1000;
    rst <= 1;
end

always #(CLK_PERIOD/2) clk = ~clk;

initial begin
    pulse <= 1'b0;      // �ϵ�͸���ֵ 0
    @(posedge rst)

    @(posedge clk) 

    repeat(10) begin
        @(posedge clk);
    end
    #4;                 // ʹ�����ź���ʱ�Ӳ�ͬ��
    pulse <= 1'b1;

    // �ӳ� 10 ��ʱ������
    repeat(10) begin
        @(posedge clk);
    end
    #4;
    pulse <= 1'b0;

    repeat(10) begin
        @(posedge clk);
    end

    #10_000;
    $stop;
end

endmodule