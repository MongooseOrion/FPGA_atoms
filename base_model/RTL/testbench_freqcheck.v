//
// ����Ƶ�ʼ���������֤ƽ̨����
//
module testbench_freqcheck(

);

parameter CLK_PERIOD = 10;

reg         clk;
reg         rst;
reg         pulse;
reg         en_count;
wire        valid;
wire [15:0] count;

// ���Ӳ���ģ��
freqcheck freqcheck_test(
    .clk        (clk),
    .rst        (rst),
    .pulse      (pulse),
    .en_count   (en_count),
    .valid      (valid),
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

integer i;
initial begin
    
    @(posedge rst);
    for(i=0;i<50;i=i+1) begin
        #(CLK_PERIOD*2);
        pulse <= ~pulse;
    end

    #1000;

    for(i=0;i<50;i=i+1) begin
        #(CLK_PERIOD*4);
        pulse <= ~pulse;
    end

    #1000;
end

endmodule