# FPGA 原子仓库

这个仓库用于存储我创建的一些小的项目，为了减少仓库数量，在此处集合较小的 FPGA 系统。在创建这些项目的过程中，离不开下述企业或组织在网络上发布的教程，特此鸣谢：

  * Alinx（芯驿电子）
  * 芯来科技
  * 野火
  * 小眼睛半导体

该仓库遵循 MIT 许可证开源，请在该许可范围内使用本项目中的部分或全部内容。

## 仓库目录

```
  |-- base_model                    // Verilog 最基础的模块，对于已经具备 FPGA 经验的人没有必要点开
  |-- pango_transplant              // 紫光同创 FPGA 移植项目
  |-- system_project                // 用于各种用途的 FPGA 项目
```

## 重要项目简要

```
  ../pango/hbird_e203               // 移植蜂鸟 E203 RISC-V 到紫光同创平台
  ../system/image_capture           // OV5640 采集图像 UDP 传输
  ../system/audio_ethernet_trans    // 音频输入，以太网音频数据传输
```