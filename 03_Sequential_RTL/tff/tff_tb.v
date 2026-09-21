module tff_tb;
reg t,clk;
wire q,qb;
tff dut(t,clk,q,qb);
initial begin
    $dumpfile("tff_tb.vcd");
    $dumpvars(0,tff_tb);    
end
initial begin
    clk=0;
    forever #5 clk=~clk;
end
initial 
begin
    #10 t=0;
    #10 t=1;
    #10 $finish;
end
endmodule