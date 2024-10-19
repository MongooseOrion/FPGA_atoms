#include "config_gui.h"
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/videodev2.h>
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"
gboolean quit_window( GtkWidget *Widget, gpointer Data );
gboolean clean_button( GtkWidget *Widget, gpointer Data );
gboolean dma_auto_test_button( GtkWidget *Widget, gpointer Data );
gboolean combo_selected_1( GtkWidget *Widget, gpointer Data );
gboolean combo_selected_2( GtkWidget *Widget, gpointer Data );
gboolean combo_selected_3( GtkWidget *Widget, gpointer Data );
gboolean combo_selected_4( GtkWidget *Widget, gpointer Data );
gboolean combo_selected_5( GtkWidget *Widget, gpointer Data );
gboolean performance_button( GtkWidget *Widget, gpointer Data );
gboolean config_button( GtkWidget *Widget, gpointer Data );
gboolean pio_test_button( GtkWidget *Widget, gpointer Data );
gboolean import_button( GtkWidget *Widget, gpointer Data );
gboolean load_button( GtkWidget *Widget, gpointer Data );
gboolean start_dma_button( GtkWidget *Widget, gpointer Data );
gboolean dma_write_button( GtkWidget *Widget, gpointer Data );
gboolean read_ddr_button( GtkWidget *Widget, gpointer Data );
gboolean close_dma_button( GtkWidget *Widget, gpointer Data );
void video_display(void);
gboolean dma_read_button( GtkWidget *Widget, gpointer Data );
gboolean write_ddr_button( GtkWidget *Widget, gpointer Data );
void stop_warning(BUTTON_FLAG *flag);
void button_status(void);
void button_process(void);
void dma_auto_process(DMA_AUTO *dma_auto, DMA_OPERATION *dma_oper);
void dma_manual_process(DMA_MANUAL *dma_manual, DMA_OPERATION *dma_oper);
void pio_test_process(COMMAND_OPERATION *cmd_op);
void performance_process(PERFORMANCE_OPERATION *per_info, PERFORMANCE_DATA *per_data);
void OpenTandemFile(GtkWidget *widget,gpointer *data);
void CancelTandemFile(GtkWidget *widget,gpointer *data);
void CloseTandemFile(GtkWidget *widget,gpointer *data);
void OpenDmaWriteFile(GtkWidget *widget,gpointer *data);
void CancelDmaOpenFile(GtkWidget *widget,gpointer *data);
void CloseDmaOpenFile(GtkWidget *widget,gpointer *data);
void switch_page(GtkNotebook *notebook, gpointer page,guint page_num, gpointer user_data);
void on_entry_insert_hex(GtkEditable *editable,gchar *new_text,gint new_text_length,gint *position,gpointer user_data);
void on_entry_insert_digit(GtkEditable *editable,gchar *new_text,gint new_text_length,gint *position,gpointer user_data);
void set_entry_text(unsigned int widget_num, unsigned int data);
int nano_delay(long delay);
void *map_mem(unsigned int addr, unsigned int size, DEV_MEM *map_mem);
void unmap_mem(DEV_MEM *map_mem);
unsigned int get_bar_info(COMMAND_OPERATION *cmd_op, unsigned int info_choice);
unsigned int pio_read(unsigned int *addr);
unsigned int pio_write(unsigned int *addr, unsigned int data);
int open_pci_driver(void);
int open_load_file(char* file_name, FILE_INFO *info);
void load_fial_bit(int fd, COMMAND_OPERATION *cmd_op, FILE_INFO *info, void *addr);
void cmd_operation(int fd, unsigned char cmd, COMMAND_OPERATION *cmd_op);
void scroll_to_line(GtkWidget *scrolled_window, gint line_num, gint to_line_index);
void create_text( const gchar *String );
void draw_widget(SCREEN_INFO *MyGuiScreen,void *PWidgets[],int i);

GtkWidget *TandemFileSelection = NULL;
GtkWidget *DmaWriteFileSelection = NULL;
void *pio_vaddr;
void *pio_vaddr_copy;
unsigned int temp_read_data = 0;
bool receive_flag = true;

enum print
{
  MSG_ERROR = 0,
  MSG_WARNING,
  MSG_INFO,
  MSG_DEBUG
};

enum print display = MSG_INFO;

#define msg_error       	display = MSG_ERROR; g_print
#define msg_warning     	display = MSG_WARNING; g_print
#define msg_info        	display = MSG_INFO; g_print
#define msg_debug       	display = MSG_DEBUG; g_print

#define printf_error(format, arg...)       	printf(NONE L_RED   "[ ERROR ] "); printf(format, ## arg)
#define printf_warning(format, arg...)     	printf(NONE YELLOW  "[WARNING] "); printf(format, ## arg)
#define printf_info(format, arg...)        	printf(NONE L_BLUE  "[ INFO  ] "); printf(format, ## arg)
#ifdef 	DEBUG
#define printf_debug(format, arg...)        printf(NONE L_GREEN "[ DEBUG ] "); printf(format, ## arg)
#else
#define printf_debug(format, arg...)        do {} while(0)
#endif


char *combo_box_text_1[]=
{
	"Write", 									/* 0 */
	"Read",    									/* 1 */
	"W & R",     								/* 2 */
	"W&R Step",									/* 3 */
	NULL
};

char *combo_box_text_2[]=
{
	"Write",									/* 0 */
	"Read",										/* 1 */
	NULL
};

char *combo_box_text_3[]=
{
	"Bar0",										/* 0 */
	"Bar1", 									/* 1 */
	"Bar2", 									/* 2 */
	"Bar3", 									/* 3 */
	"Bar4", 									/* 4 */
	"Bar5", 									/* 5 */
	NULL
};

char *combo_box_text_4[]=
{
	"Write",									/* 0 */
	"Read", 									/* 1 */
	"W & R",									/* 2 */
	NULL
};

char *combo_box_text_5[]=
{
	"0",										/* 0 */
//	"4", 										/* 1 */
//	"8",										/* 2 */
//	"16",										/* 3 */
//	"32",										/* 4 */
//	"64",										/* 5 */
//	"128",										/* 6 */
//	"256",										/* 7 */
//	"512",										/* 8 */
//	"1024",										/* 9 */
	NULL
};

char *button_char[]=
{
	"dma_auto", 								/* 0 */
	"dma_manual",								/* 1 */
	"pio_test",									/* 2 */
	"performance_test", 						/* 3 */
	NULL
};

enum ButtonInfoNum        						
{
    DMA_AUTO_INFO_NUM = 0,	
	DMA_MANUAL_INFO_NUM,	
    PIO_TEST_INFO_NUM,
    PERFORMANCE_TEST_NUM
};

ID_INFO cap_id[] =
{
	{0x00, "Null Capability"},
	{0x01, "PCI Power Management Interface"},
	{0x02, "AGP"},
	{0x03, "VPD"},
	{0x04, "Slot Identification"},
	{0x05, "Message Signaled Interrupts"},
	{0x06, "CompactPCI Hot Swap"},
	{0x07, "PCI-X"},
	{0x08, "HyperTransport"},
	{0x09, "Vendor Specific"},
	{0x0A, "Debug port"},
	{0x0B, "CompactPCI central resource control"},
	{0x0C, "PCI Hot-Plug"},
	{0x0D, "PCI Bridge Subsystem Vendor ID"},
	{0x0E, "AGP 8x"},
	{0x0F, "Secure Device"},
	{0x10, "PCI Express"},
	{0x11, "MSI-X"},
	{0x12, "Serial ATA Data/Index Configuration"},
	{0x13, "Advanced Features(AF)"},
	{0x14, "Enhanced Allocation"},
	{0x15, "Flattening Portal Bridge"},
	{0x16, "Reserved"},
};

ID_INFO extended_cap_id[] =
{
	{0x00, "Null Capability"},
	{0x01, "Advanced Error Reporting(AER)"},
	{0x02, "Virtual Channel(VC)"},
	{0x03, "Device Serial Number"},
	{0x04, "Power Budgeting"},
	{0x05, "Root Complex Link Declaration"},
	{0x06, "Root Complex Internal Link Control"},
	{0x07, "Root Complex Event Collector Endpoint Association"},
	{0x08, "Multi-Function Virtual Channel(MFVC)"},
	{0x09, "Virtual Channel(VC)"},
	{0x0A, "Root Complex Register Block(RCRB) Header"},
	{0x0B, "Vendor-Specific Extended Capability(VSEC)"},
	{0x0C, "Configuration Access Correlation(CAC)"},
	{0x0D, "Access Control Services(ACS)"},
	{0x0E, "Alternative Routing-ID Interpretation(ARI)"},
	{0x0F, "Address Translation Services(ATS)"},
	{0x10, "Single Root I/O Virtualization(SR-IOV)"},
	{0x11, "Multi-Root I/O Virtualization(MR-IOV)"},
	{0x12, "Multicast"},
	{0x13, "Page Request Interface(PRI)"},
	{0x14, "Reserved for AMD"},
	{0x15, "Resizable BAR"},
	{0x16, "Dynamic Power Allocation(DPA)"},
	{0x17, "TPH Requester"},
	{0x18, "Latency Tolerance Reporting(LTR)"},
	{0x19, "Secondary PCI Express"},
	{0x1A, "Protocol Multiplexing(PMUX)"},
	{0x1B, "Process Address Space ID(PASID)"},
	{0x1C, "LN Requester(LNR)"},
	{0x1D, "Downstream Port Containment(DPC)"},
	{0x1E, "L1 PM Substates"},
	{0x1F, "Precision Time Measurement(PTM)"},
	{0x20, "PCI Express over M-PHY(M-PCIe)"},
	{0x21, "FRS Queueing"},
	{0x22, "Readiness Time Reporting"},
	{0x23, "Designated Vendor-Specific Extended Capability"},
	{0x24, "VF Resizable BAR"},
	{0x25, "Data Link Feature"},
	{0x26, "Physical Layer 16.0 GT/s"},
	{0x27, "Lane Margining at the Receiver"},
	{0x28, "Hierarchy ID"},
	{0x29, "Native PCIe Enclosure Management(NPEM)"},
	{0x2A, "Physical Layer 32.0 GT/s"},
	{0x2B, "Alternate Protocol"},
	{0x2C, "System Firmware Intermediary(SFI)"},
	{0x2D, "Reserved"},
};

enum											/* 部件类型 */
{
    WINDOW=0, FIXED, NOTEBOOK, FRAME, LABEL, BUTTON, SCROLLED,TEXT,ENTRY,COMBO_BOX
};

enum WidgetIndex        						/* 对应的父部件 */
{
    MAIN_WINDOW_INDEX=0,
    FIXED_INDEX,
    NOTEBOOK_INDEX,
	NOTEBOOK_FRAME_INDEX_1,
	NOTEBOOK_FRAME_INDEX_2,
	NOTEBOOK_FRAME_INDEX_3,
	NOTEBOOK_FRAME_INDEX_4,
	PERFORMANCE_FRAME_INDEX,
	CONFIG_FRAME_INDEX,
	ENDPOINT_FRAME_INDEX,
    SCROLLED_INDEX,
    NOTEBOOK_FRAME_FIXED_INDEX_1,
	NOTEBOOK_FRAME_FIXED_INDEX_2,
	NOTEBOOK_FRAME_FIXED_INDEX_3,
	NOTEBOOK_FRAME_FIXED_INDEX_4,
	PERFORMANCE_FRAME_FIXED_INDEX,
	CONFIG_FRAME_FIXED_INDEX,
	ENDPOINT_FRAME_FIXED_INDEX,		
} MainIndex;

enum ConfigNum
{
	C_BUTTON = 52,
	C_W_R_NUM,
	C_OFFSET_NUM,
	C_DATA_NUM,
};

enum PioTestPageNum
{
	BAR_NUM = 115,
	W_R_NUM,
	OFFSET_NUM,
	DATA_NUM,
	CNT_NUM,
	DELAY_NUM,
	PIO_BUTTON_NUM
};

enum DMAAutoPageNum
{
	TEST_NUM = 29,
	START_NUM,
	END_NUM,
	STEP_NUM,
	WRITE_CNT_NUM,
	READ_CNT_NUM,
	ERROR_CNT_NUM,
	AUTO_BUTTON_NUM
};

enum DMAManualPageNum
{
	START_DMA_NUM = 99,
	ALLOCATE_MEM_SIZE = 102,
	OFFSET_ADDR_NUM,
	DATA_LENGTH_NUM,
	CLOSE_DMA_NUM
};

enum PCIePerformanceNum
{
	PER_W_R_NUM = 43,
	WRITE_TROUGHPUT_NUM,
	READ_TROUGHPUT_NUM,
	WRITE_BANDWIDTH_NUM,
	READ_BANDWIDTH_NUM,
	PER_START_NUM,
	PER_PACKET_SIZE_NUM = 127,
};

enum PCIePerformanceCmd
{
	READ_CMD = 0x00,
	WRITE_CMD,
	W_R_CMD
};

enum PCIeEndpointStatusNum
{
	VEDION_ID_NUM = 76,
};

enum BarInfoNum
{
	BAR_ADDRESS = 0,
	BAR_LEN
};

ENTRY_INFO pio_addr_offset;
ENTRY_INFO pio_data;
ENTRY_INFO config_addr_offset;
ENTRY_INFO config_data;
ENTRY_INFO dma_auto_start;
ENTRY_INFO dma_auto_end;
ENTRY_INFO dma_manual_alloc_mem;
ENTRY_INFO dma_manual_offset_addr;
ENTRY_INFO dma_data_length;
ENTRY_INFO performance_packet_size;


HANDLER_ID entry_callback_id = 
{
	{DATA_NUM, 0},
	{C_DATA_NUM, 0},
	{START_NUM, 0},
	{END_NUM, 0},
	{ALLOCATE_MEM_SIZE, 0},
	{OFFSET_ADDR_NUM, 0},
	{DATA_LENGTH_NUM, 0},
	{PER_PACKET_SIZE_NUM, 0},
};

enum AllFrame									/* 主窗口Frame等主部件的高度和宽度偏移量*/							
{	
	af_h = 0,									/* 高度偏移 */
	af_w = 0,									/* 宽度偏移 */
};


/*----------------------------------------------部件间距紧凑----------------------------------------------*/	
#ifndef WIDGET_SPACE
	enum NoteBook_F1								/* NoteBook第一页Frame包含的label以及entry坐标和步进*/							
	{	
		lx1 = 35,									/* label x坐标 */
		ly1 = 25,									/* label y坐标 */
		ls1 = 30,									/* label y坐标步进 */
		ex1 = 220,									/* entry x坐标 */
		ey1 = 20,									/* entry y坐标 */
		es1 = 30,									/* entry y坐标步进 */
	};

	enum NoteBook_F2								/* NoteBook第二页Frame包含的label以及entry坐标和步进*/							
	{	
		lx2 = 30,									/* label x坐标 */
		ly2 = 40,									/* label y坐标 */
		ls2 = 30,									/* label y坐标步进 */
		ex2 = 230,									/* entry x坐标 */
		ey2 = 35,									/* entry y坐标 */
		es2 = 30,									/* entry y坐标步进 */
	};

	enum NoteBook_F3								/* NoteBook第三页Frame包含的label以及entry坐标和步进*/							
	{	
		lx3 = 40,									/* label x坐标 */
		ly3 = 40,									/* label y坐标 */
		ls3 = 30,									/* label y坐标步进 */
		ex3 = 220,									/* entry x坐标 */
		ey3 = 35,									/* entry y坐标 */
		es3 = 30,									/* entry y坐标步进 */
	};

	enum NoteBook_F4								/* NoteBook第四页Frame包含的label以及entry坐标和步进*/							
	{	
		lx4 = 40,									/* label x坐标 */
		ly4 = 75,									/* label y坐标 */
		ls4 = 100,									/* label y坐标步进 */
		ex4 = 220,									/* entry x坐标 */
		ey4 = 70,									/* entry y坐标 */
		es4 = 100,									/* entry y坐标步进 */
	};


	enum Performance_F								/* Performance界面包含的label以及entry等的坐标和步进*/							
	{	
		lx_p = 25,									/* label x坐标 */
		ly_p = 35,									/* label y坐标 */
		ls_p = 30,									/* label y坐标步进 */
		ex_p = 240,									/* entry x坐标 */
		ey_p = 30,									/* entry y坐标 */
		es_p = 30,									/* entry y坐标步进 */
	};

	enum Config_F									/* Config界面包含的label以及entry等的坐标和步进*/							
	{	
		lx_c = 10,									/* label x坐标 */
		ly_c = 10,									/* label y坐标 */
		ls_c = 230,									/* label y坐标步进 */
		ex_c = 110,									/* entry x坐标 */
		ey_c = 5,									/* entry y坐标 */
		es_c = 260,									/* entry y坐标步进 */
	};

	enum Endpoint_F									/* Endpoint界面包含的label以及entry等的坐标和步进*/							
	{	
		lx_e = 10,									/* label x坐标 */
		ly_e = 20,									/* label y坐标 */
		ls_x = 200,									/* label x坐标步进 */
		ls_y = 25, 									/* label y坐标步进 */
		ld_x = 10,									/* label x坐标调整步进 */
		ex_e = 90,									/* entry x坐标 */
		ey_e = 15,									/* entry y坐标 */
		ed_x = 10,									/* entry x坐标调整步进 */
		es_x = 160,									/* entry x坐标步进 */
		es_y = 25, 									/* entry y坐标步进 */
	};

	enum BoxSize									/* BOX部件的高度和宽度 */							
	{	
		box_h = 30, 								/* 高度 */
		box_w = 90, 								/* 宽度 */
	};

	enum ButtonSize 								/* BUTTON部件的高度和宽度 */							
	{	
		but_h = 30, 								/* 高度 */
		but_w = 90, 								/* 宽度 */
	};

	enum EntrySize									/* ENTRY部件的高度和宽度 */ 						
	{	
		ent_h = 0,									/* 高度 */
		ent_w = 10, 								/* 宽度 */
	};

#else
/*----------------------------------------------部件间距宽松----------------------------------------------*/
	enum NoteBook_F1								/* NoteBook第一页Frame包含的label以及entry坐标和步进*/							
	{	
		lx1 = 35,									/* label x坐标 */
		ly1 = 17,									/* label y坐标 */
		ls1 = 32,									/* label y坐标步进 */
		ex1 = 220,									/* entry x坐标 */
		ey1 = 12,									/* entry y坐标 */
		es1 = 32,									/* entry y坐标步进 */
	};

	enum NoteBook_F2								/* NoteBook第二页Frame包含的label以及entry坐标和步进*/							
	{	
		lx2 = 30,									/* label x坐标 */
		ly2 = 40,									/* label y坐标 */
		ls2 = 32,									/* label y坐标步进 */
		ex2 = 230,									/* entry x坐标 */
		ey2 = 35,									/* entry y坐标 */
		es2 = 32,									/* entry y坐标步进 */
	};

	enum NoteBook_F3								/* NoteBook第三页Frame包含的label以及entry坐标和步进*/							
	{	
		lx3 = 40,									/* label x坐标 */
		ly3 = 35,									/* label y坐标 */
		ls3 = 33,									/* label y坐标步进 */
		ex3 = 220,									/* entry x坐标 */
		ey3 = 30,									/* entry y坐标 */
		es3 = 33,									/* entry y坐标步进 */
	};

	enum NoteBook_F4								/* NoteBook第四页Frame包含的label以及entry坐标和步进*/							
	{	
		lx4 = 40,									/* label x坐标 */
		ly4 = 75,									/* label y坐标 */
		ls4 = 100,									/* label y坐标步进 */
		ex4 = 220,									/* entry x坐标 */
		ey4 = 70,									/* entry y坐标 */
		es4 = 100,									/* entry y坐标步进 */
	};


	enum Performance_F								/* Performance界面包含的label以及entry等的坐标和步进*/							
	{	
		lx_p = 25,									/* label x坐标 */
		ly_p = 25,									/* label y坐标 */
		ls_p = 35,									/* label y坐标步进 */
		ex_p = 240,									/* entry x坐标 */
		ey_p = 20,									/* entry y坐标 */
		es_p = 35,									/* entry y坐标步进 */
	};

	enum Config_F									/* Config界面包含的label以及entry等的坐标和步进*/							
	{	
		lx_c = 10,									/* label x坐标 */
		ly_c = 10,									/* label y坐标 */
		ls_c = 230,									/* label y坐标步进 */
		ex_c = 110,									/* entry x坐标 */
		ey_c = 5,									/* entry y坐标 */
		es_c = 260,									/* entry y坐标步进 */
	};

	enum Endpoint_F									/* Endpoint界面包含的label以及entry等的坐标和步进*/							
	{	
		lx_e = 10,									/* label x坐标 */
		ly_e = 10,									/* label y坐标 */
		ls_x = 200,									/* label x坐标步进 */
		ls_y = 28, 									/* label y坐标步进 */
		ld_x = 10,									/* label x坐标调整步进 */
		ex_e = 90,									/* entry x坐标 */
		ey_e = 5,									/* entry y坐标 */
		ed_x = 10,									/* entry x坐标调整步进 */
		es_x = 160,									/* entry x坐标步进 */
		es_y = 28, 									/* entry y坐标步进 */
	};
	
	enum BoxSize									/* BOX部件的高度和宽度 */							
	{	
		box_h = 30,									/* 高度 */
		box_w = 100,								/* 宽度 */
	};

	enum ButtonSize									/* BUTTON部件的高度和宽度 */							
	{	
		but_h = 30, 								/* 高度 */
		but_w = 100, 								/* 宽度 */
	};

	enum EntrySize 									/* ENTRY部件的高度和宽度 */							
	{	
		ent_h = 0, 									/* 高度 */
		ent_w = 10, 								/* 宽度 */
	};
#endif
/*--------------------------------------------------------------------------------------------------------------------*/



SCREEN_INFO GuiScreen[] = 
{
	/* num   	name        type   	 	parent  	 		width  		height   	x    y    	active  callback   detailed_signal  data */		
	/* 主窗口 */
	{0, 	VEISION, 		WINDOW,   	-1,    			770+af_w,    	740+af_h,   0,   0,    	   FALSE,quit_window,"destroy",NULL},
	/* 主窗口的fixed容器 */
	{1, 	NULL, 			FIXED,    	MAIN_WINDOW_INDEX,	0,	  	0,		0,	 	0,  		   FALSE, 	NULL,	 NULL,	   NULL},		
	/* notebook部件 */
	{2, 	NULL, 			NOTEBOOK, 	FIXED_INDEX,	  	0,	  	0,		10,	 	10, 		   FALSE, 	NULL,	 NULL,	   NULL},
	/* notebook页面1 */
	{3, 	"DMA Auto", 	FRAME,		NOTEBOOK_INDEX,	  	365+af_w,	  280+af_h,	0,	 0,  	   TRUE, 	NULL,    NULL, 	 "blue"},
	/* notebook页面2 */
	{4, 	"DMA Manual", 	FRAME, 		NOTEBOOK_INDEX, 	365+af_w,	  280+af_h,	0,	 0,  	   TRUE, 	NULL,	 NULL, 	 "blue"},
	/* notebook页面3 */
	{5, 	"PIO Test", 	FRAME, 		NOTEBOOK_INDEX,   	365+af_w,	  280+af_h,	0,	 0,  	   TRUE, 	NULL,	 NULL, 	 "blue"},
	/* notebook页面4 */
	{6, 	"Tandem", 		FRAME, 		NOTEBOOK_INDEX,     365+af_w,	  280+af_h,	0,	 0,  	   TRUE, 	NULL,	 NULL, 	 "blue"},
	/* performance页面 */
	{7, 	"PCIe DMA Performance Test", 	FRAME, 	FIXED_INDEX, 360, 292,	400+af_w, 30+af_h,     FALSE,  NULL, 	 NULL, 	   NULL},
	/* config operation页面 */
	{8, 	"PCIe Config Operation", 		FRAME, 	FIXED_INDEX, 750, 60, 10+af_w, 332+af_h,       FALSE,  NULL, 	 NULL, 	   NULL},
	/* endpoint status页面 */
	{9, 	"PCIe Endpoint Status", 		FRAME, 	FIXED_INDEX, 750, 200, 10+af_w, 401+af_h,      FALSE,  NULL, 	 NULL, 	   NULL},
	/* show info */
	{10, 	NULL, 			SCROLLED,		FIXED_INDEX,		  750,	 86, 10+af_w, 642+af_h,	   FALSE,  NULL,	 NULL, 	   NULL},
	/* notebook页面1fixed容器 */
	{11, 	NULL, 			FIXED,	NOTEBOOK_FRAME_INDEX_1,	  0,	  0,	0,  0,    			   FALSE,  NULL, 	 NULL, 	   NULL},
	/* notebook页面2fixed容器 */
	{12, 	NULL, 			FIXED,	NOTEBOOK_FRAME_INDEX_2,	  0,	  0,	0,  0,    			   FALSE,  NULL,	 NULL, 	   NULL},
	/* notebook页面3fixed容器 */
	{13, 	NULL, 			FIXED,	NOTEBOOK_FRAME_INDEX_3,	  0,	  0,	0,  0,    			   FALSE,  NULL,	 NULL, 	   NULL},
	/* notebook页面4fixed容器 */
	{14, 	NULL, 			FIXED,	NOTEBOOK_FRAME_INDEX_4,	  0,	  0,	0,  0,    			   FALSE,  NULL,	 NULL, 	   NULL},
	/* performance页面fixed容器 */
	{15, 	NULL, 			FIXED,	PERFORMANCE_FRAME_INDEX,  0,	  0,	0,	0,	  			   FALSE,  NULL, 	 NULL, 	   NULL},
	/* config operation页面fixed容器 */
	{16, 	NULL, 			FIXED,	CONFIG_FRAME_INDEX,       0,	  0,	0,	0,	 	 		   FALSE,  NULL, 	 NULL, 	   NULL},
	/* endpoint status页面fixed容器 */
	{17, 	NULL, 			FIXED,	ENDPOINT_FRAME_INDEX, 	  0,	  0,	0,	0,	  			   FALSE,  NULL, 	 NULL, 	   NULL},
	/* print info label */
	{18, 	"Print Info", 	LABEL,   FIXED_INDEX,      		  0,      0,   15+af_w, 613+af_h,      FALSE,  NULL, 	 NULL, 	   NULL},
	/* clean button */
	{19, 	"Clean", 		BUTTON,		FIXED_INDEX,	  but_w,but_h,  100+af_w, 606+af_h, 	   TRUE,clean_button,"clicked",NULL},
	/* text view */
	{20, 	NULL, 			TEXT,	SCROLLED_INDEX,		  	  0,	  0,    0, 0,	  			   FALSE,  NULL,	NULL, 	   NULL},
	/* Test Num label */
	{21, 	"Test Num:", 				LABEL,  NOTEBOOK_FRAME_FIXED_INDEX_1, 0, 0, lx1, ly1,	   FALSE,	NULL,	NULL, 	   NULL},
	/* Start Packet Size(bytes) label */
	{22, 	"Start Packet Size(bytes):",LABEL,  NOTEBOOK_FRAME_FIXED_INDEX_1, 0, 0, lx1, ly1+ls1*1,FALSE, 	NULL,  	NULL,	   NULL},
	/* End Packet Size(bytes) label */
	{23, 	"End Packet Size(bytes):", 	LABEL,  NOTEBOOK_FRAME_FIXED_INDEX_1, 0, 0, lx1, ly1+ls1*2,FALSE, 	NULL,  	NULL,	   NULL},
	/* Packet Step(bytes) label */
	{24, 	"Packet Step(bytes):", 		LABEL,	NOTEBOOK_FRAME_FIXED_INDEX_1, 0, 0, lx1, ly1+ls1*3,FALSE, 	NULL,  	NULL,	   NULL},
	/* Write Packet Count label */
	{25, 	"Write Packet Count:", 		LABEL,  NOTEBOOK_FRAME_FIXED_INDEX_1, 0, 0, lx1, ly1+ls1*4,FALSE, 	NULL,  	NULL,	   NULL},
	/* Read Packet Count label */
	{26, 	"Read Packet Count:", 		LABEL,  NOTEBOOK_FRAME_FIXED_INDEX_1, 0, 0, lx1, ly1+ls1*5,FALSE, 	NULL,  	NULL,	   NULL},
	/* Error Packet Count label */
	{27, 	"Error Packet Count:", 		LABEL,  NOTEBOOK_FRAME_FIXED_INDEX_1, 0, 0, lx1, ly1+ls1*6,FALSE, 	NULL,  	NULL,	   NULL},
	/* Operation Button label */
	{28, 	"Operation Button:", 		LABEL,	NOTEBOOK_FRAME_FIXED_INDEX_1, 0, 0, lx1, ly1+ls1*7,FALSE, 	NULL,  	NULL,	   NULL},
	/* Test Num Entry */
	{29, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_1, ent_w, 0,ex1, ey1,       TRUE,NULL,  	NULL,		"1"},
	/* Start Packet Size(bytes) Entry */
	{30, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_1, ent_w, 0, ex1, ey1+es1*1,TRUE,NULL,	NULL,	  "128"},
	/* End Packet Size(bytes) Entry */
	{31, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_1, ent_w, 0, ex1, ey1+es1*2,FALSE,NULL,	NULL, 	  "128"},
	/* Packet Step(bytes) Box */
	{32, 	NULL, COMBO_BOX,NOTEBOOK_FRAME_FIXED_INDEX_1,box_w,box_h,ex1,ey1+es1*3-2,	FALSE, 	combo_selected_5,	"changed",	"5"},
	/* Write Packet Count Entry */
	{33, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_1, ent_w, 0, ex1,ey1+es1*4,  FALSE,	NULL, "green", 	"0"},
	/* Read Packet Count Entry */
	{34, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_1, ent_w, 0, ex1, ey1+es1*5, FALSE,	NULL, "blue",  	"0"},
	/* Error Packet Count Entry */
	{35, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_1, ent_w, 0, ex1, ey1+es1*6, FALSE,  NULL, "red",   	"0"},
	/* Operation Button */
	{36,	"Start Test",BUTTON,NOTEBOOK_FRAME_FIXED_INDEX_1,but_w,but_h,ex1,ey1+es1*7,	TRUE,	dma_auto_test_button,"clicked",NULL},
	/* Operation Button label */
	{37, 	"DMA Read/Write Mode:", 	LABEL,	PERFORMANCE_FRAME_FIXED_INDEX, 0, 0, lx_p, ly_p, 		FALSE, 	NULL,	NULL,  NULL},
	/* Operation Button label */
	{38, 	"Write Throughput(MB/s):", 	LABEL,	PERFORMANCE_FRAME_FIXED_INDEX, 0, 0, lx_p, ly_p+ls_p*2, FALSE, 	NULL,	NULL,  NULL},
	/* Operation Button label */
	{39, 	"Read Throughput(MB/s):", 	LABEL, 	PERFORMANCE_FRAME_FIXED_INDEX, 0, 0, lx_p, ly_p+ls_p*3, FALSE, 	NULL,	NULL,  NULL},
	/* Operation Button label */
	{40, 	"Write Bandwidth Utilization(%):",LABEL,PERFORMANCE_FRAME_FIXED_INDEX, 0, 0,lx_p,ly_p+ls_p*4,FALSE,	NULL,	NULL,  NULL},
	/* Operation Button label */
	{41, 	"Read Bandwidth Utilization(%):", LABEL,PERFORMANCE_FRAME_FIXED_INDEX, 0, 0,lx_p,ly_p+ls_p*5,FALSE,	NULL,	NULL,  NULL},
	/* Operation Button label */
	{42, 	"Operation Button:", 		LABEL, 	PERFORMANCE_FRAME_FIXED_INDEX, 0, 0, lx_p, ly_p+ls_p*6,	FALSE, 	NULL,	NULL,  NULL},			
	/* Check Box 1 */
	{43, 	NULL, COMBO_BOX,	PERFORMANCE_FRAME_FIXED_INDEX, box_w,box_h,ex_p,ey_p-3,	FALSE,	combo_selected_1,	"changed",	"4"},
	/* Write Throughput(Gpbs) Entry */
	{44, 	NULL, 						ENTRY,	PERFORMANCE_FRAME_FIXED_INDEX, ent_w, 0, ex_p, ey_p+es_p*2,FALSE,NULL,	NULL,"0.00"},
	/* Read Throughput(Gpbs) Entry */
	{45, 	NULL, 						ENTRY,	PERFORMANCE_FRAME_FIXED_INDEX, ent_w, 0, ex_p, ey_p+es_p*3,FALSE,NULL,	NULL,"0.00"},
	/* Write Bandwidth Utilization Entry */
	{46, 	NULL, 						ENTRY,	PERFORMANCE_FRAME_FIXED_INDEX, ent_w, 0, ex_p, ey_p+es_p*4,FALSE, NULL, NULL,"0.00"},
	/* Read Bandwidth Utilization Entry */
	{47, 	NULL, 						ENTRY,	PERFORMANCE_FRAME_FIXED_INDEX, ent_w, 0, ex_p, ey_p+es_p*5,FALSE, NULL, NULL,"0.00"},
	/* Operation Button */
	{48,	"Start Test",BUTTON,PERFORMANCE_FRAME_FIXED_INDEX,but_w,but_h,ex_p,ey_p+es_p*6,	TRUE,performance_button,"clicked", NULL},
	/* Operation label */
	{49, 	"Mode Switch:", 			LABEL, 	CONFIG_FRAME_FIXED_INDEX,  0,  0, lx_c, ly_c,  			   FALSE, NULL, NULL,  NULL},
	/* Addr Offset(hex) label */
	{50, 	"Addr Offset(hex):", 		LABEL, 	CONFIG_FRAME_FIXED_INDEX, 0, 0, lx_c+ls_c*1-15, ly_c, 	   FALSE, NULL, NULL,  NULL},
	/* Data(hex) label */
	{51, 	"Data(hex):", 				LABEL,	CONFIG_FRAME_FIXED_INDEX, 0, 0, lx_c+ls_c*2, ly_c, 		   FALSE, NULL, NULL,  NULL},
	/* Operation Button */
	{52, 	"Write",BUTTON,CONFIG_FRAME_FIXED_INDEX,but_w-20,but_h,lx_c+ls_c*3-35,ly_c-6,	TRUE,	config_button,	"clicked", NULL},
	/* Check Box 2 */
	{53, 	NULL, COMBO_BOX,	  CONFIG_FRAME_FIXED_INDEX, box_w, box_h, ex_c, ey_c,		FALSE,  combo_selected_2,"changed",	"2"},
	/* Addr Offset Entry */
	{54, 	NULL, 						ENTRY,	CONFIG_FRAME_FIXED_INDEX, ent_w, 0, ex_c+es_c*1-15, ey_c,  TRUE, 	NULL, "16", "0"},
	/* Data Entry */
	{55, 	NULL, 						ENTRY,	CONFIG_FRAME_FIXED_INDEX, ent_w, 0, ex_c+es_c*2-80, ey_c,  TRUE, 	NULL, "16", "0"},
	/* Vendor ID label */
	{56, 	"Vendor ID:", 				LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e, ly_e, 	     	   FALSE,	NULL, NULL,NULL},
	/* Device ID label */
	{57, 	"Device ID:", 				LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e, ly_e+ls_y*1, 	   FALSE,	NULL,NULL, NULL},
	/* Link Status label */
	{58, 	"Link Status:", 			LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e, ly_e+ls_y*2, 	   FALSE,	NULL,NULL, NULL},
	/* Link Speed label */
	{59, 	"Link Speed:", 				LABEL, 	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e, ly_e+ls_y*3, 	   FALSE,	NULL,NULL, NULL},
	/* Link Width label */
	{60, 	"Link Width:", 				LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e, ly_e+ls_y*4, 	   FALSE,	NULL,NULL, NULL},
	/* Interrupts label */
	{61, 	"Interrupts:", 				LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e, ly_e+ls_y*5, 	   FALSE,	NULL,NULL, NULL},
	/* Bar0 label */
	{62, 	"Bar0:", 					LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x+ld_x, ly_e,    FALSE,	NULL,NULL, NULL},
	/* Bar1 label */
	{63, 	"Bar1:", 					LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x+ld_x, ly_e+ls_y*1, FALSE,NULL,NULL,NULL},
	/* Bar2 label */
	{64, 	"Bar2:", 					LABEL,  ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x+ld_x, ly_e+ls_y*2, FALSE,NULL,NULL,NULL},
	/* Bar3 label */
	{65, 	"Bar3:", 					LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x+ld_x, ly_e+ls_y*3, FALSE,NULL,NULL,NULL},
	/* Bar4 label */
	{66, 	"Bar4:", 					LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x+ld_x, ly_e+ls_y*4, FALSE,NULL,NULL,NULL},
	/* Bar5 label */
	{67, 	"Bar5:", 					LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x+ld_x, ly_e+ls_y*5, FALSE,NULL,NULL,NULL},
	/* Size0 label */
	{68, 	"Size0:", 					LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x*2-20, ly_e, 	   FALSE,NULL,NULL,NULL},
	/* Size1 label */
	{69, 	"Size1:", 					LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x*2-20, ly_e+ls_y*1, FALSE,NULL,NULL,NULL},
	/* Size2 label */
	{70, 	"Size2:", 					LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x*2-20, ly_e+ls_y*2, FALSE,NULL,NULL,NULL},
	/* Size3 label */
	{71, 	"Size3:", 					LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x*2-20, ly_e+ls_y*3, FALSE,NULL,NULL,NULL},
	/* Size4 label */
	{72, 	"Size4:", 					LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x*2-20, ly_e+ls_y*4, FALSE,NULL,NULL,NULL},
	/* Size5 label */ 
	{73, 	"Size5:", 					LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x*2-20, ly_e+ls_y*5, FALSE,NULL,NULL,NULL},
	/* MPS(bytes) label */
	{74, 	"MPS(bytes):", 				LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0, lx_e+ls_x*3-60,ly_e,   	   FALSE,NULL,NULL,NULL},
	/* MRRS(bytes) label */
	{75, 	"MRRS(bytes):", 			LABEL,	ENDPOINT_FRAME_FIXED_INDEX, 0, 0,lx_e+ls_x*3-60,ly_e+ls_y*1,   FALSE,NULL,NULL,NULL},
	/* Vendor ID Entry */
	{76, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w, 0, ex_e, ey_e, 		 	   FALSE,NULL,NULL,	"0"},
	/* Device ID Entry */
	{77, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w, 0, ex_e, ey_e+es_y*1, 	   FALSE,NULL,NULL,	"0"},
	/* Link Status Entry */
	{78, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w, 0, ex_e, ey_e+es_y*2, 	   FALSE,NULL,NULL,	"0"},
	/* Link Speed Entry */
	{79, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w, 0, ex_e, ey_e+es_y*3, 	   FALSE,NULL,NULL,	"0"},
	/* Link Width Entry */
	{80, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w, 0, ex_e, ey_e+es_y*4, 	   FALSE,NULL,NULL,	"0"},
	/* Interrupts Entry */
	{81, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w, 0, ex_e, ey_e+es_y*5, 	   FALSE,NULL,NULL,	"0"},
	/* Bar0 Entry */
	{82, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w, 0, ex_e+es_x+ed_x, ey_e,    FALSE,NULL,NULL,	"0"},
	/* Bar1 Entry */
	{83, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x+ed_x,ey_e+es_y*1,FALSE,NULL,NULL,	"0"},
	/* Bar2 Entry */
	{84, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x+ed_x,ey_e+es_y*2,FALSE,NULL,NULL,	"0"},
	/* Bar3 Entry */
	{85, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x+ed_x,ey_e+es_y*3,FALSE,NULL,NULL,	"0"},
	/* Bar4 Entry */
	{86, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x+ed_x,ey_e+es_y*4,FALSE,NULL,NULL,	"0"},
	/* Bar5 Entry */
	{87, 	NULL, 						ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x+ed_x,ey_e+es_y*5,FALSE,NULL,NULL,	"0"},
	/* Len0 Entry */
	{88, 	NULL, 					ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x*2+ed_x*2, ey_e, 	   FALSE,NULL,NULL,	"0"},
	/* Len1 Entry */
	{89, 	NULL, 					ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x*2+ed_x*2,ey_e+es_y*1,FALSE,NULL,NULL,	"0"},
	/* Len2 Entry */
	{90, 	NULL, 					ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x*2+ed_x*2,ey_e+es_y*2,FALSE,NULL,NULL,	"0"},
	/* Len3 Entry */
	{91, 	NULL, 					ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x*2+ed_x*2,ey_e+es_y*3,FALSE,NULL,NULL,	"0"},
	/* Len4 Entry */
	{92, 	NULL, 					ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x*2+ed_x*2,ey_e+es_y*4,FALSE,NULL,NULL,	"0"},
	/* Len5 Entry */
	{93, 	NULL, 					ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x*2+ed_x*2,ey_e+es_y*5,FALSE,NULL,NULL,	"0"},
	/* MPS Entry */
	{94, 	NULL, 					ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x*3+75, ey_e,	   	   FALSE,NULL,NULL,	"0"},
	/* MRRS Entry */
	{95, 	NULL, 					ENTRY,	ENDPOINT_FRAME_FIXED_INDEX, ent_w,0,ex_e+es_x*3+75, ey_e+es_y*1,   FALSE,NULL,NULL,	"0"},
	/* Allocate Mem Size： label */
	{96, 	"Allocate Mem Size(bytes):",LABEL, 	NOTEBOOK_FRAME_FIXED_INDEX_2, 0, 0, lx2, ly2, 	   			   FALSE,NULL,NULL,NULL},
	/* Offset Addr(byte)： label */
	{97, 	"Offset Addr(hex):", 		LABEL,	NOTEBOOK_FRAME_FIXED_INDEX_2, 0, 0, lx2, ly2+ls2*1,			   FALSE,NULL,NULL,NULL},
	/* Data Length(byte)： label */
	{98, 	"Data Length(bytes):", 		LABEL,	NOTEBOOK_FRAME_FIXED_INDEX_2, 0, 0, lx2, ly2+ls2*2,			   FALSE,NULL,NULL,NULL},
	/* Start DMA Button */
	{99,   "Start DMA",BUTTON,NOTEBOOK_FRAME_FIXED_INDEX_2,but_w,but_h,lx2,ly2+ls2*3+5,		TRUE,	start_dma_button,"clicked",NULL},
	/* Write DDR Button */
	{100, 	"Write DDR",BUTTON,NOTEBOOK_FRAME_FIXED_INDEX_2,but_w,but_h,lx2,ly2+ls2*4+10,	TRUE,	write_ddr_button,"clicked",NULL},
	/* DMA Read Button */
	{101,	"DMA Read",BUTTON,NOTEBOOK_FRAME_FIXED_INDEX_2,but_w,but_h,lx2,ly2+ls2*5+15,	TRUE,	dma_read_button,"clicked", NULL},
	/* Allocate Mem Entry */
	{102, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_2, ent_w, 0, ex2, ey2,			  TRUE,	NULL,NULL,"128"},
	/* Offset Addr Entry */
	{103, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_2, ent_w, 0, ex2, ey2+es2*1,		  TRUE,	NULL,"16", 	"0"},
	/* Data Length Entry */
	{104, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_2, ent_w, 0, ex2, ey2+es2*2,		  TRUE,	NULL,NULL, 	"4"},
	/* Close DMA Button */
	{105,  "Close DMA",BUTTON,NOTEBOOK_FRAME_FIXED_INDEX_2,but_w,but_h,ex2,ey2+es2*3+10,	TRUE,	close_dma_button,"clicked",	NULL},
	/* DMA Write Button */
	{106,	"Read DDR",BUTTON,NOTEBOOK_FRAME_FIXED_INDEX_2,but_w,but_h,ex2,ey2+es2*4+15,	TRUE,	read_ddr_button,"clicked", NULL},
	/* Read DDR Button */
	{107, 	"DMA Write",BUTTON,NOTEBOOK_FRAME_FIXED_INDEX_2,but_w,but_h,ex2,ey2+es2*5+20,	TRUE,	dma_write_button,"clicked",NULL},
	/* Bar Addr Switch: label */
	{108, 	"Bar Addr Switch:", 		LABEL,	NOTEBOOK_FRAME_FIXED_INDEX_3, 0, 0, lx3, ly3,			  	   FALSE,NULL,NULL,NULL},
	/* Read/Write Mode: label */
	{109, 	"Read/Write Mode:", 		LABEL,	NOTEBOOK_FRAME_FIXED_INDEX_3, 0, 0, lx3, ly3+ls3*1, 	  	   FALSE,NULL,NULL,NULL},
	/* Addr Offset(hex): label */
	{110, 	"Addr Offset(hex):", 		LABEL, 	NOTEBOOK_FRAME_FIXED_INDEX_3, 0, 0, lx3, ly3+ls3*2, 	  	   FALSE,NULL,NULL,NULL},
	/* Data(hex) label */
	{111, 	"Data(hex):", 				LABEL,	NOTEBOOK_FRAME_FIXED_INDEX_3, 0, 0, lx3, ly3+ls3*3,			   FALSE,NULL,NULL,NULL},
	/* Repeat Cnt label */
	{112, 	"Repeat Cnt:", 				LABEL,	NOTEBOOK_FRAME_FIXED_INDEX_3, 0, 0, lx3, ly3+ls3*4,			   FALSE,NULL,NULL,NULL},
	/* Operation Delay label */
	{113, 	"Operation Delay(ns):", 	LABEL,	NOTEBOOK_FRAME_FIXED_INDEX_3, 0, 0, lx3, ly3+ls3*5,       	   FALSE,NULL,NULL,NULL},
	/* Operation Button label */
	{114, 	"Operation Button:", 		LABEL,	NOTEBOOK_FRAME_FIXED_INDEX_3, 0, 0, lx3, ly3+ls3*6, 	  	   FALSE,NULL,NULL,NULL},
	/* Check Box 3 */
	{115, 	NULL, COMBO_BOX,		NOTEBOOK_FRAME_FIXED_INDEX_3,box_w,box_h,ex3,ey3-5,		FALSE,	combo_selected_3,"changed",	"3"},
	/* Check Box 4 */
	{116, 	NULL,COMBO_BOX, NOTEBOOK_FRAME_FIXED_INDEX_3,box_w,box_h,ex3,ey3-3+es3*1,		FALSE,	combo_selected_4,"changed",	"1"},
	/* Addr Offset(hex) Entry */
	{117, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_3, ent_w, 0, ex3, ey3+es3*2,	 TRUE,	NULL,	"16",	"0"},
	/* Data Entry */
	{118, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_3, ent_w, 0, ex3, ey3+es3*3,	 TRUE, NULL,"16","12345678"},
	/* Repeat Cnt Entry */
	{119, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_3, ent_w, 0, ex3, ey3+es3*4,	 TRUE,	NULL,	NULL,	"1"},
	/* Operation Delay Entry */
	{120, 	NULL, 						ENTRY,	NOTEBOOK_FRAME_FIXED_INDEX_3, ent_w, 0, ex3, ey3+es3*5,	 TRUE,	NULL, NULL,	 "1000"},
	/* Operation Button */
	{121,	"Start Test",BUTTON,NOTEBOOK_FRAME_FIXED_INDEX_3,but_w,but_h,ex3,ey3+es3*6,		TRUE,	pio_test_button,"clicked", NULL},
	/* Import Button: label */
	{122, 	"Import Button:", 			LABEL, 	NOTEBOOK_FRAME_FIXED_INDEX_4, 0, 0, lx4, ly4, 		  		   FALSE,NULL,NULL,NULL},
	/* Load Button: label */
	{123, 	"Load Button:", 			LABEL, 	NOTEBOOK_FRAME_FIXED_INDEX_4, 0, 0, lx4, ly4+ls4*1,   		   FALSE,NULL,NULL,NULL},
	/* File To Import Button */
	{124,	"File To Import",BUTTON,NOTEBOOK_FRAME_FIXED_INDEX_4,but_w+15,but_h,ex4, ey4,	TRUE,	import_button, 	"clicked", NULL},
	/* Load The File Button */
	{125,  "Load The File",BUTTON,NOTEBOOK_FRAME_FIXED_INDEX_4,but_w+15,but_h,ex4,ey4+es4*1,TRUE,	load_button,	"clicked", NULL},	
	/* Test Packet Size(bytes) label */
	{126, 	"Test Packet Size(bytes):", LABEL,	PERFORMANCE_FRAME_FIXED_INDEX, 0, 0, lx_p, ly_p+ls_p*1,		   FALSE,NULL,NULL,NULL},
	/* Test Packet Size(bytes) Entry */
	{127, 	NULL, 						ENTRY,	PERFORMANCE_FRAME_FIXED_INDEX, ent_w, 0, ex_p, ey_p+es_p*1,	   TRUE,NULL,NULL,"128"},
};

void* GuiWidgets[sizeof(GuiScreen) / sizeof(GuiScreen[0])];				/* 主窗口部件缓存 */

/**************************************************************************
** 函数名称:    creat_file_selection
** 函数功能:创建文件选择界面
** 输入参数:*    Widget：窗口部件
**			*filename：默认文件名称
**			*ok_fun：OK按钮回调函数
**			*cancle_fun：caccel按钮回调函数
**			*destory_fun：close窗口按钮回调函数
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
static void creat_file_selection(GtkWidget *file_selection, char *filename, void *ok_fun, void *cancel_fun, void *destory_fun)
{
	file_selection = gtk_file_selection_new("Select Write File");							/*创建文件选择构件*/
	gtk_file_selection_set_filename(GTK_FILE_SELECTION(file_selection),filename);
	gtk_signal_connect(GTK_OBJECT(GTK_FILE_SELECTION(file_selection)->ok_button),"clicked",GTK_SIGNAL_FUNC(ok_fun),file_selection);/*捕捉打开按纽的”clicked”信号*/
	gtk_signal_connect(GTK_OBJECT(GTK_FILE_SELECTION(file_selection)->cancel_button),"clicked",GTK_SIGNAL_FUNC(cancel_fun),file_selection);/*捕捉取消按纽的”clicked”信号*/
	gtk_signal_connect(GTK_OBJECT(GTK_FILE_SELECTION(file_selection)), "destroy", GTK_SIGNAL_FUNC(destory_fun),file_selection);
	gtk_widget_show(file_selection);   
}

/**************************************************************************
** 函数名称:    free_file_buf
** 函数功能:释放数据缓存
** 输入参数:无
** 输出参数:    无
** 返回参数:    操作结果
****************************************************************************/
static void free_file_buf(void *buf)
{
	if(buf != NULL)
	{
		free(buf);
	}
}

/**************************************************************************
** 函数名称:    quit_window
** 函数功能:    主窗口关闭按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean quit_window( GtkWidget *Widget, gpointer Data )
{
	printf_info("gtk_main_quit\n");
	unmap_mem(&map_dev_mem);
	free_file_buf(dma_write_file_info.file_data_buffer);
	free_file_buf(load_file_info.file_data_buffer);
	close(pci_driver_fd);
	gtk_main_quit();
}

/**************************************************************************
** 函数名称:    clean_button
** 函数功能:    清除打印信息按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean clean_button( GtkWidget *Widget, gpointer Data )
{
	printf_info("The button does nothing\n");
}

/**************************************************************************
** 函数名称:    dma_auto_test_button
** 函数功能:    DMA自动测试页面开始按钮
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean dma_auto_test_button( GtkWidget *Widget, gpointer Data )
{
	char *text;
	
	if(TRUE == (button_flag.free_time ^ button_flag.dma_auto))
	{
		button_flag.dma_auto = BOOL_SWITCH(button_flag.dma_auto);
		if(TRUE == button_flag.dma_auto)
		{
			gtk_button_set_label(GTK_BUTTON(Widget),"Stop Test");
			text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[TEST_NUM].num]));
			sscanf(text,"%d",&dma_auto_info.test_num);
			text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[START_NUM].num]));
			sscanf(text,"%d",&dma_auto_info.start);
			dma_operation.current_len = dma_auto_info.start;
			text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[END_NUM].num]));
			sscanf(text,"%d",&dma_auto_info.end);
			dma_auto_info.end = dma_auto_info.start;										/*暂时关闭end*/
			text =  gtk_combo_box_get_active_text(GTK_COMBO_BOX(GuiWidgets[GuiScreen[STEP_NUM].num]));
			sscanf(text,"%d",&dma_auto_info.step);

			set_entry_text(WRITE_CNT_NUM, 0);
			set_entry_text(READ_CNT_NUM, 0);
			set_entry_text(ERROR_CNT_NUM, 0);
			creat_file_selection(DmaWriteFileSelection, ".txt", &OpenDmaWriteFile, &CancelDmaOpenFile, &CloseDmaOpenFile);
			
			printf_info("Start DMA Auto Test\n");
		}
		else
		{
			gtk_button_set_label(GTK_BUTTON(Widget),"Start Test");
			printf_info("Stop DMA Auto Test\n");
		}
	}
	else
	{
		stop_warning(&button_flag);
	}
}

/**************************************************************************
** 函数名称:    combo_selected_1
** 函数功能:    Performance测试界面combo控件选择回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean combo_selected_1( GtkWidget *Widget, gpointer Data )
{

}

/**************************************************************************
** 函数名称:    combo_selected_2
** 函数功能:    Config读写界面combo控件选择回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean combo_selected_2( GtkWidget *Widget, gpointer Data )
{
	char *text =  gtk_combo_box_get_active_text(GTK_COMBO_BOX(GuiWidgets[GuiScreen[C_W_R_NUM].num]));
	gtk_button_set_label(GTK_BUTTON(GuiWidgets[GuiScreen[C_BUTTON].num]),text);  
}

/**************************************************************************
** 函数名称:    combo_selected_3
** 函数功能:    PIO测试界面combo控件选择回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean combo_selected_3( GtkWidget *Widget, gpointer Data )
{

}

/**************************************************************************
** 函数名称:    combo_selected_4
** 函数功能:    PIO测试界面combo控件选择回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean combo_selected_4( GtkWidget *Widget, gpointer Data )
{

}

/**************************************************************************
** 函数名称:    combo_selected_5
** 函数功能:DMA自动测试界面combo控件选择回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean combo_selected_5( GtkWidget *Widget, gpointer Data )
{

}

/**************************************************************************
** 函数名称:    performance_button
** 函数功能:Performance测试界面按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean performance_button( GtkWidget *Widget, gpointer Data )
{
	if(TRUE == (button_flag.free_time ^ button_flag.performance_start))
	{
		button_flag.performance_start = BOOL_SWITCH(button_flag.performance_start);
		
		if(TRUE == button_flag.performance_start)
		{
			char *text =  gtk_combo_box_get_active_text(GTK_COMBO_BOX(GuiWidgets[GuiScreen[PER_W_R_NUM].num]));
			gtk_button_set_label(GTK_BUTTON(Widget),"Stop Test");
			if(!strcmp(text, combo_box_text_4[0]))
			{
				printf_info("Performance DMA write data test \n");
				performance_operation.cmd = WRITE_CMD;									/* DMA写数据性能测试 */
			}
			else if(!strcmp(text, combo_box_text_4[1]))
			{
				printf_info("Performance DMA read data test \n");
				performance_operation.cmd = READ_CMD;									/* DMA读数据性能测试 */
			}
			else if(!strcmp(text, combo_box_text_4[2]))
			{
				printf_info("Performance DMA write and read data test \n");
				performance_operation.cmd = W_R_CMD;									/* DMA读写数据性能测试 */
			}
			
			text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[PER_PACKET_SIZE_NUM].num]));
			sscanf(text,"%d",&performance_operation.current_len);
			set_entry_text(WRITE_TROUGHPUT_NUM, 0);
			set_entry_text(READ_TROUGHPUT_NUM,	0);
			set_entry_text(WRITE_BANDWIDTH_NUM, 0);
			set_entry_text(READ_BANDWIDTH_NUM,	0);
			button_info = button_char[PERFORMANCE_TEST_NUM];
		}
		else
		{
			gtk_button_set_label(GTK_BUTTON(Widget),"Start Test");

		}
	}
	else
	{
		stop_warning(&button_flag);
	}
}

/**************************************************************************
** 函数名称:    config_button
** 函数功能:config读写界面按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean config_button( GtkWidget *Widget, gpointer Data )
{
	char *data;
	char *addr;
	if(TRUE == button_flag.free_time)
	{
		char *text =  gtk_combo_box_get_active_text(GTK_COMBO_BOX(GuiWidgets[GuiScreen[C_W_R_NUM].num]));
		addr = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[C_OFFSET_NUM].num]));
		sscanf(addr,"%x",&config_operation.addr);
		config_operation.addr &= ~3;
		if(!strcmp(text, combo_box_text_2[0]))
		{
			data = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[C_DATA_NUM].num]));
			sscanf(data,"%x",&config_operation.data);
			#ifdef NO_TEST
				ioctl(pci_driver_fd, PCI_WRITE_DATA_CMD, &config_operation);								/* 写数据 */
			#endif
			printf_info("Write address offset = 0x%08x; Data = 0x%08x\n", config_operation.addr,config_operation.data);
		
		}
		else if(!strcmp(text, combo_box_text_2[1]))
		{
			#ifdef NO_TEST
				ioctl(pci_driver_fd, PCI_READ_DATA_CMD, &config_operation); 								/* 读数据 */
			#endif
			set_entry_text(C_DATA_NUM, config_operation.data);
			printf_info("Read address offset = 0x%08x; Data = 0x%08x\n", config_operation.addr,config_operation.data);
		}
	}
	else
	{
		stop_warning(&button_flag);
	}
}

/**************************************************************************
** 函数名称:    pio_test_button
** 函数功能:PIO测试界面按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean pio_test_button( GtkWidget *Widget, gpointer Data )
{
	if(TRUE == (button_flag.free_time ^ button_flag.pio))
	{
		button_flag.pio = BOOL_SWITCH(button_flag.pio);
		if(TRUE == button_flag.pio)
		{
			char *text =  gtk_combo_box_get_active_text(GTK_COMBO_BOX(GuiWidgets[GuiScreen[W_R_NUM].num]));
			gtk_button_set_label(GTK_BUTTON(Widget),"Stop Test");
			if(!strcmp(text, combo_box_text_1[0]))
			{
				printf_debug("PIO write data test \n");
				command_operation.w_r = write_num;
				
				text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[DATA_NUM].num]));
				sscanf(text,"%x",&command_operation.data);
			}
			else if(!strcmp(text, combo_box_text_1[1]))
			{
				printf_debug("PIO read data test \n");
				command_operation.w_r = read_num;
			}
			else if((!strcmp(text, combo_box_text_1[2])) || (!strcmp(text, combo_box_text_1[3])))
			{
				printf_debug("PIO Write before read data test \n");
				command_operation.w_r = w_r_num;
				if(!strcmp(text, combo_box_text_1[3]))
				{
					command_operation.step = 1;
					printf_debug("Open address stepping \n");
				}
				text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[DATA_NUM].num]));
				sscanf(text,"%x",&command_operation.data);
			}
			
			text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[OFFSET_NUM].num]));
			sscanf(text,"%x",&command_operation.addr);
			text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[CNT_NUM].num]));
			sscanf(text,"%d",&command_operation.cnt);
			text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[DELAY_NUM].num]));
			sscanf(text,"%d",&command_operation.delay);
			button_info = button_char[PIO_TEST_INFO_NUM];
		}
		else
		{
			gtk_button_set_label(GTK_BUTTON(Widget),"Start Test");
			printf_info("Stop Pio Test, Current Address Offset = 0x%08x\n", command_operation.addr);
		}
	}
	else
	{
		stop_warning(&button_flag);
	}
}

/**************************************************************************
** 函数名称:    import_button
** 函数功能:Tandem位流选择按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean import_button( GtkWidget *Widget, gpointer Data )
{
	if(TRUE == button_flag.free_time)
	{
		creat_file_selection(TandemFileSelection, "*.bin *.sbit", &OpenTandemFile, &CancelTandemFile, &CloseTandemFile);
	}
	else
	{
		stop_warning(&button_flag);
	}
}

/**************************************************************************
** 函数名称:    load_button
** 函数功能:Tandem位流加载按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean load_button( GtkWidget *Widget, gpointer Data )
{
	if(TRUE == button_flag.free_time)
	{
		cmd_operation(pci_driver_fd, tandem_num, &command_operation);	
	}
	else
	{
		stop_warning(&button_flag);
	}
}

/**************************************************************************
** 函数名称:    enable_button
** 函数功能:使能按钮
** 输入参数:num：部件编号
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
static void enable_button(unsigned int num)
{
	gtk_widget_set_sensitive(GTK_WIDGET(GuiWidgets[GuiScreen[num].num]), TRUE);	
}

/**************************************************************************
** 函数名称:    disable_button
** 函数功能:失能按钮
** 输入参数:num：部件编号
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
static void disable_button(unsigned int num)
{
	gtk_widget_set_sensitive(GTK_WIDGET(GuiWidgets[GuiScreen[num].num]), FALSE);	
}

/**************************************************************************
** 函数名称:    enable_start_dma_button
** 函数功能:使能Start DMA按钮
** 输入参数:无
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
static void enable_start_dma_button(void)
{
	enable_button(START_DMA_NUM);
	//disable_button(CLOSE_DMA_NUM);
}

/**************************************************************************
** 函数名称:    disable_start_dma_button
** 函数功能:失能Start DMA按钮
** 输入参数:无
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
static void disable_start_dma_button(void)
{
	disable_button(START_DMA_NUM);
	enable_button(CLOSE_DMA_NUM);
}

/**************************************************************************
** 函数名称:    print_data
** 函数功能:打印DDR回读的数据
** 输入参数:*dma_oper:配置参数以及数据缓存
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
static void print_data(DMA_OPERATION *dma_oper)
{
	unsigned int i = 0;
	if(memcmp(dma_oper->data.read_buf, dma_oper->data.write_buf, dma_oper->current_len*4) != 0)
	{
		printf_error("Write data is not equal to read data !!!\n");
	}
	for(i = 0; i < dma_oper->current_len; i++ )
	{
		printf_info("dw_cnt = %d; write_data = 0x%02x%02x%02x%02x; read_data = 0x%02x%02x%02x%02x\n", i + 1, \
		dma_oper->data.write_buf[i*4], dma_oper->data.write_buf[i*4 + 1],dma_oper->data.write_buf[i*4 + 2],dma_oper->data.write_buf[i*4 + 3],\
		dma_oper->data.read_buf[i*4], dma_oper->data.read_buf[i*4 + 1], dma_oper->data.read_buf[i*4 + 2], dma_oper->data.read_buf[i*4 + 3]);
	}
}

/**************************************************************************
** 函数名称:    start_dma_button
** 函数功能:Start DMA按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean start_dma_button( GtkWidget *Widget, gpointer Data )
{
	char *text;
	if(TRUE == (button_flag.free_time ^ button_flag.manual_start))
	{
		button_flag.manual_start = BOOL_SWITCH(button_flag.manual_start);

		text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[ALLOCATE_MEM_SIZE].num]));
		sscanf(text,"%d",&dma_manual_info.allocate_mem_size);
		text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[OFFSET_ADDR_NUM].num]));
		sscanf(text,"%d",&dma_manual_info.offset_addr);
		text = (char *)gtk_entry_get_text(GTK_ENTRY(GuiWidgets[GuiScreen[DATA_LENGTH_NUM].num]));
		sscanf(text,"%d",&dma_manual_info.data_length);
		
		creat_file_selection(DmaWriteFileSelection, ".txt", &OpenDmaWriteFile, &CancelDmaOpenFile, &CloseDmaOpenFile);
		printf_info("Start DMA Manual Test (PCI_MAP_ADDR_CMD)\n");
	}
	else
	{
		stop_warning(&button_flag);
	}
}




void rgb565_to_rgb888(unsigned char *rgb565_buf, unsigned char *rgb888_buf, int width, int height) {
	int i, j;
	int rgb565_index = 0;
	int rgb888_index = 0;

	for (i = 0; i < height; i++) {
		for (j = 0; j < width; j++) {
		// 读取RGB565数据
			unsigned short pixel = (rgb565_buf[rgb565_index+1] << 8) | rgb565_buf[rgb565_index];

		// 从RGB565格式解码出RGB888格式
			unsigned char r = (pixel >> 11) & 0x1F; // 5位红色
			unsigned char g = (pixel >> 5) & 0x3F; // 6位绿色
			unsigned char b = pixel & 0x1F; // 5位蓝色

// 扩展到8位
			rgb888_buf[rgb888_index] = (r << 3); // 5位扩展到8位
			rgb888_buf[rgb888_index + 1] = (g << 2); // 6位扩展到8位
			rgb888_buf[rgb888_index + 2] = (b << 3); // 5位扩展到8位

			// 更新索引
			rgb565_index += 2;
			rgb888_index += 3;
		}
	}
}


// 配置虚拟摄像头的函数
int configure_camera(int fd) {
	struct v4l2_format format;

	// 配置摄像头格式
	format.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	format.fmt.pix.width = WIDTH;
	format.fmt.pix.height = HEIGHT;
	format.fmt.pix.pixelformat = PIXEL_FORMAT;
	format.fmt.pix.field = V4L2_FIELD_NONE;

	// 设置摄像头格式
	if (ioctl(fd, VIDIOC_S_FMT, &format) < 0) {
		perror("Failed to set format on camera");
		return -1;
	}
	return 0;
}

// 写一帧图像数据到虚拟摄像头
int write_frame_to_camera(int fd, unsigned char *rgb888_buf) {
	ssize_t written_bytes = write(fd, rgb888_buf, FRAME_SIZE);

	// 检查是否成功写入
	if (written_bytes < 0) {
		perror("Failed to write frame to camera");
		return -1;
	} else if (written_bytes != FRAME_SIZE) {
		fprintf(stderr, "Warning: Only %zd bytes written (expected %d)\n", written_bytes, FRAME_SIZE);
		return -1;
	}
	return 0;
}

/**************************************************************************
** 函数名称:    dma_write_button
** 函数功能:DMA Write按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/


// 保存为 PNG 图片
void save_rgb888_to_png(const char *filename, unsigned char *rgb888_buf, int width, int height) {
	int channels = 3; // RGB888 有 3 个通道

	// 使用 stb_image_write 函数将缓冲区保存为图片
	if (stbi_write_png(filename, width, height, channels, rgb888_buf, width * channels)) {
		printf("Saved image to %s successfully!\n", filename);
	} else {
		printf("Failed to save image.\n");
	}
}

void save_image_frame(int frame_num, unsigned char *rgb888_buf) {
    char filename[100];
    sprintf(filename, "/home/deeplearn/frame_%04d.ppm", frame_num);  // 文件名 frame_0001.ppm, frame_0002.ppm...
    
    FILE *file = fopen(filename, "wb");
    if (!file) {
        printf("Failed to open file");
        return;
    }

    // 写入PPM头
    fprintf(file, "P6\n%d %d\n255\n", WIDTH, HEIGHT);

    // 写入RGB888像素数据
    fwrite(rgb888_buf, 1, WIDTH * HEIGHT * 3, file);

    fclose(file);
    printf("Frame %d saved as %s\n", frame_num, filename);
}


void video_display(){
	receive_flag = true;
	unsigned char rgb888_buf[WIDTH * HEIGHT * 3];
	unsigned int  flag;
	memset(&idle_flag.flag_data,1,4);
	memset(&dma_data1.write_buf,6,DMA_MAX_PACKET_SIZE);
	printf_info("dw_cnt = %d\n",idle_flag.flag_data);
	printf_info("dw_cnt = 0x%02x\n",dma_data1.write_buf[11]);
	if(idle_flag.flag_data == 0 || dma_data1.write_buf[0] == 0 )
			{
				printf_info("DMA地址映射失败\n");
			}
	ioctl(pci_driver_fd, PCI_MAP_ADDR_CMD, &dma_operation);		//往fpga发送分配的地址指令，启动dma写
	printf_info("指令发送成功\n");
	// 打开虚拟摄像头设备
	int fd;
	//int i=0;
        fd = open("/dev/video0", O_RDWR);
        if (fd < 0) {
          printf("Failed to open virtual camera");
                   }  
                   
        // 配置虚拟摄像头
        if (configure_camera(fd) < 0) {
             close(fd);
	     printf("配置失败");
         }
	//延时2/60s
	usleep(1000000/60*2);
	printf_info("1\n");
	while (receive_flag == true && receive_flag == true)
	{	
		while(idle_flag.flag_data == flag)
		{
			usleep(100);
			ioctl(pci_driver_fd, PCI_READ_DATA3, &idle_flag);	//往fpga发送dma写指令
		}
		flag = idle_flag.flag_data;
		printf_info("0x%08x\n",idle_flag.flag_data);
		if (idle_flag.flag_data == 0)
		{
			ioctl(pci_driver_fd, PCI_READ_DATA1, &dma_data1);		//往fpga发送dma写指令
		}
		else
		{
			ioctl(pci_driver_fd, PCI_READ_DATA2, &dma_data1);		//往fpga发送dma写指令
		}
		//printf_info("DMA Write data = 0x%02x\n", dma_data1.write_buf[11]);
		rgb565_to_rgb888(dma_data1.write_buf, rgb888_buf, WIDTH, HEIGHT);
		//i++;
		//save_rgb888_to_png("/home/deeplearn/output_image.png", rgb888_buf, WIDTH, HEIGHT);
		//send_frame_to_virtual_cam(rgb888_buf, WIDTH, HEIGHT);
		//save_image_frame(i, rgb888_buf);
               if (write_frame_to_camera(fd, rgb888_buf) < 0) {
                  printf("写入错误"); // 处理错误
               }
		
		
	}
}

gboolean dma_write_button( GtkWidget *Widget, gpointer Data )
{

	g_thread_create((GThreadFunc)video_display,NULL,FALSE,NULL);
	
}

/**************************************************************************
** 函数名称:    read_ddr_button
** 函数功能:Read DDR按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean read_ddr_button( GtkWidget *Widget, gpointer Data )
{
	if(TRUE == button_flag.manual_start)
	{
		printf_info("Read  DDR (PCI_READ_FROM_KERNEL_CMD)\n");
		#ifdef NO_TEST
			ioctl(pci_driver_fd, PCI_READ_FROM_KERNEL_CMD, &dma_operation); 			
		#endif
		print_data(&dma_operation);
	}
	else
	{
		printf_warning("The DMA start button is not open\n");
	}
}

/**************************************************************************
** 函数名称:    close_dma_button
** 函数功能:Close DMA按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean close_dma_button( GtkWidget *Widget, gpointer Data )
{
    receive_flag = false;
}

/**************************************************************************
** 函数名称:    dma_read_button
** 函数功能:DMA Read按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean dma_read_button( GtkWidget *Widget, gpointer Data )
{
	if(TRUE == button_flag.manual_start)
	{
		printf_info("DMA  Read (PCI_DMA_READ_CMD)\n");
		#ifdef NO_TEST
			ioctl(pci_driver_fd, PCI_DMA_READ_CMD, &dma_operation);						/* 将数据写入设备（DMA读） */
		#endif
	}
	else
	{
		printf_warning("The DMA start button is not open\n");
	}
}



/**************************************************************************
** 函数名称:    write_ddr_button
** 函数功能:Write DDR按钮回调函数
** 输入参数:*    Widget：窗口部件
**			Data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
gboolean write_ddr_button( GtkWidget *Widget, gpointer Data )
{
	if(TRUE == button_flag.manual_start)
	{
		printf_info("Write DDR (PCI_WRITE_TO_KERNEL_CMD)\n");
		#ifdef NO_TEST
			ioctl(pci_driver_fd, PCI_WRITE_TO_KERNEL_CMD, &dma_operation);				/* 将数据写入内核缓存 */
		#endif	
	}
	else
	{
		printf_warning("The DMA start button is not open\n");
	}
}

/**************************************************************************
** 函数名称:    stop_warning
** 函数功能:stop按钮关闭信息警告
** 输入参数:*flag：按键触发标志
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void stop_warning(BUTTON_FLAG *flag)
{
	if(TRUE == flag->dma_auto)
	{
		printf_warning("Please stop the DMA auto tests \n");
		msg_warning("Please stop the DMA auto tests \n");
	}
	else if(TRUE == flag->manual_start)
	{
		printf_warning("Please close the DMA manual tests \n");
		msg_warning("Please close the DMA manual tests \n");
	}
	else if(TRUE == flag->pio)
	{
		printf_warning("Please stop the PIO loop tests \n");
		msg_warning("Please stop the PIO loop tests \n");
	}
	else if(TRUE == flag->performance_start)
	{
		printf_warning("Please stop the Performance loop tests \n");
		msg_warning("Please stop the Performance loop tests \n");
	}
}

/**************************************************************************
** 函数名称:    button_status
** 函数功能:按键状态检测线程
** 输入参数:无
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void button_status(void)
{
	while(1)
	{
		button_flag.free_time = BOOL_SWITCH(button_flag.pio | \
											button_flag.dma_auto | \
											button_flag.manual_start | \
											button_flag.performance_start);
		usleep(100);
	}
} 

/**************************************************************************
** 函数名称:    button_process
** 函数功能:按键处理函数（线程回到函数）
** 输入参数:无
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void button_process(void)
{
	while(1)
	{
		if(button_info == button_char[DMA_AUTO_INFO_NUM])
		{
			dma_auto_process(&dma_auto_info, &dma_operation);
			button_info = NULL;
		}
		else if(button_info == button_char[DMA_MANUAL_INFO_NUM])
		{
			dma_manual_process(&dma_manual_info, &dma_operation);
			button_info = NULL;
		}
		else if(button_info == button_char[PIO_TEST_INFO_NUM])
		{
			pio_test_process(&command_operation);
			button_info = NULL;
		}
		else if(button_info == button_char[PERFORMANCE_TEST_NUM])
		{
			performance_process(&performance_operation, &performance_data);
			button_info = NULL;
		}
		
		usleep(100);
	}
}    

/**************************************************************************
** 函数名称:    addr_step
** 函数功能:地址步进判断
** 输入参数:*cmd_op：PCIe参数信息结构体
**          len:bar空间大小
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
static void addr_step(COMMAND_OPERATION *cmd_op, unsigned int len)
{
	cmd_op->addr &= ~3;
	pio_vaddr = pio_vaddr_copy + cmd_op->addr;
	if(cmd_op->step > 0)
	{
		cmd_op->addr = cmd_op->addr + 4;
		cmd_op->addr = (cmd_op->addr >= len) ? 0 : cmd_op->addr;
	}
}

/**************************************************************************
** 函数名称:    set_button_text
** 函数功能:设置按钮显示文本
** 输入参数:widget_num：部件编号
**          flag:按键状态
** 输出参数:    无
** 返回参数:    bool:标志切换
****************************************************************************/
static bool set_button_text(unsigned int widget_num, bool flag)
{
	gtk_button_set_label(GTK_BUTTON(GuiWidgets[GuiScreen[widget_num].num]),"Start Test");
	if(flag == button_flag.dma_auto)
	{
		printf_info("Stop DMA Auto Test\n");
	}
	else if(flag == button_flag.pio)
	{
		printf_info("Stop Pio Test\n");
	}

	return BOOL_SWITCH(flag);
}

/**************************************************************************
** 函数名称:    dma_oper_fun
** 函数功能:DMA读写操作
** 输入参数:*dma_auto：dma auto测试界面参数信息结构体
**			*dma_oper:配置参数以及数据缓存
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
static void dma_oper_fun(DMA_AUTO *dma_auto, DMA_OPERATION *dma_oper)
{
	unsigned int j = 0;
	for(j = 0; j <= dma_auto->step_add_cnt; j++)
	{
		dma_oper->current_len = dma_auto->start + j * dma_auto->step;
		dma_oper->current_len = (dma_oper->current_len > dma_auto->end) ? dma_auto->end : dma_oper->current_len;
		dma_oper->current_len = dma_oper->current_len >> 2; 						/* 将字节转换成DW(四字节) */
		dma_oper->offset_addr = 0;
		memset(dma_oper->data.read_buf, 0, DMA_MAX_PACKET_SIZE);
		#ifdef NO_TEST
			ioctl(pci_driver_fd, PCI_MAP_ADDR_CMD, dma_oper);						/* 地址映射,以及数据缓存申请 */
			ioctl(pci_driver_fd, PCI_WRITE_TO_KERNEL_CMD, dma_oper);				/* 将数据写入内核缓存 */
			ioctl(pci_driver_fd, PCI_DMA_READ_CMD, dma_oper);						/* 将数据写入设备（DMA读） */
			usleep(500*1000);
			ioctl(pci_driver_fd, PCI_DMA_WRITE_CMD, dma_oper);						/* 将数据从设备读出到内核（DMA写） */
			usleep(500*1000);
			ioctl(pci_driver_fd, PCI_READ_FROM_KERNEL_CMD, dma_oper);				/* 将数据从内核读出 */
			ioctl(pci_driver_fd, PCI_UMAP_ADDR_CMD, dma_oper);						/* 释放数据缓存 */
		#endif
		dma_auto->write_cnt = (dma_auto->write_cnt>= 0xffffffff) ? 0xffffffff : dma_auto->write_cnt + 1;
		dma_auto->read_cnt = dma_auto->write_cnt;
		if(memcmp(dma_oper->data.read_buf, dma_oper->data.write_buf, dma_oper->current_len*4) != 0)
		{
			dma_auto->error_cnt = (dma_auto->error_cnt>= 0xffffffff) ? 0xffffffff : dma_auto->error_cnt + 1;
		}
		print_data(dma_oper);
		printf_debug("DMA Auto Step operation cnt = %d; write_cnt = %d; error_cnt = %d; current_len = %d (dw)\n", j, dma_auto->write_cnt, dma_auto->error_cnt, dma_oper->current_len);
	}
	dma_oper->current_len = dma_auto->start;
}

/**************************************************************************
** 函数名称:    get_write_data
** 函数功能:获取将要写入的数据缓存
** 输入参数:length:有效数据长度
**          *dma_oper:配置参数以及数据缓存
** 输出参数:    无
** 返回参数:    操作结果
****************************************************************************/
static int get_write_data(unsigned int length, DMA_OPERATION *dma_oper)
{
	unsigned int i = 0;
	int value = 0;
	unsigned int temp_len = 0;
	value = open_load_file(dma_write_file_name, &dma_write_file_info);		/* 打开写入文件，并获取文件相关信息（文件字节大小等） */
	dma_write_file_name = NULL;
	if(value < 0)	return -1;
	temp_len = dma_write_file_info.file_total_bytes;
	temp_len = (temp_len >= length) ? length : temp_len;
	memset(dma_oper->data.write_buf, 0, DMA_MAX_PACKET_SIZE);
	memset(dma_oper->data.read_buf, 0, DMA_MAX_PACKET_SIZE);
	memcpy(dma_oper->data.write_buf, dma_write_file_info.file_data_buffer, temp_len);
	
	if(temp_len < length)
	{
		for(i = 0; i < (length - temp_len); i++)
		{
			dma_oper->data.write_buf[temp_len + i] = i%10 + 0x30;
		}
		printf_warning("The write file total bytes( %d bytes) less than configuration data length( %d bytes),fill in (i%%10 + 0x30)\n", temp_len, length);
		printf_info("dma_oper->data.write_buf info :\n%s\n",dma_oper->data.write_buf);
	}
//	printf_debug("dma_oper->data.write_buf info :\n%s\n",dma_oper->data.write_buf);
	return 1;
}

/**************************************************************************
** 函数名称:    dma_auto_process
** 函数功能:dma auto测试界面执行函数
** 输入参数:*dma_auto：dma auto测试界面参数信息结构体
**			*dma_oper:配置参数以及数据缓存
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void dma_auto_process(DMA_AUTO *dma_auto, DMA_OPERATION *dma_oper)
{
	unsigned int i = 0;
	int temp_data = 0;
	unsigned int cnt = 0;
	unsigned int temp_cnt = 0;
	unsigned int temp_start = 0;
	unsigned int temp_end = 0;
	unsigned int temp_step = 0;
	
	cnt = dma_auto->test_num;
	temp_start = (dma_auto->start/4)*4;
//	temp_end   = (dma_auto->end/4)*4;
	temp_end   = temp_start;
	temp_step  = dma_auto->step;
	set_entry_text(START_NUM, temp_start);
	set_entry_text(END_NUM, temp_end);
	
	printf_debug("test_num = %d\n", temp_start);
	printf_debug("start    = %d\n", temp_start);
	printf_debug("end      = %d\n", temp_end);
	printf_debug("step     = %d\n", temp_step);
	
	if(temp_start < DMA_MIN_PACKET_SIZE)
	{
		temp_start = DMA_MIN_PACKET_SIZE;
		set_entry_text(START_NUM, DMA_MIN_PACKET_SIZE);
		printf_warning("Start Packet Size less than %d,set to %d !!!\n", DMA_MIN_PACKET_SIZE, DMA_MIN_PACKET_SIZE);
	}
	if(temp_start > DMA_MAX_PACKET_SIZE)
	{
		temp_start = DMA_MAX_PACKET_SIZE;
		set_entry_text(START_NUM, DMA_MAX_PACKET_SIZE);
		printf_warning("Start Packet Size greater than or %d,set to %d !!!\n", DMA_MAX_PACKET_SIZE, DMA_MAX_PACKET_SIZE);
	}
	if(temp_end < DMA_MIN_PACKET_SIZE)
	{
		temp_end = DMA_MIN_PACKET_SIZE;
		set_entry_text(END_NUM, DMA_MIN_PACKET_SIZE);
		printf_warning("End Packet Size less than %d,set to %d !!!\n", DMA_MIN_PACKET_SIZE, DMA_MIN_PACKET_SIZE);
	}
	if(temp_end > DMA_MAX_PACKET_SIZE)
	{
		temp_end = DMA_MAX_PACKET_SIZE;
		set_entry_text(END_NUM, DMA_MAX_PACKET_SIZE);
		printf_warning("End Packet Size greater than %d,set to %d !!!\n", DMA_MAX_PACKET_SIZE, DMA_MAX_PACKET_SIZE);
	}
	
	if(temp_start > temp_end)
	{
		printf_error("Start Packet Size greater than End Packet Size !!!\n");
		button_flag.dma_auto = set_button_text(AUTO_BUTTON_NUM, button_flag.dma_auto);
	}
	else if(temp_step > (temp_end - temp_start))
	{
		printf_error("Reselect the step value !!!\n");
		button_flag.dma_auto = set_button_text(AUTO_BUTTON_NUM, button_flag.dma_auto);
	}
	else
	{
		dma_auto->step_add_cnt = (temp_step == 0)? 0: (((temp_end - temp_start)/temp_step) + 1);
		dma_auto->start = temp_start;
		dma_auto->end = temp_end;
		dma_auto->write_cnt = 0;
		dma_auto->read_cnt = 0;
		dma_auto->error_cnt = 0;

		temp_data = get_write_data(temp_end, dma_oper);
		
		if(temp_data > 0)
		{
			if(0 == cnt)
			{
				printf_info("DMA Auto Cycle operation......\n");
				while(1)
				{
					dma_oper_fun(dma_auto, dma_oper);
					if(FALSE == button_flag.dma_auto) break;
				}
			}
			else
			{
				printf_info("DMA Auto Operate %d times......\n", cnt);
				for(i = 0; i < cnt; i++)
				{
					dma_oper_fun(dma_auto, dma_oper);
					if(FALSE == button_flag.dma_auto) break;
					temp_cnt++;
				}
				if(temp_cnt == cnt)
				{
					button_flag.dma_auto = set_button_text(AUTO_BUTTON_NUM, button_flag.dma_auto);
				}
			}
			set_entry_text(WRITE_CNT_NUM, dma_auto->write_cnt);
			set_entry_text(READ_CNT_NUM, dma_auto->read_cnt);
			set_entry_text(ERROR_CNT_NUM, dma_auto->error_cnt);
			free_file_buf(dma_write_file_info.file_data_buffer);
		}
		else
		{
			printf_error("Open DMA Load File Failed !!!\n");
			button_flag.dma_auto = set_button_text(AUTO_BUTTON_NUM, button_flag.dma_auto);
		}
	}
}

/**************************************************************************
** 函数名称:    manual_error
** 函数功能:dma manual测试界面执行错误处理
** 输入参数:无
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
static void manual_error(void)
{
	button_flag.manual_start = BOOL_SWITCH(button_flag.manual_start);
	enable_start_dma_button();
}

/**************************************************************************
** 函数名称:    dma_manual_process
** 函数功能:dma manual测试界面执行函数
** 输入参数:*dma_manual：dma manual测试界面参数信息结构体
**			*dma_oper:配置参数以及数据缓存
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void dma_manual_process(DMA_MANUAL *dma_manual, DMA_OPERATION *dma_oper)
{
	int temp_data = 0;
	unsigned int temp_size = 0;
	unsigned int temp_offset = 0;
	unsigned int temp_length = 0;

	temp_size   = (dma_manual->allocate_mem_size/4)*4;
	temp_offset = (dma_manual->offset_addr/4)*4;
	temp_length = (dma_manual->data_length/4)*4;
	set_entry_text(ALLOCATE_MEM_SIZE, temp_size);
	set_entry_text(OFFSET_ADDR_NUM, temp_offset);
	set_entry_text(DATA_LENGTH_NUM, temp_length);
	
	printf_debug("allocate_mem_size = %d\n", temp_size);
	printf_debug("offset_addr       = %d\n", temp_offset);
	printf_debug("data_length       = %d\n", temp_length);
	
	if(temp_size < DMA_MIN_PACKET_SIZE)
	{
		temp_size = DMA_MIN_PACKET_SIZE;
		set_entry_text(ALLOCATE_MEM_SIZE, DMA_MIN_PACKET_SIZE);
		printf_warning("Allocate Mem Size less than %d,set to %d !!!\n", DMA_MIN_PACKET_SIZE, DMA_MIN_PACKET_SIZE);
	}
	if(temp_size > DMA_MAX_PACKET_SIZE)
	{
		temp_size = DMA_MAX_PACKET_SIZE;
		set_entry_text(ALLOCATE_MEM_SIZE, DMA_MAX_PACKET_SIZE);
		printf_warning("Allocate Mem Size greater than %d,set to %d !!!\n", DMA_MAX_PACKET_SIZE, DMA_MAX_PACKET_SIZE);
	}
	if(temp_length < DMA_MIN_PACKET_SIZE)
	{
		temp_length = DMA_MIN_PACKET_SIZE;
		set_entry_text(DATA_LENGTH_NUM, DMA_MIN_PACKET_SIZE);
		printf_warning("Data Length less than %d,set to %d !!!\n", DMA_MIN_PACKET_SIZE, DMA_MIN_PACKET_SIZE);
	}
	if(temp_length > DMA_MAX_PACKET_SIZE)
	{
		temp_length = DMA_MAX_PACKET_SIZE;
		set_entry_text(DATA_LENGTH_NUM, DMA_MAX_PACKET_SIZE);
		printf_warning("Data Length Size greater than %d,set to %d !!!\n", DMA_MAX_PACKET_SIZE, DMA_MAX_PACKET_SIZE);
	}
	
	if(temp_length > temp_size)
	{
		printf_error("Data Length greater than Allocate Mem Size !!!\n");
		manual_error();
	}
	else if(temp_offset > (temp_size - temp_length))
	{
		printf_error("Offset Addr greater than Allocate Mem Size subtract Data Length !!!\n");
		manual_error();
	}
	else
	{
		temp_data = get_write_data(temp_size, dma_oper);
		dma_oper->current_len = temp_length >> 2;
		dma_oper->offset_addr = temp_offset;
		
		if(temp_data > 0)
		{
			#ifdef NO_TEST
				ioctl(pci_driver_fd, PCI_MAP_ADDR_CMD, dma_oper);						/* 地址映射,以及数据缓存申请 */
			#endif
		}
		else
		{
			printf_error("Open DMA Load File Failed !!!\n");
			manual_error();
		}
	}
}
/**************************************************************************
** 函数名称:    cmd_process
** 函数功能:命令处理函数
** 输入参数:*cmd_op：PCIe参数信息结构体
**          len:bar空间大小
** 输出参数:    无
** 返回参数:无
****************************************************************************/
static void cmd_process(COMMAND_OPERATION *cmd_op, unsigned int len)
{
	addr_step(cmd_op, len);
	cmd_operation(pci_driver_fd, cmd_op->w_r, cmd_op);
	cmd_op->data = cmd_op->data + 1;
	if(cmd_op->data == 0xfffffff0) cmd_op->data = 1;
}

/**************************************************************************
** 函数名称:    pio_test_process
** 函数功能:pio测试界面执行函数
** 输入参数:*cmd_op：PCIe参数信息结构体
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void pio_test_process(COMMAND_OPERATION *cmd_op)
{
	unsigned int i = 0;
	unsigned char cmd = 0;
	unsigned int cnt = 0;
	unsigned int temp_cnt = 0;
	unsigned int bar_addr = 0;
	unsigned int size = 1;
	unsigned int len = 0;
	
	len = get_bar_info(cmd_op, BAR_LEN);
	if(cmd_op->addr <= len)
	{
		cnt = cmd_op->cnt;
		cmd = cmd_op->w_r;
		bar_addr = get_bar_info(cmd_op, BAR_ADDRESS);
		
		size = len;
		#ifdef NO_TEST
			pio_vaddr = map_mem(bar_addr, size, &map_dev_mem); 
			pio_vaddr_copy = pio_vaddr;
			if(pio_vaddr == NULL)
			{
				printf_error("Pio test,Address mapping failure !!!\n");
				button_flag.pio = set_button_text(PIO_BUTTON_NUM, button_flag.pio);
			}
			else
			{
		#endif
				if(0 == cnt)
				{
					printf_info("PIO Cycle operation, Every time delay %d ns\n", cmd_op->delay);
					while(1)
					{
						#ifdef NO_TEST
							cmd_process(cmd_op, len);
						#endif
						if(FALSE == button_flag.pio) break;
					}
				}
				else
				{ 
					printf_info("PIO Operate %d times, Every time delay %d ns\n", cnt, cmd_op->delay);
					for(i = 0; i < cnt; i++)
					{
						#ifdef NO_TEST
							cmd_process(cmd_op, len);
						#endif
						if(FALSE == button_flag.pio) break;
						temp_cnt++;
					}
					if(temp_cnt == cnt)
					{
						button_flag.pio = set_button_text(PIO_BUTTON_NUM, button_flag.pio);
					}
				}
				cmd_op->step = 0;
				set_entry_text(DATA_NUM, cmd_op->data - 1);
				printf_info("Current Address Offset = 0x%08x\n", (cmd_op->step > 0) ? (cmd_op->addr - 4) : cmd_op->addr);
		#ifdef NO_TEST
			}
			unmap_mem(&map_dev_mem);
		#endif
	}
	else
	{
		printf_error("The offset address exceeds the maximum range !!!\n");
	}
}

/**************************************************************************
** 函数名称:    performance_process
** 函数功能:性能测试界面执行函数
** 输入参数:*per_info：性能参数信息结构体
**			*per_data：数据参数结构体
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void performance_process(PERFORMANCE_OPERATION *per_info, PERFORMANCE_DATA *per_data)
{
	unsigned int temp_length = 0;
	unsigned int bar_addr = 0;
	unsigned int bar_len = 0;
	unsigned char temp_cmd = 0;
	unsigned int link_speed = 0;
	unsigned int link_width = 0;
	unsigned int effective_bandwidth = 0;
	unsigned int unit_time = 0;
	unsigned int get_data = 0;
	float float_length = 0;
	float write_cnt = 0;
	float read_cnt = 0;
	unsigned int data_cnt = 0;
	unsigned int r_error_cnt = 0;
	float bandwidth_theoretical_value = 0;
	
//	per_info->current_len = 128;											/* 目前先固定长度128字节 */
	per_info->cmp_flag = 0;
	temp_cmd = per_info->cmd;
	temp_length = (per_info->current_len/4)*4;
	set_entry_text(PER_PACKET_SIZE_NUM, temp_length);
	
	if(temp_length < DMA_MIN_PACKET_SIZE)
	{
		temp_length = DMA_MIN_PACKET_SIZE;
		set_entry_text(PER_PACKET_SIZE_NUM, DMA_MIN_PACKET_SIZE);
		printf_warning("Packet Size less than %d,set to %d !!!\n", DMA_MIN_PACKET_SIZE, DMA_MIN_PACKET_SIZE);
	}
	if(temp_length > DMA_MAX_PACKET_SIZE)
	{
		temp_length = DMA_MAX_PACKET_SIZE;
		set_entry_text(PER_PACKET_SIZE_NUM, DMA_MAX_PACKET_SIZE);
		printf_warning("Packet Size greater than %d,set to %d !!!\n", DMA_MAX_PACKET_SIZE, DMA_MAX_PACKET_SIZE);
	}
	
	per_info->current_len = temp_length >> 2;
	per_data->w_throughput = 0.00;
	per_data->r_throughput = 0.00;
	per_data->w_bandwidth  = 0.00;
	per_data->r_bandwidth  = 0.00;
	per_data->w_total_cnt = 0;
	per_data->w_invalid_cnt = 0;
	per_data->w_error_cnt = 0;
	per_data->r_total_cnt = 0;
	per_data->r_invalid_cnt = 0;
	per_data->r_error_cnt = 0;
	
	bar_addr = command_operation.get_pci_dev_info.bar[0].bar_base;
	bar_len = command_operation.get_pci_dev_info.bar[0].bar_len;
	link_speed = command_operation.get_pci_dev_info.link_speed;
	link_width = command_operation.get_pci_dev_info.link_width;
	unit_time = (link_speed == 1) ? 16 : 8;
	float_length = temp_length + 20.00;										/* 加上20个固定字节，TLP Header:12;Sequence:2;LCRC:4;STP:1;END:1 */
	effective_bandwidth = 250 * link_speed * link_width;					/* 250MBps，最小单位链路有效带宽 */
	bandwidth_theoretical_value = (temp_length/(float_length)) * effective_bandwidth  + 0.0000;

	printf_info("链路有效带宽：%dMB/s\n", effective_bandwidth);
	printf_info("理论用户带宽：%.2fMB/s\n", bandwidth_theoretical_value);
	
	#ifdef NO_TEST
		pio_vaddr = map_mem(bar_addr, bar_len, &map_dev_mem); 
		if(pio_vaddr == NULL)
		{
			printf_error("Performance test, Address mapping failure !!!\n");
			button_flag.performance_start = set_button_text(PER_START_NUM, button_flag.performance_start);
		}
		else
		{
	#endif
			while(1)
			{
				#ifdef NO_TEST
					ioctl(pci_driver_fd, PCI_PERFORMANCE_START_CMD, per_info);
				#endif	
				sleep(1);
				#ifdef NO_TEST
					ioctl(pci_driver_fd, PCI_PERFORMANCE_END_CMD, per_info);
				#endif
				#ifdef NO_TEST
					get_data = pio_read(pio_vaddr + PEFORMANCE_STATUS_OFFSET);
					per_data->dma_w_status = get_data & 0x01;
					per_data->dma_r_status = (get_data >> 16) & 0x01;
					per_data->busy_w_status = (get_data >> 1) & 0x01;
					per_data->busy_r_status = (get_data >> 17) & 0x01;
					printf_debug("dma_w_status = %d;dma_r_status = %d\n", per_data->dma_w_status, per_data->dma_r_status);
					printf_debug("busy_w_status = %d;busy_r_status = %d\n", per_data->busy_w_status, per_data->busy_r_status);
					get_data = pio_read(pio_vaddr + PEFORMANCE_WRITE_CNT_OFFSET);
					write_cnt	= get_data * unit_time + 0.00000;
					get_data = pio_read(pio_vaddr + PEFORMANCE_READ_CNT_OFFSET);
					read_cnt	= get_data * unit_time + 0.00000;
					get_data = pio_read(pio_vaddr + PEFORMANCE_ERROR_CNT_OFFSET);
					r_error_cnt = get_data;
					get_data = pio_read(pio_vaddr + PEFORMANCE_DATA_CNT_OFFSET);
					data_cnt	= get_data * 16;
					if(temp_cmd == READ_CMD)
					{
						per_data->w_throughput = 0.00;
						per_data->r_throughput = (data_cnt / read_cnt)*1000.00;
						per_data->w_bandwidth  = 0.00;
						per_data->r_bandwidth  = (per_data->r_throughput / effective_bandwidth) * 100;
						per_data->r_total_cnt++;
					}
					else if(temp_cmd == WRITE_CMD)
					{
						per_data->w_throughput = (data_cnt / write_cnt)*1000.00;
						per_data->r_throughput = 0.00;
						per_data->w_bandwidth  = (per_data->w_throughput / effective_bandwidth) * 100;
						per_data->r_bandwidth  = 0.00;
						per_data->w_total_cnt++;
					}
					else if(temp_cmd == W_R_CMD)
					{
						per_data->w_throughput = (data_cnt / write_cnt)*1000;
						per_data->r_throughput = (data_cnt / read_cnt)*1000;
						per_data->w_bandwidth  = (per_data->w_throughput / effective_bandwidth) * 100;
						per_data->r_bandwidth  = (per_data->r_throughput / effective_bandwidth) * 100;
						per_data->r_total_cnt++;
						per_data->w_total_cnt++;
					}
				#endif
								
				if(per_data->busy_w_status == 0x01)		
				{
					per_data->w_invalid_cnt++;
				}
				else
				{
					set_entry_text(WRITE_TROUGHPUT_NUM, 1);
					set_entry_text(WRITE_BANDWIDTH_NUM, 1);
				}
				
				if(per_data->busy_r_status == 0x01)
				{
					per_data->r_invalid_cnt++;
				}
				else
				{
					set_entry_text(READ_TROUGHPUT_NUM,	1);
					set_entry_text(READ_BANDWIDTH_NUM,	1);
				}
				
				if((temp_cmd == WRITE_CMD) || (temp_cmd == W_R_CMD))
				{
					if(!per_info->cmp_flag)
					{
						per_data->w_error_cnt++;
						printf_error("DMA Write data is not equal to DMA read data !!!\n");
					}
				}
				else
				{
					if(r_error_cnt > 0)
					{
						per_data->r_error_cnt++;
						printf_error("DMA Read data is not equal to DDR Memory data ,error data cnt = %d!!!\n", r_error_cnt);
					}
				}
				printf_info("DMA write total number of performance tests : %d\n", per_data->w_total_cnt);
				printf_info("DMA read total number of performance tests  : %d\n", per_data->r_total_cnt);
				printf_info("DMA write of error cnt : %d\n", per_data->w_error_cnt);
				printf_info("DMA read of error cnt  : %d\n", per_data->r_error_cnt);
				if(FALSE == button_flag.performance_start) break;	
			}
	#ifdef NO_TEST
		unmap_mem(&map_dev_mem);
		}
	#endif

	printf_info("Performance stop test \n");
}


/**************************************************************************
** 函数名称:    OpenTandemFile
** 函数功能:加载打开文件选择回调函数
** 输入参数:*    Widget：窗口部件
**			*data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void OpenTandemFile(GtkWidget *widget, gpointer *data)
{
	bit_file_name = (char *)gtk_file_selection_get_filename(GTK_FILE_SELECTION((GtkWidget *)data));
	printf_debug("bit_file_name = %s\n", bit_file_name);
	gtk_widget_destroy((GtkWidget *)data); 
}

/**************************************************************************
** 函数名称:    CancelTandemFile
** 函数功能:取消打开文件选择回调函数
** 输入参数:*    Widget：窗口部件
**			*data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void CancelTandemFile(GtkWidget *widget, gpointer *data)
{
	gtk_widget_destroy((GtkWidget *)data); 
}

/**************************************************************************
** 函数名称:    CloseTandemFile
** 函数功能:关闭打开文件选择回调函数
** 输入参数:*    Widget：窗口部件
**			*data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void CloseTandemFile(GtkWidget *widget,gpointer *data)
{

}

/**************************************************************************
** 函数名称:    OpenDmaWriteFile
** 函数功能:DMA写文件选择回调函数
** 输入参数:*    Widget：窗口部件
**			*data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void OpenDmaWriteFile(GtkWidget *widget, gpointer *data)
{
	dma_write_file_name = (char *)gtk_file_selection_get_filename(GTK_FILE_SELECTION((GtkWidget *)data));
	printf_debug("dma_write_file_name = %s\n", dma_write_file_name);
	button_flag.close_file = BOOL_SWITCH(button_flag.close_file);
	gtk_widget_destroy((GtkWidget *)data); 
	if(TRUE == button_flag.dma_auto)
	{
		button_info = button_char[DMA_AUTO_INFO_NUM];
	}
	else if(TRUE == button_flag.manual_start)
	{
		button_info = button_char[DMA_MANUAL_INFO_NUM];
		disable_start_dma_button();
	}
}

/**************************************************************************
** 函数名称:    cancel_button_operaiton
** 函数功能:DMA取消文件选择按钮标志处理函数
** 输入参数:*flag：按键标志结构体指针
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
static void cancel_button_operaiton(BUTTON_FLAG *flag)
{
	if(TRUE == flag->dma_auto)
	{
		flag->dma_auto = set_button_text(AUTO_BUTTON_NUM, flag->dma_auto);
	}
	else if(TRUE == flag->manual_start)
	{
		flag->manual_start = BOOL_SWITCH(flag->manual_start);
	}
}

/**************************************************************************
** 函数名称:    CancelDmaOpenFile
** 函数功能:DMA取消文件选择回调函数
** 输入参数:*    Widget：窗口部件
**			*data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void CancelDmaOpenFile(GtkWidget *widget, gpointer *data)
{
	cancel_button_operaiton(&button_flag);
	button_flag.close_file = BOOL_SWITCH(button_flag.close_file);
	gtk_widget_destroy((GtkWidget *)data);
	printf_debug("Cancel Open File \n");
}

/**************************************************************************
** 函数名称:    CloseDmaOpenFile
** 函数功能:DMA关闭文件选项回调函数
** 输入参数:*    Widget：窗口部件
**			*data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void CloseDmaOpenFile(GtkWidget *widget, gpointer *data)
{
	if(FALSE == button_flag.close_file)
	{
		cancel_button_operaiton(&button_flag);
		gtk_widget_destroy((GtkWidget *)data); 
		printf_debug("Close Open File \n");
	}
	else
	{
		button_flag.close_file = BOOL_SWITCH(button_flag.close_file);
	}
}



/**************************************************************************
** 函数名称:    switch_page
** 函数功能:主测试界面切换回调函数
** 输入参数:*notebook：窗口部件
**			page_num：当前页面编号
**			user_data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void switch_page(GtkNotebook *notebook, gpointer page, guint page_num, gpointer user_data)
{

}

/**************************************************************************
** 函数名称:    on_entry_insert_hex
** 函数功能:Entry输入前数据类型判断回调函数（十六进制）
** 输入参数:*editable：窗口部件
**			*new_text：输入的数据内容
**			new_text_length：输入内容的数据长度
**			user_data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void on_entry_insert_hex(GtkEditable *editable, gchar *new_text, gint new_text_length, gint *position, gpointer user_data)
{
	if(!strcmp(new_text, "0") || !strcmp(new_text, "1") ||
	   !strcmp(new_text, "2") || !strcmp(new_text, "3") ||
	   !strcmp(new_text, "4") || !strcmp(new_text, "5") ||
	   !strcmp(new_text, "6") || !strcmp(new_text, "7") ||
	   !strcmp(new_text, "8") || !strcmp(new_text, "9") ||
	   !strcmp(new_text, "a") || !strcmp(new_text, "b") || 
	   !strcmp(new_text, "c") || !strcmp(new_text, "d") || 
	   !strcmp(new_text, "e") || !strcmp(new_text, "f") || 
	   !strcmp(new_text, "A") || !strcmp(new_text, "B") || 
	   !strcmp(new_text, "C") || !strcmp(new_text, "D") || 
	   !strcmp(new_text, "E") || !strcmp(new_text, "F") )
	{
		return;
	}
	else
	{
		const char *text = gtk_entry_get_text(GTK_ENTRY(editable));
		gchar *result = g_utf8_strup(new_text, new_text_length);
		g_signal_handlers_block_by_func(editable, (gpointer)on_entry_insert_hex, user_data);
		gtk_entry_set_text(GTK_ENTRY(editable), text);
		g_signal_handlers_unblock_by_func(editable, (gpointer)on_entry_insert_hex, user_data);
		g_signal_stop_emission_by_name(editable, "insert_text");
		g_free(result);
	}
}

/**************************************************************************
** 函数名称:    on_entry_insert_digit
** 函数功能:Entry输入前数据类型判断回调函数（数字）
** 输入参数:*editable：窗口部件
**			*new_text：输入的数据内容
**			new_text_length：输入内容的数据长度
**			user_data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void on_entry_insert_digit(GtkEditable *editable, gchar *new_text, gint new_text_length, gint *position, gpointer user_data)
{
	if(!strcmp(new_text, "0") || !strcmp(new_text, "1") ||
	   !strcmp(new_text, "2") || !strcmp(new_text, "3") ||
	   !strcmp(new_text, "4") || !strcmp(new_text, "5") ||
	   !strcmp(new_text, "6") || !strcmp(new_text, "7") ||
	   !strcmp(new_text, "8") || !strcmp(new_text, "9") )
	{
		return;
	}
	else
	{
		const char *text = gtk_entry_get_text(GTK_ENTRY(editable));
		gchar *result 	 = g_utf8_strup(new_text, new_text_length);
		g_signal_handlers_block_by_func(editable, (gpointer)on_entry_insert_digit, user_data);
		gtk_entry_set_text(GTK_ENTRY(editable), text);
		g_signal_handlers_unblock_by_func(editable, (gpointer)on_entry_insert_digit, user_data);
		g_signal_stop_emission_by_name(editable, "insert_text");
		g_free(result);
	}
}

/**************************************************************************
** 函数名称:    set_entry_text
** 函数功能:设置entry显示信息
** 输入参数:widget_num：窗口部件编号
**			data：数据传参
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void set_entry_text(unsigned int widget_num, unsigned int data)
{
	char text[100] = {0};
	if(DATA_NUM == widget_num)
	{
		sprintf(text, "%08x", data);
		g_signal_handler_block(GuiWidgets[GuiScreen[widget_num].num],	entry_callback_id.pio.id);
		gtk_entry_set_text(GTK_ENTRY(GuiWidgets[GuiScreen[widget_num].num]), text); 	  
		g_signal_handler_unblock(GuiWidgets[GuiScreen[widget_num].num], entry_callback_id.pio.id);
	}
	else if(C_DATA_NUM == widget_num)
	{
		sprintf(text, "%08x", data);
		g_signal_handler_block(GuiWidgets[GuiScreen[widget_num].num],	entry_callback_id.config.id);
		gtk_entry_set_text(GTK_ENTRY(GuiWidgets[GuiScreen[widget_num].num]), text); 	  
		g_signal_handler_unblock(GuiWidgets[GuiScreen[widget_num].num], entry_callback_id.config.id);
	}
	else if(START_NUM == widget_num)
	{
		sprintf(text, "%u", data);
		g_signal_handler_block(GuiWidgets[GuiScreen[widget_num].num],	entry_callback_id.start.id);
		gtk_entry_set_text(GTK_ENTRY(GuiWidgets[GuiScreen[widget_num].num]), text); 	  
		g_signal_handler_unblock(GuiWidgets[GuiScreen[widget_num].num], entry_callback_id.start.id);
	}
	else if(END_NUM == widget_num)
	{
		sprintf(text, "%u", data);
		g_signal_handler_block(GuiWidgets[GuiScreen[widget_num].num],	entry_callback_id.end.id);
		gtk_entry_set_text(GTK_ENTRY(GuiWidgets[GuiScreen[widget_num].num]), text); 	  
		g_signal_handler_unblock(GuiWidgets[GuiScreen[widget_num].num], entry_callback_id.end.id);
	}
	else if(ALLOCATE_MEM_SIZE == widget_num)
	{
		sprintf(text, "%u", data);
		g_signal_handler_block(GuiWidgets[GuiScreen[widget_num].num],	entry_callback_id.alloc_mem.id);
		gtk_entry_set_text(GTK_ENTRY(GuiWidgets[GuiScreen[widget_num].num]), text); 	  
		g_signal_handler_unblock(GuiWidgets[GuiScreen[widget_num].num], entry_callback_id.alloc_mem.id);
	}
	else if(OFFSET_ADDR_NUM == widget_num)
	{
		sprintf(text, "%u", data);
		g_signal_handler_block(GuiWidgets[GuiScreen[widget_num].num],	entry_callback_id.offset_addr.id);
		gtk_entry_set_text(GTK_ENTRY(GuiWidgets[GuiScreen[widget_num].num]), text); 	  
		g_signal_handler_unblock(GuiWidgets[GuiScreen[widget_num].num], entry_callback_id.offset_addr.id);
	}
	else if(DATA_LENGTH_NUM == widget_num)
	{
		sprintf(text, "%u", data);
		g_signal_handler_block(GuiWidgets[GuiScreen[widget_num].num],	entry_callback_id.data_length.id);
		gtk_entry_set_text(GTK_ENTRY(GuiWidgets[GuiScreen[widget_num].num]), text); 	  
		g_signal_handler_unblock(GuiWidgets[GuiScreen[widget_num].num], entry_callback_id.data_length.id);
	}
	else if(PER_PACKET_SIZE_NUM == widget_num)
	{
		sprintf(text, "%u", data);
		g_signal_handler_block(GuiWidgets[GuiScreen[widget_num].num],	entry_callback_id.packet_size.id);
		gtk_entry_set_text(GTK_ENTRY(GuiWidgets[GuiScreen[widget_num].num]), text); 	  
		g_signal_handler_unblock(GuiWidgets[GuiScreen[widget_num].num], entry_callback_id.packet_size.id);
	}
	else
	{
		if(WRITE_TROUGHPUT_NUM == widget_num)
		{
			sprintf(text, "%.2f", performance_data.w_throughput);
		}
		else if(READ_TROUGHPUT_NUM == widget_num)
		{
			sprintf(text, "%.2f", performance_data.r_throughput);
		}
		else if(WRITE_BANDWIDTH_NUM == widget_num)
		{
			sprintf(text, "%.2f", performance_data.w_bandwidth);
		}
		else if(READ_BANDWIDTH_NUM == widget_num)
		{
			sprintf(text, "%.2f", performance_data.r_bandwidth);
		}
		else
		{
			sprintf(text, "%u", data);
		}	
		gtk_entry_set_text(GTK_ENTRY(GuiWidgets[GuiScreen[widget_num].num]), text); 	  
	}
}

/**************************************************************************
** 函数名称:    nano_delay
** 函数功能:纳秒延时
** 输入参数:delay：延时长度
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
int nano_delay(long delay)
{
    struct timespec req, rem;
    long nano_delay = delay;
    int ret = 0;
    while(nano_delay > 0)
    {
        rem.tv_sec = 0;
        rem.tv_nsec = 0;
        req.tv_sec = 0;
        req.tv_nsec = nano_delay;
        if(ret = (nanosleep(&req, &rem) == -1))
        {
            printf_error("nanosleep failed !!!\n");                
        }
        nano_delay = rem.tv_nsec;
    };
    
    return ret;
}

/**************************************************************************
** 函数名称:    map_mem
** 函数功能:虚拟空间映射函数
** 输入参数:    addr：设备物理地址
**			size：映射的大小
**			*map_mem：映射信息结构体
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void *map_mem(unsigned int addr, unsigned int size, DEV_MEM *map_mem)
{
	int fd = -1;
	void *vaddr = NULL;
	off_t offset;
	size_t len;
	if(map_mem->vaddr != NULL)
	{
		printf_warning("Bar0 is busy, please release it first\n");
		return vaddr;
	}

	offset = PAGE_ROUND_DOWN(addr);
	len    = PAGE_ROUND_UP(size);
	if ((offset == map_mem->offset) && (len == map_mem->len))
		return map_mem->vaddr;

	fd = open(MEM_FILE_PATH, O_RDWR | O_SYNC);
	if(fd < 0) 
	{
		printf_error("open '%s' failed !!!\n", MEM_FILE_PATH);
	}
	else
	{
		vaddr = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, offset);
		close(fd);
	}
	if ((vaddr == NULL) || (vaddr == MAP_FAILED)) 
	{
		printf_error("mmap '%s' failed !!!\n", MEM_FILE_PATH);
	}
	else
	{
		map_mem->len 	= len;
		map_mem->offset = offset;
		map_mem->vaddr 	= vaddr;
	}
	return vaddr;
}

/**************************************************************************
** 函数名称:    unmap_mem
** 函数功能:释放虚拟空间映射
** 输入参数:    *map_mem：映射信息结构体
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void unmap_mem(DEV_MEM *map_mem)
{
	if (map_mem->vaddr != NULL)
	{
		munmap(map_mem->vaddr, map_mem->len);
	}
	map_mem->offset = 0;
	map_mem->len 	= 0;
	map_mem->vaddr 	= NULL;
}

/**************************************************************************
** 函数名称:    get_bar_info
** 函数功能:获取bar信息
** 输入参数:    *cmd_op：PCIe参数信息结构体
**			info_choice：信息选择
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
unsigned int get_bar_info(COMMAND_OPERATION *cmd_op, unsigned int info_choice)
{
	unsigned int info = 0;
	unsigned char cnt = 0;
	char **data;
	char *text =  gtk_combo_box_get_active_text(GTK_COMBO_BOX(GuiWidgets[GuiScreen[BAR_NUM].num]));
	for(data = combo_box_text_3; *data != NULL; data++)
	{
		if(BAR_ADDRESS == info_choice)
		{
			info = cmd_op->get_pci_dev_info.bar[cnt++].bar_base;
		}
		else if(BAR_LEN == info_choice)
		{
			info = cmd_op->get_pci_dev_info.bar[cnt++].bar_len;
		}
		if(!strncmp(*data, text, strlen(*data)))
		{
			break;
		}
	}
	return info;
}

/**************************************************************************
** 函数名称:    pio_read
** 函数功能:pio读数据
** 输入参数:    *addr：读数据地址
** 输出参数:    无
** 返回参数:    读取的数据
****************************************************************************/
unsigned int pio_read(unsigned int *addr)
{
	return *((unsigned int *)addr);
}

/**************************************************************************
** 函数名称:    pio_write
** 函数功能:pio写数据
** 输入参数:    *addr：写数据地址
** 输出参数:    无
** 返回参数:    读取的数据
****************************************************************************/
unsigned int pio_write(unsigned int *addr, unsigned int data)
{
	*((unsigned int *)addr) = data;
	return 1;
}

/**************************************************************************
** 函数名称:    open_pci_driver
** 函数功能:    打开pcie驱动文件
** 输入参数:    无
** 输出参数:    无
** 返回参数:    文件描述符
****************************************************************************/
int open_pci_driver(void)
{
	int fd;
	
	fd = open(PCIE_DRIVER_FILE_PATH, O_RDWR);
	
	if(fd < 0)
	{
		perror("open fail\n");
		return -1;
	}
	return fd;
}

/**************************************************************************
** 函数名称:    open_load_file
** 函数功能:    打开加载文件
** 输入参数:    file_name:加载文件名称
**          *info:文件长度信息以及文件内容
** 输出参数:    无
** 返回参数:    操作结果
****************************************************************************/
int open_load_file(char* file_name, FILE_INFO *info)
{
	if ((info->_pg_load_file = fopen(file_name, "rb")) == NULL)
	{
		return -1;
	}
	fseek(info->_pg_load_file, 0, SEEK_END);
	info->file_total_bytes = ftell(info->_pg_load_file);
	info->file_total_dws = file_len(info->file_total_bytes);
	info->file_blocks_integer = info->file_total_dws / MAX_BLOCK_SIZE;
	info->file_blocks_remainder = info->file_total_dws % MAX_BLOCK_SIZE;
	fseek(info->_pg_load_file, 0, SEEK_SET);
	
	info->file_data_buffer = (unsigned int *)malloc(info->file_total_dws*4);
	
	printf_debug("info->file_total_bytes = %d \n", info->file_total_bytes);
	printf_debug("info->file_total_dws = %d\n", info->file_total_dws);
	if (!info->file_data_buffer)
	{
		fprintf(stderr, "Memory error!\n");
		fclose(info->_pg_load_file);
		return -1;
	}
	
	fread(info->file_data_buffer, sizeof(int), info->file_total_dws, info->_pg_load_file);
	fclose(info->_pg_load_file);
	
	return 1;
}


/**************************************************************************
** 函数名称:    load_fial_bit
** 函数功能:加载位流文件
** 输入参数:    fd:驱动文件描述符
**			cmd:操作指令
**			*cmd_op:相关信息和数据结构体
**          *info:文件长度信息以及文件内容
**          *addr:bar空间虚拟地址
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void load_fial_bit(int fd, COMMAND_OPERATION *cmd_op, FILE_INFO *info, void *addr)
{
	int load_cnt = 0;
	int i = 0;
	unsigned int buf_cnt = 0;
	unsigned int num_valdw = 0;
	unsigned int valdw = 0;
	unsigned int *data_buf;
	void *vaddr;
	
	load_cnt = info->file_blocks_integer;
	cmd_op->load_info.total_num_words = info->file_total_dws;
	data_buf = load_file_info.file_data_buffer;
	do
	{
		if(0 == load_cnt)
		{
			cmd_op->load_info.data_block.num_words = info->file_blocks_remainder;
		}
		else
		{
			cmd_op->load_info.data_block.num_words = MAX_BLOCK_SIZE;
		}
		if(cmd_op->load_info.data_block.num_words > 0)
		{
			memcpy(cmd_op->load_info.data_block.block_words, data_buf + buf_cnt * MAX_BLOCK_SIZE, cmd_op->load_info.data_block.num_words*sizeof(int));
			num_valdw = cmd_op->load_info.data_block.num_words;
			vaddr = (unsigned int *)(addr + BAR_OFFSET_3);								/* Bar0*/
			for(i = 0; i < num_valdw; i++)
			{
				valdw = cmd_op->load_info.data_block.block_words[i];
				pio_write(vaddr, valdw);
			}
		}
		buf_cnt++;
		load_cnt--;
	}while(load_cnt >= 0);
	free_file_buf(data_buf);
}

/**************************************************************************
** 函数名称:    cmd_operation
** 函数功能:    命令解析函数
** 输入参数:    fd:驱动文件描述符
**			cmd:操作指令
**			*cmd_op:相关信息和数据结构体
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void cmd_operation(int fd, unsigned char cmd, COMMAND_OPERATION *cmd_op)
{
	unsigned int w_data = 0;
	unsigned int r_data = 0;
	unsigned int i = 0;
	unsigned int j = 0;
	unsigned int cnt = 0;
	unsigned long temp_bar_len;
	int value = 0;
	char pci_info[20][20];
	char unit[5][10] = {"B", "KB", "MB", "GB", "TB"};
	void *vaddr1, *vaddr2;
	switch(cmd)
	{
		case write_num:
			pio_write(pio_vaddr, cmd_op->data);
		break;
		
		case read_num: 
			r_data =  pio_read(pio_vaddr);
			cmd_op->data = r_data;
		break;
		
		case w_r_num:																	/* 先写后读 */
			w_data = cmd_op->data;
			pio_write(pio_vaddr, cmd_op->data);
			cmd_op->data = 0;
			cmd_op->data =  pio_read(pio_vaddr);
			r_data = cmd_op->data;
			if(w_data != r_data)
			{
				printf_error("Reading and writing data is not the same !!!\n");
				printf_error("Write Data = %x;Read Data %x !!!\n", w_data, r_data);
			}
		break;

		case info_num:
			cmd_op->delay = 0;
			read(fd, cmd_op, sizeof(COMMAND_OPERATION));								/* 读取pcie信息 */
			sprintf(pci_info[cnt++], "%04x", cmd_op->get_pci_dev_info.vendor_id);
			sprintf(pci_info[cnt++], "%04x", cmd_op->get_pci_dev_info.device_id);
			if(cmd_op->cap_info.cap_status == 1)
			{
				strcpy(pci_info[cnt++],  "Up");
				printf_info("PCIe link successful\n");
				msg_info("PCIe link successful\n");
			}
			else
			{
				strcpy(pci_info[cnt++],  "Down");
				printf_error("PCIe link failure !!!\n");
				msg_error("PCIe link failure !!!\n");
			}
			sprintf(pci_info[cnt++], "Gen%x", cmd_op->get_pci_dev_info.link_speed);
			sprintf(pci_info[cnt++], "x%x", cmd_op->get_pci_dev_info.link_width);
			strcpy(pci_info[cnt++],  "No");
			for(i = 0; i <= 5; i++)
			{
				sprintf(pci_info[cnt++], "%08lx", cmd_op->get_pci_dev_info.bar[i].bar_base);
			}
			for(i = 0; i <= 5; i++)
			{
				value = 0;
				temp_bar_len = cmd_op->get_pci_dev_info.bar[i].bar_len;
				while(temp_bar_len >= 1024)
				{
					temp_bar_len = temp_bar_len / 1024;
					value++;
				}
				sprintf(pci_info[cnt++], "%d%s", temp_bar_len, unit[value]);
			}
			sprintf(pci_info[cnt++], "%d", cmd_op->get_pci_dev_info.mps);
			sprintf(pci_info[cnt++], "%d", cmd_op->get_pci_dev_info.mrrs);
			for(i = 0; i < 20; i++)
			{
				gtk_entry_set_text(GTK_ENTRY(GuiWidgets[GuiScreen[VEDION_ID_NUM + i].num]), pci_info[i]);
			}

			if(cmd_op->cap_info.cap_error == 0)
			{
				if(cmd_op->cap_info.cap_status == 1)
				{
					for(i = 0; i < 256; i++)
					{
						if(cmd_op->cap_info.cap_buf[i].flag == 1)
						{
							printf_info("-----------------------------------------------------------------------\n");
							printf_info("cap info------------:%s\n", cap_id[cmd_op->cap_info.cap_buf[i].id].id_info);
							printf_info("cap id--------------:0x%02x\n", cmd_op->cap_info.cap_buf[i].id);
							printf_info("cap address offset--:0x%02x\n", cmd_op->cap_info.cap_buf[i].addr_offset);	
							printf_info("cap next address----:0x%02x\n", cmd_op->cap_info.cap_buf[i].next_offset);	
						}
					}
				}
				else
				{
					printf_info("cap nonsupport......\n");
				}
			}
			else
			{
				printf_error("cap error !!!\n");
			}

			for(i = 0; i < 4; i++)
			{
				printf_info("offset:0x%04x data: ", i*64);
				for(j = 0; j < 16; j++)
				{
					printf("%08x ", cmd_op->get_pci_dev_info.data[i*8 + j]);
				}
				printf("\n");
			}
		break;

		case tandem_num:
			cmd_op->delay = 0;
			pio_vaddr = map_mem(cmd_op->get_pci_dev_info.bar[0].bar_base, 4, &map_dev_mem);
			if(pio_vaddr == NULL)
			{
				printf_error("Tandem test, Address mapping failure !!!\n");
			}
			else
			{
				vaddr1 = (unsigned int *)(pio_vaddr + BAR_OFFSET_1);									/* 基地址Bar0*/
				vaddr2 = (unsigned int *)(pio_vaddr + BAR_OFFSET_2);									/* 基地址Bar0*/
				cmd_op->load_info.link_status = (unsigned char)(pio_read(vaddr1) & 0x0000001F); 		/* 查询PCIe链接状态 */
				if(LINK_OK == cmd_op->load_info.link_status)
				{
					printf_info("PCIe Link OK 0x%x\n", cmd_op->load_info.link_status);
					cmd_op->load_info.axi_direction = AXI_CONNECT_SWITCH;
					pio_write(vaddr2, command_operation.load_info.axi_direction & 0x0000000F);			/* 配置数据传输方向至转换模块 */
					value = open_load_file(bit_file_name, &load_file_info); 						/* 打开加载文件，并获取文件相关信息（文件字节大小等） */
					if(value > 0)
					{
						load_fial_bit(fd, cmd_op, &load_file_info, pio_vaddr);							/* 加载文件位流 */
					}
					else
					{
						printf_error("The tandem load file open failed !!!\n");
						break;
					}
					command_operation.load_info.load_status = LOAD_DATA_FINISH;
					pio_write(vaddr2, command_operation.load_info.load_status & 0x000000F0);			/* 写入位流加载完成标志 */
					
//					command_operation.load_info.crc = (unsigned char)(pio_read(vaddr1) & 0x00000F00);	/* 读取加载位流的CRC校验结果 */
					command_operation.load_info.crc = CRC_OK;											/* 读取加载位流的CRC校验结果 */
					if(CRC_OK == (cmd_op->load_info.crc & 0x00000F00))
					{
						cmd_op->load_info.axi_direction = AXI_CONNECT_USER;
						pio_write(vaddr2, command_operation.load_info.axi_direction & 0x0000000F);		/* 配置数据传输方向至用户模块 */
						printf_info("Load File Success\n");
					}
					else if(CRC_ERROR == (cmd_op->load_info.crc & 0x00000F00))
					{
						printf_error("CRC Failed !!!\n");
					}
					else if(CRC_REPEAT == (cmd_op->load_info.crc & 0x00000F00))
					{
						printf_info("CRC Repeat\n");
					}
					else
					{
						printf_error("CRC Status ERROR !!!\n");
					}
				}
				else
				{
					printf_error("PCIe Link Failed,link_status = 0x%x !!!\n", cmd_op->load_info.link_status);
				}
				unmap_mem(&map_dev_mem);
			}
		break;
		case performance_num:
		
		break;
		default:
		break;
	}
	nano_delay(cmd_op->delay);								/* 纳秒延时，不精确 */
}

/**************************************************************************
** 函数名称:    scroll_to_line
** 函数功能:    使得滚动窗口的滚动条滚到列表的某一行
** 输入参数:    scrolled_window：要操作的滚动窗口
**			line_num：列表中行数
**			to_line_index：要滚动到的那一行的行号，从0开始
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void scroll_to_line(GtkWidget *scrolled_window, gint line_num, gint to_line_index)
{
    GtkAdjustment *adj;
    gdouble lower_value, upper_value, page_size, max_value, line_height, to_value;
	
    adj = gtk_scrolled_window_get_vadjustment(GTK_SCROLLED_WINDOW(scrolled_window));
    lower_value = gtk_adjustment_get_lower(adj);
    upper_value = gtk_adjustment_get_upper(adj);
    page_size   = gtk_adjustment_get_page_size(adj);
    max_value   = upper_value;
    line_height = upper_value/line_num;
    to_value = line_height*to_line_index;
    if (to_value < lower_value)
        to_value = lower_value;
    if (to_value > max_value)
        to_value = max_value;

    gtk_adjustment_set_value(adj, to_value);
}

/**************************************************************************
** 函数名称:    create_text
** 函数功能:    自定义打印回调函数
** 输入参数:    *String：需要打印的字符串内容
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void create_text( const gchar *String )
{
	static int cnt = 0;
    static GString *TextString;
	static GtkTextMark *BeginPos;
	GtkTextIter Iter,Start,End;
    GtkTextBuffer *Buffer;
    GtkTextTag *Tag;	
	
    Buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(GuiWidgets[GuiScreen[20].num]));
	
    if(display == MSG_WARNING)
	{
		Tag = gtk_text_buffer_create_tag(Buffer, NULL, "foreground", "blue", NULL);
		TextString = g_string_new("[WARNING] ");
	}
	else if(display == MSG_ERROR)
	{ 
		Tag = gtk_text_buffer_create_tag(Buffer, NULL, "foreground", "red", NULL);
		TextString = g_string_new("[ERROR] ");
	}
	else if(display == MSG_DEBUG)
	{ 
		Tag = gtk_text_buffer_create_tag(Buffer, NULL, "foreground", "green", NULL);
		TextString = g_string_new("[DEBUG] ");
	}
	else /* if(display==MSG_INFO) or any other value */
	{ 
		Tag = gtk_text_buffer_create_tag(Buffer, NULL, "foreground", "black", NULL);
		TextString = g_string_new("[INFO] ");
	}
		
    g_string_append(TextString, String);
    gtk_text_buffer_get_end_iter(Buffer, &Iter);
    gtk_text_buffer_get_end_iter(Buffer, &Start);
    BeginPos = gtk_text_buffer_create_mark(Buffer, "begin_pos", &Iter, TRUE);
    gtk_text_view_scroll_mark_onscreen(GTK_TEXT_VIEW(GuiWidgets[GuiScreen[20].num]), BeginPos);
	//gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(Buffer),&Start,&End);
    gtk_text_buffer_insert(Buffer, &Iter, TextString->str, -1);
    gtk_text_buffer_get_end_iter(Buffer, &End);
    gtk_text_buffer_get_iter_at_mark(Buffer, &Start, BeginPos);
    gtk_text_buffer_apply_tag (Buffer, Tag , &Start, &End);
	
	scroll_to_line(GuiWidgets[GuiScreen[10].num], GuiScreen[GuiScreen[10].num].height/20, cnt++);
	g_string_free(TextString, TRUE);
}

/**************************************************************************
** 函数名称:    draw_widget
** 函数功能:    GUI窗口部件布局主函数
** 输入参数:    *MyGuiScreen：窗口部件信息结构体指针
**			*PWidgets[]：窗口部件实体参数指针数组
**			i：窗口部件编号
** 输出参数:    无
** 返回参数:    无
****************************************************************************/
void draw_widget(SCREEN_INFO *MyGuiScreen, void *PWidgets[], int i)
{
    GdkColor   color;
    int temp_id;
    char **text;
    char **data;
    GtkWidget**  MyGuiWidgets;
    MyGuiWidgets = (GtkWidget**)PWidgets;
    
    switch(MyGuiScreen[i].type)
    {
		case WINDOW:
			MyGuiWidgets[i] = gtk_window_new(GTK_WINDOW_TOPLEVEL);
			gtk_window_set_position(GTK_WINDOW(MyGuiWidgets[i]), GTK_WIN_POS_CENTER);
			gtk_widget_set_usize (GTK_WIDGET(MyGuiWidgets[i]), MyGuiScreen[i].width, MyGuiScreen[i].height);
			gtk_window_set_resizable(GTK_WINDOW(MyGuiWidgets[i]), MyGuiScreen[i].active);
			gtk_window_set_title(GTK_WINDOW(MyGuiWidgets[i]), MyGuiScreen[i].name);
			gtk_widget_show_all(MyGuiWidgets[i]);
		break;
		case FIXED:
			MyGuiWidgets[i] = gtk_fixed_new();
			gtk_container_add(GTK_CONTAINER(MyGuiWidgets[MyGuiScreen[i].parent]), MyGuiWidgets[i]);
		break;
		case NOTEBOOK:
			MyGuiWidgets[i] = gtk_notebook_new();
			gtk_notebook_set_tab_pos(GTK_NOTEBOOK(MyGuiWidgets[i]), GTK_POS_TOP);
			g_signal_connect(GTK_OBJECT(MyGuiWidgets[i]), "switch-page", G_CALLBACK(switch_page), NULL);
			gtk_fixed_put(GTK_FIXED(MyGuiWidgets[MyGuiScreen[i].parent]), MyGuiWidgets[i], MyGuiScreen[i].gint_x, MyGuiScreen[i].gint_y);
			gtk_widget_show(MyGuiWidgets[i]);
		break;
		case FRAME:
			if(TRUE == MyGuiScreen[i].active)
			{
				MyGuiWidgets[i] = gtk_frame_new(NULL);
				gtk_widget_set_size_request(MyGuiWidgets[i], MyGuiScreen[i].width, MyGuiScreen[i].height);
				GtkWidget *label = gtk_label_new(MyGuiScreen[i].name);
				gdk_color_parse(MyGuiScreen[i].Data, &color);
				gtk_widget_modify_fg(label, GTK_STATE_NORMAL, & color);
				gtk_notebook_append_page (GTK_NOTEBOOK (MyGuiWidgets[MyGuiScreen[i].parent]), MyGuiWidgets[i], label);
			}
			else
			{
				MyGuiWidgets[i] = gtk_frame_new(MyGuiScreen[i].name);
				gtk_widget_set_size_request(MyGuiWidgets[i], MyGuiScreen[i].width, MyGuiScreen[i].height);
				gtk_fixed_put(GTK_FIXED(MyGuiWidgets[MyGuiScreen[i].parent]), MyGuiWidgets[i], MyGuiScreen[i].gint_x, MyGuiScreen[i].gint_y);
			}
			gtk_widget_show (MyGuiWidgets[i]);
		break;
		case LABEL:
			MyGuiWidgets[i] = gtk_label_new(MyGuiScreen[i].name);
			gtk_fixed_put(GTK_FIXED(MyGuiWidgets[MyGuiScreen[i].parent]), MyGuiWidgets[i], MyGuiScreen[i].gint_x, MyGuiScreen[i].gint_y);
			gtk_widget_show(MyGuiWidgets[i]);
		break;
		case BUTTON:
			MyGuiWidgets[i] = gtk_button_new_with_label(MyGuiScreen[i].name);
			if(TRUE == MyGuiScreen[i].active)
			{
				gtk_widget_set_usize(MyGuiWidgets[i], MyGuiScreen[i].width, MyGuiScreen[i].height);
			}
			if(NULL != MyGuiScreen[i].Data)
			{
				gtk_widget_set_sensitive(GTK_WIDGET(MyGuiWidgets[i]), FALSE);	
			}
			gtk_fixed_put(GTK_FIXED(MyGuiWidgets[MyGuiScreen[i].parent]), MyGuiWidgets[i], MyGuiScreen[i].gint_x, MyGuiScreen[i].gint_y);
			gtk_widget_show(MyGuiWidgets[i]);
		break;
		case SCROLLED:
			MyGuiWidgets[i] = gtk_scrolled_window_new(NULL,NULL); 										/*创建滚动窗口构件*/
			gtk_fixed_put (GTK_FIXED (MyGuiWidgets[MyGuiScreen[i].parent]), MyGuiWidgets[i], MyGuiScreen[i].gint_x, MyGuiScreen[i].gint_y);
			gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(MyGuiWidgets[i]), GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
			gtk_widget_set_size_request(MyGuiWidgets[i], MyGuiScreen[i].width, MyGuiScreen[i].height);
			gtk_widget_show(MyGuiWidgets[i]);
		break;
		case TEXT:
			MyGuiWidgets[i] = gtk_text_view_new();						
			gtk_text_view_set_editable(GTK_TEXT_VIEW(MyGuiWidgets[i]), FALSE );
			gtk_scrolled_window_add_with_viewport(GTK_SCROLLED_WINDOW(MyGuiWidgets[MyGuiScreen[i].parent]), MyGuiWidgets[i]);
			gtk_widget_show(MyGuiWidgets[i]);
		break;
		case ENTRY:
			MyGuiWidgets[i] = gtk_entry_new();	
			gtk_entry_set_width_chars(GTK_ENTRY(MyGuiWidgets[i]), MyGuiScreen[i].width);				/* 设置entry宽度 */
			gtk_entry_set_max_length(GTK_ENTRY(MyGuiWidgets[i]), MyGuiScreen[i].width);					/* 设置entry数据输入最大长度 */
			gtk_entry_set_text(GTK_ENTRY(MyGuiWidgets[i]), (char *)MyGuiScreen[i].Data);				/* 设置初始值 */
			if(FALSE == MyGuiScreen[i].active) 
			{
				gtk_entry_set_editable(GTK_ENTRY(MyGuiWidgets[i]), FALSE); 
				if(NULL != MyGuiScreen[i].detailed_signal)
				{
					gdk_color_parse(MyGuiScreen[i].detailed_signal, &color);
					gtk_widget_modify_text(MyGuiWidgets[i], GTK_STATE_NORMAL,  &color);
				}
			}
			else
			{
				if(NULL != MyGuiScreen[i].detailed_signal)
				{
					temp_id = g_signal_connect(GTK_OBJECT(MyGuiWidgets[i]), "insert-text", G_CALLBACK(on_entry_insert_hex), NULL);
				}
				else
				{
					temp_id = g_signal_connect(GTK_OBJECT(MyGuiWidgets[i]), "insert-text", G_CALLBACK(on_entry_insert_digit), NULL);
				}
				
				if(entry_callback_id.config.num ==  MyGuiScreen[i].num)
				{
					entry_callback_id.config.id = temp_id;
				}
				else if(entry_callback_id.pio.num ==  MyGuiScreen[i].num)
				{
					entry_callback_id.pio.id = temp_id;
				}
				else if(entry_callback_id.start.num == MyGuiScreen[i].num)
				{
					entry_callback_id.start.id = temp_id;
				}
				else if(entry_callback_id.end.num == MyGuiScreen[i].num)
				{
					entry_callback_id.end.id = temp_id;
				}
				else if(entry_callback_id.alloc_mem.num == MyGuiScreen[i].num)
				{
					entry_callback_id.alloc_mem.id = temp_id;
				}
				else if(entry_callback_id.offset_addr.num == MyGuiScreen[i].num)
				{
					entry_callback_id.offset_addr.id = temp_id;
				}
				else if(entry_callback_id.data_length.num == MyGuiScreen[i].num)
				{
					entry_callback_id.data_length.id = temp_id;
				}
				else if(entry_callback_id.packet_size.num == MyGuiScreen[i].num)
				{
					entry_callback_id.packet_size.id = temp_id;
				}
			}
			
			gtk_fixed_put(GTK_FIXED(MyGuiWidgets[MyGuiScreen[i].parent]), MyGuiWidgets[i], MyGuiScreen[i].gint_x, MyGuiScreen[i].gint_y);
			gtk_widget_show(MyGuiWidgets[i]);
		break;
		case COMBO_BOX:
			MyGuiWidgets[i] = gtk_combo_box_new_text();	
			if("1" == MyGuiScreen[i].Data)
			{
				text = combo_box_text_1;
			}
			else if("2" == MyGuiScreen[i].Data)
			{
				text = combo_box_text_2;
			}
			else if("3" == MyGuiScreen[i].Data)
			{
				text = combo_box_text_3;
			}
			else if("4" == MyGuiScreen[i].Data)
			{
				text = combo_box_text_4;
			}
			else if("5" == MyGuiScreen[i].Data)
			{
				text = combo_box_text_5;
			}
			for(data = text; *data != NULL; data++)
			{
				gtk_combo_box_append_text(GTK_COMBO_BOX(MyGuiWidgets[i]), *data);
			}
			gtk_widget_set_usize(MyGuiWidgets[i], MyGuiScreen[i].width, MyGuiScreen[i].height);
			gtk_combo_box_set_active(GTK_COMBO_BOX(MyGuiWidgets[i]), MyGuiScreen[i].active);
			gtk_fixed_put(GTK_FIXED(MyGuiWidgets[MyGuiScreen[i].parent]), MyGuiWidgets[i], MyGuiScreen[i].gint_x, MyGuiScreen[i].gint_y);
			gtk_widget_show(MyGuiWidgets[i]);
		break;

		
	}
	
	if(MyGuiScreen[i].callback !=NULL)
	{
		g_signal_connect(MyGuiWidgets[i], MyGuiScreen[i].detailed_signal, GTK_SIGNAL_FUNC(MyGuiScreen[i].callback), GINT_TO_POINTER(MyGuiScreen[i].Data));
	}
}

int main(int argc, char * argv[])
{
	int i, Max;

#ifdef NO_TEST
    pci_driver_fd = open_pci_driver();
    enable_button(CLOSE_DMA_NUM);
    if(pci_driver_fd)
    {
#endif
		gtk_init(&argc, &argv);
		g_set_print_handler (create_text);
		Max = sizeof(GuiScreen) / sizeof(GuiScreen[0]) ;
		for(i = 0; i < Max; i++)
		{
			draw_widget(GuiScreen, GuiWidgets, i);
			if(GuiScreen[i].num != i) 
			{
				printf_error("GuiScreen[%d].num =	%dERROR\n", i, GuiScreen[i].num);
				msg_error("GuiScreen[%d].num =	%dERROR\n", i, GuiScreen[i].num);
			}
		}
		msg_info("%s\n", VEISION);
		#ifdef NO_TEST
			cmd_operation(pci_driver_fd, info_num, &command_operation);
		#endif
		msg_warning("The tandem load base address is [ Bar0 ]\n");
		gtk_widget_show_all(GuiWidgets[0]);
		
		g_thread_create((GThreadFunc)button_process,NULL,FALSE,NULL);				/* 兼容旧版本 */
		g_thread_create((GThreadFunc)button_status,NULL,FALSE,NULL); 				/* 兼容旧版本 */

//		g_thread_new("button_process",(GThreadFunc)button_process,NULL);
//		g_thread_new("button_status",(GThreadFunc)button_status,NULL);  
		
		gdk_threads_enter();
		gtk_main();
		gdk_threads_leave();
#ifdef NO_TEST
		close(pci_driver_fd);
    }
    else
#endif

    {
		printf_error("PCIe Device Open Fail !!!\n");
    }
    printf_info("Exit main\n" NONE);
	return 0;
}











