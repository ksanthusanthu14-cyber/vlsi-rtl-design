module sub4(a,b,b0,d,b4);
input [3:0]a,b;
input b0;
output [3:0]d;
output b4;
wire b1,b2,b3;
full_sub fs0(a[0],b[0],b0,d[0],b1);
full_sub fs1(a[1],b[1],b1,d[1],b2);
full_sub fs2(a[2],b[2],b2,d[2],b3);
full_sub fs3(a[3],b[3],b3,d[3],b4);
endmodule

module full_sub(A,B,Bin,D,Br);
input A,B,Bin;
output D,Br;
assign D=A^B^Bin;
assign Br=(~A&B)|(B&Bin)|(Bin&~A);
endmodule