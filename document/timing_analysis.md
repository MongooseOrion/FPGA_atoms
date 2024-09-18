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

### setup slack 和 hold slack

首先介绍几个概念：

  * $T_{\text{skew}}$ ： 由于时钟线长度不同或负载不同，同一个时钟上升沿或下降沿到达相邻单元的时间可能有一些延迟，这个时间上的偏差就是时钟偏移（skew）；
  * $\Delta T_{\text{jitter}}$ ：在理想情况下相邻两个时钟上升沿或下降沿应该间隔恒等于周期 $T_{\text{period}}$ ，但是实际上是不可能恰好是一个时钟周期，下一个边沿提早或更晚到达，这个时钟到来不确定的情况就是时钟抖动，它是一个范围；
  * $T_{\text{co}}$ ：某个寄存器中从时钟发起到 $Q$ 端输出的时间；
  * $T_{\text{setup(min)}}$ ：建立门限，指在时钟边沿到来前，数据需要保持稳定的**最小**时间；
  * $T_{\text{hold(min)}}$ ：保持门限，指在时钟边沿到来后，数据需要保持稳定的**最小**时间；
  * $T_{\text{data}}$ ：两级寄存器间的组合逻辑延迟，包括逻辑和走线延迟。

<div align='center'><img src='.\pic\06b4cc8bc23c35e83abfaec67188d00a.png' width='500'></div>

因此，数据到达第二级寄存器 $D$ 端的实际时间应该是前一级寄存器的时钟偏移时间加上前一级寄存器时钟输入到数据输出端延迟再加上两级寄存器间的传输延迟，即 

$$\text{data arrival time} = T_{\text{clk1 skew(max)}} + T_{\text{co(max)}} + T_{\text{data(max)}}$$

而数据在满足时序要求时应该到达的时间应该是在下一个时钟边沿来临前：

$$\text{data require time} + T_{\text{setup(min)}}= T_{\text{period}} + T_{\text{clk2 skew(min)}}$$

两者相减即为时间裕量 $\text{setup slack}$ ，**当其大于等于 0 时**，即要求的时间大于到达的时间，意味着路径没有建立时间违例（setup time violetion），因此可以计算满足时序要求时的建立时间门限：

$$\text{setup slack} = \text{data require time} - \text{data arrival time} = 0$$

$$\Rightarrow T_{\text{period}} + T_{\text{clk2 skew(min)}} - T_{\text{setup(min)}} - T_{\text{clk1 skew(max)}} - T_{\text{co(max)}} - T_{\text{data(max)}} = 0$$

$$\Rightarrow T_{\text{setup(min)}} = T_{\text{period}} + T_{\text{clk2 skew(min)}} - T_{\text{clk1 skew(max)}} - T_{\text{co(max)}} - T_{\text{data(max)}}$$

---

同理，现在来解释在什么情况下保持时间违例（hold time violetion）。

数据经两级寄存器最终在 $Q$ 端输出的时间应该是前一级的所有延迟加上第二级寄存器的下一个触发边沿所需时间：

$$\text{data finish time} = T_{\text{clk1 skew(max)}} + T_{\text{co(max)}} + T_{\text{data(max)}} + T_{\text{period}}$$

而数据传送结束要求的时间为第二个时钟边沿来临的时间加上保持时间门限：

$$\text{require finish time} = T_{\text{period}} + T_{\text{clk2 skew(min)}} + T_{\text{hold(min)}}$$

当要求的时间大于等于实际完成的时间时，即 $\text{hold slack} \ge 0$ 时，没有保持时间违例，此时保持门限为：

$$T_{\text{clk1 skew(max)}} + T_{\text{co(max)}} + T_{\text{data(max)}} + T_{\text{period}} - T_{\text{period}} - T_{\text{clk2 skew(min)}} - T_{\text{hold(min)}} = 0$$

$$\Rightarrow T_{\text{hold(min)}} = T_{\text{clk1 skew(max)}} + T_{\text{co(max)}} + T_{\text{data(max)}} - T_{\text{clk2 skew(min)}}$$

## 时序约束 

下面介绍一些 FPGA 时序约束命令。

### `create_clock`

该命令定义设计中的主时钟信号及其属性，如频率、占空比、时钟名称等。这个命令告诉综合工具哪个信号是时钟，以及时钟的周期是什么。

例如：

```tcl
create_clock -name {sys_clk} [get_ports {sys_clk}] -period {20.000} -waveform {0.000 10.000}
```

这个命令定义了一个周期为 20ns 的主时钟 `sys_clk`，这个名称是一个逻辑上的标签，便于在设计的其他部分引用这个时钟信号，并将它与顶层模块的端口 `sys_clk` 关联，这个名称是模块设计的端口名称。最后，通过 `waveform` 选项定义了时钟信号的波形，即上升沿和下降沿的时间点，它指定了时钟信号的占空比，此处表示在 0.000 ns 时钟信号从低到高（上升沿），在 10.000 ns 时钟信号从高到低（下降沿）。

请注意，如果使用的是差分时钟对，那么管脚约束应该全部约束，但是创建时钟只需要 `get_ports {正相时钟}` 即可。例如：在 FPGA 中实现一个 DDR 接口，时钟信号 `ddr_clk` 运行在 200MHz，使用 `DIFF_SSTL15` 电平标准。这个差分时钟信号通过 FPGA 的 `clk_p` 和 `clk_n` 输入端口传入，分别连接到 `E15` 和 `F15` 管脚，相关的 XDC 命令为：

```tcl
set_property PACKAGE_PIN E15 [get_ports clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_p]
set_property PACKAGE_PIN F15 [get_ports clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_n]

create_clock -name ddr_clk -period 5.000 [get_ports clk_p]
```

### `set_clock_groups`

此命令用于将时钟分成不同的组，并定义这些时钟组之间是否有时序关系。你可以指定时钟之间是同步的还是异步的，或直接忽略它们之间的时序路径。

当设计中有多个不相关的时钟域时，可以使用 `set_clock_groups` 命令来告诉 STA 工具这些时钟之间没有时序关系，这样工具会忽略跨时钟域的路径，避免不必要的时序违例报告。

例如：

```tcl
set_clock_groups -asynchronous -group [get_clocks {ddr_ref_clk}] -group [get_clocks {sys_clk}]
```

这个命令将 `ddr_ref_clk` 和 `sys_clk` 分为两个独立的时钟组，并告诉工具它们是异步的，工具将不会对这两个时钟组之间的路径进行时序分析。

### `set_input_delay`

此命令定义了输入端口相对于时钟的输入延迟。这表示外部信号传输到 FPGA 输入端口所需的时间。

当 FPGA 设计接收外部信号时，你需要定义信号到达 FPGA 输入引脚的延迟，便于工具在时序分析时考虑这个延迟，从而确保输入信号在合适的时钟周期内被捕获。

例如：

```tcl
set_input_delay -clock [get_clocks sys_clk] -max {3.0} -min {1.0} [get_ports data_in]
```

这些命令定义了 `data_in` 端口的输入延迟。`data_in` 信号的到达时间在 `sys_clk` 时钟的 1ns 到 3ns 之间。

### `set_output_delay`

此命令定义了输出端口相对于时钟的输出延迟。这表示 FPGA 内部信号到达输出端口所需的时间。

当 FPGA 设计需要向外部设备发送信号时，你需要定义信号从 FPGA 输出引脚传输到外部设备的延迟，以便 STA 工具确保 FPGA 输出的信号在正确的时钟周期内可用。

例如：

```tcl
set_output_delay -clock [get_clocks sys_clk] -max {2.0} -min{0.5} [get_ports data_out]
```

这些命令定义了 `data_out` 端口的输出延迟。`data_out` 信号的有效时间在 `sys_clk` 时钟的 0.5ns 到 2ns 之间。

### `set_false_path`

此命令标记某些路径为 “假路径” ，告诉 STA 工具这些路径不参与时序分析。

当你确定某些逻辑路径不需要满足时序要求时，可以将这些路径标记为假路径。例如，跨时钟域的**异步**信号通常会被标记为假路径，以避免工具误报时序违例。通常有以下路径被设置为 false_path：

  1. 从逻辑上考虑，与电路正常工作不相关的那些路径，比如测试逻辑，静态或准静态逻辑。
  2. 从时序上考虑，我们在综合时不需要分析的那些路径，比如跨越异步时钟域的路径。 

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

这个命令告诉 FPGA 时序分析工具，针对 `cmos1_pclk` 时钟信号，在进行**建立时间**和**保持时间**分析时，都要考虑 0.200ns 的时钟不确定性。这意味着工具在时序分析时，会假设时钟可能有 0.200ns 的时间误差，从而在时序计算中引入额外的裕量。

### `set_generated_clock`

此命令定义由主时钟派生出的次级时钟信号，例如通过 PLL、MMCM、分频器等生成的时钟。

当设计中有派生时钟（例如通过时钟管理单元生成的不同频率的时钟），你需要定义这些次级时钟的属性，以便 STA 工具正确分析它们之间的时序关系。

例如：

```tcl
create_generated_clock -name {cmos2_pclk_16bit} -source [get_ports {cmos2_pclk}] [get_pins {cmos2_8_16bit/pixel_clk}] -master_clock [get_clocks {cmos2_pclk}] -multiply_by {1} -divide_by {2}
```

  1. `-name {cmos2_pclk_16bit}`

      这个选项定义了生成时钟的名称。在这个例子中，生成的时钟被命名为 `cmos2_pclk_16bit`。这个名称是用于标识这个派生时钟的逻辑标签，便于在设计的其他部分引用。

  2. `-source [get_ports {cmos2_pclk}]`

      这个选项指定了生成时钟的来源时钟信号。在这里，`get_ports {cmos2_pclk}` 表示源时钟 `cmos2_pclk` 是来自 FPGA 顶层模块的一个输入端口。`cmos2_pclk` 是主时钟的名称，是从顶层模块的端口 `cmos2_pclk` 获得的。

  3. `[get_pins {cmos2_8_16bit/pixel_clk}]`

      这个部分指定生成时钟信号的目的地（即生成时钟所连接的引脚）。在这个例子中，生成的时钟信号被分配到模块 `cmos2_8_16bit` 中的 `pixel_clk` 引脚。

      `cmos2_8_16bit/pixel_clk` 表示模块 `cmos2_8_16bit` 内的 `pixel_clk` 引脚，这个引脚使用了生成时钟 `cmos2_pclk_16bit`。

  4. `-master_clock [get_clocks {cmos2_pclk}]`

      这个选项指定了生成时钟的主时钟（master clock），即生成时钟是从哪个时钟衍生出来的。在这里，`get_clocks {cmos2_pclk}` 表示 `cmos2_pclk` 是主时钟。

      `cmos2_pclk` 是作为 `cmos2_pclk_16bit` 派生时钟的主时钟。工具会基于这个主时钟来计算派生时钟的属性。

  5. `-multiply_by {1} -divide_by {2}`

      这两个选项指定了生成时钟的频率是如何从主时钟的频率派生出来的。

      *  `-multiply_by {1}`：表示生成时钟的频率是主时钟频率的 1 倍（即没有倍频）。
      *  `-divide_by {2}`：表示生成时钟的频率是主时钟频率的 1/2（即频率被减半）。

      如果主时钟 `cmos2_pclk` 的频率是 $f$ ，那么生成时钟 `cmos2_pclk_16bit` 的频率就是：

      $$f_{\text{generated}} = \frac{f_{\text{master}} \times \text{multiply\_by}}{\text{divide\_by}}$$

### `set_propagated_clock`

指定工具自动计算和传播时钟的时序。

当时钟信号经过了复杂的逻辑或布线时（例如缓冲器或组合逻辑），你需要告诉 STA 工具自动计算时钟传播的延迟，而不是使用简单的预设值。

例如：

```tcl
set_propagated_clock [get_clocks sys_clk]
```

这个命令告诉 STA 工具对 `sys_clk` 进行传播时钟分析，自动计算和考虑时钟在实际电路中的传播延迟。

### `define_attribute`

#### `PAP_LOC`

例如：

```tcl
define_attribute {i:u_ddr.u_ipsxb_ddrphy_pll_1.u_pll_e3} {PAP_LOC} {PLL_158_179}
```

  1. `{i:u_ddr.u_ipsxb_ddrphy_pll_1.u_pll_e3}`

      * 前缀 `i:` 表示这是一个实例（instance）。在 FPGA 设计中，实例通常是指模块或单元在更大设计中的具体实现。这可能是一个逻辑模块的实例化，或者是 FPGA 的一个硬核（如 PLL、BRAM 等）实例。
      * `u_ddr.u_ipsxb_ddrphy_pll_1.u_pll_e3`：这是实例的完整路径名。它表示在设计层次结构中，`u_pll_e3` 是 `u_ipsxb_ddrphy_pll_1` 单元中的一个实例，而 `u_ipsxb_ddrphy_pll_1` 又是在 `u_ddr` 模块中实例化的。也就是说，这是一个嵌套的模块路径，`u_pll_e3` 是在最底层的模块（`u_ipsxb_ddrphy_pll_1`）中实例化的。

  2. `{PAP_LOC}`

      * 这个属性用于指定实例在 FPGA 上的具体物理位置。PAP_LOC 代表的是 "Placement Attribute for Location"，它通常用于锁定 FPGA 布局布线中的特定模块位置，确保工具将该模块放置在指定的位置上。

  3. `{PLL_158_179}`

      * 这是一个特定的位置标识符，表示 FPGA 内部的一个具体物理位置。对于一个 PLL 实例，这通常意味着它会被放置在 FPGA 布局中的编号为 158_179 的 PLL 位置上。

这意味着，在 FPGA 布局布线过程中，工具会尝试将 `u_pll_e3` 实例放置在 FPGA 内部标识为 `PLL_158_179` 的物理位置。

#### `PAP_CLOCK_DEDICATED_ROUTE`

通常，时钟信号使用专用布线资源以确保信号的低延迟和高稳定性，但在某些特殊情况下，设计者可能希望时钟信号使用普通的布线资源（例如，当信号不是主要的时钟信号，或当设计中资源紧张时），这时就需要显式地将 `PAP_CLOCK_DEDICATED_ROUTE` 设置为 `FALSE`。

例如：

```tcl
define_attribute {n:cmos2_pclk} {PAP_CLOCK_DEDICATED_ROUTE} {FALSE}
```

这意味着，`cmos2_pclk` 信号将不会使用 FPGA 内部为时钟信号专门提供的专用布线资源。

---

## 一些例子

  1. 你的设计中包含一个 SPI 通信模块，其中主时钟 `spi_clk` 运行在 20MHz，时钟信号通过 FPGA 的 `clk_in` 输入端口传入，连接到 `B12` 管脚，使用 `LVCMOS33` 逻辑电平。你还知道 SPI 通信中的 `mosi` 和 `miso` 信号分别连接到 `C13` 和 `D14` 管脚，也使用 `LVCMOS33` 电平标准。为这三个信号编写 XDC 约束命令。

      ```tcl
      set_property PACKAGE_PIN B12 [get_ports clk_in]
      set_property IOSTANDARD LVCMOS33 [get_ports clk_in]
      set_property PACKAGE_PIN C13 [get_ports MOSI]
      set_property IOSTANDARD LVCMOS33 [get_ports MOSI]
      set_property PACKAGE_PIN D14 [get_ports MISO]
      set_property IOSTANDARD LVCMOS33 [get_ports MISO]

      create_clock -name spi_clk -period 50.000 [get_ports clk_in]
      ```

  2. 在你的 FPGA 设计中，有一个信号 `data_valid`，该信号从一个高速 ADC 传入 FPGA，频率为 100MHz。由于 `data_valid` 触发的逻辑链路较长，你想指定该信号的多周期路径，以便工具在两个时钟周期内完成数据采样。请编写 XDC 约束命令。

      ```tcl
      set_multicycle_path 2 -from [get_ports data_valid] -to [get_nets DATA_VALID]
      ```

  3. 你的设计中有一个跨时钟域的路径，源时钟为 50MHz（`clk_50`），目标时钟为 100MHz（`clk_100`）。这两个时钟都是独立的，不存在时序关系。你希望工具忽略这个跨时钟域路径的时序分析，以避免误报时序违例。请编写 XDC 约束命令。

      ```tcl
      set_clock_groups -asynchronous -group [get_clocks clk_100] -group [get_clocks clk_50]
      ```

  4. 在你的设计中，有一个信号 `ready` 从低频时钟域（20MHz）跨入高频时钟域（100MHz），信号需要在 100MHz 时钟域中被正确采样。为了保证数据的可靠性，你决定将这个路径标记为假路径，并且设置一个输入延迟，假设延迟时间是 5ns。请编写 XDC 约束命令。

      ```tcl
      create_clock -name clk_1 -period 50.000 [get_ports clk_1]
      create_clock -name clk_2 -period 10.000 [get_ports clk_2]
      
      set_false_path -from [get_ports ready] -to [get_ports ready_high]
      set_input_delay -clock [get_clocks clk_1] -min 0.0 -max 5.0 [get_ports ready]
      ```


## 解决建立时间违例的通用方案

#### 时钟频率优化

如果时钟速度过快导致数据无法在时钟周期内稳定，可以考虑降低时钟频率。通过调整 `create_clock` 或 `create_generated_clock` 命令的时钟周期，来降低时钟频率。

#### 优化逻辑路径

查看时序报告中每条路径的详细信息，找到存在延迟的关键路径（critical path）。然后通过减少逻辑级数、增加寄存器来缩短路径延迟。

例如，时序报告某一某一路径存在时序问题：

```tcl
Startpoint  : power_on_delay_inst/cnt2[14]/opit_0_A2Q21/CLK 
Endpoint    : power_on_delay_inst/cnt2[14]/opit_0_A2Q21/CE
Path Group  : sys_clk
Path Type   : max (slow corner)
```

在 Verilog 代码中，可以在问题路径中插入额外的寄存器，使该信号经过多个时钟周期传递，这样可以减少每个时钟周期内的传播延迟，缓解时序压力：

```verilog
reg [15:0] cnt2_pipe_1, cnt2_pipe_2, cnt2_pipe_3;  // 定义多个级联寄存器

always @(posedge sys_clk or negedge resetn) begin
    if (!resetn) begin
        cnt2_pipe_1 <= 16'b0;
        cnt2_pipe_2 <= 16'b0;
        cnt2_pipe_3 <= 16'b0;
    end else begin
        cnt2_pipe_1 <= cnt2;           // 第一个时钟周期
        cnt2_pipe_2 <= cnt2_pipe_1;    // 第二个时钟周期
        cnt2_pipe_3 <= cnt2_pipe_2;    // 第三个时钟周期
    end
end
```

#### 多周期路径

在某些情况下，信号的传播不一定需要在一个时钟周期内完成，工具会默认认为每条路径都是单周期的。如果某条路径实际上是多周期的（即信号跨多个时钟周期完成），你可以使用 `set_multicycle_path` 命令来约束它，这样工具会给信号更多的时间完成传输，从而减少时序违例的可能性。

```tcl
set_multicycle_path 2 -from [get_pins ...] -to [get_pins ...]
```

#### 增加输入/输出延迟

如果时序违例发生在与外部接口相关的信号上，可以通过 `set_input_delay` 和 `set_output_delay` 命令来调整信号的输入和输出时序，确保外部设备和 FPGA 之间的时序匹配。

#### 假路径和异步时钟组

对于不需要进行时序检查的路径，可以使用 `set_false_path` 来告诉工具忽略该路径的时序检查。另外，跨时钟域时，可以使用 `set_clock_groups -asynchronous` 来定义异步时钟组，避免工具误判时序违例。

```tcl
set_false_path -from [get_pins ...] -to [get_pins ...]
set_clock_groups -asynchronous -group [get_clocks clk1] -group [get_clocks clk2]
```

## 解决保持时间违例的通用方案

#### 增加数据路径的延迟

由于保持时间违例通常是数据到达捕获触发器过早导致的，因此可以通过增加数据路径的延迟来解决问题。方法如下：

  * 插入小延迟单元：通过在数据路径中插入缓冲器或延迟单元（Delay Cell）来增加信号的传播时间。这可以帮助数据在保持时间内保持稳定。在具体的 FPGA 工具中，可以手动插入寄存器来增加数据路径的延迟。
  * 优化布局布线：调整数据路径的布局或布线，使数据路径稍长，从而增加数据到达捕获触发器的时间。


#### 调整时钟树（Clock Tree）

时钟偏移或时钟抖动也是导致保持时间违例的常见原因之一。以下方法可以帮助优化时钟树：

  * 插入时钟延迟：通过在时钟路径上插入延迟缓冲（例如 `BUFG` 和 `BUFR`）来增加时钟的延迟，这样可以使时钟信号的到达时间稍微晚一些，增加保持时间裕量。
  * 平衡时钟树：检查时钟分配网络中的时钟偏移，确保时钟的分配路径平衡，减少时钟之间的不均衡。FPGA 工具通常可以自动优化时钟树，也可以通过设置约束来手动调整。

BUFG（Global Clock Buffer）：BUFG 是一种**全局时钟缓冲器**，用于将时钟信号在 FPGA 芯片的整个全局时钟网络上分布。BUFG 通常用于需要全局时钟驱动的情况，比如 FPGA 中的顶层时钟输入。

BUFR（Regional Clock Buffer）：BUFR 是一种**区域时钟缓冲器**，用于驱动较小范围的时钟网络（即时钟区域），比 BUFG 更局部化。BUFR 还可以进行时钟分频，并提供有限的延迟控制。对于某些设计，BUFR 可以提供灵活的时钟管理，特别是在需要不同区域内时钟同步时。一般适用于时钟的局部分布，而不需要在整个 FPGA 上传播。

在 vivado 中可以这样调用：

```verilog
// BUFG 实例化
BUFG u_bufg_inst (
    .I(clk_in),    // 时钟输入
    .O(clk_out)    // 时钟输出
);

// BUFR 实例化
BUFR #(
    .BUFR_DIVIDE("BYPASS")  // 可选分频：BYPASS, 1, 2, 4, 8
) u_bufr_inst (
    .I(clk_in),    // 时钟输入
    .O(clk_out),   // 时钟输出
    .CE(1'b1),     // 使能
    .CLR(1'b0)     // 清除
);
```

#### 设置 `set_max_delay` 限制

使用 `set_max_delay` 来手动增加某些路径上的最大延迟，确保信号在路径上的传输时间不会太短。通常用于特定关键路径的保持时间优化。

```tcl
set_max_delay -from [get_ports data_in] -to [get_pins flipflop/Q] 2.0
```

上面的命令会将 `data_in` 到触发器输出 `flipflop/Q` 的最大延迟设置为 2 ns。

#### 跨时钟域同步

跨时钟域信号通常会遇到保持时间或建立时间问题。解决跨时钟域保持时间违例的常见方法包括：

  * 双触发器同步器（单 bit 信号）
  * 异步 FIFO（多 bit 信号）
  * 握手协议

#### 多周期路径

有时，某些信号路径实际上是多周期路径，但工具默认按照单周期路径进行时序检查，导致产生保持时间违例。在这种情况下，可以使用 `set_multicycle_path` 命令告诉工具这些路径是多周期路径，从而放宽保持时间检查的约束。

#### 调整寄存器位置

通过重新布局，确保寄存器尽量靠近数据源或目的端，从而减少时钟和数据路径之间的偏差。这种方法可以有效减少保持时间违例。