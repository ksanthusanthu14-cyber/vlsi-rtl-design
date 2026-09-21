module mux2to1(a,b,sel,y);
input a,b,sel;
output y;
assign y = sel ? b:a;
endmodule