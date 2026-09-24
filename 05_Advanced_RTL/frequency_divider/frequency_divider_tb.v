module frequency_divider_tb;

reg clk;
reg rst;

wire clk_out;

frequency_divider #(
    .DIVIDE(4)
) dut (
    .clk(clk),
    .rst(rst),
    .clk_out(clk_out)
);

initial begin
    $dumpfile("frequency_divider_tb.vcd");
    $dumpvars(0, frequency_divider_tb);

    $monitor(
        "Time=%0t | rst=%b | clk=%b | clk_out=%b",
        $time,
        rst,
        clk,
        clk_out
    );
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    rst = 1;

    #10;

    rst = 0;

    #100;

    rst = 1;

    #10;

    rst = 0;

    #50;

    $finish;

end

endmodule