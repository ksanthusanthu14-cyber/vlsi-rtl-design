module vend_tb;
reg clk,rst,coin5,coin10;
wire dispense;
vend dut(clk,rst,coin5,coin10,dispense);
initial 
begin
    $dumpfile("vend_tb.vcd");
    $dumpvars(0,vend_tb);
end
initial begin
    clk=0;
    forever #5 clk=~clk;;
end
initial begin
    rst=1;
    coin5=0;
    coin10=0;
    #10 rst=0;
    #10 coin5=1;
    #10 coin5=0;
    #10 coin5=1;
    #10 coin5=0;
    #10 coin10=1;
    #10 coin10=0;
    #30 $finish;
end
endmodule