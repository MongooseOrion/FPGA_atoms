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
# 时序分析和时钟约束

## 时序分析

### 建立时间

建立时间是指在时钟沿到来之前，输入信号需要稳定并保持不变的最短时间。换句话说，**数据必须在时钟沿到来之前足够早地稳定下来，以便寄存器能够正确地捕获这个数据**。

如果数据在时钟沿到来之前没有足够的建立时间（即数据变化得太晚），寄存器可能无法正确捕获数据，导致数据错误。这种错误称为建立时间违例（setup violation）。

引起建立时间违例的原因包括：

  * **组合逻辑延迟过大**：如果输入数据通过一条复杂的组合逻辑路径到达寄存器，并且组合逻辑的延迟太大，数据可能在时钟沿到来之前没有足够的时间稳定下来。
  * **时钟频率过高**：如果时钟周期太短，寄存器没有足够的时间让数据在下一个时钟沿之前稳定下来。

建立时间违例会导致寄存器捕获错误的数据，通常表现为寄存器的输出数据在下一周期时是错误的。这可能会导致整个电路的功能不正确。

建立时间违例的解决方案包括：

  1. 降低时钟频率：

      * 做法：减慢全局时钟频率，以增加每个时钟周期的时间。这可以为数据提供更多的时间来传播并稳定在寄存器输入端。
      * 缺点：虽然降低时钟频率通常可以缓解建立时间违例，但它会降低整个系统的性能。因此，在高性能要求的设计中，使用这种方法需要谨慎。

  2. 优化组合逻辑：

      * 做法：检查违例路径上的组合逻辑，简化逻辑表达式，减少逻辑层次，从而降低传播延迟。可以通过重写 Verilog 代码、合并逻辑运算、或将复杂的逻辑分解为多个简单的逻辑来减少路径延迟。
    
  3. 插入寄存器（流水线化）：
      
      * 做法：将长的组合逻辑路径拆分为多个较短的路径，**在中间插入寄存器**（称为流水线寄存器）。这可以减少每个路径的延迟，使数据能够在更短的时间内稳定。例如：
      ```verilog
        // assign long_comb_logic1 = ......
        reg [7:0] intermediate_reg;
        always @(posedge clk) begin
            intermediate_reg <= long_comb_logic1;
            output_reg <= long_comb_logic2(intermediate_reg);
        end
      ```
      * 影响：引入额外的时钟周期，可能会影响电路的整体延迟和吞吐量。但**这通常是提高时钟频率并保持正确功能的有效方法**。

### 保持时间

保持时间是指在时钟沿到来之后，输入信号仍然需要继续保持稳定的最短时间。换句话说，**数据在时钟沿之后不能立即变化，它需要保持一段时间，以确保寄存器正确地捕获这个数据**。

如果数据在时钟沿到来之后过早地变化，寄存器可能还没来得及捕获这个数据，导致数据错误。这种错误称为保持时间违例（hold violation）。

引起保持时间违例的原因包括：

  * **数据路径延迟过小**：在时钟沿之后，如果数据路径延迟非常小（例如没有组合逻辑延迟），输入数据可能会过快变化，从而违反保持时间要求。
  * **时钟抖动**：时钟信号中的抖动（时钟周期的不确定性）也可能导致保持时间违例。

保持时间违例会导致寄存器捕获的是在时钟沿到来后立即变化的错误数据，可能会引发电路的不稳定或寄存器的输出数据错误。

保持时间违例的解决方案包括：

  1. **增加数据路径延迟**：在数据路径上增加缓冲器或其他小延迟单元，确保数据不会在时钟沿之后立即变化。可以在 Verilog 代码中显式插入 `buf` 或 `not` 等缓冲器。增加的延迟通常非常小，对系统性能影响不大，但可以有效地防止保持时间违例。不同的 FPGA 器件或 EDA 工具可能有不同的原语可实现此功能。
  2. **使用寄存器链**：直接使用 `always` 块打拍实现延迟，例如：
      ```verilog
        reg stable_data;
        always @(posedge clk) begin
            stable_data <= input_signal;
            output_reg <= stable_data;
        end
      ```

  3. **优化时钟路径**：检查时钟路径，特别是在时钟树的分布上，确保时钟信号尽可能同时到达所有寄存器。减少或消除时钟抖动和时钟偏移（skew），可以减少保持时间违例的发生。
  4. **减少逻辑延迟**：减少数据路径上的组合逻辑延迟，可以通过卡诺图或者其他手段简化表达式，确保数据在时钟沿之后不会立即传播到寄存器输入端。可以通过重构逻辑或优化电路设计来实现。

## 时序约束 

下面介绍一些 FPGA 时序约束命令。

### `create_clock`

该命令定义设计中的主时钟信号及其属性，如频率、占空比、时钟名称等。这个命令告诉综合工具哪个信号是时钟，以及时钟的周期是什么。

例如：

```tcl
create_clock -name {sys_clk} [get_ports {sys_clk}] -period {20.000} -waveform {0.000 10.000}
```

这个命令定义了一个周期为 20ns 的主时钟 `sys_clk`，这个名称是一个逻辑上的标签，便于在设计的其他部分引用这个时钟信号，并将它与顶层模块的端口 `sys_clk` 关联，这个名称是模块设计的端口名称。最后，通过 `waveform` 选项定义了时钟信号的波形，即上升沿和下降沿的时间点，它指定了时钟信号的占空比，此处表示在 0.000 ns 时钟信号从低到高（上升沿），在 10.000 ns 时钟信号从高到低（下降沿）。

### `set_clock_groups`

此命令用于将时钟分成不同的组，并定义这些时钟组之间是否有时序关系。你可以指定时钟之间是同步的还是异步的，或直接忽略它们之间的时序路径。

当设计中有多个不相关的时钟域时，可以使用 `set_clock_groups` 命令来告诉 STA 工具这些时钟之间没有时序关系，这样工具会忽略跨时钟域的路径，避免不必要的时序违例报告。

例如：

```tcl
set_clock_groups -name ddr_ref_clk -asynchronous -group [get_clocks {sys_clk}]
```

这个命令将 `ddr_ref_clk` 和 `sys_clk` 分为两个独立的时钟组，并告诉工具它们是异步的，工具将不会对这两个时钟组之间的路径进行时序分析。

### `set_input_delay`

此命令定义了输入端口相对于时钟的输入延迟。这表示外部信号传输到 FPGA 输入端口所需的时间。

当 FPGA 设计接收外部信号时，你需要定义信号到达 FPGA 输入引脚的延迟，便于工具在时序分析时考虑这个延迟，从而确保输入信号在合适的时钟周期内被捕获。

例如：

```tcl
set_input_delay -clock [get_clocks sys_clk] -max 3 [get_ports data_in]
set_input_delay -clock [get_clocks sys_clk] -min 1 [get_ports data_in]
```

这些命令定义了 `data_in` 端口的输入延迟。`data_in` 信号的到达时间在 `sys_clk` 时钟的 1ns 到 3ns 之间。

### `set_output_delay`

此命令定义了输出端口相对于时钟的输出延迟。这表示 FPGA 内部信号到达输出端口所需的时间。

当 FPGA 设计需要向外部设备发送信号时，你需要定义信号从 FPGA 输出引脚传输到外部设备的延迟，以便 STA 工具确保 FPGA 输出的信号在正确的时钟周期内可用。

例如：

```tcl
set_output_delay -clock [get_clocks sys_clk] -max 2 [get_ports data_out]
set_output_delay -clock [get_clocks sys_clk] -min 0.5 [get_ports data_out]
```

这些命令定义了 `data_out` 端口的输出延迟。`data_out` 信号的有效时间在 `sys_clk` 时钟的 0.5ns 到 2ns 之间。

### `set_false_path`

此命令标记某些路径为“假路径”，告诉 STA 工具这些路径不参与时序分析。

当你确定某些逻辑路径不需要满足时序要求时，可以将这些路径标记为假路径。例如，跨时钟域的异步信号通常会被标记为假路径，以避免工具误报时序违例。

```tcl
set_false_path -from [get_ports async_input] -to [get_ports data_out]
```

这个命令指定了从 `async_input` 到 `data_out` 的路径为假路径，STA 工具将忽略这条路径的时序分析。

### `set_max_delay` / `set_min_delay`

指定路径的最大延迟和最小延迟。这些命令可以用来强制设定某些路径的特定时序要求。

当你需要强制某些路径的时序要求，或处理特殊时序需求时，可以使用这些命令。例如，在某些多周期路径或手动优化路径中，可能需要这些约束。

例如：

```tcl
set_max_delay 15 -from [get_ports data_in] -to [get_ports data_out]
set_min_delay 5 -from [get_ports data_in] -to [get_ports data_out]
```

这些命令设置了 `data_in` 到 `data_out` 路径的最大延迟为 15ns，最小延迟为 5ns。

### `set_multicycle_path`

指定某些路径的多周期要求，允许这些路径跨越多个时钟周期。

在设计中，有些逻辑操作需要多个时钟周期才能完成，这时你需要通过此命令告诉 STA 工具这些路径可以跨多个周期，以避免不必要的时序违例。

例如：

```tcl
set_multicycle_path 2 -from [get_ports data_in] -to [get_ports data_out]
```

这个命令指定了 `data_in` 到 `data_out` 的路径为多周期路径，可以跨越 2 个时钟周期。这意味着 STA 工具在分析时，会考虑这条路径可以有两个时钟周期的延迟。

### `set_clock_uncertainty`

设置时钟不确定性（抖动和偏移），它代表了时钟在不同触发条件下的变动范围。

在设计中，时钟抖动和不对齐（skew）可能会影响时序。你需要通过设置此命令来告诉 STA 工具时钟的不确定性，从而在时序分析时考虑到这些因素。

例如：

```tcl
set_clock_uncertainty {0.200} [get_clocks {cmos1_pclk}]  -setup -hold
```

这个命令

### `set_generated_clock`

此命令定义由主时钟派生出的次级时钟信号，例如通过 PLL、MMCM、分频器等生成的时钟。

当设计中有派生时钟（例如通过时钟管理单元生成的不同频率的时钟），你需要定义这些次级时钟的属性，以便 STA 工具正确分析它们之间的时序关系。

例如：

```tcl
create_generated_clock -name {cmos2_pclk_16bit} -source [get_ports {cmos2_pclk}] [get_pins {cmos2_8_16bit/pixel_clk}] -master_clock [get_clocks {cmos2_pclk}] -multiply_by {1} -divide_by {2}
```

这个命令

### `set_propagated_clock`

指定工具自动计算和传播时钟的时序。

当时钟信号经过了复杂的逻辑或布线时（例如缓冲器或组合逻辑），你需要告诉 STA 工具自动计算时钟传播的延迟，而不是使用简单的预设值。

### `define_attribute`

#### `PAP_LOC`

#### `PAP_CLOCK_DEDICATED_ROUTE`