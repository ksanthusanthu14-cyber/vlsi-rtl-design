module enc4to2(a,b,c,d,y0,y1);
input a,b,c,d;
output y0,y1;
assign y0=c|d;
assign y1=b|d;
endmodule