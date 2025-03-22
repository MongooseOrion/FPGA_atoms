# 项目简介

  * [音频数据 UDP 传输输出](./audio_ethernet_trans/)
  * [OV5640 摄像头（单目）采集图像 UDP 传输输出](./cam_ethernet_trans/)
  * [OV5640 摄像头（双目半速）采集图像 UDP 传输输出](./dual_image_capture/)
  * [千兆 UDP 数据双向传输](./ethernet_full_duplex_subsystem/)
  * [RS232 串口数据传输回环](./uart_duplex_module/)

请注意，以太网传输的相关项目均使用 RTL8211EG 以太网 PHY 芯片，通过 RGMII 接口与 FPGA 进行数据通信，请确认可用性。