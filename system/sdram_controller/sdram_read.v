//
// SDRAM 读控制模块
/* SDRAM页突发读操作的具体流程：
1. 发送激活指令到SDRAM，同时BA0-BA1、A0-A12分别写入L-Bank地址、行地址，激活特定L-Bank的特定行；
2. 激活指令写入后，等待tRCD时间，此过程中操作命令保持为空操作命令；
3. tRCD等待时间结束后，写入读数据指令，同时A0-A8写入数据读取首地址；
4. 读数据指令写入后，随机跳转到潜伏状态，等待潜伏期结束，DQ开始输出读取数据，设读取数据个数为N；
5. 自读指令写入周期的下个时钟周期开始计数，N个时钟周期后，写入突发停止指令，终止数据读操作；
6. 突发停止指令写入后，DQ数据输出，数据输出完成后，SDRAM的页突发读操作完成。
*/
//

module sdram_read(
    input               sys_clk,
    input               sys_rst,
    input               init_end,
    input               rd_en,
    input       [23:0]  rd_addr,
    input       [15:0]  rd_data,
    input       [9:0]   rd_burst_len,

    output              rd_ack,
    output              rd_end,

    output reg  [3:0]   read_cmd,
    output reg  [1:0]   read_ba,
    output reg  [12:0]  read_addr,
    output reg  [15:0]  rd_sdram_data
);

// 各状态等待周期
localparam  TRCD_CLK = 10'd2 ,  //激活等待周期
            TCL_CLK = 10'd3 ,   //潜伏期
            TRP_CLK = 10'd2 ;   //预充电等待周期
// 各状态参数
localparam  RD_IDLE = 4'b0000 , 
            RD_ACTIVE = 4'b0001 , 
            RD_TRCD = 4'b0011 , 
            RD_READ = 4'b0010 , 
            RD_CL = 4'b0100 , 
            RD_DATA = 4'b0101 , 
            RD_PRE = 4'b0111 , 
            RD_TRP = 4'b0110 , 
            RD_END = 4'b1100 ; 
// 输出指令
localparam  NOP = 4'b0111 ,     // 空操作指令
            ACTIVE = 4'b0011 ,  // 激活指令
            READ = 4'b0101 ,    // 数据读指令
            B_STOP = 4'b0110 ,  // 突发停止指令
            P_CHARGE = 4'b0010; // 预充电指令

wire        trp_end;
wire        trcd_end;
wire        tcl_end;
wire        tread_end; 
wire        rd_burst_end; 

reg [2:0]   read_state;
reg [9:0]   cnt_clk;
reg         cnt_clk_rst;

// 激活等待结束标志信号
assign trcd_end = (cnt_clk == TRCD_CLK) ? 1'b1 : 1'b0;
// 潜伏期等待结束标志信号
assign tcl_end = (cnt_clk == TCL_CLK) ? 1'b1 : 1'b0;
// 读数据状态结束信号
// 读指令发出后有 3 个时钟周期的潜伏期，所以需要加上 3 个时钟周期，在最后一个 rd_burst_len 时钟拉高信号
assign tread_end = ((read_state == RD_DATA) && (cnt_clk == rd_burst_len + 'd2)) ? 1'b1 : 1'b0;
// 预充电状态结束信号
assign trp_end = (cnt_clk == TRP_CLK) ? 1'b1 : 1'b0;

// 控制突发终止指令写入
// 读突发 SDRAM 字节数，读取指令送入到有效数据读出有 3 个时钟周期延迟，所以要求读取 rd_burst_len 位
// 数据就应该在进入 RD_DATA 状态后 rd_burst_len - 1 - 3 个时钟拉高结束信号
assign rd_burst_end = ((read_state == RD_DATA) && (cnt_clk == rd_burst_len - 'd4)) ? 1'b1 : 1'b0;


// 状态等待时钟周期计数
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


// 状态跳转
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        read_state <= 0;
    end
    else begin
        case(read_state)
            RD_IDLE: begin                          // 初始状态
                if((init_end == 1'b1) && (rd_en == 1'b1)) begin
                    read_state <= RD_ACTIVE;
                end
                else begin
                    read_state <= RD_IDLE;
                end
            end
            RD_ACTIVE: begin                        // 激活状态
                read_state <= RD_TRCD;
            end
            RD_TRCD: begin                          // 激活等待状态
                if(trcd_end) begin
                    read_state <= RD_READ;
                end
                else begin
                    read_state <= read_state;
                end
            end
            RD_READ: begin                          // 读指令状态
                read_state <= RD_CL;
            end
            RD_CL: begin                            // 潜伏期
                if(tcl_end) begin
                    read_state <= RD_DATA;
                end
                else begin
                    read_state <= read_state;
                end
            end
            RD_DATA: begin                          // 读数据状态
                if(tread_end) begin
                    read_state <= RD_PRE;
                end
                else begin
                    read_state <= read_state;
                end
            end
            RD_PRE: begin                           // 预充电状态
                read_state <= RD_TRP;
            end
            RD_TRP: begin                           // 预充电等待
                if(trp_end) begin
                    read_state <= RD_END;           // 预充电完成，激活行关闭
                end
                else begin
                    read_state <= read_state;
                end
            end
            RD_END: begin
                read_state <= RD_IDLE;              // 等待下一次读操作
            end
            default: begin
                read_state <= RD_IDLE;
            end
        endcase
    end
end


// 计数时钟清零信号设计
/*always @(*) begin
    case(read_state)

end*/



endmodule