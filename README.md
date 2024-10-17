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

```
  ./pango_transplant/hbird_e203           // 移植蜂鸟 E203 RISC-V 到紫光同创平台
  ./system_project/cam_ethernet_trans     // OV5640（单目）采集图像 UDP 传输
  ./system_project/dual_image_capture     // OV5640（双目）采集图像 UDP 传输
  ./system_project/audio_ethernet_trans   // 音频输入，以太网音频数据传输
```

[点此](./system_project/readme.md)进入项目目录。

## 技术文档目录

  * [AMBA-AHB 总线介绍](./document/ahb_interface.md)
  * [AMBA-AXI4 总线介绍](./document/axi_interface.md)
  * [TCP/IP 以太网传输模型介绍](./document/ethernet_udp_trans.md)
  * [I2C 两线通信总线介绍](./document/i2c.md)
  * [SPI 四线通信总线介绍](./document/spi.md)