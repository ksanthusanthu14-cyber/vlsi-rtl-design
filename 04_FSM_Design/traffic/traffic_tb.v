module traffic_tb;
reg clk,rst;
wire [1:0] highway,side;
traffic uut(clk,rst,highway,side);
initial
begin
    $dumpfile("traffic_tb.vcd");
    $dumpvars(0,traffic_tb);
end
initial
begin   
    clk=0;
    forever #5 clk=~clk;
end
//stimulus
initial begin
    rst =1;
    #10 rst =0;
    #100 $finish;
end
endmodule