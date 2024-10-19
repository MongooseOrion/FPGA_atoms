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
# FPGA 原子仓库

为了减少仓库数量，在此处集合了较小的 FPGA 项目。该仓库遵循 MIT 许可证开源，请在该许可范围内使用本项目中的部分或全部内容。

## 仓库目录

```
  |-- base_ip                       // 包含一些基础 IP
  |-- document                      // 一些技术文档
  |-- pango_transplant              // 紫光同创 FPGA 移植项目和 IP 核时序测试例程
  |-- xilinx_transplant             // 赛灵思 FPGA 移植项目和 IP 核时序测试例程
  |-- system_project                // 用于各种用途的 FPGA 项目
```

## 重要项目简要

  * [移植蜂鸟 E203 RISC-V 到紫光同创平台](./pango_transplant/hbird_e203/)
  * [紫光 PCIE 图像数据传输](./pango_transplant/hdmi_pcie_trans/)
  * [OV5640（单目）采集图像 UDP 传输](./system_project/cam_ethernet_trans/)
  * [OV5640（双目半速）采集图像 UDP 传输](./system_project/dual_image_capture/)
  * [以太网音频数据传输](./system_project/audio_ethernet_trans/)

你可以[点此](./system_project/)进入系统项目目录。

## 技术文档目录

  * [AMBA-AHB 总线介绍](./document/ahb_interface.md)
  * [AMBA-AXI4 总线介绍](./document/axi_interface.md)
  * [TCP/IP 以太网传输模型介绍](./document/ethernet_udp_trans.md)
  * [I2C 两线通信总线介绍](./document/i2c.md)
  * [SPI 四线通信总线介绍](./document/spi.md)