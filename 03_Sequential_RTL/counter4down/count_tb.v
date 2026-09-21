module count_tb;
wire [3:0]a;
reg clk;
count dut(clk,a);
initial begin
    $dumpfile("count_tb.vcd");
    $dumpvars(0,count_tb);
end
initial begin
    clk=0;
    forever #5 clk=~clk;
end
initial begin
    #100;
    $finish;
end
endmodule