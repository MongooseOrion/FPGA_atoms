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
    output reg          aref_req,
    output reg  [3:0]   aref_cmd,
    output reg  [1:0]   aref_ba,
    output reg  [12:0]  aref_addr,
    output              aref_end
);

// �Զ�ˢ�µȴ�ʱ��
localparam CNT_REF_MAX = 10'd749;   // 7.5us
// �����״̬
localparam  AREF_IDLE = 3'b000 ,    // ��ʼ״̬,�ȴ��Զ�ˢ��ʹ��
            AREF_PCHA = 3'b001 ,    // Ԥ���״̬
            AREF_TRP = 3'b011 ,     // Ԥ���ȴ� tRP
            AUTO_REF = 3'b010 ,     // �Զ�ˢ��״̬
            AREF_TRF = 3'b100 ,     // �Զ�ˢ�µȴ� tRC
            AREF_END = 3'b101 ;     // �Զ�ˢ�½���
// ����ĳЩ״̬�ĵȴ�����
localparam  TRP_CLK = 3'd2 ,        // Ԥ���ȴ�����
            TRC_CLK = 3'd7 ;        // �Զ�ˢ�µȴ�����
// ����ָ��
localparam  P_CHARGE = 4'b0010 ,    // Ԥ���ָ��
            A_REF = 4'b0001 ,       // �Զ�ˢ��ָ��
            NOP = 4'b0111 ;         // �ղ���ָ��


wire        trp_end;
wire        trc_end;
wire        aref_act;

reg [9:0]   cnt_ref;
reg [2:0]   aref_state;
reg [2:0]   cnt_clk;
reg         cnt_clk_rst;
reg [1:0]   cnt_aref_aref;


// Ԥ���ȴ�״̬�������Զ�ˢ�µȴ�״̬������־�ź�
assign trp_end = ((aref_state == AREF_TRP) && (cnt_clk == TRP_CLK)) ? 1'b1 : 1'b0;
assign trc_end = ((aref_state == AREF_TRF) && (cnt_clk == TRC_CLK)) ? 1'b1 : 1'b0;
// �Զ�ˢ����Ӧ�ź�
assign aref_act = (aref_state == AREF_PCHA) ? 1'b1 : 1'b0;


// ״̬����תʱ�Ӽ���
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


// ���ڼ�������������ִ���Զ�ˢ�²���
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


// ����Զ�ˢ�������źţ��������ٲ�ģ�鷢���Զ�ˢ��ʹ���ź�
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


// �Զ�ˢ�´���������
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


// ״̬����ת����
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        aref_state <= 0;
    end
    else begin
        case(aref_state)
            AREF_IDLE: begin                         // �Զ�ˢ��ʹ���źŽ�����ܿ�ʼ��ת
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
            AREF_TRF: begin                         // �ȴ� 7 ��ʱ���������һ���Զ�ˢ�£���Ҫ��������Զ�ˢ��
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


// ʱ�����ڼ�����λ��־
always @(*) begin
    case (aref_state)
        AREF_IDLE: cnt_clk_rst <= 1'b1; 
        AREF_TRP: cnt_clk_rst <= (trp_end == 1'b1) ? 1'b1 : 1'b0;
        AREF_TRF: cnt_clk_rst <= (trc_end == 1'b1) ? 1'b1 : 1'b0;
        AREF_END: cnt_clk_rst <= 1'b1;
        default: cnt_clk_rst <= 1'b0;
    endcase
end


// SDRAM����ָ�����
always@(posedge sys_clk or negedge sys_rst) begin
    if(sys_rst == 1'b0) begin
        aref_cmd <= NOP;
        aref_ba <= 2'b11;
        aref_addr <= 13'h1fff;
    end
    else begin
        case(aref_state)
            AREF_IDLE,AREF_TRP,AREF_TRF: begin      // ִ�пղ���ָ��
                aref_cmd <= NOP;
                aref_ba <= 2'b11;
                aref_addr <= 13'h1fff;
            end
            AREF_PCHA: begin                        // Ԥ���ָ��
                aref_cmd <= P_CHARGE;
                aref_ba <= 2'b11;
                aref_addr <= 13'h1fff;
            end
            AUTO_REF: begin                         // �Զ�ˢ��ָ��
                aref_cmd <= A_REF;
                aref_ba <= 2'b11;
                aref_addr <= 13'h1fff;
            end
            AREF_END: begin                         // һ���Զ�ˢ�����
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