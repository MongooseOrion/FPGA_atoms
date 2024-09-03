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
# I2C 协议描述

IIC 是一种两线式串行总线，由数据线 SDA 和时钟线 SCL 构成，其中 SDA 是 `inout` 接口，因此 IIC 是一种半双工通信协议。

传输速率：标准模式达 100kbit/s，快速模式达 400kbit/s，快速模式+达 1Mbps，高速模式达 3.4Mbit/s。

## 通信方式

在空闲状态下，SCL 和 SDA 都为高电平。SCL 输出高电平时，SDA 由高到低变化为开始传输标志。SCL 为高电平，SDA 再出现上升沿，表示传输结束。对于收方响应信号，如果是自行设置的收方设备，可以考虑 `SDA_in <= 1'b0` 表示响应。否则可以考虑在此处保持 `SDA_out` 不赋值的空闲状态即可。

<div align='center'><img src='.\pic\屏幕截图 2024-07-26 154134.png' width='600px'></div>

## 时序要求

注意，不同的器件可能有不同的 I2C 时序限制，下述表格描述了 EEPROM 芯片 I2C 整个读写周期受到时序限制的参数：

<table>
  <thead>
    <tr>
      <th rowspan="3">参数</th>
      <th rowspan="3">缩写</th>
      <th colspan="2">快速模式</th>
      <th colspan="2">高速模式</th>
      <th rowspan="3">单位</th>
    </tr>
    <tr>
      <th colspan="2">V<sub>CC</sub> = 1.7V ~ 2.5V</th>
      <th colspan="2">V<sub>CC</sub> = 2.5V ~ 5.5V</th>
    </tr>
    <tr>
      <th>最小值</th>
      <th>最大值</th>
      <th>最小值</th>
      <th>最大值</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>时钟频率 SCL</td>
      <td>f<sub>SCL</sub></td>
      <td>-</td>
      <td>400</td>
      <td>-</td>
      <td>1000</td>
      <td>kHz</td>
    </tr>
    <tr>
      <td>时钟脉冲低电平宽度</td>
      <td>t<sub>LOW</sub></td>
      <td>1,200</td>
      <td>-</td>
      <td>500</td>
      <td>-</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>时钟脉冲高电平宽度</td>
      <td>t<sub>HIGH</sub></td>
      <td>600</td>
      <td>-</td>
      <td>400</td>
      <td>-</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>输入滤波尖峰抑制</td>
      <td>t<sub>I</sub></td>
      <td>-</td>
      <td>100</td>
      <td>-</td>
      <td>50</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>时钟低电平到数据输出有效时间</td>
      <td>t<sub>AA</sub></td>
      <td>100</td>
      <td>900</td>
      <td>50</td>
      <td>450</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>停止与开始之间的总线空闲时间</td>
      <td>t<sub>BUF</sub></td>
      <td>1200</td>
      <td>-</td>
      <td>500</td>
      <td>-</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>起始保持时间</td>
      <td>t<sub>HD.STA</sub></td>
      <td>600</td>
      <td>-</td>
      <td>250</td>
      <td>-</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>起始建立时间</td>
      <td>t<sub>SU.STA</sub></td>
      <td>600</td>
      <td>-</td>
      <td>250</td>
      <td>-</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>SDA in 保持时间</td>
      <td>t<sub>HD.DAT</sub></td>
      <td>0</td>
      <td>-</td>
      <td>0</td>
      <td>-</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>SDA in 建立时间</td>
      <td>t<sub>SU.DAT</sub></td>
      <td>100</td>
      <td>-</td>
      <td>100</td>
      <td>-</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>输入上升时间</td>
      <td>t<sub>R</sub></td>
      <td>-</td>
      <td>300</td>
      <td>-</td>
      <td>300</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>输入下降时间</td>
      <td>t<sub>F</sub></td>
      <td>-</td>
      <td>300</td>
      <td>-</td>
      <td>100</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>STOP 信号建立时间</td>
      <td>t<sub>SU.STO</sub></td>
      <td>600</td>
      <td>-</td>
      <td>250</td>
      <td>-</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>SDA out 保持时间</td>
      <td>t<sub>DH</sub></td>
      <td>50</td>
      <td>-</td>
      <td>50</td>
      <td>-</td>
      <td>ns</td>
    </tr>
    <tr>
      <td>写周期时间</td>
      <td>t<sub>WR</sub></td>
      <td>-</td>
      <td>5</td>
      <td>-</td>
      <td>5</td>
      <td>ms</td>
    </tr>
  </tbody>
</table>

时序图如下图所示：

<div align='center'><img src='.\pic\屏幕截图 2024-07-25 180009.png' width='600px'></div>

### 可能的预设配置

快速模式：400kHz， $t_{\text{high}} = 1250\text{ns}$ ， $t_{\text{low}} = 1250\text{ns}$ ， `SDA_out` 每次变化位置在 `SCL` 低电平中间。

## I2C 写流程

下述描述的为 EEPROM 的 I2C 读写流程，但是一般来说，通过总线传输数据都应该包含目标地址和有效数据两个部分，因此不同器件的 I2C 数据交互应该是类似的。

写流程时序图如下图所示：

<div align='center'><img src='.\pic\屏幕截图 2024-07-26 151700.png' width='600px'></div>

  * 在开始写之前，请先保证 `SCL` 和 `SDA_out` 为高，然后将 `SDA_out` 拉低且 `SCL` 下降沿采集到其低电平后开始写流程。

  * 在结束写时，请先在收到响应信号后将 `SDA_out` 置为低，在 `SCL` 最后一个上升沿采集到其低电平后再将 `SDA_out` 置为高，以便标识 `STOP` 。响应信号由 `SDA_in` 给出。

<div align='center'><img src='.\pic\屏幕截图 2024-07-26 183339.png' width='500px'></div>

每次写操作，都需要发送 3 个字节的数据，第一个字节表示从设备的设备 ID，第二个字节表示写地址，第三个字节是要写入的数据。某些设备支持按页写入，请参见后续的传输流程描述。

对于从设备 ID 的 8 位数据， `[7:4]` 表示设备类型标识符， `[3:1]` 表示硬件接入地址， `[0]` 表示读写指示。对于读操作，最低位应该置为高，对于写操作，最低位应该置为低。

如果是某些物理器件，应该会有专门的设备类型标识符和硬件地址，这可能需要查看该器件的手册和原理图才可以知道。一般而言，硬件地址将在原理图上标识为 $A_2 A_1 A_0$ ，如果它们全接地，则表示硬件地址为 `000` 。

对于写地址的 8 位数据，应该查看相关硬件手册的地址范围。某些器件的地址范围可能超出 1 个字节，请参见后续的传输流程。

在每次发送完一字节的数据后，需要等待从设备发出写响应信号，或者空闲一个时钟周期。

### 按地址写入数据

  1. 主机产生并发送起始信号到从机，将控制命令写入从机设备，读写控制位设置为低电平，表示对从机进行数据写操作，控制命令的写入高位在前低位在后；
  2. 从机接收到控制指令后，回传应答信号，主机接收到应答信号后开始存储地址的写入。若为 2 字节地址，顺序执行操作；若为单字节地址跳转到步骤(5)；
  3. 先向从机写入高8位地址，且高位在前低位在后；
  4. 待接收到从机回传的应答信号，再写入低 8 位地址，且高位在前低位在后，若为 2 字节地址，跳转到步骤(6)；
  5. 按高位在前低位在后的顺序写入单字节存储地址；
  6. 地址写入完成，主机接收到从机回传的应答信号后，开始单字节数据的写入；
  7. 单字节数据写入完成，主机接收到应答信号后，向从机发送停止信号，单字节数据写入完成。

### 按页写入数据

在上述描述中，主机只能向从机中写入一次数据；在页写操作中，主机一次可向从机写入多字节数据，数据量不可超过分页地址，具体取决于设备支持。

  1. 主机产生并发送起始信号到从机，将控制命令写入从机设备，读写控制位设置为低电平，表示对从机进行数据写操作，控制命令的写入高位在前低位在后；
  2. 从机接收到控制指令后，回传应答信号，主机接收到应答信号后开始存储地址的写入。若为2字节地址，顺序执行操作；若为单字节地址跳转到步骤(5)；
  3. 先向从机写入高8位地址，且高位在前低位在后；
  4. 待接收到从机回传的应答信号，再写入低 8 位地址，且高位在前低位在后，若为 2 字节地址，跳转到步骤(6)；
  5. 按高位在前低位在后的顺序写入单字节存储地址；
  6. 地址写入完成，主机接收到从机回传的应答信号后，开始第一个单字节数据的写入；
  7. 数据写入完成，主机接收到应答信号后，开始下一个单字节数据的写入；
  8. 数据写入完成，主机接收到应答信号。若所有数据均写入完成，顺序执行操作流程；若数据尚未完成写入，跳回到步骤(7)；
  9. 主机向从机发送停止信号，页写操作完成。

## I2C 读流程

读流程的时序图如下图所示：

<div align='center'><img src='.\pic\屏幕截图 2024-07-26 165630.png' width='600px'></div>

  * 在开始读之前，需要将 `SCL` 和 `SDA_out` 置为高，然后将 `SDA_out` 拉低且 `SCL` 下降沿采集到其低电平后开始读流程。

  * 在读操作时，需要先发一个字节的从设备 ID，注意此时最低位应该发写指示，然后下一个字节发要读的地址。在完成两个字节的传输后，需要将 `SCL` 和 `SDA_out` 置为高，重新开始 `START` 流程，然后重新发一个字节的从设备 ID，注意此时最低位应该发读指示，然后下一个字节由 `SDA_in` 发出，注意此时响应信号由 `SDA_out` 发出。

  * 如果顺序读，则将 `SDA_out <= 1'b0` 以便继续读取，此时 `SDA_in` 继续传入数据。如果该地址的数据全部接收完毕，由 `SDA_out <= 1'b1` 发出响应信号标识读流程完成。注意，在发出 `SDA_out <= 1'b1` 后，需要将其重新置为低，当 `SCL` 最后一个上升沿采集到低电平后，再将 `SDA_out` 置为高，以便标识 `STOP` 。

<div align='center'><img src='.\pic\屏幕截图 2024-07-26 183351.png' width='600px'></div>