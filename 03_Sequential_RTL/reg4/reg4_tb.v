module reg4_tb;
reg [3:0]a;
reg clk;
wire [3:0]y;
reg4 dut(a,clk,y);
initial
begin
    $dumpfile("reg4_tb.vcd");
    $dumpvars(0,reg4_tb);
end
initial
begin
    clk=0;
    forever #5 clk=~clk;
end
initial
begin
    #10 a=4'b1111;
    #10 a=4'b0000;
    #10 a=4'b0011;
    #10 a=4'b1100;
    #10 $finish;
end
endmodule