//
// ��Ƶʱ�ӵ���֤ƽ̨����
//

`timescale 1ns/1ps                  // ʱ�䵥λΪ 1 ns��ʱ�侫��Ϊ 1 ps
module testbench_partfreq(

);

parameter CLK_PERIORD = 10;         // 100MHz ����Ϊ 10ns����Ӧ 10 ��ʱ�䵥λ

reg         clk;
reg         rst;
wire        clk_out;


partfreq    partfreq_test(			// ǰ���� ���ģ�� ���ƣ������� ����ģ�� ����
    .clk        (clk),
    .rst        (rst),
    .clk_out    (clk_out)
);

//////////////////////////////////
// ʱ�Ӻ͸�λ�źŵĲ���
//////////////////////////////////
initial begin
	clk <= 0;
	rst_n <= 0;
	#1000;
	rst_n <= 1;
end
	
// ʱ�Ӳ��������ڷ��� 100MHz ��Ҫ��
always #(CLK_PERIORD / 2) clk = ~clk;


////////////////////////////////////////////////////////////
// ���Լ�������
////////////////////////////////////////////////////////////
initial begin

	@(posedge rst_n);	        // �ȴ���λ���
	
	@(posedge clk);				// �ȴ�ʱ��������
	

	repeat(10) begin
		@(posedge clk);         // �ظ� 10 ��ʱ���������жϣ���ôҲ���ǲ��� 10 �η�Ƶ�ź�
	end
	
	#10_000;                    // ����ʱ��Ϊ 10000 ��ʱ�䵥λ��Ҳ�� 10000*1ns=10000ns
	
	$stop;
end


endmodule