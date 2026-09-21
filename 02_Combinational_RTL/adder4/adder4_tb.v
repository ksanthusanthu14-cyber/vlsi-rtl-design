module adder4_tb;
reg [3:0]a,b;
reg c0;
wire [3:0]s;
wire c4;
adder4 dut(a,b,c0,s,c4);
initial
begin
    $dumpfile("adder4_tb.vcd");
    $dumpvars(0,adder4_tb);
    a=4'b1111;b=4'b1111;c0=1'b0;
    #10 a=4'b1100;b=4'b0011;c0=1'b1;
    #10 a=4'b1111;b=4'b1100;c0=1'b0;
    #10 a=4'b1111;b=4'b0000;c0=1'b1;
    #10;
end
endmodule