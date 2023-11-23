//
// SDRAM 写控制模块
/* SDRAM页突发写操作的流程：
1. 发送激活指令到SDRAM，同时BA0-BA1、A0-A12分别写入L-Bank地址、行地址，激活特定L-Bank的特定行；
2. 激活指令写入后，等待tRCD时间，此过程中操作命令保持为空操作命令；
3. tRCD等待时间结束后，写入写数据指令，同时A0-A8写入数据的列首地址；
4. 读数据指令写入同时，由DQ开始写入数据，在最后一个数据写入后的下一个时钟写入突发终止指令；
5. 突发终止指令写入后， SDRAM的页突发写操作完成。
*/ 
//

module sdram_write(
    input               sys_clk,
    input               sys_rst,

    input               init_end,
    input               wr_en,
    input       [23:0]  wr_addr,        // 高2位为数据写入位置的逻辑Bank地址，中间13位为数据写入位置行地址，后9位为数据突发写入首地址
    input       [15:0]  wr_data,
    input       [9:0]   wr_burst_len,

    output              wr_act,
    output              wr_end,
    output reg  [3:0]   write_cmd,
    output reg  [1:0]   write_ba,
    output reg  [12:0]  write_addr,
    output reg          wr_sdram_en,
    output      [15:0]  wr_sdram_data
);

// 定义各状态参数
localparam  WR_IDLE = 4'b0000 ,     //初始状态
            WR_ACTIVE = 4'b0001 ,   //激活
            WR_TRCD = 4'b0011 ,     //激活等待
            WR_WRITE = 4'b0010 ,    //写操作
            WR_DATA = 4'b0100 ,     //写数据
            WR_PRE = 4'b0101 ,      //预充电
            WR_TRP = 4'b0111 ,      //预充电等待
            WR_END = 4'b0110 ;      //一次突发写结束
// 定义状态内保持的时钟周期数
localparam  TRCD_CLK = 10'd2,
            TRP_CLK = 10'd2;
// 定义输出状态类型
localparam  NOP = 4'b0111 ,         //空操作指令
            ACTIVE = 4'b0011 ,      //激活指令
            WRITE = 4'b0100 ,       //数据写指令
            B_STOP = 4'b0110 ,      //突发停止指令
            P_CHARGE = 4'b0010 ;    //预充电指令    

wire        trp_end;
wire        trcd_end;
wire        twrite_end;

reg [9:0]   cnt_clk;
reg         cnt_clk_rst;
reg [2:0]   write_state;


// 激活等待状态结束标志信号
assign trcd_end = ((write_state == WR_ACTIVE) && (cnt_clk == TRCD_CLK)) ? 1'b1 : 1'b0;
// 写数据结束标志信号
assign twrite_end = ((write_state == WR_DATA) && (cnt_clk == wr_burst_len - 1)) ? 1'b1 : 1'b0;
// 预充电等待状态结束标志信号
assign trp_end = ((write_state == WR_TRP) && (cnt_clk == TRP_CLK)) ? 1'b1 : 1'b0;

// 数据写响应信号
// 1. 告知主控制模块一次突发写操作已经完成，页突发写操作首地址可以更新；
// 2. 作为主控制模块中写 fifo 的读使能信号，读出数据为本模块输入数据信号 wr_data
// 进入写状态后置一，为使 wr_data 与 WR_DATA 状态同步。wr_act 应超前 WR_DATA 一个时钟周期 
assign wr_act = (((write_state == WR_WRITE) || (write_state == WR_DATA)) && (cnt_clk == wr_burst_len - 2'd2)) ? 
                1'b1 : 1'b0;

// 写操作结束信号
assign wr_end = (write_state == WR_END) ? 1'b1 : 1'b0;


// 时钟周期计数器
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        cnt_clk <= 0;
    end
    else if (cnt_clk_rst) begin
        cnt_clk <= 10'b0;
    end
    else begin
        cnt_clk <= cnt_clk + 1'b1;
    end
end


// 写状态机跳转
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        write_state <= 0;
    end
    else begin
        case(write_state)
            WR_IDLE: begin
                if((init_end == 1'b1) && (wr_en == 1'b1)) begin
                    write_state <= WR_ACTIVE;
                end
                else begin
                    write_state <= WR_IDLE;
                end
            end
            WR_ACTIVE: begin
                write_state <= WR_TRCD;
            end
            WR_TRCD: begin
                if(trcd_end) begin
                    write_state <= WR_WRITE;
                end
                else begin
                    write_state <= write_state;
                end
            end
            WR_WRITE: begin
                write_state <= WR_DATA;
            end
            WR_DATA: begin
                if(twrite_end) begin
                    write_state <= WR_PRE;
                end
                else begin
                    write_state <= write_state;
                end
            end
            WR_PRE: begin
                write_state <= WR_TRP;
            end
            WR_TRP: begin
                if(trp_end) begin
                    write_state <= WR_END;
                end
                else begin
                    write_state <= write_state;
                end
            end
            WR_END: begin
                write_state <= WR_IDLE;
            end
            default: write_state <= WR_IDLE;
        endcase
    end
end


// 计数器清零信号
always @(*) begin
    case(write_state)
        WR_IDLE: cnt_clk_rst <= 1'b1;
        WR_ACTIVE: cnt_clk_rst <= 1'b0;
        WR_TRCD: cnt_clk_rst <= (trcd_end == 1'b1) ? 1'b1 : 1'b0;
        WR_WRITE: cnt_clk_rst <= 1'b1;
        WR_DATA: cnt_clk_rst <= (twrite_end == 1'b1) ? 1'b1 : 1'b0;
        WR_PRE: cnt_clk_rst <= 1'b0;
        WR_TRP: cnt_clk_rst <= (trp_end == 1'b1) ? 1'b1 : 1'b0;
        WR_END: cnt_clk_rst <= 1'b1;
    endcase
end


// 输出指令、逻辑 Bank 地址和地址总线信号
always @(posedge sys_clk or negedge sys_rst) begin
    if(sys_rst) begin
        write_cmd <= 0;
        write_ba <= 0;
        write_addr <= 0;
    end
    else begin
        case(write_state)
            WR_IDLE, WR_TRCD, WR_TRP: begin
                write_cmd <= NOP;
                write_ba <= 2'b11;              // 
                write_addr <= 13'h1FFF;
            end
            WR_ACTIVE: begin
                write_cmd <= ACTIVE;
                write_ba <= wr_addr[23:22];     // 写入逻辑 bank 地址
                write_addr <= wr_addr[21:9];    // 写入行地址
            end
            WR_WRITE: begin
                write_cmd <= WRITE;
                write_ba <= wr_addr[23:22];     
                write_addr <= {4'b0000, wr_addr[8:0]};// 写入列首地址
            end
            WR_DATA: begin                      // 突发传输终止
                if(twrite_end == 1'b1) begin    // 如果写状态保持了突发长度个周期，则发送突发终止指令
                    write_cmd <= B_STOP;
                end
                else begin
                    write_cmd <= NOP;
                    write_ba <= 2'b11;
                    write_addr <= 13'h1FFF;
                end
            end
            WR_PRE: begin
                write_cmd <= P_CHARGE;
                write_ba <= wr_addr[23:22];
                write_addr <= 13'h0400;
            end
            WR_END: begin
                write_cmd <= NOP;
                write_ba <= 2'b11;
                write_addr <= 13'h1fff;
            end
            default: begin
                write_cmd <= NOP;
                write_ba <= 2'b11;
                write_addr <= 13'h1fff;
            end
        endcase
    end
end


// 数据总线输出使能
// SDRAM 此时作输入功能
always@(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        wr_sdram_en <= 1'b0;
    end
    else begin
        wr_sdram_en <= wr_act;
    end
end


// 写入 SDRAM 的数据
// 由 wr_ack 控制的 wr_sdram_en 来控制数据传出（传入 SDRAM）
assign wr_sdram_data = (wr_sdram_en == 1'b1) ? wr_data : 16'd0;


endmodule