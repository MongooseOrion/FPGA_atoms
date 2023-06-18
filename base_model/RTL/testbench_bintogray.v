//
// ��Ȼ 2 ����ת 4 λ��������֤ƽ̨����
//

`timescale 1ns/1ps
module testbench_bintogray(

);

parameter CLK_PERIOD = 10;

reg         clk;
reg         rst;
reg  [3:0]  data;
wire [3:0]  gray_data;

// ���Ӳ���ģ��
bin_to_Gray bin_to_Gray_test(
    .clk            (clk),
    .rst            (rst),
    .data           (data),
    .gray_data      (gray_data)
);

// ��ʼ��ʱ�Ӻ͸�λ
initial begin
    clk <= 0;
    rst <= 0;
    data <= 0;
    #1000;
    rst <= 1;

end

always begin
    #(CLK_PERIOD/2)
    clk = ~clk;
end

// �������Լ���
integer i;
initial begin

    @(posedge rst);

    @(posedge clk) begin
        for(i=0;i<50;i=i+1) begin
            #500;
            data <= {$random} % 15;

            #300
            data <= 0;
        end
    end

    data <= 0;
    
    #10000;

    $stop;

end

endmodule