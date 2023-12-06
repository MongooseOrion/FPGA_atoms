//
// �������ź���ʹ���ź�Ϊ��ʱ���������������ź�Ϊ 4 ·����ģ�黯˼·����
//

module top_counter(
    input               clk,
    input               rst,
    input       [3:0]   pulse,
    input               en_count,
    output      [15:0]   count1,
    output      [15:0]   count2,
    output      [15:0]   count3,
    output      [15:0]   count4
);

// ���� pulse[0] �ļ���ģ��
counterfour counter_check1(
    .clk        (clk),
    .rst        (rst),
    .pulse      (pulse[0]),
    .en_count   (en_count),
    .count      (count1)
);

// ���� pulse[1] �ļ���ģ��
counterfour counter_check2(
    .clk        (clk),
    .rst        (rst),
    .pulse      (pulse[1]),
    .en_count   (en_count),
    .count      (count2)
);

// ���� pulse[2] �ļ���ģ��
counterfour counter_check3(
    .clk        (clk),
    .rst        (rst),
    .pulse      (pulse[2]),
    .en_count   (en_count),
    .count      (count3)
);

// ���� pulse[3] �ļ���ģ��
counterfour counter_check4(
    .clk        (clk),
    .rst        (rst),
    .pulse      (pulse[3]),
    .en_count   (en_count),
    .count      (count4)
);

endmodule