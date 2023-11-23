//
// SDRAM ������ģ��
/* SDRAMҳͻ���������ľ������̣�
1. ���ͼ���ָ�SDRAM��ͬʱBA0-BA1��A0-A12�ֱ�д��L-Bank��ַ���е�ַ�������ض�L-Bank���ض��У�
2. ����ָ��д��󣬵ȴ�tRCDʱ�䣬�˹����в��������Ϊ�ղ������
3. tRCD�ȴ�ʱ�������д�������ָ�ͬʱA0-A8д�����ݶ�ȡ�׵�ַ��
4. ������ָ��д��������ת��Ǳ��״̬���ȴ�Ǳ���ڽ�����DQ��ʼ�����ȡ���ݣ����ȡ���ݸ���ΪN��
5. �Զ�ָ��д�����ڵ��¸�ʱ�����ڿ�ʼ������N��ʱ�����ں�д��ͻ��ָֹͣ���ֹ���ݶ�������
6. ͻ��ָֹͣ��д���DQ������������������ɺ�SDRAM��ҳͻ����������ɡ�
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

// ��״̬�ȴ�����
localparam  TRCD_CLK = 10'd2 ,  //����ȴ�����
            TCL_CLK = 10'd3 ,   //Ǳ����
            TRP_CLK = 10'd2 ;   //Ԥ���ȴ�����
// ��״̬����
localparam  RD_IDLE = 4'b0000 , 
            RD_ACTIVE = 4'b0001 , 
            RD_TRCD = 4'b0011 , 
            RD_READ = 4'b0010 , 
            RD_CL = 4'b0100 , 
            RD_DATA = 4'b0101 , 
            RD_PRE = 4'b0111 , 
            RD_TRP = 4'b0110 , 
            RD_END = 4'b1100 ; 
// ���ָ��
localparam  NOP = 4'b0111 ,     // �ղ���ָ��
            ACTIVE = 4'b0011 ,  // ����ָ��
            READ = 4'b0101 ,    // ���ݶ�ָ��
            B_STOP = 4'b0110 ,  // ͻ��ָֹͣ��
            P_CHARGE = 4'b0010; // Ԥ���ָ��

wire        trp_end;
wire        trcd_end;
wire        tcl_end;
wire        tread_end; 
wire        rd_burst_end; 

reg [2:0]   read_state;
reg [9:0]   cnt_clk;
reg         cnt_clk_rst;

// ����ȴ�������־�ź�
assign trcd_end = (cnt_clk == TRCD_CLK) ? 1'b1 : 1'b0;
// Ǳ���ڵȴ�������־�ź�
assign tcl_end = (cnt_clk == TCL_CLK) ? 1'b1 : 1'b0;
// ������״̬�����ź�
// ��ָ������� 3 ��ʱ�����ڵ�Ǳ���ڣ�������Ҫ���� 3 ��ʱ�����ڣ������һ�� rd_burst_len ʱ�������ź�
assign tread_end = ((read_state == RD_DATA) && (cnt_clk == rd_burst_len + 'd2)) ? 1'b1 : 1'b0;
// Ԥ���״̬�����ź�
assign trp_end = (cnt_clk == TRP_CLK) ? 1'b1 : 1'b0;

// ����ͻ����ָֹ��д��
// ��ͻ�� SDRAM �ֽ�������ȡָ�����뵽��Ч���ݶ����� 3 ��ʱ�������ӳ٣�����Ҫ���ȡ rd_burst_len λ
// ���ݾ�Ӧ���ڽ��� RD_DATA ״̬�� rd_burst_len - 1 - 3 ��ʱ�����߽����ź�
assign rd_burst_end = ((read_state == RD_DATA) && (cnt_clk == rd_burst_len - 'd4)) ? 1'b1 : 1'b0;


// ״̬�ȴ�ʱ�����ڼ���
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


// ״̬��ת
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        read_state <= 0;
    end
    else begin
        case(read_state)
            RD_IDLE: begin                          // ��ʼ״̬
                if((init_end == 1'b1) && (rd_en == 1'b1)) begin
                    read_state <= RD_ACTIVE;
                end
                else begin
                    read_state <= RD_IDLE;
                end
            end
            RD_ACTIVE: begin                        // ����״̬
                read_state <= RD_TRCD;
            end
            RD_TRCD: begin                          // ����ȴ�״̬
                if(trcd_end) begin
                    read_state <= RD_READ;
                end
                else begin
                    read_state <= read_state;
                end
            end
            RD_READ: begin                          // ��ָ��״̬
                read_state <= RD_CL;
            end
            RD_CL: begin                            // Ǳ����
                if(tcl_end) begin
                    read_state <= RD_DATA;
                end
                else begin
                    read_state <= read_state;
                end
            end
            RD_DATA: begin                          // ������״̬
                if(tread_end) begin
                    read_state <= RD_PRE;
                end
                else begin
                    read_state <= read_state;
                end
            end
            RD_PRE: begin                           // Ԥ���״̬
                read_state <= RD_TRP;
            end
            RD_TRP: begin                           // Ԥ���ȴ�
                if(trp_end) begin
                    read_state <= RD_END;           // Ԥ�����ɣ������йر�
                end
                else begin
                    read_state <= read_state;
                end
            end
            RD_END: begin
                read_state <= RD_IDLE;              // �ȴ���һ�ζ�����
            end
            default: begin
                read_state <= RD_IDLE;
            end
        endcase
    end
end


// ����ʱ�������ź����
/*always @(*) begin
    case(read_state)

end*/



endmodule