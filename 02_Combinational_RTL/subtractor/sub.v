module sub(a,b,bin,d,br);
input a,b,bin;
output d,br;
assign d=a^b^bin;
assign br=(~a&b)|(b&bin)|(bin&~a);
endmodule