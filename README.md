# FPGA 原子仓库

这个仓库用于存储我创建的一些小的项目，为了减少仓库数量，在此处集合较小的 FPGA 系统。在创建这些项目的过程中，离不开下述企业或组织在网络上发布的教程，特此鸣谢：

  * Alinx（芯驿电子）
  * 芯来科技
  * 野火
  * 小眼睛半导体

该仓库遵循 MIT 许可证开源，请在该许可范围内使用本项目中的部分或全部内容。

## 仓库目录

```
  |-- base_model                    // Verilog 最基础的模块，对于已经具备 FPGA 经验的人没有必要查看
  |-- document                      // 一些技术文档
  |-- pango_transplant              // 紫光同创 FPGA 移植项目和 IP 核时序测试例程
  |-- xilinx_transplant             // 赛灵思 FPGA 移植项目和 IP 核时序测试例程
  |-- system_project                // 用于各种用途的 FPGA 项目
```

## 重要项目简要

```
  ../pango/hbird_e203               // 移植蜂鸟 E203 RISC-V 到紫光同创平台
  ../system/cam_ethernet_trans      // OV5640（单目）采集图像 UDP 传输
  ../system/audio_ethernet_trans    // 音频输入，以太网音频数据传输
```

## 技术文档目录

  * [AMBA-AHB 总线介绍](./document/ahb_interface.md)
  * [AMBA-AXI4 总线介绍](./document/axi_interface.md)
  * [TCP/IP 以太网传输模型介绍](./document/ethernet_udp_trans.md)
  * [I2C 两线通信总线介绍](./document/i2c.md)
  * [SPI 四线通信总线介绍](./document/spi.md)