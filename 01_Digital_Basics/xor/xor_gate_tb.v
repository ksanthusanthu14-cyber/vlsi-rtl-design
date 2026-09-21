module xor_gate_tb;
reg a,b;
wire y;
xor_gate dut(a,b,y);
initial 
begin
    $dumpfile("xor_gate_tb.vcd");
    $dumpvars(0,xor_gate_tb);
    #10 a=0;b=0;
    #10 a=0;b=1;
    #10 a=1;b=0;
    #10 a=1;b=1;
    #10;
end
endmodule