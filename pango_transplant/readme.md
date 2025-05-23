# 基于紫光 FPGA 的一些项目

由于核心部分均采用 IP 核，或者 RTL 大量采用原语，因此此处的项目不建议迁移到除下述所列出的其他环境中运行，请自行确认可用性。

  * 开发平台：PGL50H-6FBG484
  * 软件：PDS 2022.2 Lite

## ddr3_test

生成自增的数据通过 AXI 送入 DDR，以便查看 DDR 时序。请自行通过逻辑分析仪观察信号。

## fifo_test

生成自增的数据存储到 FIFO 中，并在写满后开始读，你可以仿真 `test_fifo_test.v` 通过 ModelSim 查看空满、几乎空满信号的时序情况，以及在写满之后 FIFO 的工作情况。

## pcie_triple_trans

该项目使用 PCIe 将 FPGA 采集的三路信号同时传输至上位机，已兼容 OV5640、HDMI 和音频信号传输。

由于我们采用的是类似 `VESA` 的时序（即数据流使用行场同步信号来指示帧）来传输数据，因此你可以通过更改或自定义生成行场同步信号来扩展支持各类其他的媒体信号。

请注意，你需确保上位机安装的系统版本为 **Ubuntu 20.04.x** 或更低版本，否则驱动程序将不能运行。