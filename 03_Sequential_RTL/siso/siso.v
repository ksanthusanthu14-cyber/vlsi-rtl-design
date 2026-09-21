module siso(sin,clk,sout);
input sin,clk;
output sout;
reg [3:0]shift;
always@(posedge clk)
begin
    shift<={shift[2:0],sin};
end
assign sout = shift[3];
endmodule