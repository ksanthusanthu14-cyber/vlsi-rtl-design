module comp_tb;
reg a,b;
wire x,y,z;
comp dut(a,b,x,y,z);
initial
begin
    $dumpfile("comp_tb.vcd");
    $dumpvars(0,comp_tb);
    #10 a=0;b=0;
    #10 a=0;b=1;
    #10 a=1;b=0;
    #10 a=1;b=1;
    #10;
end
endmodule