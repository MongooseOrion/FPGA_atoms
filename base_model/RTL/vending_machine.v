//
// 设计一个自动贩卖机的状态机，其中可用 1、2、5 元纸币，获取 6 元的商品
//
module vending_machine(
    input               clk,
    input               rst,
    input               i_one_cny,
    input               i_two_cny,
    input               i_five_cny,
    output  reg         o_done
);

// 最小输入次数：5*1+1*1
// 最大输入次数：1*6
// 

// 参数化，以便 case 语句的操作
parameter IDLE = 4'd0;
parameter IN_1 = 4'd1;
parameter IN_2 = 4'd2;
parameter IN_3 = 4'd3;
parameter IN_4 = 4'd4;
parameter IN_5 = 4'd5;
parameter IN_6 = 4'd6;
parameter DONE = 4'd7;
parameter MONEY_PAY = 4'd6;

reg  [3:0]  current_state;
reg  [3:0]  next_state;
reg  [3:0]  money_sum;


// 时序逻辑，锁存状态
always@(posedge clk) begin
    if(!rst) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end


// 组合逻辑，实现状态转移
always@(*) begin
    case(current_state)
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
            if(money_sum >= MONEY_PAY) begin
                next_state = DONE;
            end
            else if(i_one_cny || i_two_cny || i_five_cny) begin
                next_state = IN_4;
            end
            else begin
                next_state = IN_3;
            end
        end
        IN_4: begin
            if(money_sum >= MONEY_PAY) begin
                next_state = DONE;
            end
            else if(i_one_cny || i_two_cny || i_five_cny) begin
                next_state = IN_5;
            end
            else begin
                next_state = IN_4;
            end
        end
        IN_5: begin
            if(money_sum >= MONEY_PAY) begin
                next_state = DONE;
            end
            else if(i_one_cny || i_two_cny || i_five_cny) begin
                next_state = IN_6;
            end
            else begin
                next_state = IN_5;
            end
        end
        IN_6: begin
            if(money_sum >= MONEY_PAY) begin
                next_state = DONE;
            end
            else if(i_one_cny || i_two_cny || i_five_cny) begin
                next_state = DONE;
            end
            else begin
                next_state = IN_6;
            end
        end
        DONE: begin
            next_state = IDLE;
        end
        default: ;
    endcase
end


// 当前状态输入金额的计算
always@(posedge clk) begin
    if(!rst) begin
        money_sum <= 'b0;
    end
    else begin
        case(current_state)
            DONE: money_sum <= 'b0;             // 当 case 语句执行情况 DONE 时，变量赋值为 0
            default: begin
                if(i_one_cny) begin
                    money_sum <= money_sum + 1'b1;
                end
                else if(i_two_cny) begin
                    money_sum <= money_sum + 'd2;
                end
                else if(i_five_cny) begin
                    money_sum <= money_sum + 'd5;
                end
                else begin
                    money_sum <= money_sum;
                end
            end
        endcase
    end
end


// 状态机输出赋值
always@(posedge clk or negedge rst) begin
    if(!rst) begin
        o_done <= 'b0;
    end
    else if(current_state == DONE) begin
        o_done <= 'b1;
    end
    else begin
        o_done <= 'b0;
    end
end

endmodule