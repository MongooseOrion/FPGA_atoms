//
// ��Ƶʱ�ӣ���ʱ�� 100MHz�����ʱ��Ƶ��Ϊ 1MHz
//

module partfreq(
    input       clk,
    input       rst,
    output reg  clk_out
);

parameter CNT_MAX = 8'd100;
parameter CNT_HALF = CNT_MAX / 2;

reg [7:0]   cnt;

always@(posedge clk or negedge rst)
begin
    if(!rst) begin
        cnt <= 8'd0;
    end
    else if(cnt < CNT_MAX-1) begin
        cnt <= cnt + 1'b1;
    end
    else begin
        cnt <= 8'd0;
    end
end

always@(posedge clk or negedge rst)
begin
    if(!rst) begin
        clk_out <= 1'b0;
    end
    else if(cnt < CNT_HALF) begin
        clk_out <= ~clk_out;
    end
    else begin
        clk_out <= clk_out;
    end

endmodule