//
// SDRAM д����ģ��
/* SDRAMҳͻ��д���������̣�
1. ���ͼ���ָ�SDRAM��ͬʱBA0-BA1��A0-A12�ֱ�д��L-Bank��ַ���е�ַ�������ض�L-Bank���ض��У�
2. ����ָ��д��󣬵ȴ�tRCDʱ�䣬�˹����в��������Ϊ�ղ������
3. tRCD�ȴ�ʱ�������д��д����ָ�ͬʱA0-A8д�����ݵ����׵�ַ��
4. ������ָ��д��ͬʱ����DQ��ʼд�����ݣ������һ������д������һ��ʱ��д��ͻ����ָֹ�
5. ͻ����ָֹ��д��� SDRAM��ҳͻ��д������ɡ�
*/ 
//

module sdram_write(
    input               sys_clk,
    input               sys_rst,

    input               init_end,
    input               wr_en,
    input       [23:0]  wr_addr,        // ��2λΪ����д��λ�õ��߼�Bank��ַ���м�13λΪ����д��λ���е�ַ����9λΪ����ͻ��д���׵�ַ
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

// �����״̬����
localparam  WR_IDLE = 4'b0000 ,     //��ʼ״̬
            WR_ACTIVE = 4'b0001 ,   //����
            WR_TRCD = 4'b0011 ,     //����ȴ�
            WR_WRITE = 4'b0010 ,    //д����
            WR_DATA = 4'b0100 ,     //д����
            WR_PRE = 4'b0101 ,      //Ԥ���
            WR_TRP = 4'b0111 ,      //Ԥ���ȴ�
            WR_END = 4'b0110 ;      //һ��ͻ��д����
// ����״̬�ڱ��ֵ�ʱ��������
localparam  TRCD_CLK = 10'd2,
            TRP_CLK = 10'd2;
// �������״̬����
localparam  NOP = 4'b0111 ,         //�ղ���ָ��
            ACTIVE = 4'b0011 ,      //����ָ��
            WRITE = 4'b0100 ,       //����дָ��
            B_STOP = 4'b0110 ,      //ͻ��ָֹͣ��
            P_CHARGE = 4'b0010 ;    //Ԥ���ָ��    

wire        trp_end;
wire        trcd_end;
wire        twrite_end;

reg [9:0]   cnt_clk;
reg         cnt_clk_rst;
reg [2:0]   write_state;


// ����ȴ�״̬������־�ź�
assign trcd_end = ((write_state == WR_ACTIVE) && (cnt_clk == TRCD_CLK)) ? 1'b1 : 1'b0;
// д���ݽ�����־�ź�
assign twrite_end = ((write_state == WR_DATA) && (cnt_clk == wr_burst_len - 1)) ? 1'b1 : 1'b0;
// Ԥ���ȴ�״̬������־�ź�
assign trp_end = ((write_state == WR_TRP) && (cnt_clk == TRP_CLK)) ? 1'b1 : 1'b0;

// ����д��Ӧ�ź�
// 1. ��֪������ģ��һ��ͻ��д�����Ѿ���ɣ�ҳͻ��д�����׵�ַ���Ը��£�
// 2. ��Ϊ������ģ����д fifo �Ķ�ʹ���źţ���������Ϊ��ģ�����������ź� wr_data
// ����д״̬����һ��Ϊʹ wr_data �� WR_DATA ״̬ͬ����wr_act Ӧ��ǰ WR_DATA һ��ʱ������ 
assign wr_act = (((write_state == WR_WRITE) || (write_state == WR_DATA)) && (cnt_clk == wr_burst_len - 2'd2)) ? 
                1'b1 : 1'b0;

// д���������ź�
assign wr_end = (write_state == WR_END) ? 1'b1 : 1'b0;


// ʱ�����ڼ�����
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


// д״̬����ת
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


// �����������ź�
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


// ���ָ��߼� Bank ��ַ�͵�ַ�����ź�
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
                write_ba <= wr_addr[23:22];     // д���߼� bank ��ַ
                write_addr <= wr_addr[21:9];    // д���е�ַ
            end
            WR_WRITE: begin
                write_cmd <= WRITE;
                write_ba <= wr_addr[23:22];     
                write_addr <= {4'b0000, wr_addr[8:0]};// д�����׵�ַ
            end
            WR_DATA: begin                      // ͻ��������ֹ
                if(twrite_end == 1'b1) begin    // ���д״̬������ͻ�����ȸ����ڣ�����ͻ����ָֹ��
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


// �����������ʹ��
// SDRAM ��ʱ�����빦��
always@(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        wr_sdram_en <= 1'b0;
    end
    else begin
        wr_sdram_en <= wr_act;
    end
end


// д�� SDRAM ������
// �� wr_ack ���Ƶ� wr_sdram_en ���������ݴ��������� SDRAM��
assign wr_sdram_data = (wr_sdram_en == 1'b1) ? wr_data : 16'd0;


endmodule