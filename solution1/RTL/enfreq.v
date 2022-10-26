//
// ʹ���źſ��Ƶ�ʹ��ʱ�ӣ��ŵ��Ǳ���һ��ʱ���źţ����ٿ�ʱ��������
//
// ���ʹ��ÿ 20 �� 100MHz ��ʱ�����ڵ�Ч��Ƶһ�Σ�ʵ��ϵͳ����

module enfreq(
    input               clk,
    input               rst,
    output reg [3:0]    syscnt
);

parameter DIVCNT_MAX = 5'd19;

reg[4:0]    divcnt;
reg         clk_en;

/////////////////////////////////////////
// ����ʱ���� 20 ��Ƶ����
////////////////////////////////////////
always@(posedge clk or negedge rst)
begin
    if(!rst) begin
        divcnt <= 0;
    end
    else if(divcnt < DIVCNT_MAX) begin
        divcnt <= divcnt + 1'b1;
    end
    else begin
        divcnt <= 'b0;
    end
end

////////////////////////////////////////////
// ��ÿ 20 ����ʱ��������� 1 ���������źţ���ʱ��Ϊʱ�ӵ�һ�����ڣ�
///////////////////////////////////////////
always@(posedge clk or negedge rst)
begin
    if(!rst) begin
        clk_en <= 0;
    end
    else if(divcnt == DIVCNT_MAX) begin
        clk_en <= 1'b1;
    end
    else begin
        clk_en <= clk_en;
    end
end

////////////////////////////////////////////////////
// ʹ��ʱ��ʹ���źŽ���ϵͳ���������Ǹ�ʱ������Ҫʵ�ֵĹ��ܣ�
// syscnt ÿ���� 15 �����¿�ʼ����
///////////////////////////////////////////////////
always@(posedge clk or negedge rst)
begin
    if(!rst) begin
        syscnt <= 0;
    end
    else if(clk_en == 1'b1) begin
        syscnt <= syscnt + 1'b1;
    end
    else begin
        syscnt <= syscnt;
    end
end

endmodule