module dff(d,clk,rst,q,qb);
input d,clk,rst;
output reg q;
output qb;
always@(posedge clk)
begin
    if (rst==1)
        q<=0;
    else
        q<=d;
end
assign qb=~q;
endmodule