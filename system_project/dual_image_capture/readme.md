# ���� FPGA ��˫Ŀͼ��ɼ�ϵͳ

������̫������˫Ŀ����ͷ��ͼ�����ݡ�

ʹ�õ�ƽ̨��

  * �Ϲ�ͬ�� PGL50H-6FBG484
  * PDS 2022.2Lite

## �����������

| �� | ֵ |
| :---: | :---: |
| ͼ��ͨ���� | 2 |
| ���ͼ��ֱ��� | $1280 \times 720$ |
| ���ͼ��֡�� | 15FPS |

## �ֿ�Ŀ¼

```
  |-- FPGA
    |-- constraint.fdc                // Լ���ļ�
  |-- project.old                     
    |-- ov5640_ethernet_transfer      // ˫Ŀ����ͷ�����ļ�
    |-- trans_ddr                     // ���ݴ洢�� ddr �ķ��湤���ļ�
  |-- RTL                             
    |-- testbench                     // ����ļ�����֤ƽ̨����
  |-- Software                        // ��������ʾ��̫�����͵�˫Ŀ����ͷ����
```

## ��ʶ

����Ŀ�� cmos1 �� cmos2 �����ݰ�֡ǰ�����ʹ�� UDP ���ͣ����Ϊ����������ͷͨ������ÿ֡�ʼ�����˶�������ݡ������·�� `../Python/udp_video_dual.py` �ҵ���ص�ͼ�������롣��ʼ��ʶ����������ʾ��

| ͨ�� | ֡ͨ����ʶ�� | ֡��Ч������ʼ��ʶ�� | ֡��Ч���ݽ�����ʶ�� |
| :---: | :---: | :---: | :---: |
| cmos1 | \xff\xa1\xff\xa1 | \xff\xd8 | \xff\xd9 |
| cmos2 | \xff\xa2\xff\xa2 | \xff\xd8 | \xff\xd9 |