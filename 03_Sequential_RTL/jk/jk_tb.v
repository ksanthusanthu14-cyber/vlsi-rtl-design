module jk_tb;
reg j,k,clk;
wire q,qb;
jk dut(j,k,clk,q,qb);
initial begin
    $dumpfile("jk_tb.vcd");
    $dumpvars(0,jk_tb);
end
initial begin
    clk=0;
    forever #5 clk=~clk;
end
initial begin
    #10 j=0;k=0;
    #10 j=0;k=1;
    #10 j=1;k=0;
    #10 j=1;k=1;
    #10 $finish;
end
endmodule