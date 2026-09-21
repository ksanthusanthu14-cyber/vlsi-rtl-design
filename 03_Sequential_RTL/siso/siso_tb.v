module siso_tb;
reg sin,clk;
wire sout;
siso dut(sin,clk,sout);
initial begin
    $dumpfile("siso_tb.vcd");
    $dumpvars(0,siso_tb);
end
initial begin
    clk=0;
    forever #5 clk=~clk;
end
initial begin
    #10 sin=1'b1;
    #10 sin=1'b0;
    #10 sin=1'b1;
    #10 sin=1'b1;
    #10 $finish;
end
endmodule