module frame_sync_delay(
  input                data_clk           ,              
  input                data_href          ,             
	input                data_vsync         ,             
	input     [7:0]      source_data        ,            

  output               data_href_delay    ,       
	output               data_vsync_delay   ,       
	output     [7:0]     source_data_delay       
) ;

reg [2:0] href_buf ;
reg [2:0] vsync_buf ;
reg [7:0] data_d0 ;
reg [7:0] data_d1 ;
reg [7:0] data_d2 ;


always @(posedge data_clk)
begin 
  href_buf <= {href_buf[1:0], data_href} ;
end

always @(posedge data_clk)
begin 
  vsync_buf <= {vsync_buf[1:0], data_vsync} ;
end

always @(posedge data_clk)
begin 
  data_d0 <= source_data ;
  data_d1 <= data_d0 ;
  data_d2 <= data_d1 ;
end

assign data_href_delay = href_buf[2] ;
assign data_vsync_delay = vsync_buf[2] ;
assign source_data_delay = data_d2 ;



endmodule
