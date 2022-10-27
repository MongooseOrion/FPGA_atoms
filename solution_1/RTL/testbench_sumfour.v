///////////////////////////////////
// ��λ�ӷ�����֤ƽ̨����
///////////////////////////////////

`timescale 1ns/1ps
module testbench_sumfour(

);

parameter CLK_PERIORD = 10;

reg         clk;
reg         rst;
wire [3:0]  o_cnt_1;
wire [3:0]  o_cnt_2;

// ����ģ��
sumfour sumfour_test(
    .clk        (clk),
    .rst        (rst),
    .o_cnt_1    (o_cnt_1),
    .o_cnt_2    (o_cnt_2)
);

// ��ʼ��ʱ��
initial begin
    clk <= 0;
    rst <= 0;
    #1000;
    rst <= 1;
end

always #(CLK_PERIORD / 2) clk = ~clk;

// ���������ź�
initial begin

	@(posedge rst);	        	// �ȴ���λ���
	
	@(posedge clk);				// �ȴ�ʱ��������
	

	repeat(10) begin
		@(posedge clk);         // �ظ� 10 ��ʱ���������жϣ���ôҲ���ǲ��� 10 �η�Ƶ�ź�
	end
	
	#10_000;                    // ����ʱ��Ϊ 10000 ��ʱ�䵥λ��Ҳ�� 10000*1ns=10000ns
	
	$stop;
end

endmodule

