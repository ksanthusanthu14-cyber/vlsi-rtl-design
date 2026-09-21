module mux2to1_tb;
reg a,b,s;
wire y;
mux2to1 dut(a,b,s,y);
initial
begin
    $dumpfile("mux2to1_tb.vcd");
    $dumpvars(0,mux2to1_tb);
    #10 a=0;b=0;s=0;
    #10 a=0;b=0;s=1;
    #10 a=0;b=1;s=0;
    #10 a=0;b=1;s=1;
    #10 a=1;b=0;s=0;
    #10 a=1;b=0;s=1;
    #10 a=1;b=1;s=0;
    #10 a=1;b=1;s=1;
    #10;
end
endmodule