module dff_tb;
reg d,clk;
wire q,qb;
dff dut(d,clk,q,qb);
initial
begin
    $dumpfile("dff_tb.vcd");
    $dumpvars(0,dff_tb);
end
initial
begin
    clk=0;
    forever #5 clk=~clk;
end
initial
begin
    d=0;
    #10 d=1;
    #10 d=0;
    #10 d=1;
    #10 $finish;
end
endmodule
