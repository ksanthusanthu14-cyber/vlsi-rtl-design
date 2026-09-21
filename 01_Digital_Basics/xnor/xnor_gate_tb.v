module xnor_gate_tb;
reg a,b;
wire y;
xnor_gate dut(a,b,y);
initial 
begin
    $dumpfile("xnor_gate_tb.vcd");
    $dumpvars(0,xnor_gate_tb);
    #10 a=0;b=0;
    #10 a=0;b=1;
    #10 a=1;b=0;
    #10 a=1;b=1;
    #10;
end
endmodule