module moore_tb;
reg clk,rst;
wire y;
moore uut(clk,rst,y);
initial
begin
    $dumpfile("moore_tb.vcd");
    $dumpvars(0,moore_tb);
end 
initial
begin   
    clk=0;
    forever #5 clk=~clk;
end     
initial begin
    rst=1;
    #10 rst=0;
    #100 $finish;   
end
endmodule