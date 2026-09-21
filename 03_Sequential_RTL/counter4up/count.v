module count(a,clk);
input clk;
output reg [3:0]a;
initial
begin
    a=4'b0000;
end
always@(posedge clk)
begin
    a<=a+1;
end
endmodule
