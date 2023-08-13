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

    output reg [3:0]    init_cmd,
    output reg [1:0]    init_ba,
    output reg [12:0]   init_addr,
    output              init_end
);

localparam  T_POWER = 15'd20_000;   // 设置上电时钟等待 200us
localparam  P_CHARGE = 4'b0010,     // 预充电指令
            AUTO_REF = 4'b0001,     // 自动刷新指令
            NOP = 4'b0111 ,         // 空操作指令
            M_REG_SET = 4'b0000 ;   // 模式寄存器设置指令

// SDRAM初始化过程各个状态
localparam  INIT_IDLE = 3'b000 ,    //初始状态
            INIT_PRE = 3'b001 ,     //预充电状态
            INIT_TRP = 3'b011 ,     //预充电等待 tRP
            INIT_AR = 3'b010 ,      //自动刷新
            INIT_TRF = 3'b100 ,     //自动刷新等待 tRC
            INIT_MRS = 3'b101 ,     //模式寄存器设置
            INIT_TMRD = 3'b111 ,    //模式寄存器设置等待 tMRD
            INIT_END = 3'b110 ;     //初始化完成

localparam  TRP_CLK = 3'd2 ,        //预充电等待周期,20ns
            TRC_CLK = 3'd7 ,        //自动刷新等待,70ns
            TMRD_CLK = 3'd3 ;       //模式寄存器设置等待周期,30ns

reg 