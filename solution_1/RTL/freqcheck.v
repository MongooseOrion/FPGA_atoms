//
// �����������Ƶ�ʽ��м��
//

module freqcheck(
    input               clk,
    input               rst,
    input               pulse,
    input               en_count,
    output              valid,
    output     [15:0]   count
);

wire    rise_edge;
wire    fall_edge;

reg [1:0]   r_pulse;
reg [15:0]  cnt;
reg         r_flag;

//
// valid �����Ч�źŲ���
//
always@(posedge clk) begin
    if(!rst) begin
        r_flag <= 'b0;
    end
    else if(!en_count) begin
        r_flag <= 'b0;
    end
    else if(rise_edge) begin
        r_flag <= 'b1;
    end
    else begin
        r_flag <= r_flag;
    end
end

assign valid = r_flag & rise_edge;


//
// ������ؼ��
//
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

// assign r_pulse1_invert = ~r_pulse[1];
// assign r_pulse1_invert1 = ~r_pulse[0];
assign rise_edge = r_pulse[0] & ~r_pulse[1];
assign fall_edge = r_pulse[1] & ~r_pulse[0];


//
// �����źż���
//
always@(posedge clk) begin
    if(!rst) begin
        cnt <= 0;
    end
    else begin
        if(!en_count) begin
            cnt <= 'b0;
        end
        else if(rise_edge) begin
            cnt <= 'b0;
        end
        else begin
            cnt <= cnt + 1'b1;
        end
    end
end 

assign count = cnt + 1'b1;

endmodule