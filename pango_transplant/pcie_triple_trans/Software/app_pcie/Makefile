#生成可执行文件的名称
Target = app
#编译器CC
CC = gcc
#存放中间文件的路径
build_dir = build
#存放源文件的文件夹
src_dir =  sources
#存放头文件的文件夹
inc_dir = includes

#源文件
sources = $(foreach dir,$(src_dir),$(wildcard $(dir)/*.c))
#目标文件（*.o）
objects = $(patsubst %.c,$(build_dir)/%.o,$(notdir $(sources)))
#头文件
includes = $(foreach dir,$(inc_dir),$(wildcard $(dir)/*.h))
#编译参数
#指定头文件的路径
CFLAGS = $(patsubst %, -I%, $(inc_dir))

# GTK 和 ALSA 的编译和链接参数
GTK = `pkg-config --cflags --libs gtk+-2.0 gmodule-export-2.0`
ALSA = `pkg-config --cflags --libs alsa`

#链接过程
$(build_dir)/$(Target) : $(objects)  | create_build
	$(CC) $^ -o $@ $(GTK) $(ALSA)

#编译源文件
$(build_dir)/%.o : $(src_dir)/%.c $(includes)  | create_build
	$(CC) -c $(CFLAGS) $< -o $@ $(GTK) $(ALSA)

#以下为伪目标，调用方式：make 伪目标
.PHONY:clean check create_build
clean:
	rm -rf $(build_dir)

check:
	@echo $(CFLAGS)
	@echo $(CURDIR)
	@echo $(src_dir)
	@echo $(sources)
	@echo $(objects)
	
# 创建编译目录
create_build:
	@mkdir -p $(build_dir)

cp:	
	cp ./build/app ./
