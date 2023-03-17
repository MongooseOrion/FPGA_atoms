/////////////////////////////////////////////////
// ��ģ��ʵ���˽� 8 ����ť���ƶ�Ӧ 8 �� LED �ƵĹ���
/////////////////////////////////////////////////

module led(
  input              clk,
  input              rst,
  input       [7:0]  key,
  output reg  [7:0]  led
);

// ����������Ҫ�ӳٵ�ʱ�䵥λ
parameter CLK_PULSE = 10;

reg  [7:0]  key_reg;
reg  [7:0]  key_reg_out;
reg  [3:0]  count;
reg         flag;

// ����ֱ�Ӵ洢����ֵ
always@(posedge clk or negedge rst) begin
    if(!rst) key_reg <= 0;        // PDS �� rst Ϊ null ʱ��Ը��źű���
    else key_reg <= key;
end

// ���ڲ��������ź�
always@(posedge clk or negedge rst) begin
    if(!rst) count <= 0;
    else count <= count + 1;
end

// ���ڲ�����־λ
always@(posedge clk or negedge rst) begin
    if(!rst) flag <= 0;
    else begin
        if(count == CLK_PULSE-1) begin
            flag <= 1'b1;
        end
        else begin
            if(count == 0) flag <= 1'b0;
            else flag <= flag;
        end
    end
end

// �ڱ�־λ��Чʱ���洢��״̬�µİ���ֵ
always@(posedge clk or negedge rst) begin
  if(!rst)begin
    key_reg_out <= 8'b0;
  end
  else begin
    if(flag == 1'b1) begin
      key_reg_out <= key_reg;
    end
    else key_reg_out <= key_reg_out;
  end
end

// ���� LED ��
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        led <= 8'b0;
    end else begin
        if (flag) begin
            led <= key_reg_out;
        end
    end
end


endmodule
