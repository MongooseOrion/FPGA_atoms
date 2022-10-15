# MyVerilogLearning
这是一个用于记录我的 **Verilog** 学习过程的项目。<br><br>
**Verilog** 是一门硬件描述语言，其支持从晶体管级到行为级的数字系统建模。使用 **Verilog HDL** 描述硬件的基本设计单元是**模块**。通过模块间的相互连接调用，可以实现复杂的电路。在关键字 **“module”** 和 **“endmodule”** 之间可以描述一个完整的模块。通过 **Verilog HDL** 例化语句，引用一个模块的输入输出端口，就可以在另一个模块中使用该模块，且无需知道该模块内部的具体实现细节。这样做的好处在于：当设计者修改一个模块的内部结构时，不会对整个设计的其他部分造成影响。这也是采用“自顶向下”设计思路的重要原因之一。<br><br>
尽管 **Verilog HDL** 在某些语法上类似于 **C 语言**。但两者之间有着本质的区别：C 语言的目标是面向处理器，本质上是在 CPU 上串行执行；而目前 **Verilog HDL** 的主要目标是面向数字逻辑电路，本质上是并行执行，也即靠逻辑流推动。<br><br>
一个完整的**模块**应该包括端口定义、数据类型说明和逻辑功能定义。其中，模块名是模块的唯一标识符，端口列表是由模块的各个输入、输出和输入输出双向端口组成的一个端口列表，这些端口用于与其他模块进行通信；数据类型说明用来指定模块内部使用到的数据对象是网络还是变量；逻辑功能定义是使用逻辑功能语句来实现具体的逻辑功能。**Verilog HDL** 具有如下的特征：
  1.  每个 **Verilog HDL** 都以 **“.v”** 作为文件扩展名；
  2.  **Verilog** 区分大小写；
  3.  **Verilog HDL** 程序一行可以写多条语句，也可以将一条语句分成多行书写。

下面来回顾以下 MOSFET 的漏电流计算公式，以 nMOS 管为例，其处于**三极管区**时，漏电流满足下述公式：<br>
  $$I_{D}=\mu_{n}C_{ox}\frac{W}{L}[(V_{GS}-V_{TH})V_{DS}-\frac{1}{2}V_{DS}^{2}]$$

当其处于**饱和区**时，漏电流满足下述公式（考虑沟道长度调制效应 $\lambda$）：
  $$I_{D,max}=\frac{1}{2}\mu_{n}C_{ox}\frac{W}{L}\left( V_{GS}-V_{TH} \right)^{2}(1+\lambda V_{DS})$$
