module mux4to1_tb;
reg a,b,c,d;
reg [1:0]s;
wire y;
mux4to1 dut(a,b,c,d,s,y);
initial 
begin
    $dumpfile("mux4to1_tb.vcd");
    $dumpvars(0,mux4to1_tb);
    a=1;b=0;c=1;d=0;
    #10 s=2'b00;
    #10 s=2'b01;
    #10 s=2'b10;
    #10 s=2'b11;
    #10 $finish;
end
endmodule