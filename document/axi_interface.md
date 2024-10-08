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
# AXI4 总线接口描述

## AXI-FULL

AXI FULL 表示具备完整 AXI 接口的总线，下述按照传输事务来描述接口。

### AXI 读写控制信号

| 信号名称 | 位宽 | 描述 |
| :---: | :---: | :--- |
| AxLEN | [7:0] | 突发长度，指定突发传输中的数据单元数。<br>Length = AWLEN + 1。<br>例如：若要一次突发传输 16 个数据单元，`awlen=8'd15`。 |
| AxSIZE | [2:0] | 突发大小，指定每个数据单元的大小。计算方法为 DATA_WIDTH/8。<br>3'b000: 1byte<br>3'b001: 2bytes<br>3'b010: 4bytes<br>3'b011: 8bytes<br>...<br>3'b111: 128bytes<br>例如，若写数据位宽为 32bit，则 `awsize=3'b010`。 |
| AxBURST | [1:0] | 设置突发类型，参见下述介绍。 |
| AxID/xID | ID_W_WIDTH | 在多主多从的场景标识事务，参见下述介绍。 |
| WSTRB | DATA_WIDTH/8 | 掩码要传输的数据，按字节指示传输的数据中某些字节为 0，如果全有效，请设置 {(DATA_WIDTH/8){1'b1}} |

#### 突发传输类型

假设有 `awlen='d15, awsize='b010`，则：

  * **FIXED**: 所有数据传输操作的地址 `awaddr` 都是相同的。例如起始地址为 0x1000，则地址序列：0x1000, 0x1000, 0x1000, ..., 0x1000（重复 16 次）；
  * **INCR**：每次数据传输操作的地址 `awaddr` 都会递增，递增的步幅为数据单位的大小（字节）。例如起始地址为 0x1000，则地址序列：0x1000（第 1 个传输）, 0x1004（第 2 个传输）, 0x1008（第 3 个传输）, ..., 0x103C（第 16 个传输）；
  * **WRAP**：在握手时给出首地址，当自增地址达到地址上界时环回到地址下界，并重新开始自增。

      ```python
      地址下界 = (int(start_address / (number_bytes * burst_length))) * (number_bytes * burst_length)   # 起始地址需要对齐
      ```
      ```python
      地址上界 = 地址下界 + (number_bytes * burst_length)
      ```
      例如，起始地址为 0x30，地址下界为 `(int(0x30 / (16 * 4))) * (16 * 4) = int(0x30 / 0x40) * 0x40 = 0x00`，地址上界为 `0x00 + (16 * 4) = 0x40`，地址序列应该是：0x30, 0x34, 0x38, 0x3C, 0x00, ..., 0x2C（第 16 个传输）
  
当突发传输时，起始地址非对齐，此时的处理方法：

例如起始地址为 `0x32`，则有：

```python
align_addr = (int(start_addr / number_bytes)) * number_bytes = (int(0x32 / 4)) * 4 = 0x30
```
地址序列为：0x32, align_addr+4=0x34, 0x38, ..., 0x2C（WRAP）或 0x6C（INCR）

#### 读写事务 ID 信号 

  1. 写地址通道 `AWID`：写地址 ID，标识写事务。写地址通道上的每个地址请求都带有一个 `AWID`，从设备使用这个 ID 来匹配后续的写数据和响应。
  2. 写数据通道 `WID`：写数据 ID，与 `AWID` 对应。写数据通道上的每个数据传输都带有一个 `WID`，从设备使用这个 ID 来确保数据与正确的写事务匹配。

假设一个系统中有两个主设备（Master 0 和 Master 1），它们同时发起读写事务。现在通过给出事务 ID 信号，确保每个主设备的请求和响应正确匹配。流程如下：

  1. Master 0 发起读事务

      * ARID = 0x01
      * ARADDR = 0x1000
      
      从设备收到请求，并在读数据通道上返回数据：

      * RID = 0x01
      * RDATA = 数据
    
      Master 0 使用 RID = 0x01 来识别数据是对其请求的响应。

  2. Master 1 发起写事务

      * AWID = 0x02
      * AWADDR = 0x2000

      从设备收到请求，并在写响应通道上返回响应：

      * BID = 0x02
      * BRESP = 写响应

      Master 1 使用 BID = 0x02 来识别响应是对其请求的回应。

### 典型的写事务流程

数据

### AXI 的 outstanding 和 out of order 机制

#### Outstanding（未完成事务）机制

AXI 总线中的 outstanding 机制是指在 AXI 总线上，主设备（Master）能够同时发起多个读写事务，而无需等待前一个事务完成，从而提高总线的并发性和吞吐量。事务的完成包括数据的传输和确认（响应）等步骤。

例如在 AXI 传输时可以有下述操作：

  * 在 `AW` 通道 发送首地址，并以 `AWID` 标识事务。
  * 同时，在当前 `W` 通道 的数据还没有写完的情况下，继续发送新的地址事务。
  * 在写通道写完当前事务后，通过 `WID` 标识来对应之前在 `AW` 通道发送的地址事务。

Outstanding 机制允许主设备（Master）在发送一个读写请求后，无需等待该请求完成，即可继续发送更多的读写请求。在读写操作中，AXI 协议将地址通道和数据通道解耦（独立处理）。

####  Out-of-Order（乱序事务）机制

Out-of-order 机制是指 AXI 总线支持多个事务的响应按照不同于它们请求的顺序返回。换句话说，从设备（Slave）可以以不同的顺序完成并返回事务结果，而主设备（Master）必须根据事务的唯一 ID 来匹配响应，以保证最终结果的正确性。

例如在 AXI 传输时可以有下述操作：

  * 在执行 DDR 的读取操作时，DDR 返回的事务顺序与发送的事务顺序不同。

如果 DDR 控制器支持 Out-of-Order 机制，它可以乱序处理读请求，根据自身的处理能力和速度，以不同于请求顺序的顺序返回数据。主设备通过每个事务的 `RID` 匹配响应数据与请求，从而确保数据被正确处理，即使返回顺序与请求顺序不同。

## AXI-FULL、AXI-LITE 和 AXI-stream 的区别

| 特性 | AXI-Full | AXI-Lite | AXI-Stream |
| :--- | :--- | :--- | :--- |
| 突发传输 | 突发长度最大 256 | 不支持 | 不适用 |
| 通道数 | AW/W/B/AR/R | AW/W/B/AR/R | 单一数据流通道，半双工 |
| 数据宽度 | 8-1024bit | 32、64bit | 8-1024bit |
| 控制信号 | 支持缓存、保护等复杂控制信号 | 只有基础的握手和响应信号 | 一共只剩下 `TVALID`、`TREADY`、`TDATA`、`TLAST`、`TKEEP`（可选，作用与 `WSTRB` 相同） 五个信号 |


## AXI4 和 AXI3 的区别

| 特点 | AXI4 | AXI3 |
| :--- | :--- | :--- |
| 数据传输模式 | 支持突发传输（burst transfer） | 同样支持突发传输 |
| 突发传输最大长度 | 最大突发长度为 256 beat | 最大突发长度为 16 beat |
| 突发传输类型 | 支持固定、增量、包装模式 | 支持固定、增量、包装模式 |
| 写响应（Write Response） | 支持 | 支持 |
| 字节对齐（Byte Alignment） | 支持字节对齐，可以进行任意字节的传输 | 支持字节对齐，可以进行任意字节的传输 |
| 地址宽度 | 可以扩展到 64 位或更多 | 一般为 32 位（但也可扩展） |
| 数据宽度 | 8 位到 1024 位 | 8 位到 1024 位 |
| 缓存信号 | 提供额外的缓存信号（如 QoS、缓存策略） | 没有这些额外信号 |
| 应用场景 | AXI4 是 AXI 的最新版本，专为高性能片上系统设计，广泛用于 CPU、GPU、DMA 等 | 适合中等性能要求的场景 |

## 补充说明

### 如何理解突发传输时，不能越过页边界？

在 AXI 总线协议中，突发传输不能超过页边界的限制主要是为了确保内存访问的效率和一致性。页边界（page boundary）通常由系统的内存管理单元（MMU）或相关硬件定义，具体大小可能会因系统而异，但常见的页大小有 4KB、8KB、16KB 等。

页边界是内存分页系统中的一个概念，用于分割内存的逻辑区域。每个页代表一块固定大小的连续内存地址。页边界是这些固定大小块的起始地址。

例如，如果页大小为 4KB（即 4096 字节），页边界地址将是：0x0000, 0x1000, 0x2000, 0x3000, 等等。

突发传输跨越页边界会导致复杂的内存访问问题，如：

  * 页错误：跨越页边界可能会导致访问未映射或受保护的内存区域，从而引发页错误。
  * 性能降低：跨页访问可能需要额外的内存管理操作，降低传输效率。
  * 数据一致性问题：如果跨页访问导致一部分数据成功写入而另一部分失败，可能会造成数据不一致。

在设计时，需要确保突发传输不会跨越页边界。下述是设计的方法：

  1. 突发传输长度限制：确保突发传输的长度和起始地址之和不会超过页边界。例如，对于4KB的页大小，如果起始地址为 0x0FF0，允许的最大突发长度为 (0x1000 - 0x0FF0) / 数据单位大小。
  2. 地址对齐：确保突发传输的起始地址对齐到数据单元的大小。这样可以简化边界检查，减少跨页的风险。
  3. 计算实际突发传输长度：

      * 起始地址：假设 araddr 为突发传输的起始地址。
      * 页大小：假设为 4KB（即 4096 字节）。
      * 数据单位大小：由 awsize 决定，例如 32 字节。
      * 如果起始地址为 0x0FF0，那么：距离下一个页边界的字节数 = 0x1000 - 0x0FE0 = 32 字节。

因此，若 awsize 为 32 字节的突发传输，最大允许长度为 1 个数据单位，因为 32 字节已经足够跨越到下一个页边界。

假设：

  * 页大小为 4KB（4096 字节）。
  * awsize = 'b101（32 字节）。
  * awlen = 15（16 个数据单元）。

从起始地址 0x0FE0 开始：第一个数据单元：0x0FE0 - 0x1000。突发传输超过页边界，因此必须拆分。

解决方法：拆分传输：将突发传输分成两部分，以确保每部分都在同一页内。

  * 第一部分：从 0x0FE0 到 0x1000。
  * 第二部分：从 0x1000 开始的下一个页内继续突发传输。
  * 限制突发长度：在页边界内控制突发长度。例如，起始地址 0x0FE0，突发长度应为 (0x1000 - 0x0FE0) / 数据单位大小，即最多1个32字节的数据单元。