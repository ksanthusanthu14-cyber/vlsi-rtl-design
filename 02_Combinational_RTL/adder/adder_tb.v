module adder_tb;
reg a,b,cin;
wire s,c;
adder dut(a,b,cin,s,c);
initial
begin
    $dumpfile("adder_tb.vcd");
    $dumpvars(0,adder_tb);
    #10 a=0;b=0;cin=0;
    #10 a=0;b=0;cin=1;
    #10 a=0;b=1;cin=0;
    #10 a=0;b=1;cin=1;
    #10 a=1;b=0;cin=0;
    #10 a=1;b=0;cin=1;
    #10 a=1;b=1;cin=0;
    #10 a=1;b=1;cin=1;
    #10;
end
endmodule