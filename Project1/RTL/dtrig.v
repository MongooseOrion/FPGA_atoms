/////////////////////////////////////////////////
// ʵ�ֵĹ����ǽ�����ֵת�ݸ�������1������ q �Ӵ�����2��
// ��Ҫ��Ϊ��д��֤ƽ̨����
/////////////////////////////////////////////////

module dtrig(
    input          clk,
    input          rst,
    input  [3:0]   d,
    output [3:0]   q
);

reg [3:0]   cnt_1;
reg [3:0]   cnt_2;

always@(posedge clk or negedge rst)
begin
    if(!rst) begin
        cnt_1 <= 0;
    end
    else begin
        cnt_1 <= d;
    end
end

always@(posedge clk or negedge rst)
begin
    if(!rst) begin
        cnt_2 <= 0;
    end
    else begin
        cnt_2 <= cnt_1;
    end
end

assign q = cnt_2;

endmodule