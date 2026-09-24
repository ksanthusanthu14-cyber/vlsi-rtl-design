module universal_shift_register_tb;

reg clk;
reg rst;
reg [1:0] mode;

reg serial_in_left;
reg serial_in_right;
reg [3:0] parallel_in;

wire [3:0] data_out;

universal_shift_register #(
    .WIDTH(4)
) dut (
    .clk(clk),
    .rst(rst),
    .mode(mode),
    .serial_in_left(serial_in_left),
    .serial_in_right(serial_in_right),
    .parallel_in(parallel_in),
    .data_out(data_out)
);

initial begin
    $dumpfile("universal_shift_register_tb.vcd");
    $dumpvars(0, universal_shift_register_tb);

    $monitor(
        "Time=%0t | rst=%b | mode=%b | parallel=%b | left=%b | right=%b | data_out=%b",
        $time,
        rst,
        mode,
        parallel_in,
        serial_in_left,
        serial_in_right,
        data_out
    );
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    // Initial values
    rst = 1;
    mode = 2'b00;
    serial_in_left = 0;
    serial_in_right = 0;
    parallel_in = 4'b0000;

    #10;

    // Release reset
    rst = 0;

    // Parallel load 1010
    #5;
    mode = 2'b11;
    parallel_in = 4'b1010;

    #10;

    // Hold
    mode = 2'b00;

    #10;

    // Shift right
    // 1010 -> 0101
    mode = 2'b01;
    serial_in_left = 0;

    #10;

    // Shift right again
    // 0101 -> 0010
    serial_in_left = 0;

    #10;

    // Shift left
    // 0010 -> 0101
    mode = 2'b10;
    serial_in_right = 1;

    #10;

    // Parallel load 1100
    mode = 2'b11;
    parallel_in = 4'b1100;

    #10;

    // Shift left
    // 1100 -> 1001
    mode = 2'b10;
    serial_in_right = 1;

    #10;

    // Hold
    mode = 2'b00;

    #10;

    $finish;

end

endmodule