module jk(j,k,clk,q,qb);
input j,k,clk;
output reg q;
output qb;
always@(posedge clk)
case({j,k})
2'b00 : q<=q;
2'b01 : q<=1'b0;
2'b10 : q<=1'b1;
2'b11 : q<=~q;
endcase
assign qb=~q;
endmodule