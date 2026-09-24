module johnson_counter_tb;

reg clk;
reg rst;

wire [3:0] count;

johnson_counter #(
    .WIDTH(4)
) dut (
    .clk(clk),
    .rst(rst),
    .count(count)
);

initial begin
    $dumpfile("johnson_counter_tb.vcd");
    $dumpvars(0, johnson_counter_tb);

    $monitor(
        "Time=%0t | rst=%b | count=%b",
        $time,
        rst,
        count
    );
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    // Reset
    rst = 1;

    #10;

    // Release reset
    rst = 0;

    // Run through multiple states
    #100;

    // Apply reset again
    rst = 1;

    #10;

    rst = 0;

    #40;

    $finish;

end

endmodule