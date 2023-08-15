//
// SDRAM �Զ�ˢ��ģ��
//
/* �Զ�ˢ�²����ο��������£�
1. д��Ԥ������A10����Ϊ�ߵ�ƽ��������L-Bank����Ԥ��磻
2. Ԥ���ָ��д��󣬵ȴ�tRPʱ�䣬�˹����в��������Ϊ�ղ������
3. tRP�ȴ�ʱ�������д���Զ�ˢ�����
4. �Զ�ˢ������д��󣬵ȴ�tRCʱ�䣬�˹����в��������Ϊ�ղ������
5. tRC�ȴ�ʱ��������ٴ�д���Զ�ˢ�����
6. �Զ�ˢ������д��󣬵ȴ�tRCʱ�䣬�˹����в��������Ϊ�ղ������
7. tRC�ȴ�ʱ��������Զ�ˢ�²�����ɡ�
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



// ���ڼ�������������ִ���Զ�ˢ�²���
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