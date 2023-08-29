//
// SDRAM 自动刷新模块
//
/* 自动刷新操作参考流程如下：
1. 写入预充电命令，A10设置为高电平，对所有L-Bank进行预充电；
2. 预充电指令写入后，等待tRP时间，此过程中操作命令保持为空操作命令；
3. tRP等待时间结束后，写入自动刷新命令；
4. 自动刷新命令写入后，等待tRC时间，此过程中操作命令保持为空操作命令；
5. tRC等待时间结束后，再次写入自动刷新命令；
6. 自动刷新命令写入后，等待tRC时间，此过程中操作命令保持为空操作命令；
7. tRC等待时间结束后，自动刷新操作完成。
*/
//

module sdram_auref(
    input               sys_clk,        // 100MHz
    input               sys_rst,
    input               init_end,
    input               aref_en,
    output reg          aref_req,
    output reg  [3:0]   aref_cmd,
    output reg  [1:0]   aref_ba,
    output reg  [12:0]  aref_addr,
    output              aref_end
);

// 自动刷新等待时钟
localparam CNT_REF_MAX = 10'd749;   // 7.5us
// 定义各状态
localparam  AREF_IDLE = 3'b000 ,    // 初始状态,等待自动刷新使能
            AREF_PCHA = 3'b001 ,    // 预充电状态
            AREF_TRP = 3'b011 ,     // 预充电等待 tRP
            AUTO_REF = 3'b010 ,     // 自动刷新状态
            AREF_TRF = 3'b100 ,     // 自动刷新等待 tRC
            AREF_END = 3'b101 ;     // 自动刷新结束
// 定义某些状态的等待周期
localparam  TRP_CLK = 3'd2 ,        // 预充电等待周期
            TRC_CLK = 3'd7 ;        // 自动刷新等待周期
// 操作指令
localparam  P_CHARGE = 4'b0010 ,    // 预充电指令
            A_REF = 4'b0001 ,       // 自动刷新指令
            NOP = 4'b0111 ;         // 空操作指令


wire        trp_end;
wire        trc_end;
wire        aref_act;

reg [9:0]   cnt_ref;
reg [2:0]   aref_state;
reg [2:0]   cnt_clk;
reg         cnt_clk_rst;
reg [1:0]   cnt_aref_aref;


// 预充电等待状态结束和自动刷新等待状态结束标志信号
assign trp_end = ((aref_state == AREF_TRP) && (cnt_clk == TRP_CLK)) ? 1'b1 : 1'b0;
assign trc_end = ((aref_state == AREF_TRF) && (cnt_clk == TRC_CLK)) ? 1'b1 : 1'b0;
// 自动刷新响应信号
assign aref_act = (aref_state == AREF_PCHA) ? 1'b1 : 1'b0;


// 状态机跳转时钟计数
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        cnt_clk <= 0;
    end
    else if (cnt_clk_rst) begin
        cnt_clk <= 3'b0;
    end
    else begin
        cnt_clk <= cnt_clk + 1'b1;
    end
end


// 周期计数，以周期性执行自动刷新操作
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        cnt_ref <= 0;
    end
    else if (init_end) begin
        cnt_ref <= cnt_ref + 1'b1;
    end
    else if (cnt_ref > CNT_REF_MAX - 1'b1) begin
        cnt_ref <= 10'b0;
    end
    else begin
        cnt_ref <= cnt_ref;
    end
end


// 输出自动刷新请求信号，以请求仲裁模块发送自动刷新使能信号
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        aref_req <= 0;
    end
    else if (cnt_ref == CNT_REF_MAX - 1'b1) begin
        aref_req <= 1'b1;
    end
    else if (aref_act) begin
        aref_req <= 1'b0;
    end
    else begin
        aref_req <= aref_req;
    end
end


// 自动刷新次数计数器
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        cnt_aref_aref <= 0;
    end
    else if (aref_state == AREF_IDLE) begin
        cnt_aref_aref <= 2'b0;
    end
    else if (aref_state == AREF_TRF) begin
        cnt_aref_aref <= cnt_aref_aref + 1'b1;
    end
    else begin
        cnt_aref_aref <= cnt_aref_aref;
    end
end


// 状态机跳转设置
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        aref_state <= 0;
    end
    else begin
        case(aref_state)
            AREF_IDLE: begin                         // 自动刷新使能信号进入才能开始跳转
                if((aref_en == 1'b1) && (init_end == 1'b1)) begin
                    aref_state <= AREF_PCHA;
                end
                else begin
                    aref_state <= aref_state;
                end
            end
            AREF_PCHA: begin
                aref_state <= AREF_TRP;
            end
            AREF_TRP: begin
                if(trp_end) begin
                    aref_state <= AUTO_REF;
                end
                else begin
                    aref_state <= aref_state;
                end
            end
            AUTO_REF: begin
                aref_state <= AREF_TRF;
            end
            AREF_TRF: begin                         // 等待 7 个时钟周期完成一次自动刷新，需要完成两次自动刷新
                if(trc_end == 1'b1) begin
                    if(cnt_aref_aref == 2'd2) begin
                        aref_state <= AREF_END;
                    end
                    else begin
                        aref_state <= AUTO_REF;
                    end
                end
                else begin
                    aref_state <= aref_state;
                end
            end
            AREF_END: begin
                aref_state <= AREF_IDLE;
            end
            default: begin
                aref_state <= AREF_IDLE;
            end
        endcase
    end
end


// 时钟周期计数复位标志
always @(*) begin
    case (aref_state)
        AREF_IDLE: cnt_clk_rst <= 1'b1; 
        AREF_TRP: cnt_clk_rst <= (trp_end == 1'b1) ? 1'b1 : 1'b0;
        AREF_TRF: cnt_clk_rst <= (trc_end == 1'b1) ? 1'b1 : 1'b0;
        AREF_END: cnt_clk_rst <= 1'b1;
        default: cnt_clk_rst <= 1'b0;
    endcase
end


// SDRAM操作指令控制
always@(posedge sys_clk or negedge sys_rst) begin
    if(sys_rst == 1'b0) begin
        aref_cmd <= NOP;
        aref_ba <= 2'b11;
        aref_addr <= 13'h1fff;
    end
    else begin
        case(aref_state)
            AREF_IDLE,AREF_TRP,AREF_TRF: begin      // 执行空操作指令
                aref_cmd <= NOP;
                aref_ba <= 2'b11;
                aref_addr <= 13'h1fff;
            end
            AREF_PCHA: begin                        // 预充电指令
                aref_cmd <= P_CHARGE;
                aref_ba <= 2'b11;
                aref_addr <= 13'h1fff;
            end
            AUTO_REF: begin                         // 自动刷新指令
                aref_cmd <= A_REF;
                aref_ba <= 2'b11;
                aref_addr <= 13'h1fff;
            end
            AREF_END: begin                         // 一次自动刷新完成
                aref_cmd <= NOP;
                aref_ba <= 2'b11;
                aref_addr <= 13'h1fff;
            end
            default: begin
                aref_cmd <= NOP;
                aref_ba <= 2'b11;
                aref_addr <= 13'h1fff;
            end
        endcase
    end
end


endmodule