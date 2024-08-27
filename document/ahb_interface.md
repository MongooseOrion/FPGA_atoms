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
# AHB 总线接口描述

## AHB FULL

FULL 表示具备完整 AHB 接口的总线。下表显示了相关的接口：

#### 主设备接口信号

| 接口名称 | 位宽 | 方向 | 描述 |
| :--- | :---: | :---: |  :--- |
| HADDR | ADDR_WIDTH | output | 地址总线，主设备用来指定要访问的存储地址。 |
| HTRANS | [1:0] | output | 传输类型，指定当前传输的类型（IDLE, BUSY, NONSEQ, SEQ）。 |
| HSIZE | [2:0] | output | 传输大小，指定当前传输的数据字节数（如字节、半字、字）。 |
| HBURST | [2:0] | output | 突发类型，指定突发传输的类型（如单次传输、4次突发等）。 |
| HPROT | [3:0] | output | 保护类型，指定传输的保护属性（如缓存属性、特权级别等）。 |
| HWSTRB | DATA_WIDTH/8 | output | 指定传输的数据哪些字节有效，有效位为 1，无效位为 0 |
| HWRITE | 1bit | output | 写使能信号，指示当前传输是读操作还是写操作。 |
| HWDATA | DATA_WIDTH | output | 写数据总线，主设备通过该信号发送要写入的数据。| 
| HMASTLOCK | 1bit | output | 主设备锁定信号，用于指示当前主设备是否锁定总线。 |
| HREADY | 1bit | input | 准备信号，指示当前总线传输是否完成。 |
| HRDATA | DATA_WIDTH | input | 读数据总线，从设备通过该信号发送要读取的数据。 |
| HRESP | 1bit | input | 响应信号，指示传输的状态（OKAY、ERROR等）。 |

#### 从设备接口信号

| 接口名称 | 位宽 | 方向 | 描述 |
| :--- | :---: | :---: | :--- |
| HADDR | ADDR_WIDTH | input | 地址总线，从设备接收主设备发送的存储地址。 |
| HTRANS | [1:0] | input | 传输类型，从设备接收主设备发送的传输类型。 |
| HSIZE | [2:0] | input | 传输大小，从设备接收主设备发送的数据字节数。 |
| HBURST | [2:0] | input | 突发类型，从设备接收主设备发送的突发类型。 |
| HPROT | [3:0] | input | 保护类型，从设备接收主设备发送的保护属性。 |
| HWRITE | 1bit | input | 写使能信号，从设备接收主设备发送的读写操作指示。 |
| HWDATA | DATA_WIDTH | input | 写数据总线，从设备接收主设备发送的数据。 |
| HREADYOUT | 1bit | output | 准备输出信号，从设备用来指示当前传输是否完成。 |
| HRDATA | DATA_WIDTH | output | 读数据总线，从设备通过该信号发送数据给主设备。 |
| HRESP | 1bit | output | 响应信号，从设备用来指示传输的状态。 |

### AHB 控制信号

  * `HWRITE` ：若为高电平，则表示主设备往从设备写数据；若为低电平，则表示主设备往从设备读数据；
  * `HTRANS` ：见下表

| `HTRANS[1:0]` | 类型 | 描述 |
| :--- | :---: | :--- |
| IDLE 空闲传输 | 2'b00 | 此状态表示当前没有有效的传输，主设备不发送任何数据或命令。从设备可以忽略此状态下的所有总线信号。 |
| BUSY 忙碌传输 | 2'b01 | 此状态表示主设备在执行一个突发传输过程中需要延迟的周期。从设备保持当前状态，不进行新的数据传输，但准备好继续后续的传输。 |
| NONSEQ 非顺序传输 | 2'b10 | 这是一个独立的传输，与之前的传输无关。每一个新的突发传输都以 `NONSEQ` 状态开始。 |
| SEQ 顺序传输 | 2'b11 | 这表示当前传输是一个突发传输中的一部分，地址和控制信号是连续的。从设备在接收到 `SEQ` 传输类型后，会识别这是突发传输的一部分，并继续处理数据。 |

  * `HMASTLOCK` ：（适用于多主多从）当 `HMASTLOCK` 信号被断言（通常为高电平）时，表示当前主设备需要锁定总线。这意味着在当前传输完成之前，其他主设备不能获得总线控制权。当 `HMASTLOCK` 断言、`HSEL` 断言（如果存在）且 `HREADY` 为高电平时，总线被锁定；当 `HMASTLOCK` 取消断言且 `HREADY` 为高电平时，总线被解锁。
  * `HSIZE[2:0]` ：指定突发传输中每个数据单元的大小，如下表所示：

| `HSIZE[2:0]` | 代表的传输数据位宽 |
| :---: | :---: |
| 3'b000 | 8bit |
| 3'b001 | 16bit |
| ... | ... |
| 3'b111 | 1024bit |

  * `HWSTRB`：信号位宽与 `HSIZE` 一致，当其某些位为 0 时，对应的数据字节位置被填 0，例如要写入的数据为 `8'b10101010`，`HWSTRB=2'b01`，则实际写入的数据为 `8'b00001010`。
  * `HBURST[2:0]`：控制突发传输类型和突发传输的数据单元数量，如下表所示：

| `HSIZE[2:0]` | 类型 | 描述 |
| :---: | :---: | :--- |
| 3'b000 | SINGLE（单次传输） | 表示只有一个数据传输，不涉及突发操作。 |
| 3'b001 | INCR（递增突发） | 表示一系列的传输，地址在每次传输后递增。长度不固定，可以是任意数量的传输。但是需要注意**单次突发传输不能越过分页地址，如果越过，必须分成两次传输**，具体请参见[如何理解突发传输时不能越过页边界](./axi_interface.md#如何理解突发传输时不能越过页边界)。 |
| 3'b010 | WRAP4（4 次传输环回突发） | 突发传输[环回模式](./axi_interface.md#axi-写控制信号)，`burst_len=4` |
| 3'b011 | INCR4（4 次递增突发） | 突发传输[递增模式](./axi_interface.md#axi-写控制信号)，`burst_len=4` |
| 3'b100 | WRAP8（8 次传输环回突发） | 环回模式， `burst_len=8` |
| 3'b101 | INCR8 | 递增模式， `burst_len=8` |
| 3'b110 | WRAP16 | 环回模式， `burst_len=16` |
| 3'b111 | INCR16 | 递增模式， `burst_len=16` |

  * `HPROT[2:0]`：保护类型信号，指定传输的属性（如特权级别、缓存属性等）。一般可以设置为 `4'b0011`。

### 典型的写事务流程

下图展示了 1 主 1 从设备传输时的相关信号时序图：

<div align='center'><img src='.\pic\屏幕截图 2024-08-01 150058.png' width='600px'></div>

首先将 `HWRITE` 信号置高，以便指示写事务。当从设备响应 `HREADY` 信号时，当前在 `HADDR` 地址线和 `HWDATA` 上的数据才可以被时钟上升沿采到，也即必须在此之后地址线和数据线的数据才能变化。

注意，图中选择的突发传输模式为环回，`burst_len=4`。在要传输的第一个地址位置，`HTRANS` 信号都要置为 `NONSEQ`，其后置为 `SEQ`，由于是突发传输，因此只需要给首地址即可。

要传输的每个数据单元数据位宽由 `HSIZE` 指定，`HWSTRB` 用于掩码要传输的字节，如果不作掩码，则 `HWSTRB={number_bytes{1'b1}}`。

### 典型的读事务流程

下图展示了 1 主 1 从设备传输时的相关信号时序图：

<div align='center'><img src='.\pic\屏幕截图 2024-08-01 145909.png' width='600px'></div>

主设备读与写的区别就在于将 `HWRITE` 信号置为低。当从设备发出 `HREADY` 信号时，主设备的 `HADDR` 信号才被时钟上升沿采集到，因此 `HRDATA` 会在时钟周期内变化，但是从结果上看，就是需要下一个时钟周期才可以获取到地址对应的数据。

注意，AHB 是**半双工**总线，因为它在任一时刻的数据传输方向是单向的。（从地址线不分读写就可以发现）

### 完成读写操作的响应信号

一个典型的流程如下述所示：

  1. 主设备发起传输： 
      * 主设备设置地址和控制信号（如 HADDR、HTRANS、HWRITE 等），开始一次新的传输。

  2. 从设备处理传输：

      * 从设备接收地址和控制信号，根据传输类型（读或写）进行相应的处理。

  3. 从设备设置 `HREADYOUT`：

      * 如果从设备准备好并完成传输处理，将 `HREADYOUT` 设置为高电平。
      * 如果从设备需要更多时间处理当前传输，将 `HREADYOUT` 保持为低电平。

  4. `HREADY` 信号传递给主设备、从设备设置 `HRESP`：

      * 在 1 主 1 从系统中，`HREADY` 信号直接连接到从设备的 `HREADYOUT` 信号。
      * 主设备通过读取 HREADY 信号，判断当前传输是否完成。
      * 从设备根据传输结果设置 HRESP 信号，指示传输的响应状态，低为 `OKAY`，高为 `ERROR`。

  6. 主设备读取 `HREADY` 和 `HRESP`：

      * 当 `HREADY` 为高电平时，主设备读取 `HRESP` 信号，确定当前传输的状态。
      * 如果 `HRESP` 为 `OKAY`，表示传输正常完成；如果为 `ERROR`，表示传输发生错误，主设备可能需要采取相应措施。

可以发现，`HREADY` 既充当了 AXI 总线中 `WREADY/RREADY` 信号，还充当了 `BVALID` 信号。