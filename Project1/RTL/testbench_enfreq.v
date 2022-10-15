//
// ʹ��ʱ�ӵ���֤ƽ̨����
//

`timescale 1ns/1ps
module testbench_enfreq(

);

parameter   CLK_PERIOD = 10;

reg     clk;
reg     rst;
wire    syscnt;

// ���Ӳ���ģ��
enfreq enfreq_test(
    .clk    (clk),
    .rst    (rst),
    .syscnt (syscnt)
);

// ��ʼ��ʱ�Ӻ͸�λ�ź�
initial begin
    clk <= 0;
    rst <= 0;
    #1000;
    rst <= 1;
end

always@(CLK_PERIOD / 2) begin
    clk <= ~ clk;
end


// �������Լ���
initial begin
    @(posedge rst);
    @(posedge clk);

    repeat(10) begin
        @(posedge clk);
    end

    #10_000;

    $stop
end

endmodule
