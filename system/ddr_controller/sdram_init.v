//
// SDRAM ��ʼ��ģ��
/* SDRAM ��ʼ�����̣�
    1. �� SDRAM �ϵ磬�����ȶ�ʱ���źţ�CKE ����Ϊ�ߵ�ƽ��
    2. �ȴ� T>=100us ��ʱ�䣬�˹����в��������Ϊ�ղ������
    3. 100us�ȴ�������д��Ԥ������A10����Ϊ�ߵ�ƽ��������L-Bank����Ԥ��磻
    4. Ԥ���ָ��д��󣬵ȴ�tRPʱ�䣬�˹����в��������Ϊ�ղ������
    5. tRP�ȴ�ʱ�������д���Զ�ˢ�����
    6. �Զ�ˢ������д��󣬵ȴ�tRCʱ�䣬�˹����в��������Ϊ�ղ������
    7. tRC�ȴ�ʱ��������ٴ�д���Զ�ˢ�����
    8. �Զ�ˢ������д��󣬵ȴ�tRCʱ�䣬�˹����в��������Ϊ�ղ������
    9. tRC�ȴ�ʱ�������д��ģʽ�Ĵ�������ָ���ַ����A0-A11������ͬ����ģʽ�Ĵ�����ͬģʽ�����ã�
    10. ģʽ�Ĵ�������ָ��д��󣬵ȴ�tMRDʱ�䣬�˹����в��������Ϊ�ղ������
    11. tMRD�ȴ�ʱ�������SDRAM��ʼ����ɡ�
*/
//
//

module sdram_init #()(

    input               sys_clk,    // 100MHz
    input               sys_rst,

    output reg [3:0]    init_cmd,   // ��ʼ����д�� SDRAM ��ָ��
    output reg [1:0]    init_ba,    // ��ʼ���� Bank ��ַ
    output reg [12:0]   init_addr,  // ��ַ����
    output              init_end    // ��ʼ�������ź�
);

localparam  T_POWER = 15'd20_000;   // �����ϵ�ʱ�ӵȴ� 200us
localparam  P_CHARGE = 4'b0010,     // Ԥ���ָ��
            AUTO_REF = 4'b0001,     // �Զ�ˢ��ָ��
            NOP = 4'b0111 ,         // �ղ���ָ��
            M_REG_SET = 4'b0000 ;   // ģʽ�Ĵ�������ָ��

// SDRAM��ʼ�����̸���״̬
localparam  INIT_IDLE = 3'b000 ,    // ��ʼ״̬
            INIT_PRE = 3'b001 ,     // Ԥ���״̬
            INIT_TRP = 3'b011 ,     // Ԥ���ȴ� tRP
            INIT_AR = 3'b010 ,      // �Զ�ˢ��
            INIT_TRF = 3'b100 ,     // �Զ�ˢ�µȴ� tRC
            INIT_MRS = 3'b101 ,     // ģʽ�Ĵ�������
            INIT_TMRD = 3'b111 ,    // ģʽ�Ĵ������õȴ� tMRD
            INIT_END = 3'b110 ;     // ��ʼ�����
// Ԥ��ĵȴ�ʱ������
localparam  TRP_CLK = 3'd2 ,        // Ԥ���ȴ�����, 20ns
            TRC_CLK = 3'd7 ,        // �Զ�ˢ�µȴ�, 70ns
            TMRD_CLK = 3'd3 ;       // ģʽ�Ĵ������õȴ�����, 30ns


wire        wait_end;
wire        trp_end;
wire        trc_end;
wire        tmrd_end;

reg  [15:0] cnt_200us;
reg  [2:0]  init_state;
reg  [2:0]  cnt_clk;
reg         cnt_clk_rst;
reg  [3:0]  cnt_init_aref;

// SDRAM ��ʼ������ź�
assign init_end = (init_state == INIT_END) ? 1'b1 : 1'b0;
// Ԥ���ȴ�������־
assign trp_end = ((cnt_clk == TRP_CLK) && (init_state == INIT_TRP)) ? 1'b1 : 1'b0;
// �Զ�ˢ�µȴ�״̬������־
assign trc_end = ((cnt_clk == TRC_CLK) && (init_state == INIT_TRF)) ? 1'b1 : 1'b0;
// ģʽ�Ĵ������õȴ�������־
assign tmrd_end = ((cnt_clk == TMRD_CLK) && (init_state == INIT_TMRD)) ? 1'b1 : 1'b0;


// �ȶ�ʱ�Ӽ������ϵ�ȴ� 200us
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
assign wait_end = (cnt_200us == T_POWER - 1'b1) ? 1'b1 : 1'b0; // �ϵ�� 200us �ȴ�������־


// ��¼��ʼ����״̬��ʱ�����ڣ��Ա��ڸ�״̬��ת
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


// ��ʼ�������Զ�ˢ�´�������������ʼ��������Ҫ���� >= 2 ���Զ�ˢ�²���
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



// SDRAM ״̬��������ת
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        init_state <= 0;
    end
    else begin
        case(init_state)
            INIT_IDLE: begin            // �ڵȴ� 200us ����ת��Ԥ���״̬
                if(wait_end) begin
                    init_state <= INIT_PRE;
                end
                else begin
                    init_state <= init_state;
                end
            end
            INIT_PRE: begin             // ֱ����ת��Ԥ���ȴ�״̬
                init_state <= INIT_TRP;
            end
            INIT_TRP: begin             // �ȴ��趨ʱ������(2)�������Ԥ���׶Σ�Ȼ����ת���Զ�ˢ�½׶�
                if(trp_end) begin
                    init_state <= INIT_AR;
                end
                else begin
                    init_state <= init_state;
                end
            end
            INIT_AR: begin              // ֱ����ת���Զ�ˢ�µȴ�״̬
                init_state <= INIT_TRF;
            end
            INIT_TRF: begin             // �ȴ��趨ʱ������(7)��Ȼ����� 8 ���Զ�ˢ�£�Ȼ���������ģʽ�Ĵ���״̬
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
            INIT_MRS: begin             // ֱ����ת������ģʽ�Ĵ���״̬
                init_state <= INIT_TMRD;
            end
            INIT_TMRD: begin            // �ȴ��趨ʱ������(3)���������ģʽ�Ĵ�����Ȼ������ʼ�����״̬
                if(tmrd_end) begin
                    init_state <= INIT_END;
                end
                else begin
                    init_state <= init_state;
                end
            end
            INIT_END: begin             // ��ʼ�����״̬
                init_state <= INIT_END;
            end
            default: init_state <= INIT_IDLE;
        endcase
    end
end


// cnt_clk �����ź�
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


// SDRAM ����ָ�����
// ��ʼ���׶��߼� Bank ��ַ init_ba����ʼ���׶ε�ַ���� init_addr����״̬������
// ����ģʽ�Ĵ���״̬(INIT_MRS)ʱ���ֱ�д���߼�Bank��ַ��ģʽ�Ĵ������õ���ز�����
// ����״̬���߾�д��ȫ 1��
always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) begin
        init_cmd <= NOP;
        init_ba <= 2'b11;
        init_addr <= 13'h1fff;
    end
    else begin
        case(init_state)
            INIT_IDLE,INIT_TRP,INIT_TRF,INIT_TMRD: begin    //ִ�пղ���ָ��
                init_cmd <= NOP;
                init_ba <= 2'b11;
                init_addr <= 13'h1fff;
            end
            INIT_PRE: begin                                 //Ԥ���ָ��
                init_cmd <= P_CHARGE;
                init_ba <= 2'b11;
                init_addr <= 13'h1fff;
            end
            INIT_AR: begin                                  //�Զ�ˢ��ָ��
                init_cmd <= AUTO_REF;
                init_ba <= 2'b11;
                init_addr <= 13'h1fff;
            end
            INIT_MRS: begin                                 //ģʽ�Ĵ�������ָ��
                init_cmd <= M_REG_SET;
                init_ba <= 2'b00;
                init_addr <= { // ��ַ��������ģʽ�Ĵ���
                    3'b000, // A12-A10:Ԥ��
                    1'b0,   // A9=0:��д��ʽ,0:ͻ����&ͻ��д,1:ͻ����&��д
                    2'b00,  // {A8,A7}=00:��׼ģʽ,Ĭ��
                    3'b011, // {A6,A5,A4}=011:CASǱ����,010:2,011:3,����:����
                    1'b0,   // A3=0:ͻ�����䷽ʽ,0:˳��,1:����
                    3'b111  // {A2,A1,A0}=111:ͻ������,000:���ֽ�,001:2�ֽ�,010:4�ֽ�,011:8�ֽ�,111:��ҳ,����:����
                };
            end
            INIT_END: begin                                 //SDRAM��ʼ�����
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


// ��ʼ�������ź�
assign init_end = (init_state == INIT_END) ? 1'b1 : 1'b0;


endmodule