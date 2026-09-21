module ora_tb;
reg a,b;
wire y;
ora dut(a,b,y);
initial
begin
    $dumpfile("ora_tb.vcd");
    $dumpvars(0,ora_tb);
    #10 a=0;b=0;
    #10 a=0;b=1;
    #10 a=1;b=0;
    #10 a=1;b=1;
    #10;
end
endmodule