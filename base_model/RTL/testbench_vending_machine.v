//
// �Զ�������״̬����Ƶ���֤ƽ̨����
//

`timescale 1ns/1ps
module testbench_vending_machine(

);

parameter CLK_PEROID = 10;

reg         clk;
reg         rst;
reg         i_one_cny;
reg         i_two_cny;
reg         i_five_cny;

wire        o_done;


// ���Ӳ���ƽ̨
vending_machine vending_machine_test(
    .clk        (clk),
    .rst        (rst),
    .i_one_cny  (i_one_cny),
    .i_two_cny  (i_two_cny),
    .i_five_cny (i_five_cny),
    .o_done     (o_done)
);


// ��ʼ��ʱ�Ӻ͸�λ
initial begin
    clk <= 0;
    rst <= 0;
    i_one_cny <= 0;
    i_two_cny <= 0;
    i_five_cny <= 0;
    #1000;
    rst <= 1;

end
always #(CLK_PEROID/2) clk=~clk;


// �������Լ���
initial begin
    @(posedge rst);
    @(posedge clk);

    #100;
    i_one_cny <= 1;

    #1000;
    i_two_cny <= 1;

    #1000;
    i_five_cny <= 1;

    #1000;
    rst <= 0;

    #1000;
    i_five_cny <= 1;

    #1000;
    i_one_cny <= 1;

end

endmodule

