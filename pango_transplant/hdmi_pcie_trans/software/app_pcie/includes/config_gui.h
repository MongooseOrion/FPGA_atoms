#ifndef _CONFIG_GUI_H
#define _CONFIG_GUI_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>
#include <fcntl.h> 
#include <sys/ioctl.h> 
#include <time.h>
#include <pthread.h>
#include <sys/mman.h>
#include <glib.h>
#include <gtk/gtk.h>
#include "color.h"

 #include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <linux/videodev2.h>
#include <sys/ioctl.h>
#include <errno.h>

#define WIDTH 1920
#define HEIGHT 1080
#define RGB_MODE  2  //一个像素多少个字节
#define FRAME_SIZE (WIDTH*HEIGHT*3)
#define PIXEL_FORMAT V4L2_PIX_FMT_RGB24
#define NO_TEST														/* 代码功能测试时打开注释 */
#define DEBUG
/* 宽间距为了兼容低版本，部件尺寸标准不一致 */
//#define WIDGET_SPACE													/* 部件间距，宏定义打开表示为宽松；注释掉表示间距紧凑 */

#define PCIE_DRIVER_FILE_PATH 			"/dev/pango_pci_driver"			/* pcie驱动文件目录 */
#define MEM_FILE_PATH 					"/dev/mem"						/* mem驱动文件目录 */
#define VEISION 						"Pango PCIe Test v1.0"			/* 软件测试版本信息 */

#define TYPE 							'S'
#define PCI_READ_DATA_CMD    			_IOWR(TYPE, 0, int)				/* 读数据指令 */
#define PCI_WRITE_DATA_CMD    			_IOWR(TYPE, 1, int)				/* 写数据指令 */
#define PCI_MAP_ADDR_CMD    			_IOWR(TYPE, 2, int)				/* DMA总线地址映射 */
#define PCI_WRITE_TO_KERNEL_CMD    		_IOWR(TYPE, 3, int)				/* 写内核数据操作 */
#define PCI_DMA_READ_CMD    			_IOWR(TYPE, 4, int)				/* DMA读操作 */
#define PCI_DMA_WRITE_CMD    			_IOWR(TYPE, 5, int)				/* DMA写操作 */
#define PCI_READ_FROM_KERNEL_CMD    	_IOWR(TYPE, 6, int)				/* 读取内核数据操作 */
#define PCI_UMAP_ADDR_CMD    			_IOWR(TYPE, 7, int)				/* 释放映射地址 */
#define PCI_PERFORMANCE_START_CMD		_IOWR(TYPE, 8, int)				/* 性能测试开始操作 */
#define PCI_PERFORMANCE_END_CMD			_IOWR(TYPE, 9, int)				/* 性能测试结束操作 */

//新增的命令
#define PCI_READ_DATA1		_IOWR(TYPE, 10, int)							//读缓存区1数据指令
#define PCI_READ_DATA2		_IOWR(TYPE, 11, int)							//读缓存区2数据指令
#define PCI_READ_DATA3		_IOWR(TYPE, 12, int)							//读缓存区flag数据指令



#define MAX_BLOCK_SIZE   				1024							/* 位流分块缓存区最大值 */
#define LINK_OK							0x11							/* PCI链接成功，返回值 bit[4:0]*/
#define CRC_OK							0xa00							/* 位流加载完成后，校验成功返回值 bit[11:8]*/
#define CRC_ERROR						0xe00							/* 位流加载完成后，校验错误返回值 bit[11:8]*/
#define CRC_REPEAT						0xf00							/* 位流加载完成后，重新读取校验返回值 bit[11:8]*/
#define AXI_CONNECT_USER				0xa								/* AXI链接用户接口配置值 bit[3:0]*/
#define AXI_CONNECT_SWITCH				0xf								/* AXI链接转换接口配置值 bit[3:0]*/
#define LOAD_DATA_FINISH        		0xa0							/* 位流加载成功返回值 bit[7:4]*/
#define LOAD_DATA_UNFINISH				0x00							/* 位流正在加载返回值 bit[7:4]*/
#define BAR_OFFSET_1					0x00							/* 读取PCI状态地址偏移地址 */
#define BAR_OFFSET_2					0x10							/* 配置PCI加载偏移地址 */
#define BAR_OFFSET_3					0x20							/* 加载位流偏移地址 */
#define PEFORMANCE_STATUS_OFFSET		0x00							/* 性能测试状态寄存器 */
#define PEFORMANCE_WRITE_CNT_OFFSET		0x04							/* 性能测试DMA写计数 */	
#define PEFORMANCE_READ_CNT_OFFSET		0x08							/* 性能测试DMA读计数 */	
#define PEFORMANCE_ERROR_CNT_OFFSET		0x0c							/* 性能测试错误计数 */	
#define PEFORMANCE_DATA_CNT_OFFSET		0x10							/* 性能测试数据包计数 */	

#define PAGE_ROUND_DOWN(x)				((x) & ~(getpagesize() - 1))
#define PAGE_ROUND_UP(x)				(PAGE_ROUND_DOWN((x) + getpagesize() - 1))
#define file_len(len)					((len)%4 == 0 ? (len)/4 : ((len)/4)+1)
#define BOOL_SWITCH(flag)  				(((flag) == TRUE) ? FALSE : TRUE) //布尔值取反可以理解为
#define DMA_MAX_PACKET_SIZE   			4194304							/* DMA包最大值 */
#define DMA_MIN_PACKET_SIZE   			4								/* DMA包最小值 */
int pci_driver_fd = -1;													/* PCIe驱动文件描述符 */
char *bit_file_name = NULL;
char *dma_write_file_name = NULL;
char *button_info = NULL;

typedef enum _OPERATION_NUM_
{
	write_num = 0,
	read_num,
	w_r_num,
	info_num,
	tandem_num,
	performance_num
}op_num;

enum bar_num
{
	Bar0 = 0,
	Bar1,
	Bar2,
	Bar3,
	Bar4,
	Bar5
};

typedef struct _DMA_DATA_NEW_  //新增的DMA数据结构体
{
	unsigned char write_buf[DMA_MAX_PACKET_SIZE];
}DMA_DATA_NEW;
DMA_DATA_NEW dma_data1;

typedef struct _IDLE_FLAG_ //新增的空闲标志结构体
{
	unsigned int flag_data;
}IDLE_FLAG;
IDLE_FLAG idle_flag;







typedef struct _BAR_INFO_
{
	unsigned long bar_base;
	unsigned long bar_len;
}BAR_BASE_INFO;

typedef struct _CAP_INFO_
{
	unsigned char flag;
	unsigned char id;
	unsigned char addr_offset;
	unsigned char next_offset;
}CAP_INFO;

typedef struct _CAP_LIST_
{
	unsigned char cap_status;
	unsigned char cap_error;
	CAP_INFO cap_buf[256];
}CAP_LIST;

typedef struct _PCI_INFO_
{
	unsigned int vendor_id;
	unsigned int device_id;
	unsigned int cmd_reg;
	unsigned int status_reg;
	unsigned int revision_id;
	unsigned int class_prog;
	unsigned int class_device;
	BAR_BASE_INFO bar[6];
	unsigned int min_gnt;
	unsigned int max_lat;
	unsigned int link_speed;
	unsigned int link_width;
	unsigned int mps;
	unsigned int mrrs;
	unsigned int data[1024];
}PCI_DEVICE_INFO;

typedef struct _LOAD_DATA_
{
	unsigned int num_words;
	unsigned int block_words[MAX_BLOCK_SIZE];	
}LOAD_DATA_INFO;

typedef struct _PCI_LOAD_
{
	unsigned char link_status;
	unsigned int  crc;
	unsigned char axi_direction;
	unsigned char load_status;
	unsigned int total_num_words;
	LOAD_DATA_INFO data_block;
}PCI_LOAD_INFO;


typedef struct _COMMAND_
{
	unsigned char w_r;
	unsigned char step;
	unsigned int addr;
	unsigned int data;
	unsigned int cnt;
	unsigned int delay;
	PCI_DEVICE_INFO get_pci_dev_info;
	CAP_LIST cap_info;
	PCI_LOAD_INFO load_info;
}COMMAND_OPERATION;


COMMAND_OPERATION command_operation;

typedef struct _CONFIG_
{
	unsigned int addr;
	unsigned int data;
}CONFIG_OPERATION;

COMMAND_OPERATION config_operation;


typedef struct _FILE_INFO_
{
	FILE* _pg_load_file;
	unsigned int *file_data_buffer;
	unsigned int file_total_bytes;
	unsigned int file_total_dws;
	unsigned int file_blocks_integer;
	unsigned int file_blocks_remainder;
}FILE_INFO;

FILE_INFO load_file_info;
FILE_INFO dma_write_file_info;

typedef struct _SCREEN_INFO_
{
	int num;									/* 部件编号 */
    char * name;        						/* 窗口名称*/
    unsigned int type;  						/* 窗口类型*/
    int parent;         						/* 窗口父类 */
    unsigned int width;							/* 窗口宽度 */				
    unsigned int height;						/* 窗口高度 */
    unsigned int gint_x;   						/* 控件x坐标 */
    unsigned int gint_y;   						/* 控件y坐标 */
    int active;         						/* 控件初始化相关使能标志 */
    gboolean (*callback)(GtkWidget* ,void *);	/* 回调函数 */
    char * detailed_signal;    					/* 回调函数的详细操作信号 */
    gpointer Data;      						/* 传给回到函数的参数 */
}SCREEN_INFO;


typedef struct _ENTRY_INFO_
{
	int num;
	int id;
}ENTRY_INFO;

typedef struct _HANDLER_ID_
{
	ENTRY_INFO pio;
	ENTRY_INFO config;
	ENTRY_INFO start;
	ENTRY_INFO end;
	ENTRY_INFO alloc_mem;
	ENTRY_INFO offset_addr;
	ENTRY_INFO data_length;
	ENTRY_INFO packet_size;
}HANDLER_ID;

typedef struct _DEV_MEM_
{
	off_t offset;
	size_t len;
	void *vaddr;
} DEV_MEM;

DEV_MEM map_dev_mem = {0, 0, NULL};

typedef struct _PIO_PAGE_INFO_
{
	unsigned char bar;
	unsigned char w_r;
	unsigned int addr;
	unsigned int data;
	unsigned int cnt;
	unsigned int delay;
}PIO_INFO;

PIO_INFO pio_page_info;

typedef struct _BUTTON_FLAG_
{
	bool free_time;
	bool pio;
	bool dma_auto;
	bool close_file;
	bool manual_start;
	bool performance_start;
}BUTTON_FLAG;

BUTTON_FLAG button_flag = {FALSE, FALSE, FALSE, FALSE, FALSE, FALSE};

typedef struct _ID_
{
	unsigned char id;
	unsigned char *id_info;
}ID_INFO;

typedef struct _DMA_DATA_
{
	unsigned char read_buf[4096];
	unsigned char write_buf[4096];
}DMA_DATA;

typedef struct _DMA_OPERATION_
{
	unsigned int current_len;
	unsigned int offset_addr;
	unsigned int cmd;
	DMA_DATA data;
}DMA_OPERATION;

DMA_OPERATION dma_operation;

typedef struct _DMA_AUTO_
{
	unsigned int test_num;
	unsigned int start;
	unsigned int end;
	unsigned int step;
	unsigned int write_cnt;
	unsigned int read_cnt;
	unsigned int error_cnt;
	unsigned int step_add_cnt;
}DMA_AUTO;

DMA_AUTO dma_auto_info;


typedef struct _DMA_MANUAL_
{
	unsigned int allocate_mem_size;
	unsigned int offset_addr;
	unsigned int data_length;
}DMA_MANUAL;

DMA_MANUAL dma_manual_info;

typedef struct _PERFORMANCE_OPERATION_
{
	unsigned int current_len;
	unsigned int cmd;
	unsigned char cmp_flag;
}PERFORMANCE_OPERATION;

PERFORMANCE_OPERATION performance_operation;

typedef struct _PERFORMANCE_DATA_
{
	float w_throughput;
	float r_throughput;
	float w_bandwidth;
	float r_bandwidth;
	unsigned char dma_w_status;
	unsigned char dma_r_status;
	unsigned char busy_w_status;
	unsigned char busy_r_status;
	unsigned int w_total_cnt;
	unsigned int w_invalid_cnt;
	unsigned int w_error_cnt;
	unsigned int r_total_cnt;
	unsigned int r_invalid_cnt;
	unsigned int r_error_cnt;
}PERFORMANCE_DATA;

PERFORMANCE_DATA performance_data;


#endif // _CONFIG_GUI_H
