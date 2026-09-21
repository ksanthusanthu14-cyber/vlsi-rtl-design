module mux4to1_tb;
reg a,b,c,d;
reg [1:0]s;
wire y;
mux4to1 dut(a,b,c,d,s,y);
initial
begin
    $dumpfile("mux4to1_tb.vcd");
    $dumpvars(0,mux4to1_tb);
    #10 a=1;b=0;c=0;d=0;s=2'b00;
    #10 a=0;b=1;c=0;d=0;s=2'b01;
    #10 a=0;b=0;c=1;d=0;s=2'b10;
    #10 a=0;b=0;c=0;d=1;s=2'b11;
    #10;
end
endmodule