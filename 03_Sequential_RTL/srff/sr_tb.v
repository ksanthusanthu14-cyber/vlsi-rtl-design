module sr_tb;
reg s,r,clk;
wire q,qb;
sr dut(s,r,clk,q,qb);
initial begin
    $dumpfile("sr_tb.vcd");
    $dumpvars(0,sr_tb);
end
initial begin
    clk=0;
    forever #5 clk=~clk;
end
initial begin
    #10 s=0;r=0;
    #10 s=0;r=1;
    #10 s=1;r=0;
    #10 s=1;r=1;
    #10 $finish;
end
endmodule