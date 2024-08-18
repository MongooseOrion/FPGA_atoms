# 基于 FPGA 的双目图像采集系统

利用以太网传输双目摄像头的图像数据。

使用的平台：

  * 紫光同创 PGL50H-6FBG484
  * PDS 2022.2Lite

## 输入输出参数

| 键 | 值 |
| :---: | :---: |
| 图像通道数 | 2 |
| 输出图像分辨率 | $1280 \times 720$ |
| 输出图像帧率 | 15FPS |

## 仓库目录

```
  |-- FPGA
    |-- constraint.fdc                // 约束文件
  |-- project.old                     
    |-- ov5640_ethernet_transfer      // 双目摄像头工程文件
    |-- trans_ddr                     // 数据存储到 ddr 的仿真工程文件
  |-- RTL                             
    |-- testbench                     // 设计文件的验证平台代码
  |-- Software                        // 解析并显示以太网发送的双目摄像头数据
```

## 标识

此项目将 cmos1 与 cmos2 的数据按帧前后编组使用 UDP 发送，因此为了区分摄像头通道，在每帧最开始加入了额外的数据。你可在路径 `../Python/udp_video_dual.py` 找到相关的图像编码代码。起始标识符如下述所示：

| 通道 | 帧通道标识符 | 帧有效数据起始标识符 | 帧有效数据结束标识符 |
| :---: | :---: | :---: | :---: |
| cmos1 | \xff\xa1\xff\xa1 | \xff\xd8 | \xff\xd9 |
| cmos2 | \xff\xa2\xff\xa2 | \xff\xd8 | \xff\xd9 |