# MyVerilogLearning
这是一个用于记录我的 **Verilog** 学习过程的项目。该项目整合了一些基础模块，RTL 实现的原语和系统化的内容，你可以在此复用这些模块。

## 存储库结构

```
  |-- base_model                // 基本 verilog 内容
    |-- RTL
    |-- Vivado
  |-- counter                   // 基本计数器
  |-- logic_primitive           // 原语的逻辑表达形式
  |-- system                    // 高级 verilog 内容
    |-- ahb_to_axi_bridge.v     // ahb lite 转 axi4 lite 转接桥
    |-- 

```

## 前序知识
**Verilog** 是一门硬件描述语言，其支持从晶体管级到行为级的数字系统建模。使用 **Verilog HDL** 描述硬件的基本设计单元是**模块**。通过模块间的相互连接调用，可以实现复杂的电路。在关键字 **“module”** 和 **“endmodule”** 之间可以描述一个完整的模块。通过 **Verilog HDL** 例化语句，引用一个模块的输入输出端口，就可以在另一个模块中使用该模块，且无需知道该模块内部的具体实现细节。这样做的好处在于：当设计者修改一个模块的内部结构时，不会对整个设计的其他部分造成影响。这也是采用“自顶向下”设计思路的重要原因之一。

尽管 **Verilog HDL** 在某些语法上类似于 **C 语言**。但两者之间有着本质的区别：C 语言的目标是面向处理器，本质上是在 CPU 上串行执行；而目前 **Verilog HDL** 的主要目标是面向数字逻辑电路，本质上是并行执行，也即靠逻辑流推动。

一个完整的**模块**应该包括端口定义、数据类型说明和逻辑功能定义。其中，模块名是模块的唯一标识符，端口列表是由模块的各个输入、输出和输入输出双向端口组成的一个端口列表，这些端口用于与其他模块进行通信；数据类型说明用来指定模块内部使用到的数据对象是网络还是变量；逻辑功能定义是使用逻辑功能语句来实现具体的逻辑功能。**Verilog HDL** 具有如下的特征：
  1.  每个 **Verilog HDL** 都以 **“.v”** 作为文件扩展名；
  2.  **Verilog** 区分大小写；
  3.  **Verilog HDL** 程序一行可以写多条语句，也可以将一条语句分成多行书写。

众所周知，MOSFET (金属-氧化物半导体场效应晶体管) 是一种压控元件，通过施加在栅极的电压可控制源漏极之间的导通，实现“开关”效果。根据漏源电压 $V_{DS}$ 与漏电流 $I_D$ 的关系，可以将 MOSFET 的工作特性划分为如下的几个区域：
  * 截止区： ${V_{GS}} > {V_{TH}}$
  * 深线性区： $V_{GS} > V_{TH}$, $V_{DS} \ll 2(V_{GS}-V_{TH})$
  * 三极管区： $V_{GS} > V_{TH}$, $V_{DS} \le V_{GS}-V_{TH}$
  * 饱和区： $V_{DS} > V_{GS}-V_{TH}$

下面来回顾以下 MOSFET 的漏电流计算公式，以 nMOS 管为例，其处于**三极管区**时，漏电流满足下述公式：<br>
  $$I_{D}=\mu_{n}C_{ox}\frac{W}{L}[(V_{GS}-V_{TH})V_{DS}-\frac{1}{2}V_{DS}^{2}]$$

当其处于**饱和区**时，漏电流满足下述公式（考虑沟道长度调制效应 $\lambda$）：
  $$I_{D,max}=\frac{1}{2}\mu_{n}C_{ox}\frac{W}{L}\left( V_{GS}-V_{TH} \right)^{2}(1+\lambda V_{DS})$$

## 语法内容
尽管 Verilog 的语法在很大程度上与 c 语言类似，但是由于其是一门设计硬件的语言，在诸多语法上仍会有所不同，这可能会导致 “先入为主” 的错误。下面就介绍一些内容。

### 文件写入和读取操作
文件操作与 python 类似。在创建文件对象后，将内容写入，同时可指定操作类型，最后关闭文件。一套完整的 testbench 数据写入文件的操作如下述所示：
```ruby
integer wfile;

initial begin
	wfile = $fopen("./output_file/result_data.txt","w");
end

always @(posedge clk) begin
	if(valid) $fwrite(wfile,"%b\n",data);
end

initial begin
  #10000;
  $fclose(wfile);
end
```
读取文件可如下述所示，这里定义了一个 8 位格雷码数据输出与正确的格雷码相比对的功能：
```verilog
reg[7:0] data_mem[255:0];
initial $readmemb("./input_file/8bit_grayencode.txt",data_mem);

always @(posedge clk) begin
	if(valid) $display("%b\n%b\n\n",o_gray,data_mem[cnt]);
end
```

### 随机数生成
如果想要产生负数到正数范围内的随机数，例如 -99 到 99，则按如下代码：
```
variable = $random % 100;
```
如果仅需产生正数范围的随机数，例如 0 到 99，则可使用：
```
variable = {$random} % 100;
```
如果需要在指定范围产生随机数，例如 min 到 max，则使用：
```
variable = min + {%random} % {max-min+1}
```
同时，在学习 c 语言时我们知道，`$random`是一种伪随机数函数，这种情况在 verilog 中被放大了——在不同的 always 块内如果重复使用了`$random`函数，则生成的随机数完全一样。解决方法是这样写：`$random(seed)`。

### 阻塞和非阻塞赋值
阻塞与非阻塞之间最大的区别是：一个顺序执行，一个并行执行。以代码进行演示：
```verilog
// 阻塞赋值
initial begin
  a = #5 'b1;   // 在 5 个时间单位后赋值
  b = #6 'b1;   // 在 11 个时间单位后赋值
end

// 非阻塞赋值
initial begin
  a <= #5 'b1;  // 在 5 个时间单位后赋值
  b <= #6 'b1;  // 在 6 个时间单位后赋值
end
```
