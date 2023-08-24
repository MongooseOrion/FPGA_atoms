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
    input      [23:0]   rd_addr,
    input      [15:0]   rd_data,

    output              rd_ack,
    output              rd_end,
    output reg []
);