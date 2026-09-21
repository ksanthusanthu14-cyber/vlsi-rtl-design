module not_gate_tb;
reg a;
wire y;
not_gate dut(a,y);
initial
begin
    $dumpfile("not_gate_tb.vcd");
    $dumpvars(0,not_gate_tb);
    #10 a=0;
    #10 a=1;
    #10;
end
endmodule