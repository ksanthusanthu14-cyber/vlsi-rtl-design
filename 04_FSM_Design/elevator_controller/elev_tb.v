module elev_tb;
reg clk,rst,up,down;
wire motor_up,motor_down;
elev uut(clk,rst,up,down,motor_up,motor_down);
initial
begin
    $dumpfile("elev_tb.vcd");
    $dumpvars(0,elev_tb);
end
initial
begin
    clk=0;
    forever #5 clk=~clk;
end
initial begin
    rst=1;
    up=0;
    down=0;
    #10 rst=0;
    #10 up=1;
    #10 up=0;
    #10 down=1;
    #10 down=0;
    #30 $finish;
end
endmodule