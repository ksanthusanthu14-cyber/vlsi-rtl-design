module sipo(sin,clk,q);
input sin,clk;
output reg [3:0]q;
always@(posedge clk)
begin
    q<={q[2:0],sin};
end
endmodule