`timescale 1ns/1ps
module testbench_fulladder(

);

  reg  [3:0]    A;
  reg  [3:0]    B;
  reg           Cin;
  wire [3:0]    Sum;
  wire          Cout;

  FourBitAdder DUT (
    .A      (A),
    .B      (B),
    .Cin    (Cin),
    .Sum    (Sum),
    .Cout   (Cout)
  );

  initial begin
    // �����ʼֵ
    A = 4'b0;
    B = 4'b0;
    Cin = 1'b0;

    // �ȴ�һЩʱ�䣬��ȷ����·�ȶ�
    #1000;

    A = 4'b0101;
    B = 4'b0010;

    #500;

    A = 4'b1111;
    B = 4'b1100;
    Cin = 1'b1;

    #500;

    
    #10;

    // ��������
    $stop;

  end

endmodule
