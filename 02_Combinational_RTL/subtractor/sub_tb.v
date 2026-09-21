module sub_tb;
reg a,b,bin;
wire d,br;
sub dut(a,b,bin,d,br);
initial
begin
    $dumpfile("sub_tb.vcd");
    $dumpvars(0,sub_tb);
    #10 a=0;b=0;bin=0;
    #10 a=0;b=0;bin=1;
    #10 a=0;b=1;bin=0;
    #10 a=0;b=1;bin=1;
    #10 a=1;b=0;bin=0;
    #10 a=1;b=0;bin=1;
    #10 a=1;b=1;bin=0;
    #10 a=1;b=1;bin=1;
    #10;
end
endmodule