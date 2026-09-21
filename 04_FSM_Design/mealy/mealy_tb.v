module mealy_tb;
reg clk,rst,x;
wire y;
mealy uut(clk,rst,x,y);
initial
begin
    $dumpfile("mealy_tb.vcd");
    $dumpvars(0,mealy_tb);
end
initial
begin   
    clk=0;
    forever #5 clk=~clk;
end
//stimulus
initial begin
    rst =1;
    x=0;
    #10 rst =0;
    #10 x =0;
    #10 x =1;
    #10 x =0;
    #10 x =1;
    #10 x =1;
    #10 x =0;
    #20 $finish;
end
endmodule
