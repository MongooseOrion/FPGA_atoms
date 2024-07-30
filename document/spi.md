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
* FILE ENCODER TYPE: UTF-8
* ========================================================================
-->
# SPI 协议描述

SPI 包含 1 条时钟信号线： `SCK` 、2 条数据总线： `MISO` （主输入从输出） `MOSI` （主输出从输入）和 1 条片选信号线 `CS` 。在一主多从的情况下，可以通过连接多条 `CS{index}` 信号线来使主设备使能相关从设备。当 `CS` 为低电平时，使能设备。

## SPI 时钟触发模式

<div align='center'><img src='.\pic\SPIFla004.png' width='550px'></div>

SPI 数据信号的采样模式可以由时钟极性（ `CPOL` ，Clock Polarity）和时钟相位（ `CPHA` ，Clock Phase）来控制，具体如下：

  * `CPOL=0 CPHA=0` ：空闲状态下 `SCK` 为低电平，数据采样方式为 `SCK` 的上升沿；
  * `CPOL=0 CPHA=1` ：空闲状态下 `SCK` 为低电平，数据采样方式为 `SCK` 的下降沿；
  * `CPOL=1 CPHA=0` ：空闲状态下 `SCK` 为高电平，数据采样方式为 `SCK` 的下降沿；
  * `CPOL=1 CPHA=1` ：空闲状态下 `SCK` 为高电平，数据采样方式为 `SCK` 的上升沿；

## 时序要求

| 符号          | 替代名称     | 参数                                              | 最小值 | 典型值 | 最大值 | 单位 |
|--------------|-------------|--------------------------------------------------|--------|--------|--------|------|
| $f_\text{C}$     | $f_\text{C}$     | 以下指令的时钟频率：FAST_READ, PP, SE, BE, DP, RES, WREN, WRDI, RDID, RDSR, WRSR | D.C.   | -      | 50     | MHz  |
| $f_\text{R}$     | $f_\text{R}$     | 读取指令的时钟频率                                  | D.C.   | -      | 20     | MHz  |
| $t_{\text{CH}}$ | $t_{\text{CLH}}$ | 时钟高电平时间                                     | 9      | -      | -      | ns   |
| $t_{\text{CL}}$ | $t_{\text{CLL}}$ | 时钟低电平时间                                     | 9      | -      | -      | ns   |
| $t_{\text{CLCH}}$ | -           | 时钟上升时间（峰值）                               | -      | -      | 0.1    | V/ns |
| $t_{\text{CHCL}}$ | -           | 时钟下降时间（峰值）                               | -      | -      | 0.1    | V/ns |
| $t_{\text{SLCH}}$  | $t_{\text{CSS}}$ | $\overline{S}$ 相对于 C 的激活建立时间                | 5      | -      | -      | ns   |
| $t_{\text{SHSL}}$  | $t_{\text{CSH}}$ | $\overline{S}$ 相对于 C 的非激活保持时间                | 5      | -      | -      | ns   |
| $t_{\text{DVCH}}$  | $t_{\text{DSU}}$ | 数据输入建立时间                                    | 5      | -      | -      | ns   |
| $t_{\text{CHDX}}$  | $t_{\text{DH}}$  | 数据输入保持时间                                    | 5      | -      | -      | ns   |
| $t_{\text{CHSH}}$  | $t_{\text{CSH}}$ | $\overline{S}$ 相对于 C 的激活保持时间                | 5      | -      | -      | ns   |
| $t_{\text{SHCH}}$  | -           | $\overline{S}$ 相对于 C 的非激活建立时间                | 5      | -      | -      | ns   |
| $t_{\text{SHSL}}$  | $t_{\text{CSH}}$ | $\overline{S}$ 取消选择时间                           | -      | -      | 100    | ns   |

<div align='center'><img src='.\pic\屏幕截图 2024-07-29 193902.png' width='600px'></div>

## SPI 写流程

此处以 flash 示例，但应该与其他数据交互的硬件没有区别。

### 页写 

某些硬件支持按页写入数据，这样可以在发送一次地址后连续写。注意，写入的数据不能超出分页地址位置，否则会指向该页首地址重新覆盖写入。

使用 `CPOL=0 CPHA=0` 模式，时序图如下图所示：

<div align='center'><img src='.\pic\屏幕截图 2024-07-30 151749.png' width='550px'></div>

其中，对于控制指令的传输方式，不同的器件可能有不同的要求。在 flash 中，要进行页写，需要依次发送两次指令：写使能指令和页写指令，同时在发送写使能指令后需要将片选信号拉高，然后重新拉低片选信号，再发送页写指令，如下图所示。

<div align='center'><img src='.\pic\SPIFla065.png' width='600px'></div>

### 写入单字节

不同器件可能有不同的随机写指令，请参见相关的器件手册。在 flash 中，控制写入单个字节的数据，可以直接使用页写指令写入一个数据后，**停止** `SCK` 信号发信，并在满足等待时序要求后拉高片选信号即可。

下图描述了顺序写时的波形图：

<div align='center'><img src='.\pic\SPIFla068.png' width='600px'></div>

下图描述了随机写时的波形图：

<div align='center'><img src='.\pic\SPIFla085.png' width='600px'></div>

## SPI 读流程

<div align='center'><img src='.\pic\屏幕截图 2024-07-30 154107.png' width='600px'></div>

flash 读时，只需发一个读控制命令，而无需在它之前发其他命令。若主机读取从机的数据，则 `MOSI` 发送控制命令和地址数据， `MISO` 接收读取到的有效数据。注意，如果 `SCK` 不停止，则会一直往给定地址后继续读取数据，若最高位地址内数据读取完成，会自动跳转到芯片首地址继续进行数据读取。

如果需要停止读取，应该停止 `SCK` 信号发信，并拉高 `CS` 信号。