module enfreq(
    input       clk,
    input       rst,
    output      multiple
);

wire        clk_temp;
wire        d_outn;
reg         d_outn = 0;

assign      clk_temp = clk^d_out;
assign      clk_out  = clk_temp;
assign      d_outn   = ~d_out;

always@(posedge clk_temp)
begin
    d_out <= d_outn;
end

endmodule