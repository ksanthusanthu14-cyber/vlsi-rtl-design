module deco2to4_tb;
reg a,b;
wire y0,y1,y2,y3;
deco2to4 dut (a,b,y0,y1,y2,y3);
initial
begin
    $dumpfile("deco2to4_tb.vcd");
    $dumpvars(0,deco2to4_tb);
    #10 a=0;b=0;
    #10 a=0;b=1;
    #10 a=1;b=0;
    #10 a=1;b=1;
    #10;
end
endmodule