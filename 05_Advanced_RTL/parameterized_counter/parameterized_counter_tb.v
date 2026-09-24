module parameterized_counter_tb;

reg clk;
reg rst;

wire [7:0] count;

parameterized_counter #(
    .WIDTH(8)
) dut (
    .clk(clk),
    .rst(rst),
    .count(count)
);

initial begin
    $dumpfile("parameterized_counter_tb.vcd");
    $dumpvars(0, parameterized_counter_tb);

    $monitor("Time=%0t | Reset=%b | Count=%b (%0d)",
             $time, rst, count, count);
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

    $finish;
end

endmodule