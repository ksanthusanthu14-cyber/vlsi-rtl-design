module enc4to2_tb;
reg [3:0]a;
wire [1:0]y;
enc4to2 dut(a,y);
initial
begin
    $dumpfile("enc4to2_tb.vcd");
    $dumpvars(0,enc4to2_tb);
    #10 a=4'b0001;
    #10 a=4'b0010;
    #10 a=4'b0100;
    #10 a=4'b1000;
    #10 $finish;
end
endmodule