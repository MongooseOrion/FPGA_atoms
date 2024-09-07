# FPGA ԭ�Ӳֿ�

����ֿ����ڴ洢�Ҵ�����һЩС����Ŀ��Ϊ�˼��ٲֿ��������ڴ˴����Ͻ�С�� FPGA ϵͳ���ڴ�����Щ��Ŀ�Ĺ����У��벻��������ҵ����֯�������Ϸ����Ľ̳̣��ش���л��

  * Alinx��о����ӣ�
  * о���Ƽ�
  * Ұ��
  * С�۾��뵼��

�òֿ���ѭ MIT ���֤��Դ�����ڸ���ɷ�Χ��ʹ�ñ���Ŀ�еĲ��ֻ�ȫ�����ݡ�

## �ֿ�Ŀ¼

```
  |-- base_ip                       // ����һЩ���� IP
  |-- document                      // һЩ�����ĵ�
  |-- pango_transplant              // �Ϲ�ͬ�� FPGA ��ֲ��Ŀ�� IP ��ʱ���������
  |-- xilinx_transplant             // ����˼ FPGA ��ֲ��Ŀ�� IP ��ʱ���������
  |-- system_project                // ���ڸ�����;�� FPGA ��Ŀ
```

## ��Ҫ��Ŀ��Ҫ

```
  ./pango_transplant/hbird_e203           // ��ֲ���� E203 RISC-V ���Ϲ�ͬ��ƽ̨
  ./system_project/cam_ethernet_trans     // OV5640����Ŀ���ɼ�ͼ�� UDP ����
  ./system_project/dual_image_capture     // OV5640��˫Ŀ���ɼ�ͼ�� UDP ����
  ./system_project/audio_ethernet_trans   // ��Ƶ���룬��̫����Ƶ���ݴ���
```

## �����ĵ�Ŀ¼

  * [AMBA-AHB ���߽���](./document/ahb_interface.md)
  * [AMBA-AXI4 ���߽���](./document/axi_interface.md)
  * [TCP/IP ��̫������ģ�ͽ���](./document/ethernet_udp_trans.md)
  * [I2C ����ͨ�����߽���](./document/i2c.md)
  * [SPI ����ͨ�����߽���](./document/spi.md)