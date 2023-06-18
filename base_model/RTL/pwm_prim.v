//
// ���һ�������ò������������ڣ��ߵ�ƽʱ�䣬���������� PWM ģ��
//
// ռ�ձȵ��ڸߵ�ƽʱ���������
module pwm_prim(
    input               clk,
    input               rst,
    input               i_en,
    input       [31:0]  i_period,
    input       [31:0]  i_high,
    input       [15:0]  i_times,
    output reg          o_pwm
);

reg  [1:0]  r_en;
reg         r_en_cnt;
reg  [31:0] r_period_cnt;
reg  [15:0] r_times_cnt;
wire        w_pos_en;
wire        w_neg_en;
wire        w_end;


// ����ʹ���ź������غ��½��ر�־λ
always@(posedge clk) begin
    if(!rst) begin
        r_en <= 'b0;
    end
    else begin
        r_en <= {r_en[0],i_en};
    end
end
assign w_pos_en = r_en[0] & ~r_en[1];
assign w_neg_en = r_en[1] & ~r_en[0];


// ���� pwm �ź���Ҫ��������ʱ�ı�־λ
assign w_end = (r_period_cnt == (i_period-1'b1)) && (r_times_cnt == (i_times-1'b1));


// �����ڲ�����������Ч�ź�
always@(posedge clk) begin
    if(!rst) begin
        r_en_cnt <= 'b0;
    end
    else if(i_en == 1'b0) begin
        r_en_cnt <= 'b0;
    end
    else if(w_pos_en) begin
        r_en_cnt <= 1'b1;
    end
    else if(w_end) begin
        r_en_cnt <= 1'b0;
    end
    else begin
        r_en_cnt <= r_en_cnt;
    end
end


// ���ڼ���
always@(posedge clk) begin
    if(!r_en_cnt) begin
        r_period_cnt <= 'b0;
    end
    else if(r_period_cnt < (i_period-1)) begin
        r_period_cnt <= r_period_cnt+1'b1;
    end
    else begin
        r_period_cnt <= 'b0;
    end
end


// ��������
always@(posedge clk) begin
    if(!r_en_cnt) begin
        r_times_cnt <= 'b0;
    end
    else if(r_period_cnt == (i_period-1)) begin
        r_times_cnt <= r_times_cnt + 1'b1;
    end
    else begin
        r_times_cnt <= 'b0;
    end
end


// ��� pwm ����
always@(posedge clk) begin
    if((r_period_cnt > 32'b0) && (r_period_cnt <= i_high)) begin
        o_pwm <= 1'b1;
    end
    else begin
        o_pwm <= 'b0;
    end
end

endmodule