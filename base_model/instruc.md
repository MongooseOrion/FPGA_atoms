# 语法内容
尽管 Verilog 的语法在很大程度上与 c 语言类似，但是由于其是一门设计硬件的语言，在诸多语法上仍会有所不同，这可能会导致 “先入为主” 的错误。下面就介绍一些内容。

## 文件写入和读取操作
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

## 随机数生成
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

## 阻塞和非阻塞赋值
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
