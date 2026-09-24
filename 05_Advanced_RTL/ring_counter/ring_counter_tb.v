module ring_counter_tb;

reg clk;
reg rst;

wire [3:0] count;

ring_counter #(
    .WIDTH(4)
) dut (
    .clk(clk),
    .rst(rst),
    .count(count)
);

initial begin
    $dumpfile("ring_counter_tb.vcd");
    $dumpvars(0, ring_counter_tb);

    $monitor(
        "Time=%0t | rst=%b | count=%b",
        $time,
        rst,
        count
    );
end

// 10 time-unit clock period
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    // Apply reset
    rst = 1;

    #10;

    // Release reset
    rst = 0;

    // Allow counter to rotate
    #80;

    // Test reset again
    rst = 1;

    #10;

    rst = 0;

    #40;

    $finish;

end

endmodule