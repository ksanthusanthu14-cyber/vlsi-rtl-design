module mux2to1_tb;
reg a,b,sel;
wire y;
mux2to1 dut(a,b,sel,y);
initial
begin
    $dumpfile("mux2to1_tb.vcd");
    $dumpvars(0,mux2to1_tb);
    #10 a=0;b=0;sel=0;
    #10 a=0;b=0;sel=1;
    #10 a=0;b=1;sel=0;
    #10 a=0;b=1;sel=1;
    #10 a=1;b=0;sel=0;
    #10 a=1;b=0;sel=1;
    #10 a=1;b=1;sel=0;
    #10 a=1;b=1;sel=1;
    #10;
end
endmodule