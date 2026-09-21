module count(clk,a);
input clk;
output reg [3:0]a;
initial begin
    a=4'b1111;
end
always@(posedge clk)
begin
    a<=a-1;
end
endmodule