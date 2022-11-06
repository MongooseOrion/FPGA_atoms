//
// ���һ���Զ���������״̬�������п��� 1��2��5 Ԫֽ�ң���ȡ 6 Ԫ����Ʒ
//
module vending_machine(
    input               clk,
    input               rst,
    input               i_one_cny,
    input               i_two_cny,
    input               i_five_cny,
    output              o_done
);

// ��С���������5*1+1*1
// ������������1*6
// 

// ���������Ա� case ���Ĳ���
parameter IDLE = 4'b0;
parameter IN_1 = 4'b1;
parameter IN_2 = 4'b2;
parameter IN_3 = 4'b3;
parameter IN_4 = 4'b4;
parameter IN_5 = 4'b5;
parameter IN_6 = 4'b6;
parameter DONE = 4'b7;
parameter MONEY_PAY = 4'd6;

reg  [3:0]  current_state;
reg  [3:0]  next_state;
reg  [3:0]  money_sum;


// ʱ���߼�������״̬
always@(posedge clk) begin
    if(!rst) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end


// ����߼���ʵ��״̬ת��
always@(*) begin
    case(current_state) begin
        IDLE: begin
            if(i_one_cny || i_two_cny || i_five_cny) begin
                next_state = IN_1;
            end
            else begin
                next_state = IDLE;
            end
        end
        IN_1: begin
            if(i_one_cny || i_two_cny || i_five_cny) begin
                next_state = IN_2;
            end
            else begin
                next_state = IN_1;
            end
        end
        IN_2: begin
            if(money_sum >= MONEY_PAY) begin
                next_state = DONE;
            end
            else if(i_one_cny || i_two_cny || i_five_cny) begin
                next_state = IN_3;
            end
            else begin
                next_state = IN_2;
            end
        end
        IN_3: begin
            
end