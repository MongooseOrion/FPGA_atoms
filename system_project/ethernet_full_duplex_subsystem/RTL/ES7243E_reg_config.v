`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////
//ES7243E�мĴ��������ó���
 module ES7243E_reg_config(     
	input       clk_12M         ,
	input       rstn            ,
	output      reg_conf_done   ,
	output      i2c_sclk        ,
	inout       i2c_sdat        ,
    output      clock_i2c        
);

     reg [15:0]clock_cnt;
     reg [1:0]config_step/*synthesis PAP_MARK_DEBUG="1"*/;	  
     reg [23:0]i2c_data;
     reg [15:0]reg_data;
     reg start/*synthesis PAP_MARK_DEBUG="1"*/;
	 reg reg_conf_done_reg;
     reg clock_i2c/*synthesis PAP_MARK_DEBUG="1"*/;
     reg [8:0]reg_index/*synthesis PAP_MARK_DEBUG="1"*/;
	  
     i2c_com u_i2c_com(
         .clock_i2c     (clock_i2c      ),//input clock_i2c;
         .rstn          (rstn           ),//input rstn;
         .ack           (ack            ),//output ack;
         .i2c_data      (i2c_data       ),//input [23:0]i2c_data;
         .start         (start          ),//input start;
         .tr_end        (tr_end         ),//output tr_end;
         .i2c_sclk      (i2c_sclk       ),//output i2c_sclk;
         .i2c_sdat      (i2c_sdat       ) //inout i2c_sdat;
     );

assign reg_conf_done=reg_conf_done_reg;
//����i2c����ʱ��-100khz    
always@(posedge clk_12M)   
begin
   if(clock_cnt<14)//100K
      clock_cnt<=clock_cnt+1'b1;
   else begin
         clock_i2c<=!clock_i2c;
         clock_cnt<=0;
   end
end


////iic�Ĵ������ù��̿���    
always@(posedge clock_i2c)    
begin
   if(!rstn) begin
       config_step<=0;
       start<=0;
       reg_index<=0;
	   reg_conf_done_reg<=0;
   end
   else begin
      if(reg_conf_done_reg==1'b0) begin          //�����ʼ��δ���
			  if(reg_index<=38) begin               //���üĴ���
					 case(config_step)
					 0:begin
						i2c_data<={8'h20,reg_data};       //8'h28  IIC Device address is 0x28=0010 AD2 AD1 AD2 RW  
						start<=1;                         //i2cд��ʼ
						config_step<=1;                  
					 end
					 1:begin
						if(tr_end) begin                  //i2cд����               					
							 start<=0;
							 config_step<=2;
						end
					 end
					 2:begin
						  reg_index<=reg_index+1'b1;       //������һ���Ĵ���
						  config_step<=0;
					 end
					 endcase
				end
			 else 
				reg_conf_done_reg<=1'b1;                //�Ĵ�����ʼ�����
      end
   end
 end
			
////iic��Ҫ���õļĴ���ֵ  			
always@(reg_index)   
 begin
    case(reg_index)
	 0  :reg_data    <=16'h1000 ;//:V1000@//Version  2023.5.17 ��𩷢�ļĴ����б�
	 1  :reg_data    <=16'h013A ;//:w013A@                              
	 2  :reg_data    <=16'h0080 ;//:w0080@
	 3  :reg_data    <=16'h0402 ;//:w0402@
	 4  :reg_data    <=16'h0401 ;//:w0401@
	 5  :reg_data    <=16'hF901 ;//:wF901@
	 6  :reg_data    <=16'h001E ;//:w001E@
	 7  :reg_data    <=16'h0100 ;//:w0100@
	 8  :reg_data    <=16'h0200 ;//:w0200@
	 9  :reg_data    <=16'h0320 ;//:w0320@
	 10 :reg_data    <=16'h0D00 ;//:w0D00@
	 11 :reg_data    <=16'hF900 ;//:wF900@
	 12 :reg_data    <=16'h0402 ;//:w0402@
	 13 :reg_data    <=16'h0401 ;//:w0401@
	 14 :reg_data    <=16'h0500 ;//:w0500@
	 15 :reg_data    <=16'h0607 ;//:w0607@
	 16 :reg_data    <=16'h0700 ;//:w0700@
	 17 :reg_data    <=16'h08FF ;//:w08FF@
	 18 :reg_data    <=16'h09C5 ;//:w09C5@
	 19 :reg_data    <=16'h0A81 ;//:w0A81@
	 20 :reg_data    <=16'h0B0C ;//:w0B0C@
	 21 :reg_data    <=16'h0EBF ;//:w0EBF@
	 22 :reg_data    <=16'h0F80 ;//:w0F80@
	 23 :reg_data    <=16'h140C ;//:w140C@
	 24 :reg_data    <=16'h150C ;//:w150C@
	 25 :reg_data    <=16'h1702 ;//:w1702@
	 26 :reg_data    <=16'h1826 ;//:w1826@
	 27 :reg_data    <=16'h1977 ;//:w1977@
	 28 :reg_data    <=16'h1AF4 ;//:w1AF4@
	 29 :reg_data    <=16'h1B66 ;//:w1B66@
	 30 :reg_data    <=16'h1C44 ;//:w1C44@
	 31 :reg_data    <=16'h1E00 ;//:w1E00@
	 32 :reg_data    <=16'h1F0C ;//:w1F0C@
	 33 :reg_data    <=16'h2010 ;//:w2010@
	 34 :reg_data    <=16'h2110 ;//:w2110@
	 35 :reg_data    <=16'h00C0 ;//:w00C0@
	 36 :reg_data    <=16'h013A ;//:w013A@
	 37 :reg_data    <=16'h163F ;//:w163F@            
	 38 :reg_data    <=16'h1600 ;//:w1600@
    default:reg_data<=16'hffff  ;           
    endcase      
end	 

endmodule

