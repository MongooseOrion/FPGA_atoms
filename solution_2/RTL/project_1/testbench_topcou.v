`timescale 1ns/1ps
module testbench_topcou(

);

parameter CLK_PERIOD = 10;

reg         clk;
reg         rst;
reg  [3:0]  pulse;
reg         en_count;
wire [15:0] count1;
wire [15:0] count2;
wire [15:0] count3;
wire [15:0] count4;

// ���Ӳ���ģ��
top_counter top_counter_test(
    .clk        (clk),
    .rst        (rst),
    .pulse      (pulse),
    .en_count   (en_count),
    .count1     (count1),
    .count2     (count2),
    .count3     (count3),
    .count4     (count4)
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
    pulse <= 'b0;

    @(posedge rst);

    @(posedge clk);
    #10;
    en_count <= 1;
    repeat(1000) begin
        @(posedge clk);
    end
    en_count <= 0;

    /*
    i_en <= 1'b1;
	for(i=0; i<50; i=i+1) begin
		#500;
		i_pulse <= 4'b1110;
		#300;
		i_pulse <= 'b0;
	end
	i_en <= 1'b0;	
	#10_000;
	
	i_en <= 1'b1;
	for(i=0; i<69; i=i+1) begin
		#500;
		i_pulse <= 4'b0111;
		#300;
		i_pulse <= 'b0;
	end
	i_en <= 1'b0;	
	#10_000;	
	
	i_en <= 1'b0;
	for(i=0; i<15; i=i+1) begin
		#500;
		i_pulse <= 'b1;
		#300;
		i_pulse <= 'b0;
	end
	i_en <= 1'b0;	
	#10_000;

	
	$stop;
    */

    #10000;

    $stop;
end

// ���������ź���������Ϊ 40 ��ʱ�䵥λ
always begin
    #(CLK_PERIOD*2);
    pulse[0] = ~pulse[0];
end

always begin
    #(CLK_PERIOD*2);
    //# 4;
    pulse[1] = ~pulse[1];
end

always begin
    #(CLK_PERIOD*2);
    //# 8;
    pulse[2] = ~pulse[2];
end

always begin
    #(CLK_PERIOD*2);
    //# 12;
    pulse[3] = ~pulse[3];
end

// ������ 250 ��
// �ظ��� 1000 �β��������أ���ôʹ���źŴ��������ص�ʱ��Ӧ����
// 1000*10 ��ʱ�䵥λ��Ȼ�� 10000/40 =250 �����ȷ

endmodule