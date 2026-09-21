module sub4_tb;
reg [3:0]a,b;
reg b0;
wire [3:0]d;
wire b4;
sub4 dut(a,b,b0,d,b4);
initial
begin
    $dumpfile("sub4_tb.vcd");
    $dumpvars(0,sub4_tb);
    a=4'b1111;b=4'b1111;b0=1'b0;
    #10 a=4'b1100;b=4'b0011;b0=1'b1;
    #10 a=4'b1111;b=4'b1100;b0=1'b0;
    #10 a=4'b1111;b=4'b0000;b0=1'b1;
    #10;
end
endmodule