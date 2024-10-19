<!-- =====================================================================
* Copyright (c) 2023, MongooseOrion.
* All rights reserved.
*
* The following code snippet may contain portions that are derived from
* OPEN-SOURCE communities, and these portions will be licensed with: 
*
* <NULL>
*
* If there is no OPEN-SOURCE licenses are listed, it indicates none of
* content in this Code document is sourced from OPEN-SOURCE communities. 
*
* In this case, the document is protected by copyright, and any use of
* all or part of its content by individuals, organizations, or companies
* without authorization is prohibited, unless the project repository
* associated with this document has added relevant OPEN-SOURCE licenses
* by github.com/MongooseOrion. 
*
* Please make sure using the content of this document in accordance with 
* the respective OPEN-SOURCE licenses. 
* 
* THIS CODE IS PROVIDED BY https://github.com/MongooseOrion. 
* FILE ENCODER TYPE: GBK
* ========================================================================
-->
# FPGA ԭ�Ӳֿ�

Ϊ�˼��ٲֿ��������ڴ˴������˽�С�� FPGA ��Ŀ���òֿ���ѭ MIT ���֤��Դ�����ڸ���ɷ�Χ��ʹ�ñ���Ŀ�еĲ��ֻ�ȫ�����ݡ�

## �ֿ�Ŀ¼

```
  |-- base_ip                       // ����һЩ���� IP
  |-- document                      // һЩ�����ĵ�
  |-- pango_transplant              // �Ϲ�ͬ�� FPGA ��ֲ��Ŀ�� IP ��ʱ���������
  |-- xilinx_transplant             // ����˼ FPGA ��ֲ��Ŀ�� IP ��ʱ���������
  |-- system_project                // ���ڸ�����;�� FPGA ��Ŀ
```

## ��Ҫ��Ŀ��Ҫ

  * [��ֲ���� E203 RISC-V ���Ϲ�ͬ��ƽ̨](./pango_transplant/hbird_e203/)
  * [�Ϲ� PCIE ͼ�����ݴ���](./pango_transplant/hdmi_pcie_trans/)
  * [OV5640����Ŀ���ɼ�ͼ�� UDP ����](./system_project/cam_ethernet_trans/)
  * [OV5640��˫Ŀ���٣��ɼ�ͼ�� UDP ����](./system_project/dual_image_capture/)
  * [��̫����Ƶ���ݴ���](./system_project/audio_ethernet_trans/)

�����[���](./system_project/)����ϵͳ��ĿĿ¼��

## �����ĵ�Ŀ¼

  * [AMBA-AHB ���߽���](./document/ahb_interface.md)
  * [AMBA-AXI4 ���߽���](./document/axi_interface.md)
  * [TCP/IP ��̫������ģ�ͽ���](./document/ethernet_udp_trans.md)
  * [I2C ����ͨ�����߽���](./document/i2c.md)
  * [SPI ����ͨ�����߽���](./document/spi.md)