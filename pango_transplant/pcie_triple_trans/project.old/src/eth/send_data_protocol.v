module  send_data_protocol(
    input            clk_data_in,
    input            rst,
    input            clk_data_out,
    input            i_valid,
    input  [7:0]     i_data,
    output [15:0]    o_data,
    output reg       o_href,
    output reg       o_vsync

);

parameter INIT = 5'b00001;
parameter VSYNC = 5'b00010;
parameter DELAY = 5'b00100;
parameter WAIT = 5'b01000;
parameter HREF = 5'b10000;
parameter HREF_WIDTH = 'd1024;
parameter VSYNC_WIDTH = 'd16;
parameter DELAY_CNT   = 'd128;
parameter HREF_CNT    = 'd8;

wire          almost_full;
reg           rd_en;
reg           almost_full_d0;
reg [4:0]     state;

data_buff_fifo the_instance_name (
  .wr_clk(clk_data_in),                // input
  .wr_rst(~rst),                // input
  .wr_en(i_valid),                  // input
  .wr_data(i_data),              // input [7:0]
  .wr_full(),              // output
  .almost_full(almost_full),      // output
  .rd_clk(clk_data_out),                // input
  .rd_rst(~rst),                // input
  .rd_en(rd_en),                  // input
  .rd_data (o_data),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

//跨时钟打拍，以及延迟处理
always @(posedge clk_data_out or negedge rst) begin
    if (~rst) begin
        almost_full_d0 <= 1'b0;
        o_href <= 1'b0;
    end
    else begin
        almost_full_d0 <= almost_full;
        o_href <= rd_en;
    end
end
reg   [5:0]  v_width_cnt;
reg   [10:0]  h_width_cnt;
reg   [5:0]  h_cnt;
reg   [7:0]  delay_cnt;
//v_width_cnt计数
always @(posedge clk_data_out or negedge rst) begin
    if (~rst) begin
        v_width_cnt <= 5'b0;
    end
    else if (state == VSYNC) begin
            v_width_cnt <= v_width_cnt + 1'b1;
    end
    else begin
        v_width_cnt <= 5'b0;
    end
end

//delay_cnt计数
always @(posedge clk_data_out or negedge rst) begin
    if (~rst) begin
        delay_cnt <= 8'b0;
    end
    else if (state == DELAY) begin
            delay_cnt <= delay_cnt + 1'b1;
    end
    else begin
        delay_cnt <= 8'b0;
    end
end

//h_width_cnt 计数
always @(posedge clk_data_out or negedge rst) begin
    if (~rst) begin
        h_width_cnt <= 'b0;
    end
    else if (state == HREF) begin
            h_width_cnt <= h_width_cnt + 1'b1;
    end
    else begin
        h_width_cnt <= 'b0;
    end
end

//rd_en控制
always @(posedge clk_data_out or negedge rst) begin
    if (~rst) begin
        rd_en <= 1'b0;
    end
    else if(state == HREF) begin
        rd_en <= 1'b1;
    end
    else begin
        rd_en <= 1'b0;
    end
end

//o_vsync控制
always @(posedge clk_data_out or negedge rst) begin
    if (~rst) begin
        o_vsync <= 1'b0;
    end
    else if(state == VSYNC) begin
        o_vsync <= 1'b1;
    end
    else begin
        o_vsync <= 1'b0;
    end
end

//状态机跳转
always @(posedge clk_data_out or negedge rst) begin
    if (~rst) begin
        state <= INIT;
        h_cnt <= 5'b0;
    end
    else begin
        case (state)
            INIT: begin
                if (almost_full_d0 == 1'b1) begin   
                    state <= VSYNC;
                    h_cnt <= 'd0;
                end
            end
            VSYNC: begin
                if (v_width_cnt ==  VSYNC_WIDTH - 1'b1) begin
                    state <= DELAY;
                end
            end
            DELAY: begin
                if (delay_cnt == DELAY_CNT - 1'b1) begin
                    state <= WAIT;
                end
            end
            WAIT: begin
                if (almost_full_d0 == 1'b1) begin
                    state <= HREF;
                    h_cnt <= h_cnt + 1'b1;
                end
            end
            HREF: begin
                if (h_width_cnt == HREF_WIDTH - 1'b1) begin
                    if (h_cnt == HREF_CNT ) begin
                        state <= INIT;
                    end
                    else begin
                        state <= WAIT;
                    end
                end
            end
            default: begin
                state <= INIT;
                h_cnt <= 5'b0;
            end 
        endcase
    end
end


endmodule