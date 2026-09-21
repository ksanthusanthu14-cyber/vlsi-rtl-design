module anda_tb;
reg a,b;
wire y;
anda dut(a,b,y);
initial
begin
    $dumpfile("anda_tb.vcd");
    $dumpvars(0,anda_tb);
    a=0;b=0;
    #10 a=0;b=1;
    #10 a=1;b=0;
    #10 a=1;b=1;
    #10;
end
endmodule