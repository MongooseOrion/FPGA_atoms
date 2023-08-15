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

    output reg  [3:0]   aref_cmd,
    output reg  [1:0]   aref_ba,
    output reg  [12:0]  aref_addr,
    output              aref_end
);


// 
localparam  = ;


reg [9:0]   cnt_ref;
reg []



// 周期计数，以周期性执行自动刷新操作
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        cnt_ref <= 0
    end
    else if (cnt_ref < 'd750) begin
        cnt_ref <= cnt_ref + 1'b1;
    end
    else begin
        cnt_ref <= 10'b0;
    end
end

endmodule