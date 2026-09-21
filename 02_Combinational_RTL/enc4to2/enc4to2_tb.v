module enc4to2_tb;
reg a,b,c,d;
wire y0,y1;
enc4to2 dut(a,b,c,d,y0,y1);
initial 
begin
    $dumpfile("enc4to2_tb.vcd");
    $dumpvars(0,enc4to2_tb);
    #10 a=1;b=0;c=0;d=0;
    #10 a=0;b=1;c=0;d=0;
    #10 a=0;b=0;c=1;d=0;
    #10 a=0;b=0;c=0;d=1;
    #10;
end
endmodule