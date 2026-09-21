module alu_tb;
reg [31:0]a,b;
reg [2:0]f;
wire [31:0]y;
alu dut(a,b,f,y);
initial
begin  
    $dumpfile("alu_tb.vcd");
    $dumpvars(0,alu_tb);
    a=32'h00000009;
    b=32'h00000010;
    #10 f=3'b000;
    #10 f=3'b001;
    #10 f=3'b010;
    #10 f=3'b011;
    #10 f=3'b100;
    #10 f=3'b101;
    #10 f=3'b110;
    #10 f=3'b111;
  #100 $finish;
end
endmodule
