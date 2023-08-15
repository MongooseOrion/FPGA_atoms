//
// SDRAM 初始化模块
/* SDRAM 初始化流程：
    1. 对 SDRAM 上电，加载稳定时钟信号，CKE 设置为高电平；
    2. 等待 T>=100us 的时间，此过程中操作命令保持为空操作命令；
    3. 100us等待结束后，写入预充电命令，A10设置为高电平，对所有L-Bank进行预充电；
    4. 预充电指令写入后，等待tRP时间，此过程中操作命令保持为空操作命令；
    5. tRP等待时间结束后，写入自动刷新命令；
    6. 自动刷新命令写入后，等待tRC时间，此过程中操作命令保持为空操作命令；
    7. tRC等待时间结束后，再次写入自动刷新命令；
    8. 自动刷新命令写入后，等待tRC时间，此过程中操作命令保持为空操作命令；
    9. tRC等待时间结束后，写入模式寄存器配置指令，地址总线A0-A11参数不同辅助模式寄存器不同模式的设置；
    10. 模式寄存器配置指令写入后，等待tMRD时间，此过程中操作命令保持为空操作命令；
    11. tMRD等待时间结束后，SDRAM初始化完成。
*/
//
//

module sdram_init #()(

    input               sys_clk,    // 100MHz
    input               sys_rst,

    output reg [3:0]    init_cmd,   // 初始化后写入 SDRAM 的指令
    output reg [1:0]    init_ba,    // 初始化后 Bank 地址
    output reg [12:0]   init_addr,  // 地址总线
    output              init_end    // 初始化结束信号
);

localparam  T_POWER = 15'd20_000;   // 设置上电时钟等待 200us
localparam  P_CHARGE = 4'b0010,     // 预充电指令
            AUTO_REF = 4'b0001,     // 自动刷新指令
            NOP = 4'b0111 ,         // 空操作指令
            M_REG_SET = 4'b0000 ;   // 模式寄存器设置指令

// SDRAM初始化过程各个状态
localparam  INIT_IDLE = 3'b000 ,    // 初始状态
            INIT_PRE = 3'b001 ,     // 预充电状态
            INIT_TRP = 3'b011 ,     // 预充电等待 tRP
            INIT_AR = 3'b010 ,      // 自动刷新
            INIT_TRF = 3'b100 ,     // 自动刷新等待 tRC
            INIT_MRS = 3'b101 ,     // 模式寄存器设置
            INIT_TMRD = 3'b111 ,    // 模式寄存器设置等待 tMRD
            INIT_END = 3'b110 ;     // 初始化完成
// 预设的等待时钟周期
localparam  TRP_CLK = 3'd2 ,        // 预充电等待周期, 20ns
            TRC_CLK = 3'd7 ,        // 自动刷新等待, 70ns
            TMRD_CLK = 3'd3 ;       // 模式寄存器设置等待周期, 30ns


wire        wait_end;
wire        trp_end;
wire        trc_end;
wire        tmrd_end;

reg  [15:0] cnt_200us;
reg  [2:0]  init_state;
reg  [2:0]  cnt_clk;
reg         cnt_clk_rst;
reg  [3:0]  cnt_init_aref;

// SDRAM 初始化完毕信号
assign init_end = (init_state == INIT_END) ? 1'b1 : 1'b0;
// 预充电等待结束标志
assign trp_end = ((cnt_clk == TRP_CLK) && (init_state == INIT_TRP)) ? 1'b1 : 1'b0;
// 自动刷新等待状态结束标志
assign trc_end = ((cnt_clk == TRC_CLK) && (init_state == INIT_TRF)) ? 1'b1 : 1'b0;
// 模式寄存器配置等待结束标志
assign tmrd_end = ((cnt_clk == TMRD_CLK) && (init_state == INIT_TMRD)) ? 1'b1 : 1'b0;


// 稳定时钟计数，上电等待 200us
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        cnt_200us <= 0;
    end
    else if (cnt_200us < T_POWER) begin
        cnt_200us <= cnt_200us + 1'b1;
    end
    else begin
        cnt_200us <= cnt_200us
    end
end
assign wait_end = (cnt_200us == T_POWER - 1'b1) ? 1'b1 : 1'b0; // 上电后 200us 等待结束标志


// 记录初始化各状态的时钟周期，以便于各状态跳转
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        cnt_clk <= 0;
    end
    else if (cnt_clk_rst == 1'b1) begin
        cnt_clk <= 3'b0;
    end
    else begin
        cnt_clk <= cnt_clk + 1'b1;
    end
end


// 初始化过程自动刷新次数计数器，初始化过程需要进行 >= 2 次自动刷新操作
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        cnt_init_aref <= 0;
    end
    else if (init_state == INIT_IDLE) begin
        cnt_init_aref <= 4'd0;
    end
    else if (init_state == INIT_AR) begin
        cnt_init_aref <= cnt_init_aref + 1'b1;
    end
    else begin
        cnt_init_aref <= cnt_init_aref;
    end
end



// SDRAM 状态机变量跳转
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        init_state <= 0;
    end
    else begin
        case(init_state)
            INIT_IDLE: begin            // 在等待 200us 后跳转到预充电状态
                if(wait_end) begin
                    init_state <= INIT_PRE;
                end
                else begin
                    init_state <= init_state;
                end
            end
            INIT_PRE: begin             // 直接跳转到预充电等待状态
                init_state <= INIT_TRP;
            end
            INIT_TRP: begin             // 等待设定时钟周期(2)，以完成预充电阶段，然后跳转到自动刷新阶段
                if(trp_end) begin
                    init_state <= INIT_AR;
                end
                else begin
                    init_state <= init_state;
                end
            end
            INIT_AR: begin              // 直接跳转到自动刷新等待状态
                init_state <= INIT_TRF;
            end
            INIT_TRF: begin             // 等待设定时钟周期(7)，然后完成 8 次自动刷新，然后进入配置模式寄存器状态
                if(trc_end) begin
                    if(cnt_init_aref == 4'd8) begin
                        init_state <= INIT_MRS;
                    end
                    else begin
                        init_state <= INIT_AR;
                    end
                end
                else begin
                    init_state <= init_state;
                end
            end
            INIT_MRS: begin             // 直接跳转到配置模式寄存器状态
                init_state <= INIT_TMRD;
            end
            INIT_TMRD: begin            // 等待设定时钟周期(3)，完成配置模式寄存器，然后进入初始化完成状态
                if(tmrd_end) begin
                    init_state <= INIT_END;
                end
                else begin
                    init_state <= init_state;
                end
            end
            INIT_END: begin             // 初始化完成状态
                init_state <= INIT_END;
            end
            default: init_state <= INIT_IDLE;
        endcase
    end
end


// cnt_clk 清零信号
always @(*) begin
    case(init_state)
        INIT_IDLE: cnt_clk_rst <= 1'b1;
        INIT_TRP: cnt_clk_rst <= (trp_end == 1'b1) ? 1'b1 : 1'b0;
        INIT_TRF: cnt_clk_rst <= (trc_end == 1'b1) ? 1'b1 : 1'b0;
        INIT_TMRD: cnt_clk_rst <= (tmrd_end == 1'b1) ? 1'b1 : 1'b0;
        INIT_END: cnt_clk_rst <= 1'b1;
        default: cnt_clk_rst <= 1'b0;
    endcase
end


// SDRAM 操作指令控制
// 初始化阶段逻辑 Bank 地址 init_ba、初始化阶段地址总线 init_addr，当状态机处于
// 配置模式寄存器状态(INIT_MRS)时，分别写入逻辑Bank地址和模式寄存器配置的相关参数，
// 其他状态二者均写入全 1。
always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) begin
        init_cmd <= NOP;
        init_ba <= 2'b11;
        init_addr <= 13'h1fff;
    end
    else begin
        case(init_state)
            INIT_IDLE,INIT_TRP,INIT_TRF,INIT_TMRD: begin    //执行空操作指令
                init_cmd <= NOP;
                init_ba <= 2'b11;
                init_addr <= 13'h1fff;
            end
            INIT_PRE: begin                                 //预充电指令
                init_cmd <= P_CHARGE;
                init_ba <= 2'b11;
                init_addr <= 13'h1fff;
            end
            INIT_AR: begin                                  //自动刷新指令
                init_cmd <= AUTO_REF;
                init_ba <= 2'b11;
                init_addr <= 13'h1fff;
            end
            INIT_MRS: begin                                 //模式寄存器设置指令
                init_cmd <= M_REG_SET;
                init_ba <= 2'b00;
                init_addr <= { // 地址辅助配置模式寄存器
                    3'b000, // A12-A10:预留
                    1'b0,   // A9=0:读写方式,0:突发读&突发写,1:突发读&单写
                    2'b00,  // {A8,A7}=00:标准模式,默认
                    3'b011, // {A6,A5,A4}=011:CAS潜伏期,010:2,011:3,其他:保留
                    1'b0,   // A3=0:突发传输方式,0:顺序,1:隔行
                    3'b111  // {A2,A1,A0}=111:突发长度,000:单字节,001:2字节,010:4字节,011:8字节,111:整页,其他:保留
                };
            end
            INIT_END: begin                                 //SDRAM初始化完成
                init_cmd <= NOP;
                init_ba <= 2'b11;
                init_addr <= 13'h1fff;
            end
            default: begin
                init_cmd <= NOP;
                init_ba <= 2'b11;
                init_addr <= 13'h1fff;
                end
        endcase
    end
end


// 初始化结束信号
assign init_end = (init_state == INIT_END) ? 1'b1 : 1'b0;


endmodule