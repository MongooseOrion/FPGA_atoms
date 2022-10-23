//
// ���ĳһ�źŵ������غ��½��ص���
//

module posenege(
    input       clk,
    input       rst,
    input       pulse,
    output      rise_edge,
    output      fall_edge
);

reg [1:0]   r_pulse;
wire        r_pulse1_invert;
wire        r_pulse1_invert1;

always@(posedge clk) begin
    if(!rst) begin
        r_pulse <= 2'b00;
    end
    else begin
        // ��0λ��ֵ����1λ������0λ�������źŸ���
        r_pulse[0] <= pulse;
        r_pulse[1] <= r_pulse[0];
        // ��Ч r_pulse <= {r_pulse[0],pulse};
        
        // ���뼤���źŵı仯�������ʱ���������ܲ�����һ����ʹ���źţ����ǲ�������ź�Ϊ2λ����һ��
        // ʹ���źſ����ڵڶ���ʱ������������ڶ���ʹ���źţ���������֮����һ��ʱ�����ڵĲ�ֵ��������
        // ����ָʾ���뼤���ź��Ѿ������˱仯
    end
end

assign r_pulse1_invert = ~r_pulse[1];
assign r_pulse1_invert1 = ~r_pulse[0];
assign rise_edge = r_pulse[0] & r_pulse1_invert;
assign fall_edge = r_pulse[1] & r_pulse1_invert1;

endmodule