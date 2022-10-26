////////////////////////////////////
// ��һ���źž������� D ����������֤ƽ̨����
/////////////////////////////////////

`timescale 1ns/1ps
module testbench_dtrig(

);

parameter CLK_PERIOD = 10;

reg         clk;
reg         rst;
reg  [3:0]  d;
wire [3:0]  q;

// ���Ӳ���ģ��
dtrig dtrig_test(
    .clk        (clk),
    .rst        (rst),
    .d          (d),
    .q          (q)
);

// ��ʼ��ʱ�ӡ���λ�������ź�
initial begin
    clk <= 0;
    rst <= 0;
    # 1000;
    rst <= 1;
    
    @(posedge clk);
    # 2;
    d <= 4'd1;
    @(posedge clk);
    # 2;
    d <= 4'd2;
    @(posedge clk);
    # 2;
    d <= 4'd3;
    @(posedge clk);
    # 2;
    d <= 4'd4;

end

always #(CLK_PERIOD/2) clk <= ~clk;

initial begin
    @(posedge rst);     // �ȴ���һ�� initial ��ĸ�λ���
    
    @(posedge clk);     // �ڸ�λ��ɵĻ����ϵȴ�ʱ��������

    repeat(10) begin
        @(posedge clk);
    end

    #10_000;

    $stop;
end

endmodule
