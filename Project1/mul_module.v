module mul(
    input       mul_a       ,
    input       mul_b       ,
    input       sysclk      ,
    input       rst         ,
    output      mul_result
);

// ������
parameter A_W = 4           ;
parameter B_W = 3           ;
parameter C_W = A_W + B_W   ;

reg  [C_W-1:0]  mul_result_tmp;

wire [A_W-1:0]  mul_a       ;
wire [B_W-1:0]  mul_b       ;
reg  [C_W-1:0]  mul_result  ;


// ����߼�
always@(*)
begin
    mul_result_tmp = mul_a*mul_b;
end

// ʱ���߼�
always@(posedge sysclk or negedge rst)
begin
    if(rst==1) begin
        mul_result <= 0;
    end
    else begin
        mul_result <= mul_result_tmp;
    end
end

endmodule