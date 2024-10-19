# 紫光 FPGA 的一些项目

  * 开发平台：PGL50H-6FBG484
  * 软件：PDS 2022.2 Lite

## ddr3_test

生成自增的数据通过 AXI 送入 DDR，请通过逻辑分析仪观察信号。

## fifo_test

生成自增的数据存储到 FIFO 中，并在写满后开始读，你可以仿真 `test_fifo_test.v` 通过 ModelSim 查看空满、几乎空满信号的时序情况，以及在写满之后 FIFO 的工作情况。

## hdmi_pcie_trans

该项目使用 PCIE 将采集的 HDMI 视频信号传输至上位机，由于采用 HDMI-VESA 时序，因此你可以较方便地将项目迁移为摄像头图像传输。

请注意，你需确保上位机安装的系统版本为 **Ubuntu 20.04.x** 或更低版本。