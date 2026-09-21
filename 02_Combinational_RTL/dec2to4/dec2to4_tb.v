module dec2to4_tb;
reg [1:0]a;
wire [3:0]y;
dec2to4 dut(a,y);
initial
begin
    $dumpfile("dec2to4_tb.vcd");
    $dumpvars(0,dec2to4_tb);
    #10 a=2'b00;
    #10 a=2'b01;
    #10 a=2'b10;
    #10 a=2'b11;
    #10;
end
endmodule