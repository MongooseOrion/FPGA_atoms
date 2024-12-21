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
# FIR 滤波器和 IIR 滤波器设计

## 卷积计算方法

假设有两个离散信号： $x[n]$ 和 $h[n]$ ，它们的卷积表示为 $y[n]$ ，离散卷积的公式如下：

$$y[n] = (x * h)[n] = \sum_{k=-\infty}^{\infty} x[n] \cdot h[n-k]$$

其中， $x[n]$ 表示输入信号； $h[n]$ 表示卷积核（也叫滤波器、脉冲响应），定义了想要应用在 $x[n]$ 上的操作； $k$ 卷积计算中用来滑动 $h[n]$ 的索引。

例如：

$$x[n] = [1,2,3]$$

$$h[n] = [4,5,6]$$

  1. 按元素逆序信号 $h[n]$ 得到 $h[-n]=[6,5,4]$
  2. 平移 $h[-n]$ 并于对应位置 $x[n]$ 对应位置相乘：
      
      * $y[0] = 1\times 6 = 6$
      * $y[1] = 1\times 5 + 2\times 6=17$
      * $y[2] = 1\times 4 + 2\times 5 + 3\times 6 = 32$
      * $y[3] = 2\times 4 + 3\times 5 = 23$
      * $y[4] = 3\times 4 = 12$

  3. 输出信号序列 $y[n] = [6,17,32,23,12]$

因此卷积操作可以理解为：将卷积核序列的尾部相对于输入信号序列从左往右滑动相乘再相加，得到输出序列。如下图所示：

<div align='center'><img src='.\pic\绘图2.png' width='650px'></div>

可以将滑窗法扩展到 2 维空间：

<div align='center'><img src='.\pic\74944ebc7c6f46d0436019fbd313fc38.gif' width='400px'></div>

## FIR 滤波器

现在假设有一个正弦信号，带有噪声，它们时域和频域的图如下图所示：

<div align='center'><img src='.\pic\屏幕截图 2024-08-11 160300.png' width='450px'></div>

可以看到主要频率在 5Hz 附近，噪声信息分布在其他频率。如果此时使用一个理想低通滤波器乘以输入信号以滤去其他频率的幅值，则会得到下图：

<div align='center'><img src='.\pic\屏幕截图 2024-08-11 161606.png' width='500px'></div>

因此，设计一个频域滤波器，将其与含噪声信号的频谱在频域上相乘，再将乘积做傅里叶逆变换，即可实现滤波，这种滤波器叫频域滤波器。

由于在频域上的乘积等效于时域上的卷积，因此，如果通过傅里叶逆变换得到频域滤波器的频响特性对应的时域序列，该序列就是 FIR 滤波器的**脉冲响应**。将输入信号与这个脉冲响应序列在时域上做卷积运算，即可实现滤波。

“有限冲激响应”（Finite Impulse Response，简称 FIR）滤波器之所以被称为 “有限”，关键在于它的脉冲响应是有限长的，也就是说，其脉冲响应序列只有有限个非零值，且在这些非零值之外，全为零。

FIR 滤波器的阶数 $N$ 是指滤波器脉冲响应序列 $h[n]$ 中非零系数的数量减去一。如果 FIR 滤波器的脉冲响应序列 $h[n]$ 有 $M$ 个非零系数，则滤波器的阶数 $N = M - 1$ 。在时域中，FIR 滤波器的输出 $y[n]$ 是输入信号 $x[n]$ 与滤波器脉冲响应 $h[n]$ 的卷积。具体计算公式如下：

$$y[n] = \sum_{k=0}^{N} h[k] \cdot x[n-k]$$

假设一个 FIR 滤波器的脉冲响应序列为 $h[n] = [h_0, h_1, h_2, h_3]$ ，则：

$$y[n] = h_0 \cdot x[n] + h_1 \cdot x[n-1] + h_2 \cdot x[n-2] + h_3 \cdot x[n-3]$$

## IIR 滤波器

FIR 滤波器的脉冲响应具有有限个非零系数，这与无限冲激响应（IIR）滤波器形成了对比。IIR 滤波器的脉冲响应理论上可以是无限长的，因为 IIR 滤波器的反馈结构可能导致输出信号的持续振荡或延续。

IIR滤波器的差分方程可以表示为：

$$y[n] = \sum_{k=0}^{N} b_k \cdot x[n-k] - \sum_{j=1}^{M} a_j \cdot y[n-j]$$

其中， $x[n]$ 表示输入信号序列； $y[n]$ 表示输出信号序列； $b_k$ 表示前馈（输入）系数，用于输入信号的加权； $a_j$ 表示反馈（输出）系数，用于前一时刻输出信号的加权； $N$ 和 $M$ 分别表示前馈部分和反馈部分的阶数。

### 工作过程

  1. 前馈部分：和FIR滤波器类似，前馈部分是对当前输入信号及其延迟的加权和进行计算。其计算涉及输入信号的当前值及过去N个样本的加权求和。
  2. 反馈部分：不同于 FIR 滤波器，IIR 滤波器的输出不仅取决于当前输入信号，还取决于以前的输出信号。反馈部分是对先前输出信号的加权求和，并从前馈部分的结果中减去该和。
  3. 滤波器输出：最终的输出是前馈部分和反馈部分的结合，形成了 IIR 滤波器的输出信号。

### 设计方法

IIR 滤波器的设计通常使用经典的模拟滤波器设计方法（如 Butterworth、Chebyshev、椭圆滤波器等），然后通过双线性变换（Bilinear Transform）将模拟滤波器转换为数字滤波器。

下面以一个 3 阶的低通巴特沃斯滤波器为例，介绍如何使用双线性变换法获得数字滤波器表示。

巴特沃斯滤波器的模拟域传递函数 $H(s)$ 通常具有以下形式：

$$H(s) = \frac{1}{b_n \cdot s^n + b_{n-1} \cdot s^{n-1} + \cdots + b_1 \cdot s + b_0}$$

对于 3 阶巴特沃斯滤波器，其标准化传递函数为：

$$H(s) = \frac{\omega_c^3}{s^3 + 2\omega_c \cdot s^2 + 2\omega_c^2 \cdot s + \omega_c^3}$$

其中， $n$ 表示滤波器阶数， $\omega_c$ 表示通带截止频率。

双线性变换将模拟域中的 $s$-域转换为数字域中的 $z$-域。其基本公式为：

$$s= \frac{2}{T}\cdot \frac{1-z^{-1}}{1+z^{-1}}$$

其中， $T$ 是采样周期， $s$ 是模拟域的复频率变量， $z$ 是数字域的复频率变量。

假设选择的采样频率 $f_s = 8 \text{kHz}$ ，则 $T=\frac{1}{f_s} = 0.000125$ 秒。

将模拟滤波器的传递函数 $H(s)$ 代入双线性变换公式，进行替换并整理为如下格式：

$$H(z) = \frac{K\cdot (1+z^{-1})^3}{A \cdot (1-z^{-1})^3 + B(1-z^{-1})^2(1+z^{-1}) + C \cdot (1-z^{-1})(1+z^{-1})^2 + D \cdot (1+z^{-1})^3}$$

展开上式得：

$$H(z) = \frac{b_0 + b_1\cdot z^{-1} + b_2 \cdot z^{-2} + b_3 \cdot z^{-3}}{1+a_1 \cdot z^{-1} + a_2 \cdot z^{-2} + a_3 \cdot z^{-3}}$$

数字滤波器通常采用直接 I 型结构来实现，直接 I 型结构的差分方程为：

$$y[n] = b_0 \cdot x[n] + b_1 \cdot x[n-1] + b_2 \cdot x[n-2] + b_3 \cdot x[n-3] - a_1 \cdot y[n-1] - a_2 \cdot y[n-2] - a_3 \cdot y[n-3]$$

其中， $b_0, b_1, b_2, b_3$ 和 $a_1, a_2, a_3$ 是数字滤波器系数，在 FPGA 实现中可以固化到 ROM 中； $x[n]$ 是当前输入得样本； $y[n]$ 是当前输出的样本； $x[n-1], x[n-2], x[n-3]$ 是之前输入的样本； $y[n-1], y[n-2], y[n-3]$ 是之前输出的样本。

上式差分方程即是 FPGA 实现最终滤波器的数学公式。