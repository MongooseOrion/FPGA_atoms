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
* FILE ENCODER TYPE: GBK
* ========================================================================
-->
# Verilog 的跨时钟域处理手段

跨时钟域设计在 FPGA 项目中十分常见，处理跨时钟域信号时需要特别小心，因为时钟域之间没有严格的时序关系，因此信号跨时钟域时可能会引发亚稳态问题和数据传输不可靠问题。为了解决这些问题，设计中需要采取适当的同步手段来确保数据正确可靠地在不同的时钟域之间传输。

## 单 bit 信号传输

双触发器同步器（Two-flip-flop Synchronizer）：即打拍，这是最常见的跨时钟域处理方法，适用于单比特信号。原理是将信号从源时钟域采样进入目标时钟域，并通过两个级联的触发器消除亚稳态。

## 多 bit 信号的跨时钟域处理

多比特信号（如数据总线、控制字）跨时钟域时，除了亚稳态问题，还需要确保数据完整性，即避免时钟采样时数据的某些位发生变化，导致错误数据传输。这是因为多位信号不同位的数据可能在跨时钟域时到达目标时钟域的时间不一致。

  * 将传输之前将信号的编码方式由自然二进制码转换为格雷码：

      ```verilog
      // 自然二进制码转格雷码
      assign gray = (bin >> 1) ^ bin;

      // 格雷码转为自然二进制码
      bin[HSB] = gray[HSB];
      for(i=HSB-1'b1; i>=0; i=i+1) begin
        bin[i] = bin[i+1] ^ gray[i]
      ```

  * 异步 FIFO；

## 慢时钟到快时钟和快时钟到慢时钟的处理有所不同

### 从慢时钟到快时钟的处理

从慢时钟域向快时钟域传递信号时，目标时钟域的时钟周期相对于源时钟域较短，因此在目标时钟域中可以多次采样慢时钟信号，来保证信号在目标时钟域稳定。

  * 双触发器同步器（打拍）：由于快时钟的采样周期较短，因此在快时钟域中通过双触发器可以有效同步慢时钟信号。

### 从快时钟到慢时钟的处理

从快时钟域到慢时钟域传递信号时，慢时钟域的采样周期较长，可能会错过快时钟域中更新的数据，因此需要特别注意信号的稳定性和数据完整性。

握手协议（Handshake Protocol）：对于快时钟到慢时钟的信号传输，常用的方法是设计一个握手协议，确保数据在慢时钟域采样时，快时钟域中的数据已经准备好并稳定。

```verilog
reg data_ready, data_ack;

// 快时钟域
always @(posedge fast_clk or negedge rstn) begin
  if (!rstn) begin
    data_ready <= 1'b0;
  end 
  else begin
    data_ready <= 1'b1;  // 数据准备完成
  end
end

// 慢时钟域
always @(posedge slow_clk or negedge rstn) begin
  if (!rstn) begin
    data_ack <= 1'b0;
  end 
  else begin
    if (data_ready) begin
      data_ack <= 1'b1;  // 慢时钟域确认接收
    end
  end
end
```

当然，异步 FIFO 也是适合处理快时钟到慢时钟的解决方案。因为异步 FIFO 的读写操作分别由不同时钟控制，写入快时钟域的数据会被缓存在 FIFO 中，并等待慢时钟域的读取操作。