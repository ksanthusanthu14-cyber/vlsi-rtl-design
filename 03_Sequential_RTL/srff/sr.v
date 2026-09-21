module sr(s,r,clk,q,qb);
input s,r,clk;
output reg q;
output qb;
always@(posedge clk)
begin
case({s,r}) //we can use if/else loop wwith && ex: if (s==0 && r==0)
2'b00 : q<=q;
2'b01 : q<=1'b0;
2'b10 : q<=1'b1;
2'b11 : q<=1'bz;
endcase
end
assign qb=~q;
endmodule
