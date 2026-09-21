module sipo_tb;
reg sin,clk;
wire [3:0]q;
sipo uut(sin,clk,q);
initial
begin
    $dumpfile("sipo_tb.vcd");
    $dumpvars(0,sipo_tb);
end
initial
begin
    clk=0;
    forever #5 clk=~clk;
end
initial
begin
    sin=0;
    #10 sin=1;
    #10 sin=0;
    #10 sin=1;
    #10 sin=0;
    #10 $finish;
end
endmodule